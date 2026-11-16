package gitremote

import (
	"os/exec"
	"strings"
	"testing"
)

func TestParse(t *testing.T) {
	cases := []struct {
		remote, ws, repo string
	}{
		{"git@bitbucket.org:tablogs-workspace/testlab360.git", "tablogs-workspace", "testlab360"},
		{"bitbucket.org:ws/repo", "ws", "repo"},
		{"https://bitbucket.org/ws/repo", "ws", "repo"},
		{"https://user@bitbucket.org/ws/repo.git", "ws", "repo"},
		{"ssh://git@bitbucket.org/ws/repo.git", "ws", "repo"},
	}
	for _, tc := range cases {
		ws, repo, err := Parse(tc.remote)
		if err != nil || ws != tc.ws || repo != tc.repo {
			t.Errorf("Parse(%q) = %q, %q, %v; want %q, %q", tc.remote, ws, repo, err, tc.ws, tc.repo)
		}
	}
}

func TestParseRejectsOtherHosts(t *testing.T) {
	for _, remote := range []string{"git@github.com:a/b.git", "https://gitlab.com/a/b", "not a url"} {
		if _, _, err := Parse(remote); err == nil {
			t.Errorf("Parse(%q) succeeded, want error", remote)
		}
	}
}

func TestParseErrorDoesNotEchoCredentials(t *testing.T) {
	_, _, err := Parse("https://user:hunter2@github.com/a/b.git")
	if err == nil || strings.Contains(err.Error(), "hunter2") {
		t.Fatalf("err = %v", err)
	}
}

func gitRepo(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	for _, args := range [][]string{
		{"init", "-q", "-b", "feature/x"},
		{"remote", "add", "origin", "git@bitbucket.org:ws/repo.git"},
	} {
		if out, err := exec.Command("git", append([]string{"-C", dir}, args...)...).CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, out)
		}
	}
	return dir
}

func TestOriginAndCurrentBranch(t *testing.T) {
	dir := gitRepo(t)
	ws, repo, err := Origin(dir)
	if err != nil || ws != "ws" || repo != "repo" {
		t.Fatalf("Origin = %q, %q, %v", ws, repo, err)
	}
	branch, err := CurrentBranch(dir)
	if err != nil || branch != "feature/x" {
		t.Fatalf("CurrentBranch = %q, %v", branch, err)
	}
}
