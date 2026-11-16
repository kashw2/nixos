package bitbucket

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
)

type User struct {
	DisplayName string `json:"display_name,omitempty"`
	Nickname    string `json:"nickname,omitempty"`
	UUID        string `json:"uuid,omitempty"`
	AccountID   string `json:"account_id,omitempty"`
}

func (u User) key() string {
	if u.UUID != "" {
		return u.UUID
	}
	return u.AccountID
}

// same matches on whichever id both users carry; Bitbucket returns either or both.
func (u User) same(o User) bool {
	return (u.UUID != "" && u.UUID == o.UUID) || (u.AccountID != "" && u.AccountID == o.AccountID)
}

func (u User) ref() map[string]string {
	if u.UUID != "" {
		return map[string]string{"uuid": u.UUID}
	}
	return map[string]string{"account_id": u.AccountID}
}

type Participant struct {
	Name     string `json:"name"`
	Role     string `json:"role"`
	Approved bool   `json:"approved"`
	State    string `json:"state,omitempty"`
}

type PullRequest struct {
	ID           int           `json:"id"`
	Title        string        `json:"title"`
	Description  string        `json:"description,omitempty"`
	State        string        `json:"state"`
	Draft        bool          `json:"draft"`
	Source       string        `json:"source"`
	Destination  string        `json:"destination"`
	Author       string        `json:"author,omitempty"`
	Participants []Participant `json:"participants,omitempty"`
	CommentCount int           `json:"comment_count"`
	CreatedOn    string        `json:"created_on,omitempty"`
	UpdatedOn    string        `json:"updated_on,omitempty"`
	URL          string        `json:"url"`
}

type Comment struct {
	ID       int    `json:"id"`
	Author   string `json:"author"`
	Body     string `json:"body"`
	Path     string `json:"path,omitempty"`
	Line     int    `json:"line,omitempty"`
	ParentID int    `json:"parent_id,omitempty"`
	Created  string `json:"created_on,omitempty"`
}

type Status struct {
	Key         string `json:"key"`
	Name        string `json:"name"`
	State       string `json:"state"`
	Description string `json:"description,omitempty"`
	URL         string `json:"url,omitempty"`
}

type FileStat struct {
	Path    string `json:"path"`
	Status  string `json:"status"`
	Added   int    `json:"added"`
	Removed int    `json:"removed"`
}

type CreateInput struct {
	Title, Description, Source, Destination string
	Reviewers                               []string
	DefaultReviewers, CloseSourceBranch     bool
	Draft                                   bool
}

type EditInput struct {
	Title, Description, Destination *string
	Reviewers                       []string
}

type CommentInput struct {
	Body      string
	Path      string
	Line      int
	LineIsOld bool
	ParentID  int
}

type MergeInput struct {
	Strategy, Message string
	CloseSourceBranch *bool
}

type branchRef struct {
	Branch struct {
		Name string `json:"name"`
	} `json:"branch"`
}

type wirePR struct {
	ID           int       `json:"id"`
	Title        string    `json:"title"`
	Description  string    `json:"description"`
	State        string    `json:"state"`
	Draft        bool      `json:"draft"`
	Author       User      `json:"author"`
	Source       branchRef `json:"source"`
	Destination  branchRef `json:"destination"`
	Reviewers    []User    `json:"reviewers"`
	Participants []struct {
		User     User   `json:"user"`
		Role     string `json:"role"`
		Approved bool   `json:"approved"`
		State    string `json:"state"`
	} `json:"participants"`
	Links struct {
		HTML struct {
			Href string `json:"href"`
		} `json:"html"`
	} `json:"links"`
	CommentCount      int    `json:"comment_count"`
	CreatedOn         string `json:"created_on"`
	UpdatedOn         string `json:"updated_on"`
	CloseSourceBranch bool   `json:"close_source_branch"`
}

func (w wirePR) trim() PullRequest {
	pr := PullRequest{
		ID: w.ID, Title: w.Title, Description: w.Description, State: w.State, Draft: w.Draft,
		Source: w.Source.Branch.Name, Destination: w.Destination.Branch.Name, Author: w.Author.DisplayName,
		CommentCount: w.CommentCount, CreatedOn: w.CreatedOn, UpdatedOn: w.UpdatedOn, URL: w.Links.HTML.Href,
	}
	seen := map[string]bool{}
	for _, p := range w.Participants {
		seen[p.User.key()] = true
		pr.Participants = append(pr.Participants, Participant{Name: p.User.DisplayName, Role: p.Role, Approved: p.Approved, State: p.State})
	}
	// Reviewers who have not acted yet are absent from participants.
	for _, r := range w.Reviewers {
		if !seen[r.key()] {
			pr.Participants = append(pr.Participants, Participant{Name: r.DisplayName, Role: "REVIEWER"})
		}
	}
	return pr
}

func repoPath(ws, repo string) string {
	return "/repositories/" + url.PathEscape(ws) + "/" + url.PathEscape(repo)
}

func prPath(ws, repo string, id int, suffix string) string {
	return fmt.Sprintf("%s/pullrequests/%d%s", repoPath(ws, repo), id, suffix)
}

func (c *Client) ListPRs(ctx context.Context, ws, repo, state string, limit int) ([]PullRequest, error) {
	q := url.Values{}
	if state != "" {
		q.Set("state", strings.ToUpper(state))
	}
	prs := []PullRequest{}
	err := c.paginate(ctx, repoPath(ws, repo)+"/pullrequests", q, limit, func(raw json.RawMessage) error {
		var w wirePR
		if err := json.Unmarshal(raw, &w); err != nil {
			return err
		}
		prs = append(prs, w.trim())
		return nil
	})
	return prs, err
}

func (c *Client) getWirePR(ctx context.Context, ws, repo string, id int) (wirePR, error) {
	var w wirePR
	err := c.do(ctx, http.MethodGet, prPath(ws, repo, id, ""), nil, nil, &w)
	return w, err
}

func (c *Client) GetPR(ctx context.Context, ws, repo string, id int) (PullRequest, error) {
	w, err := c.getWirePR(ctx, ws, repo, id)
	return w.trim(), err
}

func branch(name string) map[string]any {
	return map[string]any{"branch": map[string]string{"name": name}}
}

func refs(users []User) []map[string]string {
	out := make([]map[string]string, 0, len(users))
	for _, u := range users {
		out = append(out, u.ref())
	}
	return out
}

func (c *Client) CreatePR(ctx context.Context, ws, repo string, in CreateInput) (PullRequest, error) {
	var reviewers []User
	if len(in.Reviewers) > 0 || in.DefaultReviewers {
		me, err := c.CurrentUser(ctx)
		if err != nil {
			return PullRequest{}, fmt.Errorf("current user: %w", err)
		}
		if reviewers, err = c.ResolveReviewers(ctx, ws, repo, in.Reviewers, in.DefaultReviewers, me); err != nil {
			return PullRequest{}, err
		}
	}
	body := map[string]any{
		"title":               in.Title,
		"description":         in.Description,
		"source":              branch(in.Source),
		"destination":         branch(in.Destination),
		"reviewers":           refs(reviewers),
		"close_source_branch": in.CloseSourceBranch,
		"draft":               in.Draft,
	}
	var w wirePR
	err := c.do(ctx, http.MethodPost, repoPath(ws, repo)+"/pullrequests", nil, body, &w)
	return w.trim(), err
}

// EditPR re-sends every current field it does not change, because a PUT that omits one can reset it.
func (c *Client) EditPR(ctx context.Context, ws, repo string, id int, in EditInput) (PullRequest, error) {
	cur, err := c.getWirePR(ctx, ws, repo, id)
	if err != nil {
		return PullRequest{}, err
	}
	reviewers := cur.Reviewers
	if len(in.Reviewers) > 0 {
		added, err := c.ResolveReviewers(ctx, ws, repo, in.Reviewers, false, cur.Author)
		if err != nil {
			return PullRequest{}, err
		}
		reviewers = dedupe(append(reviewers, added...))
	}
	body := map[string]any{
		"title":               cur.Title,
		"description":         cur.Description,
		"reviewers":           refs(reviewers),
		"draft":               cur.Draft,
		"close_source_branch": cur.CloseSourceBranch,
	}
	if in.Title != nil {
		body["title"] = *in.Title
	}
	if in.Description != nil {
		body["description"] = *in.Description
	}
	if in.Destination != nil {
		body["destination"] = branch(*in.Destination)
	}
	var w wirePR
	err = c.do(ctx, http.MethodPut, prPath(ws, repo, id, ""), nil, body, &w)
	return w.trim(), err
}

// Diff returns the PR's unified diff, narrowed to one file when path is set.
func (c *Client) Diff(ctx context.Context, ws, repo string, id int, path string) (string, error) {
	var diff string
	if err := c.do(ctx, http.MethodGet, prPath(ws, repo, id, "/diff"), nil, nil, &diff); err != nil {
		return "", err
	}
	if path == "" {
		return diff, nil
	}
	filtered := filterDiff(diff, path)
	if filtered == "" {
		return "", fmt.Errorf("#%d does not change %s", id, path)
	}
	return filtered, nil
}

func filterDiff(diff, path string) string {
	var out strings.Builder
	keep := false
	for _, line := range strings.SplitAfter(diff, "\n") {
		if strings.HasPrefix(line, "diff --git ") {
			header := strings.TrimSpace(line)
			keep = strings.HasSuffix(header, " b/"+path) || strings.Contains(header, " a/"+path+" ")
		}
		if keep {
			out.WriteString(line)
		}
	}
	return out.String()
}

func (c *Client) DiffStat(ctx context.Context, ws, repo string, id int) ([]FileStat, error) {
	stats := []FileStat{}
	err := c.paginate(ctx, prPath(ws, repo, id, "/diffstat"), nil, 0, func(raw json.RawMessage) error {
		var w struct {
			Status       string `json:"status"`
			LinesAdded   int    `json:"lines_added"`
			LinesRemoved int    `json:"lines_removed"`
			Old, New     *struct {
				Path string `json:"path"`
			}
		}
		if err := json.Unmarshal(raw, &w); err != nil {
			return err
		}
		s := FileStat{Status: w.Status, Added: w.LinesAdded, Removed: w.LinesRemoved}
		if w.New != nil {
			s.Path = w.New.Path
		} else if w.Old != nil {
			s.Path = w.Old.Path
		}
		stats = append(stats, s)
		return nil
	})
	return stats, err
}

func (c *Client) Comments(ctx context.Context, ws, repo string, id, limit int) ([]Comment, error) {
	comments := []Comment{}
	err := c.paginate(ctx, prPath(ws, repo, id, "/comments"), nil, limit, func(raw json.RawMessage) error {
		var w struct {
			ID      int  `json:"id"`
			Deleted bool `json:"deleted"`
			User    User `json:"user"`
			Content struct {
				Raw string `json:"raw"`
			} `json:"content"`
			Inline *struct {
				Path string `json:"path"`
				To   *int   `json:"to"`
				From *int   `json:"from"`
			} `json:"inline"`
			Parent *struct {
				ID int `json:"id"`
			} `json:"parent"`
			CreatedOn string `json:"created_on"`
		}
		if err := json.Unmarshal(raw, &w); err != nil {
			return err
		}
		if w.Deleted {
			return nil
		}
		cm := Comment{ID: w.ID, Author: w.User.DisplayName, Body: w.Content.Raw, Created: w.CreatedOn}
		if w.Inline != nil {
			cm.Path = w.Inline.Path
			if w.Inline.To != nil {
				cm.Line = *w.Inline.To
			} else if w.Inline.From != nil {
				cm.Line = *w.Inline.From
			}
		}
		if w.Parent != nil {
			cm.ParentID = w.Parent.ID
		}
		comments = append(comments, cm)
		return nil
	})
	return comments, err
}

func (c *Client) AddComment(ctx context.Context, ws, repo string, id int, in CommentInput) (Comment, error) {
	body := map[string]any{"content": map[string]string{"raw": in.Body}}
	if in.Path != "" {
		inline := map[string]any{"path": in.Path}
		if in.Line > 0 {
			side := "to"
			if in.LineIsOld {
				side = "from"
			}
			inline[side] = in.Line
		}
		body["inline"] = inline
	}
	if in.ParentID > 0 {
		body["parent"] = map[string]int{"id": in.ParentID}
	}
	var w struct {
		ID int `json:"id"`
	}
	if err := c.do(ctx, http.MethodPost, prPath(ws, repo, id, "/comments"), nil, body, &w); err != nil {
		return Comment{}, err
	}
	return Comment{ID: w.ID, Body: in.Body, Path: in.Path, Line: in.Line, ParentID: in.ParentID}, nil
}

func (c *Client) Approve(ctx context.Context, ws, repo string, id int) error {
	return c.do(ctx, http.MethodPost, prPath(ws, repo, id, "/approve"), nil, nil, nil)
}

func (c *Client) Unapprove(ctx context.Context, ws, repo string, id int) error {
	return c.do(ctx, http.MethodDelete, prPath(ws, repo, id, "/approve"), nil, nil, nil)
}

func (c *Client) RequestChanges(ctx context.Context, ws, repo string, id int) error {
	return c.do(ctx, http.MethodPost, prPath(ws, repo, id, "/request-changes"), nil, nil, nil)
}

func (c *Client) RemoveRequestChanges(ctx context.Context, ws, repo string, id int) error {
	return c.do(ctx, http.MethodDelete, prPath(ws, repo, id, "/request-changes"), nil, nil, nil)
}

func (c *Client) Decline(ctx context.Context, ws, repo string, id int) error {
	return c.do(ctx, http.MethodPost, prPath(ws, repo, id, "/decline"), nil, nil, nil)
}

// Merge leaves merge_strategy out when none is given so the destination branch's default applies.
// Bitbucket answers 202 for merges that outlast its request window; that is reported, not polled.
func (c *Client) Merge(ctx context.Context, ws, repo string, id int, in MergeInput) (PullRequest, error) {
	body := map[string]any{}
	if in.Strategy != "" {
		body["merge_strategy"] = in.Strategy
	}
	if in.Message != "" {
		body["message"] = in.Message
	}
	if in.CloseSourceBranch != nil {
		body["close_source_branch"] = *in.CloseSourceBranch
	}
	resp, err := c.send(ctx, http.MethodPost, prPath(ws, repo, id, "/merge"), nil, body)
	if err != nil {
		return PullRequest{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusAccepted {
		return PullRequest{ID: id, State: "MERGE_IN_PROGRESS", URL: resp.Header.Get("Location")}, nil
	}
	var w wirePR
	err = decode(resp, &w)
	return w.trim(), err
}

func (c *Client) Statuses(ctx context.Context, ws, repo string, id int) ([]Status, error) {
	statuses := []Status{}
	err := c.paginate(ctx, prPath(ws, repo, id, "/statuses"), nil, 0, func(raw json.RawMessage) error {
		var s Status
		if err := json.Unmarshal(raw, &s); err != nil {
			return err
		}
		statuses = append(statuses, s)
		return nil
	})
	return statuses, err
}

func (c *Client) MainBranch(ctx context.Context, ws, repo string) (string, error) {
	var r struct {
		MainBranch struct {
			Name string `json:"name"`
		} `json:"mainbranch"`
	}
	if err := c.do(ctx, http.MethodGet, repoPath(ws, repo), nil, nil, &r); err != nil {
		return "", err
	}
	if r.MainBranch.Name == "" {
		return "", fmt.Errorf("%s/%s has no main branch set", ws, repo)
	}
	return r.MainBranch.Name, nil
}

func (c *Client) CurrentUser(ctx context.Context) (User, error) {
	var u User
	err := c.do(ctx, http.MethodGet, "/user", nil, nil, &u)
	return u, err
}
