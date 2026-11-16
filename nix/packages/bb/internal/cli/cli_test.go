package cli

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os/exec"
	"strings"
	"testing"

	"bb/internal/bitbucket"
)

type request struct {
	Method, Path string
	Body         map[string]any
}

const samplePR = `{"id":7,"title":"Add thing","state":"OPEN","source":{"branch":{"name":"feature/x"}},
"destination":{"branch":{"name":"dev"}},"author":{"display_name":"Keanu"},"links":{"html":{"href":"https://bitbucket.org/ws/repo/pull-requests/7"}}}`

func harness(t *testing.T, routes map[string]string) (Env, *bytes.Buffer, *bytes.Buffer, *[]request) {
	t.Helper()
	var reqs []request
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		req := request{Method: r.Method, Path: r.URL.Path}
		if b, _ := io.ReadAll(r.Body); len(b) > 0 {
			json.Unmarshal(b, &req.Body)
		}
		reqs = append(reqs, req)
		body, ok := routes[r.Method+" "+r.URL.Path]
		if !ok {
			w.WriteHeader(http.StatusNotFound)
			fmt.Fprint(w, `{"error":{"message":"no route"}}`)
			return
		}
		fmt.Fprint(w, body)
	}))
	t.Cleanup(srv.Close)

	dir := t.TempDir()
	for _, args := range [][]string{
		{"init", "-q", "-b", "feature/x"},
		{"remote", "add", "origin", "git@bitbucket.org:ws/repo.git"},
	} {
		if out, err := exec.Command("git", append([]string{"-C", dir}, args...)...).CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, out)
		}
	}
	var stdout, stderr bytes.Buffer
	env := Env{
		Stdout: &stdout, Stderr: &stderr, Dir: dir, Version: "test",
		NewClient: func() (*bitbucket.Client, error) {
			return bitbucket.NewClient(srv.URL, "e", "t", srv.Client()), nil
		},
	}
	return env, &stdout, &stderr, &reqs
}

func runCLI(env Env, args string) int {
	return Run(context.Background(), strings.Fields(args), env)
}

func TestRepoFromOrigin(t *testing.T) {
	env, _, stderr, reqs := harness(t, map[string]string{"GET /repositories/ws/repo/pullrequests": `{"values":[]}`})
	if code := runCLI(env, "pr list"); code != 0 {
		t.Fatalf("exit %d: %s", code, stderr)
	}
	if (*reqs)[0].Path != "/repositories/ws/repo/pullrequests" {
		t.Fatalf("requests = %v", *reqs)
	}
}

func TestRepoFromFlagOverridesOrigin(t *testing.T) {
	env, _, stderr, reqs := harness(t, map[string]string{"GET /repositories/other/thing/pullrequests": `{"values":[]}`})
	if code := runCLI(env, "pr list --repo other/thing"); code != 0 {
		t.Fatalf("exit %d: %s", code, stderr)
	}
	if (*reqs)[0].Path != "/repositories/other/thing/pullrequests" {
		t.Fatalf("requests = %v", *reqs)
	}
}

func TestCreateDefaultsSourceAndDest(t *testing.T) {
	env, stdout, stderr, reqs := harness(t, map[string]string{
		"GET /repositories/ws/repo":                             `{"mainbranch":{"name":"dev"}}`,
		"GET /repositories/ws/repo/effective-default-reviewers": `{"values":[]}`,
		"GET /user": `{"uuid":"{me}"}`,
		"POST /repositories/ws/repo/pullrequests": samplePR,
	})
	if code := runCLI(env, "pr create --title Hello"); code != 0 {
		t.Fatalf("exit %d: %s", code, stderr)
	}
	body := (*reqs)[len(*reqs)-1].Body
	src := body["source"].(map[string]any)["branch"].(map[string]any)["name"]
	dst := body["destination"].(map[string]any)["branch"].(map[string]any)["name"]
	if src != "feature/x" || dst != "dev" || body["title"] != "Hello" {
		t.Fatalf("body = %v", body)
	}
	if !strings.Contains(stdout.String(), "https://bitbucket.org/ws/repo/pull-requests/7") {
		t.Fatalf("stdout = %q, want the PR URL", stdout)
	}
}

func TestJSONOutputIsValid(t *testing.T) {
	env, stdout, stderr, _ := harness(t, map[string]string{"GET /repositories/ws/repo/pullrequests/7": samplePR})
	if code := runCLI(env, "pr view 7 --json"); code != 0 {
		t.Fatalf("exit %d: %s", code, stderr)
	}
	var pr bitbucket.PullRequest
	if err := json.Unmarshal(stdout.Bytes(), &pr); err != nil || pr.ID != 7 {
		t.Fatalf("stdout %q: %v", stdout, err)
	}
}

func TestViewReadable(t *testing.T) {
	env, stdout, _, _ := harness(t, map[string]string{"GET /repositories/ws/repo/pullrequests/7": samplePR})
	runCLI(env, "pr view 7")
	for _, want := range []string{"#7 Add thing", "feature/x → dev", "OPEN"} {
		if !strings.Contains(stdout.String(), want) {
			t.Errorf("stdout %q missing %q", stdout, want)
		}
	}
}

func TestUnknownCommandExits2(t *testing.T) {
	env, _, stderr, _ := harness(t, nil)
	if code := runCLI(env, "pr frobnicate"); code != 2 {
		t.Fatalf("exit %d, want 2", code)
	}
	if !strings.Contains(stderr.String(), "frobnicate") {
		t.Fatalf("stderr = %q", stderr)
	}
}

func TestMergeRequiresID(t *testing.T) {
	env, _, _, reqs := harness(t, nil)
	if code := runCLI(env, "pr merge"); code != 2 {
		t.Fatalf("exit %d, want 2", code)
	}
	if len(*reqs) != 0 {
		t.Fatalf("requests sent without an id: %v", *reqs)
	}
}

func TestMergeRejectsUnknownStrategy(t *testing.T) {
	env, _, _, reqs := harness(t, nil)
	if code := runCLI(env, "pr merge 7 --strategy rebase"); code != 2 || len(*reqs) != 0 {
		t.Fatalf("exit %d, requests %v", code, *reqs)
	}
}

func TestAPIErrorExits1(t *testing.T) {
	env, _, stderr, _ := harness(t, nil)
	if code := runCLI(env, "pr view 99"); code != 1 {
		t.Fatalf("exit %d, want 1", code)
	}
	if !strings.Contains(stderr.String(), "404") {
		t.Fatalf("stderr = %q", stderr)
	}
}

func TestVersion(t *testing.T) {
	env, stdout, _, _ := harness(t, nil)
	if code := runCLI(env, "--version"); code != 0 || !strings.Contains(stdout.String(), "test") {
		t.Fatalf("exit %d stdout %q", code, stdout)
	}
}

func TestJSONEmptyListIsArray(t *testing.T) {
	env, stdout, stderr, _ := harness(t, map[string]string{"GET /repositories/ws/repo/pullrequests": `{"values":[]}`})
	if code := runCLI(env, "pr list --json"); code != 0 {
		t.Fatalf("exit %d: %s", code, stderr)
	}
	if got := strings.TrimSpace(stdout.String()); got != "[]" {
		t.Fatalf("stdout = %q, want []", got)
	}
}

func TestJSONKeepsHTMLCharacters(t *testing.T) {
	pr := strings.Replace(samplePR, `"Add thing"`, `"Use List<T> && more"`, 1)
	env, stdout, stderr, _ := harness(t, map[string]string{"GET /repositories/ws/repo/pullrequests/7": pr})
	if code := runCLI(env, "pr view 7 --json"); code != 0 {
		t.Fatalf("exit %d: %s", code, stderr)
	}
	if !strings.Contains(stdout.String(), "List<T> && more") {
		t.Fatalf("stdout = %q, want <, > and & unescaped", stdout)
	}
}

func TestTooManyIDsSaysSo(t *testing.T) {
	env, _, stderr, reqs := harness(t, nil)
	if code := runCLI(env, "pr view 7 8"); code != 2 {
		t.Fatalf("exit %d, want 2", code)
	}
	if !strings.Contains(stderr.String(), `"7 8"`) || strings.Contains(stderr.String(), "needs a pull request id") {
		t.Fatalf("stderr = %q, want the extra arguments named", stderr)
	}
	if len(*reqs) != 0 {
		t.Fatalf("requests sent: %v", *reqs)
	}
}

func TestDiffUnknownPathExits1(t *testing.T) {
	env, _, stderr, _ := harness(t, map[string]string{
		"GET /repositories/ws/repo/pullrequests/7/diff": "diff --git a/a.go b/a.go\n+x\n",
	})
	if code := runCLI(env, "pr diff 7 --path nope.go"); code != 1 {
		t.Fatalf("exit %d, want 1", code)
	}
	if !strings.Contains(stderr.String(), "nope.go") {
		t.Fatalf("stderr = %q", stderr)
	}
}
