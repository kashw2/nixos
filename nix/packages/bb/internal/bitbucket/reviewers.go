package bitbucket

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"regexp"
	"strings"
)

var (
	uuidRe      = regexp.MustCompile(`^\{[0-9a-fA-F-]{36}\}$`)
	accountIDRe = regexp.MustCompile(`^(\d+:[0-9a-fA-F-]{36}|[0-9a-fA-F]{24})$`)
)

// ResolveReviewers turns reviewer names (display name or nickname, case-insensitive) or ids into
// users, optionally starting from the repo's effective default reviewers. author is dropped because
// Bitbucket rejects a PR's author as its reviewer.
func (c *Client) ResolveReviewers(ctx context.Context, ws, repo string, names []string, includeDefaults bool, author User) ([]User, error) {
	if len(names) == 0 && !includeDefaults {
		return nil, nil
	}
	var users []User
	if includeDefaults {
		err := c.paginate(ctx, repoPath(ws, repo)+"/effective-default-reviewers", nil, 0, func(raw json.RawMessage) error {
			var d struct {
				User User `json:"user"`
			}
			if err := json.Unmarshal(raw, &d); err != nil {
				return err
			}
			users = append(users, d.User)
			return nil
		})
		if err != nil {
			return nil, fmt.Errorf("default reviewers: %w", err)
		}
	}

	var members []User
	for _, name := range names {
		name = strings.TrimSpace(name)
		switch {
		case uuidRe.MatchString(name):
			users = append(users, User{UUID: name})
			continue
		case accountIDRe.MatchString(name):
			users = append(users, User{AccountID: name})
			continue
		}
		if members == nil {
			var err error
			if members, err = c.workspaceMembers(ctx, ws); err != nil {
				return nil, fmt.Errorf("workspace members: %w", err)
			}
		}
		u, err := matchMember(members, name)
		if err != nil {
			return nil, err
		}
		users = append(users, u)
	}

	var out []User
	for _, u := range dedupe(users) {
		if !u.same(author) {
			out = append(out, u)
		}
	}
	return out, nil
}

func (c *Client) workspaceMembers(ctx context.Context, ws string) ([]User, error) {
	members := []User{}
	err := c.paginate(ctx, "/workspaces/"+url.PathEscape(ws)+"/members", nil, 0, func(raw json.RawMessage) error {
		var m struct {
			User User `json:"user"`
		}
		if err := json.Unmarshal(raw, &m); err != nil {
			return err
		}
		members = append(members, m.User)
		return nil
	})
	return members, err
}

func matchMember(members []User, name string) (User, error) {
	var matches []User
	for _, m := range members {
		if strings.EqualFold(m.DisplayName, name) || (m.Nickname != "" && strings.EqualFold(m.Nickname, name)) {
			matches = append(matches, m)
		}
	}
	switch len(matches) {
	case 1:
		return matches[0], nil
	case 0:
		var partial []User
		lower := strings.ToLower(name)
		for _, m := range members {
			if strings.Contains(strings.ToLower(m.DisplayName), lower) || strings.Contains(strings.ToLower(m.Nickname), lower) {
				partial = append(partial, m)
			}
		}
		if len(partial) == 0 {
			return User{}, fmt.Errorf("no workspace member named %q", name)
		}
		return User{}, fmt.Errorf("no workspace member named %q; did you mean: %s", name, describe(partial))
	}
	return User{}, fmt.Errorf("%q matches several members, pass one of their account ids instead: %s", name, describe(matches))
}

func describe(users []User) string {
	var out []string
	for _, m := range users {
		out = append(out, fmt.Sprintf("%s (nickname %s, account id %s)", m.DisplayName, m.Nickname, m.AccountID))
	}
	return strings.Join(out, "; ")
}

func dedupe(users []User) []User {
	seen := map[string]bool{}
	var out []User
	for _, u := range users {
		if k := u.key(); k != "" && !seen[k] {
			seen[k] = true
			out = append(out, u)
		}
	}
	return out
}
