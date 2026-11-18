package bitbucket

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"testing"
)

var ctx = context.Background()

const prBase = "/repositories/ws/repo/pullrequests"

const samplePR = `{
  "id": 7, "title": "Add thing", "description": "Why", "state": "OPEN", "draft": false,
  "author": {"display_name": "Keanu", "uuid": "{me}"},
  "source": {"branch": {"name": "feature/x"}},
  "destination": {"branch": {"name": "dev"}},
  "reviewers": [{"display_name": "Josh", "uuid": "{josh}"}, {"display_name": "Lachlan", "uuid": "{lach}"}],
  "participants": [{"user": {"display_name": "Josh", "uuid": "{josh}"}, "role": "REVIEWER", "approved": true, "state": "approved"}],
  "links": {"html": {"href": "https://bitbucket.org/ws/repo/pull-requests/7"}},
  "comment_count": 2
}`

func TestListPRsSendsStateAndTrims(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{"GET " + prBase: {body: `{"values":[` + samplePR + `]}`}})
	prs, err := c.ListPRs(ctx, "ws", "repo", "MERGED", 10)
	if err != nil {
		t.Fatal(err)
	}
	if got := last(reqs).Query["state"]; len(got) != 1 || got[0] != "MERGED" {
		t.Fatalf("state query = %v", got)
	}
	pr := prs[0]
	if pr.ID != 7 || pr.Source != "feature/x" || pr.Destination != "dev" || pr.Author != "Keanu" || pr.URL == "" {
		t.Fatalf("pr = %+v", pr)
	}
}

func TestGetPRMergesReviewersIntoParticipants(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"GET " + prBase + "/7": {body: samplePR}})
	pr, err := c.GetPR(ctx, "ws", "repo", 7)
	if err != nil {
		t.Fatal(err)
	}
	if len(pr.Participants) != 2 {
		t.Fatalf("participants = %+v, want approved Josh plus pending Lachlan", pr.Participants)
	}
	if !pr.Participants[0].Approved || pr.Participants[1].Name != "Lachlan" || pr.Participants[1].Role != "REVIEWER" {
		t.Fatalf("participants = %+v", pr.Participants)
	}
}

func TestCreatePRBody(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{
		"POST " + prBase:             {status: http.StatusCreated, body: samplePR},
		"GET /user":                  {body: `{"uuid":"{me}"}`},
		"GET /workspaces/ws/members": {body: `{"values":[{"user":{"display_name":"Josh Pinalli","uuid":"{josh}"}}]}`},
		"GET /repositories/ws/repo/effective-default-reviewers": {body: `{"values":[{"user":{"display_name":"Lachlan","uuid":"{lach}"}}]}`},
	})
	_, err := c.CreatePR(ctx, "ws", "repo", CreateInput{
		Title: "T", Description: "D", Source: "feature/x", Destination: "dev",
		Reviewers: []string{"josh pinalli"}, DefaultReviewers: true, Draft: true, CloseSourceBranch: true,
	})
	if err != nil {
		t.Fatal(err)
	}
	body := last(reqs).Body
	if dig(body, "source", "branch", "name") != "feature/x" || dig(body, "destination", "branch", "name") != "dev" {
		t.Fatalf("branches in body = %v", body)
	}
	if body["title"] != "T" || body["description"] != "D" || body["draft"] != true || body["close_source_branch"] != true {
		t.Fatalf("body = %v", body)
	}
	reviewers, _ := body["reviewers"].([]any)
	if len(reviewers) != 2 {
		t.Fatalf("reviewers = %v, want default Lachlan + named Josh", reviewers)
	}
}

func TestEditPRAddsReviewersAndKeepsTitle(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{
		"GET " + prBase + "/7":       {body: samplePR},
		"PUT " + prBase + "/7":       {body: samplePR},
		"GET /user":                  {body: `{"uuid":"{me}"}`},
		"GET /workspaces/ws/members": {body: `{"values":[{"user":{"display_name":"Sam","uuid":"{sam}"}}]}`},
	})
	if _, err := c.EditPR(ctx, "ws", "repo", 7, EditInput{Reviewers: []string{"Sam"}}); err != nil {
		t.Fatal(err)
	}
	body := last(reqs).Body
	if body["title"] != "Add thing" || body["description"] != "Why" {
		t.Fatalf("body = %v, want current title and description re-sent", body)
	}
	if reviewers, _ := body["reviewers"].([]any); len(reviewers) != 3 {
		t.Fatalf("reviewers = %v, want Josh + Lachlan + Sam", body["reviewers"])
	}
	if _, ok := body["destination"]; ok {
		t.Fatalf("destination sent without being changed: %v", body)
	}
}

func TestCommentInline(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{"POST " + prBase + "/7/comments": {status: http.StatusCreated, body: `{"id":1,"content":{"raw":"hi"}}`}})
	if _, err := c.AddComment(ctx, "ws", "repo", 7, CommentInput{Body: "hi", Path: "a.go", Line: 12}); err != nil {
		t.Fatal(err)
	}
	body := last(reqs).Body
	if dig(body, "content", "raw") != "hi" || dig(body, "inline", "path") != "a.go" || dig(body, "inline", "to") != float64(12) {
		t.Fatalf("body = %v", body)
	}
}

func TestCommentOldLineUsesFrom(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{"POST " + prBase + "/7/comments": {status: http.StatusCreated, body: `{"id":1}`}})
	c.AddComment(ctx, "ws", "repo", 7, CommentInput{Body: "x", Path: "a.go", Line: 3, LineIsOld: true})
	body := last(reqs).Body
	if dig(body, "inline", "from") != float64(3) || dig(body, "inline", "to") != nil {
		t.Fatalf("body = %v", body)
	}
}

func TestCommentReply(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{"POST " + prBase + "/7/comments": {status: http.StatusCreated, body: `{"id":2}`}})
	c.AddComment(ctx, "ws", "repo", 7, CommentInput{Body: "x", ParentID: 1})
	body := last(reqs).Body
	if dig(body, "parent", "id") != float64(1) || body["inline"] != nil {
		t.Fatalf("body = %v", body)
	}
}

func TestCommentsSkipDeletedAndTrim(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"GET " + prBase + "/7/comments": {body: `{"values":[
	  {"id":1,"content":{"raw":"a"},"user":{"display_name":"Josh"},"inline":{"path":"x.go","to":4},"created_on":"t"},
	  {"id":2,"content":{"raw":""},"deleted":true},
	  {"id":3,"content":{"raw":"b"},"user":{"display_name":"Keanu"},"parent":{"id":1}}]}`}})
	comments, err := c.Comments(ctx, "ws", "repo", 7, 0)
	if err != nil {
		t.Fatal(err)
	}
	if len(comments) != 2 || comments[0].Path != "x.go" || comments[0].Line != 4 || comments[1].ParentID != 1 {
		t.Fatalf("comments = %+v", comments)
	}
}

func TestReviewActions(t *testing.T) {
	cases := []struct {
		name, method, suffix string
		call                 func(*Client) error
	}{
		{"approve", "POST", "/approve", func(c *Client) error { return c.Approve(ctx, "ws", "repo", 7) }},
		{"unapprove", "DELETE", "/approve", func(c *Client) error { return c.Unapprove(ctx, "ws", "repo", 7) }},
		{"request-changes", "POST", "/request-changes", func(c *Client) error { return c.RequestChanges(ctx, "ws", "repo", 7) }},
		{"remove-request-changes", "DELETE", "/request-changes", func(c *Client) error { return c.RemoveRequestChanges(ctx, "ws", "repo", 7) }},
		{"decline", "POST", "/decline", func(c *Client) error { return c.Decline(ctx, "ws", "repo", 7) }},
	}
	for _, tc := range cases {
		c, reqs := fakeAPI(t, map[string]route{tc.method + " " + prBase + "/7" + tc.suffix: {body: `{}`}})
		if err := tc.call(c); err != nil || len(*reqs) != 1 {
			t.Errorf("%s: err=%v reqs=%v", tc.name, err, *reqs)
		}
	}
}

func TestMergeOmitsStrategyWhenEmpty(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{"POST " + prBase + "/7/merge": {body: samplePR}})
	if _, err := c.Merge(ctx, "ws", "repo", 7, MergeInput{}); err != nil {
		t.Fatal(err)
	}
	if _, ok := last(reqs).Body["merge_strategy"]; ok {
		t.Fatalf("body = %v, want no merge_strategy so the branch default applies", last(reqs).Body)
	}
}

func TestMergeSendsStrategy(t *testing.T) {
	c, reqs := fakeAPI(t, map[string]route{"POST " + prBase + "/7/merge": {body: samplePR}})
	closeBranch := true
	c.Merge(ctx, "ws", "repo", 7, MergeInput{Strategy: "squash", Message: "m", CloseSourceBranch: &closeBranch})
	body := last(reqs).Body
	if body["merge_strategy"] != "squash" || body["message"] != "m" || body["close_source_branch"] != true {
		t.Fatalf("body = %v", body)
	}
}

func TestMerge202ReturnsInProgress(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"POST " + prBase + "/7/merge": {
		status: http.StatusAccepted, header: map[string]string{"Location": "https://api.bitbucket.org/2.0/x/merge/task-status/1"},
	}})
	pr, err := c.Merge(ctx, "ws", "repo", 7, MergeInput{})
	if err != nil {
		t.Fatal(err)
	}
	if pr.ID != 7 || pr.State != "MERGE_IN_PROGRESS" || !strings.Contains(pr.URL, "task-status") {
		t.Fatalf("pr = %+v", pr)
	}
}

const twoFileDiff = "diff --git a/a.go b/a.go\n--- a/a.go\n+++ b/a.go\n@@ -1 +1 @@\n-x\n+y\n" +
	"diff --git a/b.go b/b.go\n--- a/b.go\n+++ b/b.go\n@@ -1 +1 @@\n-p\n+q\n"

func TestDiffFiltersPath(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"GET " + prBase + "/7/diff": {body: twoFileDiff}})
	got, err := c.Diff(ctx, "ws", "repo", 7, "b.go")
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(got, "a.go") || !strings.Contains(got, "+q") {
		t.Fatalf("diff = %q, want only b.go", got)
	}
	all, _ := c.Diff(ctx, "ws", "repo", 7, "")
	if all != twoFileDiff {
		t.Fatalf("full diff altered: %q", all)
	}
}

func TestDiffStat(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"GET " + prBase + "/7/diffstat": {body: `{"values":[
	  {"status":"modified","lines_added":1,"lines_removed":2,"old":{"path":"a.go"},"new":{"path":"a.go"}},
	  {"status":"removed","lines_removed":5,"old":{"path":"gone.go"},"new":null}]}`}})
	stats, err := c.DiffStat(ctx, "ws", "repo", 7)
	if err != nil {
		t.Fatal(err)
	}
	if len(stats) != 2 || stats[0].Added != 1 || stats[1].Path != "gone.go" || stats[1].Status != "removed" {
		t.Fatalf("stats = %+v", stats)
	}
}

func TestStatuses(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"GET " + prBase + "/7/statuses": {body: `{"values":[
	  {"key":"k","name":"Pipeline #1","state":"SUCCESSFUL","url":"https://x"}]}`}})
	statuses, err := c.Statuses(ctx, "ws", "repo", 7)
	if err != nil || len(statuses) != 1 || statuses[0].State != "SUCCESSFUL" || statuses[0].Name != "Pipeline #1" {
		t.Fatalf("statuses = %+v err = %v", statuses, err)
	}
}

func TestMainBranch(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"GET /repositories/ws/repo": {body: `{"mainbranch":{"name":"dev"}}`}})
	if b, err := c.MainBranch(ctx, "ws", "repo"); err != nil || b != "dev" {
		t.Fatalf("MainBranch = %q, %v", b, err)
	}
}

func TestEditPRDropsPRAuthorNotMe(t *testing.T) {
	joshsPR := `{"id":9,"title":"T","description":"D","author":{"display_name":"Josh","uuid":"{josh}"},"reviewers":[]}`
	c, reqs := fakeAPI(t, map[string]route{
		"GET " + prBase + "/9": {body: joshsPR},
		"PUT " + prBase + "/9": {body: joshsPR},
		"GET /user":            {body: `{"uuid":"{me}"}`},
		"GET /workspaces/ws/members": {body: `{"values":[
		  {"user":{"display_name":"Keanu Ashwell","uuid":"{me}"}},{"user":{"display_name":"Josh","uuid":"{josh}"}}]}`},
	})
	if _, err := c.EditPR(ctx, "ws", "repo", 9, EditInput{Reviewers: []string{"Keanu Ashwell", "Josh"}}); err != nil {
		t.Fatal(err)
	}
	reviewers, _ := last(reqs).Body["reviewers"].([]any)
	if len(reviewers) != 1 || dig(reviewers[0].(map[string]any), "uuid") != "{me}" {
		t.Fatalf("reviewers = %v, want me added and the PR author (Josh) dropped", reviewers)
	}
}

func TestEditPRKeepsDraftAndCloseSourceBranch(t *testing.T) {
	draftPR := `{"id":9,"title":"T","description":"D","draft":true,"close_source_branch":true,"reviewers":[]}`
	c, reqs := fakeAPI(t, map[string]route{
		"GET " + prBase + "/9": {body: draftPR},
		"PUT " + prBase + "/9": {body: draftPR},
	})
	title := "New"
	if _, err := c.EditPR(ctx, "ws", "repo", 9, EditInput{Title: &title}); err != nil {
		t.Fatal(err)
	}
	body := last(reqs).Body
	if body["draft"] != true || body["close_source_branch"] != true {
		t.Fatalf("body = %v, want draft and close_source_branch re-sent", body)
	}
}

func TestDiffUnknownPathErrors(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{"GET " + prBase + "/7/diff": {body: twoFileDiff}})
	_, err := c.Diff(ctx, "ws", "repo", 7, "missing.go")
	if err == nil || !strings.Contains(err.Error(), "missing.go") {
		t.Fatalf("err = %v, want an error naming the path", err)
	}
}

func TestEmptyListsEncodeAsArrays(t *testing.T) {
	c, _ := fakeAPI(t, map[string]route{
		"GET " + prBase:                 {body: `{"values":[]}`},
		"GET " + prBase + "/7/diffstat": {body: `{"values":[]}`},
		"GET " + prBase + "/7/comments": {body: `{"values":[]}`},
		"GET " + prBase + "/7/statuses": {body: `{"values":[]}`},
	})
	prs, err1 := c.ListPRs(ctx, "ws", "repo", "OPEN", 10)
	stats, err2 := c.DiffStat(ctx, "ws", "repo", 7)
	comments, err3 := c.Comments(ctx, "ws", "repo", 7, 10)
	statuses, err4 := c.Statuses(ctx, "ws", "repo", 7)
	if err := errors.Join(err1, err2, err3, err4); err != nil {
		t.Fatal(err)
	}
	for name, v := range map[string]any{"prs": prs, "stats": stats, "comments": comments, "statuses": statuses} {
		if b, _ := json.Marshal(v); string(b) != "[]" {
			t.Errorf("%s = %s, want []", name, b)
		}
	}
}
