package bitbucket

import (
	"strings"
	"testing"
)

func reviewerRoutes(defaults, members string) map[string]route {
	return map[string]route{
		"GET /user": {body: `{"uuid":"{me}","display_name":"Keanu"}`},
		"GET /repositories/ws/repo/effective-default-reviewers": {body: `{"values":[` + defaults + `]}`},
		"GET /workspaces/ws/members":                            {body: `{"values":[` + members + `]}`},
	}
}

func keys(users []User) string {
	var out []string
	for _, u := range users {
		out = append(out, u.key())
	}
	return strings.Join(out, ",")
}

func TestResolveReviewersDefaultsAndNames(t *testing.T) {
	c, _ := fakeAPI(t, reviewerRoutes(
		`{"user":{"display_name":"Lachlan","uuid":"{lach}"}}`,
		`{"user":{"display_name":"Joshua Pinalli","nickname":"josh","uuid":"{josh}"}}`,
	))
	users, err := c.ResolveReviewers(ctx, "ws", "repo", []string{"JOSH"}, true, User{UUID: "{me}"})
	if err != nil {
		t.Fatal(err)
	}
	if keys(users) != "{lach},{josh}" {
		t.Fatalf("users = %s", keys(users))
	}
}

func TestResolveReviewersDropsAuthor(t *testing.T) {
	c, _ := fakeAPI(t, reviewerRoutes(
		`{"user":{"display_name":"Keanu","uuid":"{me}"}},{"user":{"display_name":"Lachlan","uuid":"{lach}"}}`, ``,
	))
	users, err := c.ResolveReviewers(ctx, "ws", "repo", nil, true, User{UUID: "{me}"})
	if err != nil {
		t.Fatal(err)
	}
	if keys(users) != "{lach}" {
		t.Fatalf("users = %s, want the author removed", keys(users))
	}
}

func TestResolveReviewersDeduplicates(t *testing.T) {
	c, _ := fakeAPI(t, reviewerRoutes(
		`{"user":{"display_name":"Lachlan","uuid":"{lach}"}}`,
		`{"user":{"display_name":"Lachlan","uuid":"{lach}"}}`,
	))
	users, _ := c.ResolveReviewers(ctx, "ws", "repo", []string{"Lachlan"}, true, User{UUID: "{me}"})
	if keys(users) != "{lach}" {
		t.Fatalf("users = %s", keys(users))
	}
}

func TestResolveReviewersAmbiguous(t *testing.T) {
	c, _ := fakeAPI(t, reviewerRoutes(``,
		`{"user":{"display_name":"Josh","nickname":"jp","uuid":"{a}"}},{"user":{"display_name":"josh","nickname":"jb","uuid":"{b}"}}`,
	))
	_, err := c.ResolveReviewers(ctx, "ws", "repo", []string{"Josh"}, false, User{UUID: "{me}"})
	if err == nil || !strings.Contains(err.Error(), "jp") || !strings.Contains(err.Error(), "jb") {
		t.Fatalf("err = %v, want both candidates listed", err)
	}
}

func TestResolveReviewersNoMatch(t *testing.T) {
	c, _ := fakeAPI(t, reviewerRoutes(``, `{"user":{"display_name":"Josh","uuid":"{a}"}}`))
	_, err := c.ResolveReviewers(ctx, "ws", "repo", []string{"Nobody"}, false, User{UUID: "{me}"})
	if err == nil || !strings.Contains(err.Error(), "Nobody") {
		t.Fatalf("err = %v", err)
	}
}

func TestResolveReviewersPassesThroughIDs(t *testing.T) {
	c, reqs := fakeAPI(t, reviewerRoutes(``, ``))
	users, err := c.ResolveReviewers(ctx, "ws", "repo",
		[]string{"{0b8e6a7e-1111-2222-3333-444455556666}", "557058:0b8e6a7e-1111-2222-3333-444455556666", "5b10ac8d82e05b22cc7d4ef5"}, false, User{UUID: "{me}"})
	if err != nil {
		t.Fatal(err)
	}
	if len(users) != 3 || users[0].UUID == "" || users[1].AccountID == "" || users[2].AccountID == "" {
		t.Fatalf("users = %+v", users)
	}
	for _, r := range *reqs {
		if r.Path == "/workspaces/ws/members" {
			t.Fatalf("members fetched although every reviewer was an id")
		}
	}
}

func TestResolveReviewersNoMatchSuggests(t *testing.T) {
	c, _ := fakeAPI(t, reviewerRoutes(``,
		`{"user":{"display_name":"Joshua Pinalli","nickname":"josh","account_id":"557058:aaa","uuid":"{josh}"}},{"user":{"display_name":"Lachlan","uuid":"{lach}"}}`))
	_, err := c.ResolveReviewers(ctx, "ws", "repo", []string{"pinalli"}, false, User{UUID: "{me}"})
	if err == nil || !strings.Contains(err.Error(), "Joshua Pinalli") || strings.Contains(err.Error(), "Lachlan") {
		t.Fatalf("err = %v, want the partial match suggested and nothing else", err)
	}
}
