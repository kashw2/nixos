package mcpserver

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"sort"
	"strings"
	"testing"

	"bb/internal/bitbucket"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

var allTools = []string{
	"pr_approve", "pr_checks", "pr_comment", "pr_comments", "pr_create", "pr_decline", "pr_diff",
	"pr_edit", "pr_list", "pr_merge", "pr_remove_request_changes", "pr_request_changes", "pr_unapprove", "pr_view",
}

func connect(t *testing.T, routes map[string]string) *mcp.ClientSession {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, ok := routes[r.Method+" "+r.URL.Path]
		if !ok {
			w.WriteHeader(http.StatusNotFound)
			fmt.Fprint(w, `{"error":{"message":"Pull request not found"}}`)
			return
		}
		fmt.Fprint(w, body)
	}))
	t.Cleanup(srv.Close)

	server := New(func() (*bitbucket.Client, error) {
		return bitbucket.NewClient(srv.URL, "e", "t", srv.Client()), nil
	}, "test")
	ct, st := mcp.NewInMemoryTransports()
	ctx := context.Background()
	if _, err := server.Connect(ctx, st, nil); err != nil {
		t.Fatal(err)
	}
	cs, err := mcp.NewClient(&mcp.Implementation{Name: "test", Version: "0"}, nil).Connect(ctx, ct, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cs.Close() })
	return cs
}

func call(t *testing.T, cs *mcp.ClientSession, name string, args map[string]any) *mcp.CallToolResult {
	t.Helper()
	res, err := cs.CallTool(context.Background(), &mcp.CallToolParams{Name: name, Arguments: args})
	if err != nil {
		t.Fatal(err)
	}
	return res
}

func text(res *mcp.CallToolResult) string {
	var b strings.Builder
	for _, c := range res.Content {
		if tc, ok := c.(*mcp.TextContent); ok {
			b.WriteString(tc.Text)
		}
	}
	return b.String()
}

func TestListsAllTools(t *testing.T) {
	cs := connect(t, nil)
	res, err := cs.ListTools(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	var names []string
	for _, tool := range res.Tools {
		names = append(names, tool.Name)
	}
	sort.Strings(names)
	if strings.Join(names, ",") != strings.Join(allTools, ",") {
		t.Fatalf("tools = %v\nwant    %v", names, allTools)
	}
}

func TestToolsRequireWorkspaceAndRepo(t *testing.T) {
	cs := connect(t, nil)
	res, _ := cs.ListTools(context.Background(), nil)
	for _, tool := range res.Tools {
		schema, _ := json.Marshal(tool.InputSchema)
		var s struct {
			Required []string `json:"required"`
		}
		json.Unmarshal(schema, &s)
		req := strings.Join(s.Required, ",")
		if !strings.Contains(req, "workspace") || !strings.Contains(req, "repo") {
			t.Errorf("%s required = %v", tool.Name, s.Required)
		}
	}
}

func TestDestructiveHints(t *testing.T) {
	cs := connect(t, nil)
	res, _ := cs.ListTools(context.Background(), nil)
	for _, tool := range res.Tools {
		destructive := tool.Annotations != nil && tool.Annotations.DestructiveHint != nil && *tool.Annotations.DestructiveHint
		want := tool.Name == "pr_merge" || tool.Name == "pr_decline" || tool.Name == "pr_edit"
		if destructive != want {
			t.Errorf("%s destructive = %v, want %v", tool.Name, destructive, want)
		}
		readOnly := tool.Annotations != nil && tool.Annotations.ReadOnlyHint
		wantRO := map[string]bool{"pr_list": true, "pr_view": true, "pr_diff": true, "pr_comments": true, "pr_checks": true}[tool.Name]
		if readOnly != wantRO {
			t.Errorf("%s readOnly = %v, want %v", tool.Name, readOnly, wantRO)
		}
	}
}

func TestPRListCallsAPI(t *testing.T) {
	cs := connect(t, map[string]string{
		"GET /repositories/ws/repo/pullrequests": `{"values":[{"id":7,"title":"Add thing","state":"OPEN"}]}`,
	})
	res := call(t, cs, "pr_list", map[string]any{"workspace": "ws", "repo": "repo"})
	if res.IsError {
		t.Fatalf("error: %s", text(res))
	}
	var prs []bitbucket.PullRequest
	if err := json.Unmarshal([]byte(text(res)), &prs); err != nil || len(prs) != 1 || prs[0].ID != 7 {
		t.Fatalf("result %q: %v", text(res), err)
	}
}

func TestPRDiffTruncates(t *testing.T) {
	big := "diff --git a/big.txt b/big.txt\n" + strings.Repeat("+line of added text\n", 12000)
	cs := connect(t, map[string]string{
		"GET /repositories/ws/repo/pullrequests/7/diff":     big,
		"GET /repositories/ws/repo/pullrequests/7/diffstat": `{"values":[{"status":"modified","lines_added":12000,"new":{"path":"big.txt"}}]}`,
	})
	res := call(t, cs, "pr_diff", map[string]any{"workspace": "ws", "repo": "repo", "id": 7})
	var out struct {
		Truncated bool                 `json:"truncated"`
		Diff      string               `json:"diff"`
		Files     []bitbucket.FileStat `json:"files"`
	}
	if err := json.Unmarshal([]byte(text(res)), &out); err != nil {
		t.Fatalf("result %.200q: %v", text(res), err)
	}
	if !out.Truncated || len(out.Diff) > maxDiffBytes || len(out.Files) != 1 || !strings.HasSuffix(out.Diff, "\n") {
		t.Fatalf("truncated=%v len=%d files=%v", out.Truncated, len(out.Diff), out.Files)
	}
}

func TestPRDiffSmallIsRawText(t *testing.T) {
	cs := connect(t, map[string]string{"GET /repositories/ws/repo/pullrequests/7/diff": "diff --git a/x b/x\n+y\n"})
	res := call(t, cs, "pr_diff", map[string]any{"workspace": "ws", "repo": "repo", "id": 7})
	if text(res) != "diff --git a/x b/x\n+y\n" {
		t.Fatalf("result = %q", text(res))
	}
}

func TestToolErrorOnAPIError(t *testing.T) {
	cs := connect(t, nil)
	res := call(t, cs, "pr_view", map[string]any{"workspace": "ws", "repo": "repo", "id": 99})
	if !res.IsError || !strings.Contains(text(res), "Pull request not found") {
		t.Fatalf("IsError=%v text=%q", res.IsError, text(res))
	}
}

func TestMergeRejectsUnknownStrategy(t *testing.T) {
	cs := connect(t, nil)
	res := call(t, cs, "pr_merge", map[string]any{"workspace": "ws", "repo": "repo", "id": 7, "strategy": "rebase"})
	if !res.IsError || !strings.Contains(text(res), "strategy") {
		t.Fatalf("IsError=%v text=%q", res.IsError, text(res))
	}
}

func TestMissingCredentialsIsToolError(t *testing.T) {
	server := New(func() (*bitbucket.Client, error) { return nil, bitbucket.ErrMissingCredentials }, "test")
	ct, st := mcp.NewInMemoryTransports()
	ctx := context.Background()
	server.Connect(ctx, st, nil)
	cs, _ := mcp.NewClient(&mcp.Implementation{Name: "test", Version: "0"}, nil).Connect(ctx, ct, nil)
	defer cs.Close()
	res := call(t, cs, "pr_list", map[string]any{"workspace": "ws", "repo": "repo"})
	if !res.IsError || !strings.Contains(text(res), "BITBUCKET_API_TOKEN") {
		t.Fatalf("IsError=%v text=%q", res.IsError, text(res))
	}
}

func TestPRDiffTruncatedKeepsHTMLCharacters(t *testing.T) {
	big := "diff --git a/big.go b/big.go\n" + strings.Repeat("+if a && b { var x List<T> }\n", 5000)
	cs := connect(t, map[string]string{
		"GET /repositories/ws/repo/pullrequests/7/diff":     big,
		"GET /repositories/ws/repo/pullrequests/7/diffstat": `{"values":[{"status":"modified","new":{"path":"big.go"}}]}`,
	})
	res := call(t, cs, "pr_diff", map[string]any{"workspace": "ws", "repo": "repo", "id": 7})
	if !strings.Contains(text(res), "a && b { var x List<T> }") {
		t.Fatalf("result %.200q, want <, > and & unescaped", text(res))
	}
}
