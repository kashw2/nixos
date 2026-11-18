// Package mcpserver exposes the Bitbucket pull request operations as MCP tools.
package mcpserver

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"sync"

	"bb/internal/bitbucket"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

// maxDiffBytes keeps a large diff from flooding the model's context.
const maxDiffBytes = 100 << 10

type repoArgs struct {
	Workspace string `json:"workspace" jsonschema:"Bitbucket workspace slug, e.g. tablogs-workspace"`
	Repo      string `json:"repo" jsonschema:"repository slug, e.g. testlab360"`
}

type idArgs struct {
	Workspace string `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo      string `json:"repo" jsonschema:"repository slug"`
	ID        int    `json:"id" jsonschema:"pull request id"`
}

type listArgs struct {
	Workspace string `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo      string `json:"repo" jsonschema:"repository slug"`
	State     string `json:"state,omitempty" jsonschema:"OPEN (default), MERGED, DECLINED or SUPERSEDED"`
	Limit     int    `json:"limit,omitempty" jsonschema:"maximum results (default 25)"`
}

type diffArgs struct {
	Workspace string `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo      string `json:"repo" jsonschema:"repository slug"`
	ID        int    `json:"id" jsonschema:"pull request id"`
	Path      string `json:"path,omitempty" jsonschema:"only return the diff of this file"`
}

type createArgs struct {
	Workspace         string   `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo              string   `json:"repo" jsonschema:"repository slug"`
	Title             string   `json:"title" jsonschema:"pull request title"`
	Source            string   `json:"source" jsonschema:"source branch"`
	Destination       string   `json:"destination" jsonschema:"destination branch"`
	Description       string   `json:"description,omitempty" jsonschema:"markdown description"`
	Reviewers         []string `json:"reviewers,omitempty" jsonschema:"extra reviewers by display name, nickname or account id"`
	DefaultReviewers  *bool    `json:"default_reviewers,omitempty" jsonschema:"add the repo's default reviewers (default true)"`
	Draft             bool     `json:"draft,omitempty" jsonschema:"open as a draft"`
	CloseSourceBranch bool     `json:"close_source_branch,omitempty" jsonschema:"delete the source branch on merge"`
}

type editArgs struct {
	Workspace   string   `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo        string   `json:"repo" jsonschema:"repository slug"`
	ID          int      `json:"id" jsonschema:"pull request id"`
	Title       *string  `json:"title,omitempty" jsonschema:"new title"`
	Description *string  `json:"description,omitempty" jsonschema:"new description"`
	Destination *string  `json:"destination,omitempty" jsonschema:"new destination branch"`
	Reviewers   []string `json:"reviewers,omitempty" jsonschema:"reviewers to add, by display name, nickname or account id"`
}

type commentsArgs struct {
	Workspace string `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo      string `json:"repo" jsonschema:"repository slug"`
	ID        int    `json:"id" jsonschema:"pull request id"`
	Limit     int    `json:"limit,omitempty" jsonschema:"maximum comments (default 100)"`
}

type commentArgs struct {
	Workspace string `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo      string `json:"repo" jsonschema:"repository slug"`
	ID        int    `json:"id" jsonschema:"pull request id"`
	Body      string `json:"body" jsonschema:"comment text (markdown)"`
	Path      string `json:"path,omitempty" jsonschema:"file for an inline comment"`
	Line      int    `json:"line,omitempty" jsonschema:"line for an inline comment"`
	LineIsOld bool   `json:"line_is_old,omitempty" jsonschema:"line refers to the old side of the diff"`
	ParentID  int    `json:"parent_id,omitempty" jsonschema:"reply to this comment id"`
}

type mergeArgs struct {
	Workspace         string `json:"workspace" jsonschema:"Bitbucket workspace slug"`
	Repo              string `json:"repo" jsonschema:"repository slug"`
	ID                int    `json:"id" jsonschema:"pull request id"`
	Strategy          string `json:"strategy,omitempty" jsonschema:"merge_commit, squash or fast_forward (default: the branch's setting)"`
	Message           string `json:"message,omitempty" jsonschema:"merge commit message"`
	CloseSourceBranch *bool  `json:"close_source_branch,omitempty" jsonschema:"delete the source branch"`
}

type server struct {
	newClient func() (*bitbucket.Client, error)
	mu        sync.Mutex
	client    *bitbucket.Client
}

// client is created on first use so the server still starts, and reports the problem per call,
// when credentials are missing.
func (s *server) get() (*bitbucket.Client, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.client == nil {
		c, err := s.newClient()
		if err != nil {
			return nil, err
		}
		s.client = c
	}
	return s.client, nil
}

func jsonResult(v any) (*mcp.CallToolResult, any, error) {
	var b strings.Builder
	enc := json.NewEncoder(&b)
	enc.SetEscapeHTML(false)
	enc.SetIndent("", "  ")
	if err := enc.Encode(v); err != nil {
		return nil, nil, err
	}
	return textResult(strings.TrimSuffix(b.String(), "\n"))
}

func textResult(s string) (*mcp.CallToolResult, any, error) {
	return &mcp.CallToolResult{Content: []mcp.Content{&mcp.TextContent{Text: s}}}, nil, nil
}

func boolPtr(b bool) *bool { return &b }

var (
	readOnly    = &mcp.ToolAnnotations{ReadOnlyHint: true}
	additive    = &mcp.ToolAnnotations{DestructiveHint: boolPtr(false)}
	destructive = &mcp.ToolAnnotations{DestructiveHint: boolPtr(true)}
)

var mergeStrategies = map[string]bool{"merge_commit": true, "squash": true, "fast_forward": true}

func New(newClient func() (*bitbucket.Client, error), version string) *mcp.Server {
	s := &server{newClient: newClient}
	srv := mcp.NewServer(&mcp.Implementation{Name: "bb", Version: version}, nil)

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_list", Description: "List pull requests in a Bitbucket repository.", Annotations: readOnly},
		func(ctx context.Context, _ *mcp.CallToolRequest, a listArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			limit := a.Limit
			if limit <= 0 {
				limit = 25
			}
			prs, err := c.ListPRs(ctx, a.Workspace, a.Repo, a.State, limit)
			if err != nil {
				return nil, nil, err
			}
			if prs == nil {
				prs = []bitbucket.PullRequest{}
			}
			return jsonResult(prs)
		})

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_view", Description: "Show a pull request: title, description, branches, author, reviewer approval states and URL.", Annotations: readOnly},
		func(ctx context.Context, _ *mcp.CallToolRequest, a idArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			pr, err := c.GetPR(ctx, a.Workspace, a.Repo, a.ID)
			if err != nil {
				return nil, nil, err
			}
			return jsonResult(pr)
		})

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_diff", Description: "Unified diff of a pull request, optionally for one file. Diffs over 100 KB are truncated and returned with the changed-file list; request a single path to see the rest.", Annotations: readOnly},
		func(ctx context.Context, _ *mcp.CallToolRequest, a diffArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			diff, err := c.Diff(ctx, a.Workspace, a.Repo, a.ID, a.Path)
			if err != nil {
				return nil, nil, err
			}
			if len(diff) <= maxDiffBytes {
				return textResult(diff)
			}
			files, err := c.DiffStat(ctx, a.Workspace, a.Repo, a.ID)
			if err != nil {
				return nil, nil, err
			}
			cut := strings.LastIndexByte(diff[:maxDiffBytes], '\n') + 1
			return jsonResult(map[string]any{"truncated": true, "files": files, "diff": diff[:cut]})
		})

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_create", Description: "Open a pull request. The repo's default reviewers are added unless default_reviewers is false.", Annotations: additive},
		func(ctx context.Context, _ *mcp.CallToolRequest, a createArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			defaults := a.DefaultReviewers == nil || *a.DefaultReviewers
			pr, err := c.CreatePR(ctx, a.Workspace, a.Repo, bitbucket.CreateInput{
				Title: a.Title, Description: a.Description, Source: a.Source, Destination: a.Destination,
				Reviewers: a.Reviewers, DefaultReviewers: defaults, Draft: a.Draft, CloseSourceBranch: a.CloseSourceBranch,
			})
			if err != nil {
				return nil, nil, err
			}
			return jsonResult(pr)
		})

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_edit", Description: "Change a pull request's title, description or destination, or add reviewers.", Annotations: destructive},
		func(ctx context.Context, _ *mcp.CallToolRequest, a editArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			if a.Title == nil && a.Description == nil && a.Destination == nil && len(a.Reviewers) == 0 {
				return nil, nil, fmt.Errorf("pr_edit needs at least one of title, description, destination, reviewers")
			}
			pr, err := c.EditPR(ctx, a.Workspace, a.Repo, a.ID, bitbucket.EditInput{
				Title: a.Title, Description: a.Description, Destination: a.Destination, Reviewers: a.Reviewers,
			})
			if err != nil {
				return nil, nil, err
			}
			return jsonResult(pr)
		})

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_comments", Description: "List a pull request's comments, including inline file/line and reply parents.", Annotations: readOnly},
		func(ctx context.Context, _ *mcp.CallToolRequest, a commentsArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			limit := a.Limit
			if limit <= 0 {
				limit = 100
			}
			comments, err := c.Comments(ctx, a.Workspace, a.Repo, a.ID, limit)
			if err != nil {
				return nil, nil, err
			}
			if comments == nil {
				comments = []bitbucket.Comment{}
			}
			return jsonResult(comments)
		})

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_comment", Description: "Comment on a pull request: general, inline (path + line), or as a reply (parent_id).", Annotations: additive},
		func(ctx context.Context, _ *mcp.CallToolRequest, a commentArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			if a.Line > 0 && a.Path == "" {
				return nil, nil, fmt.Errorf("line needs path")
			}
			cm, err := c.AddComment(ctx, a.Workspace, a.Repo, a.ID, bitbucket.CommentInput{
				Body: a.Body, Path: a.Path, Line: a.Line, LineIsOld: a.LineIsOld, ParentID: a.ParentID,
			})
			if err != nil {
				return nil, nil, err
			}
			return jsonResult(cm)
		})

	addAction := func(name, desc string, ann *mcp.ToolAnnotations, act func(*bitbucket.Client, context.Context, string, string, int) error) {
		mcp.AddTool(srv, &mcp.Tool{Name: name, Description: desc, Annotations: ann},
			func(ctx context.Context, _ *mcp.CallToolRequest, a idArgs) (*mcp.CallToolResult, any, error) {
				c, err := s.get()
				if err != nil {
					return nil, nil, err
				}
				if err := act(c, ctx, a.Workspace, a.Repo, a.ID); err != nil {
					return nil, nil, err
				}
				return jsonResult(map[string]any{"id": a.ID, "ok": true})
			})
	}
	addAction("pr_approve", "Approve a pull request as the authenticated user.", additive, (*bitbucket.Client).Approve)
	addAction("pr_unapprove", "Withdraw the authenticated user's approval.", additive, (*bitbucket.Client).Unapprove)
	addAction("pr_request_changes", "Request changes on a pull request.", additive, (*bitbucket.Client).RequestChanges)
	addAction("pr_remove_request_changes", "Withdraw the authenticated user's change request.", additive, (*bitbucket.Client).RemoveRequestChanges)
	addAction("pr_decline", "Decline (close without merging) a pull request. Only call when the user asks for it.", destructive, (*bitbucket.Client).Decline)

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_merge", Description: "Merge a pull request. Only call when the user asks for it. Without strategy, the destination branch's default applies.", Annotations: destructive},
		func(ctx context.Context, _ *mcp.CallToolRequest, a mergeArgs) (*mcp.CallToolResult, any, error) {
			if a.Strategy != "" && !mergeStrategies[a.Strategy] {
				return nil, nil, fmt.Errorf("unknown strategy %q: use merge_commit, squash or fast_forward", a.Strategy)
			}
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			pr, err := c.Merge(ctx, a.Workspace, a.Repo, a.ID, bitbucket.MergeInput{
				Strategy: a.Strategy, Message: a.Message, CloseSourceBranch: a.CloseSourceBranch,
			})
			if err != nil {
				return nil, nil, err
			}
			return jsonResult(pr)
		})

	mcp.AddTool(srv, &mcp.Tool{Name: "pr_checks", Description: "Build statuses (Bitbucket Pipelines and other CI) reported on a pull request.", Annotations: readOnly},
		func(ctx context.Context, _ *mcp.CallToolRequest, a idArgs) (*mcp.CallToolResult, any, error) {
			c, err := s.get()
			if err != nil {
				return nil, nil, err
			}
			statuses, err := c.Statuses(ctx, a.Workspace, a.Repo, a.ID)
			if err != nil {
				return nil, nil, err
			}
			if statuses == nil {
				statuses = []bitbucket.Status{}
			}
			return jsonResult(statuses)
		})

	return srv
}
