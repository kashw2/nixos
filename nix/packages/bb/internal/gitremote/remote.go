// Package gitremote finds the Bitbucket workspace/repo and branch of a local checkout.
package gitremote

import (
	"errors"
	"fmt"
	"net/url"
	"os/exec"
	"regexp"
	"strings"
)

var scpRemote = regexp.MustCompile(`^(?:[^@/]+@)?bitbucket\.org:([^/]+)/([^/]+?)(?:\.git)?/?$`)

// Parse extracts workspace and repo from a bitbucket.org remote URL (scp-style, ssh:// or https://).
func Parse(remote string) (workspace, repo string, err error) {
	remote = strings.TrimSpace(remote)
	if m := scpRemote.FindStringSubmatch(remote); m != nil {
		return m[1], m[2], nil
	}
	if u, perr := url.Parse(remote); perr == nil && strings.EqualFold(u.Hostname(), "bitbucket.org") {
		parts := strings.Split(strings.Trim(u.Path, "/"), "/")
		if len(parts) == 2 && parts[0] != "" && parts[1] != "" {
			return parts[0], strings.TrimSuffix(parts[1], ".git"), nil
		}
	}
	// The remote itself is not echoed: https remotes can embed credentials.
	return "", "", errors.New("origin is not a bitbucket.org repository; pass --repo workspace/repo")
}

// Origin returns the workspace and repo of the "origin" remote of the checkout at dir.
func Origin(dir string) (workspace, repo string, err error) {
	out, err := git(dir, "remote", "get-url", "origin")
	if err != nil {
		return "", "", err
	}
	return Parse(out)
}

// CurrentBranch returns the checked-out branch at dir; symbolic-ref also works on an unborn branch.
func CurrentBranch(dir string) (string, error) {
	return git(dir, "symbolic-ref", "--short", "HEAD")
}

func git(dir string, args ...string) (string, error) {
	out, err := exec.Command("git", append([]string{"-C", dir}, args...)...).Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return "", fmt.Errorf("git %s: %s", strings.Join(args, " "), strings.TrimSpace(string(exitErr.Stderr)))
		}
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}
