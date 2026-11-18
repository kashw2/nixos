// Package cli implements the gh-style `bb pr …` command line.
package cli

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"bb/internal/bitbucket"
	"bb/internal/gitremote"
)

type Env struct {
	Stdout, Stderr io.Writer
	Dir            string
	Version        string
	NewClient      func() (*bitbucket.Client, error)
}

const usage = `bb: Bitbucket Cloud pull requests

Usage:
  bb pr list [--state OPEN|MERGED|DECLINED|SUPERSEDED] [--limit N]
  bb pr view <id>
  bb pr diff <id> [--path FILE] [--stat]
  bb pr create --title T [--body B | --body-file F] [--source BRANCH] [--dest BRANCH]
               [--reviewer NAME]... [--no-default-reviewers] [--draft] [--close-source-branch]
  bb pr edit <id> [--title T] [--body B | --body-file F] [--dest BRANCH] [--reviewer NAME]...
  bb pr comments <id> [--limit N]
  bb pr comment <id> (--body B | --body-file F) [--path FILE --line N [--old]] [--reply-to ID]
  bb pr approve|unapprove|request-changes|remove-request-changes|decline <id>
  bb pr merge <id> [--strategy merge_commit|squash|fast_forward] [--message M] [--close-source-branch]
  bb pr checks <id>
  bb mcp                 serve the same operations as MCP tools over stdio
  bb --version

Every pr command takes --repo WORKSPACE/REPO (default: the origin remote) and --json.
Credentials: BITBUCKET_EMAIL and BITBUCKET_API_TOKEN, or their *_FILE variants.
`

// usageError makes Run exit 2 instead of 1.
type usageError struct{ msg string }

func (e usageError) Error() string { return e.msg }

func usagef(format string, args ...any) error { return usageError{fmt.Sprintf(format, args...)} }

func Run(ctx context.Context, args []string, env Env) int {
	err := run(ctx, args, env)
	var ue usageError
	switch {
	case err == nil:
		return 0
	case errors.As(err, &ue):
		fmt.Fprintf(env.Stderr, "bb: %s\nRun 'bb help' for usage.\n", ue.msg)
		return 2
	case errors.Is(err, flag.ErrHelp):
		return 0
	default:
		fmt.Fprintf(env.Stderr, "bb: %s\n", err)
		return 1
	}
}

func run(ctx context.Context, args []string, env Env) error {
	if len(args) == 0 {
		return usagef("missing command")
	}
	switch args[0] {
	case "help", "-h", "--help":
		fmt.Fprint(env.Stdout, usage)
		return nil
	case "version", "--version":
		fmt.Fprintf(env.Stdout, "bb %s\n", env.Version)
		return nil
	case "pr":
	default:
		return usagef("unknown command %q", args[0])
	}
	if len(args) < 2 {
		return usagef("missing pr subcommand")
	}
	sub, rest := args[1], args[2:]
	handler, ok := handlers[sub]
	if !ok {
		return usagef("unknown pr subcommand %q", sub)
	}
	cmd := &command{env: env, fs: flag.NewFlagSet("bb pr "+sub, flag.ContinueOnError)}
	cmd.fs.SetOutput(env.Stderr)
	cmd.fs.StringVar(&cmd.repoFlag, "repo", "", "WORKSPACE/REPO")
	cmd.fs.BoolVar(&cmd.json, "json", false, "print JSON")
	return handler(ctx, cmd, rest)
}

type command struct {
	env      Env
	fs       *flag.FlagSet
	repoFlag string
	json     bool
	ws, repo string
	client   *bitbucket.Client
	args     []string
}

// parse accepts flags before or after positional arguments, then resolves the repo and client.
func (c *command) parse(args []string, positional int) error {
	for {
		if err := c.fs.Parse(args); err != nil {
			if errors.Is(err, flag.ErrHelp) {
				return err
			}
			return usageError{err.Error()}
		}
		if c.fs.NArg() == 0 {
			break
		}
		c.args = append(c.args, c.fs.Arg(0))
		args = c.fs.Args()[1:]
	}
	if len(c.args) != positional {
		switch {
		case positional == 1 && len(c.args) == 0:
			return usagef("%s needs a pull request id", c.fs.Name())
		case positional == 1:
			return usagef("%s takes one pull request id, got %q", c.fs.Name(), strings.Join(c.args, " "))
		}
		return usagef("%s takes no arguments, got %q", c.fs.Name(), strings.Join(c.args, " "))
	}
	if c.repoFlag != "" {
		ws, repo, ok := strings.Cut(c.repoFlag, "/")
		if !ok || ws == "" || repo == "" || strings.Contains(repo, "/") {
			return usagef("--repo must be WORKSPACE/REPO, got %q", c.repoFlag)
		}
		c.ws, c.repo = ws, repo
	} else {
		ws, repo, err := gitremote.Origin(c.env.Dir)
		if err != nil {
			return err
		}
		c.ws, c.repo = ws, repo
	}
	client, err := c.env.NewClient()
	if err != nil {
		return err
	}
	c.client = client
	return nil
}

func (c *command) id() (int, error) {
	id, err := strconv.Atoi(strings.TrimPrefix(c.args[0], "#"))
	if err != nil || id <= 0 {
		return 0, usagef("invalid pull request id %q", c.args[0])
	}
	return id, nil
}

// parseWithID is parse for commands taking exactly one PR id.
func (c *command) parseWithID(args []string) (int, error) {
	if err := c.parse(args, 1); err != nil {
		return 0, err
	}
	return c.id()
}

func (c *command) out(v any, readable func(io.Writer)) error {
	if c.json {
		enc := json.NewEncoder(c.env.Stdout)
		enc.SetEscapeHTML(false)
		enc.SetIndent("", "  ")
		return enc.Encode(v)
	}
	readable(c.env.Stdout)
	return nil
}

type stringList []string

func (s *stringList) String() string     { return strings.Join(*s, ",") }
func (s *stringList) Set(v string) error { *s = append(*s, v); return nil }

func readBody(body, bodyFile string) (string, error) {
	if bodyFile == "" {
		return body, nil
	}
	if body != "" {
		return "", usagef("use --body or --body-file, not both")
	}
	b, err := os.ReadFile(bodyFile)
	return string(b), err
}

func (c *command) visited(name string) bool {
	found := false
	c.fs.Visit(func(f *flag.Flag) { found = found || f.Name == name })
	return found
}

type handler func(ctx context.Context, c *command, args []string) error

var handlers = map[string]handler{
	"list":                   prList,
	"view":                   prView,
	"diff":                   prDiff,
	"create":                 prCreate,
	"edit":                   prEdit,
	"comments":               prComments,
	"comment":                prComment,
	"approve":                reviewAction("Approved", (*bitbucket.Client).Approve),
	"unapprove":              reviewAction("Removed approval from", (*bitbucket.Client).Unapprove),
	"request-changes":        reviewAction("Requested changes on", (*bitbucket.Client).RequestChanges),
	"remove-request-changes": reviewAction("Removed change request from", (*bitbucket.Client).RemoveRequestChanges),
	"decline":                reviewAction("Declined", (*bitbucket.Client).Decline),
	"merge":                  prMerge,
	"checks":                 prChecks,
}

func prList(ctx context.Context, c *command, args []string) error {
	state := c.fs.String("state", "OPEN", "OPEN, MERGED, DECLINED or SUPERSEDED")
	limit := c.fs.Int("limit", 25, "maximum pull requests")
	if err := c.parse(args, 0); err != nil {
		return err
	}
	prs, err := c.client.ListPRs(ctx, c.ws, c.repo, *state, *limit)
	if err != nil {
		return err
	}
	return c.out(prs, func(w io.Writer) {
		if len(prs) == 0 {
			fmt.Fprintf(w, "No %s pull requests in %s/%s\n", strings.ToLower(*state), c.ws, c.repo)
		}
		for _, pr := range prs {
			draft := ""
			if pr.Draft {
				draft = " [draft]"
			}
			fmt.Fprintf(w, "#%d\t%s%s\t%s\t%s → %s\t%s\n", pr.ID, pr.State, draft, pr.Title, pr.Source, pr.Destination, pr.Author)
		}
	})
}

func printPR(w io.Writer, pr bitbucket.PullRequest) {
	fmt.Fprintf(w, "#%d %s\n", pr.ID, pr.Title)
	state := pr.State
	if pr.Draft {
		state += " (draft)"
	}
	fmt.Fprintf(w, "State:     %s\n", state)
	fmt.Fprintf(w, "Branch:    %s → %s\n", pr.Source, pr.Destination)
	if pr.Author != "" {
		fmt.Fprintf(w, "Author:    %s\n", pr.Author)
	}
	var people []string
	for _, p := range pr.Participants {
		switch {
		case p.Approved:
			people = append(people, p.Name+" ✓ approved")
		case p.State == "changes_requested":
			people = append(people, p.Name+" ✗ changes requested")
		case p.Role == "REVIEWER":
			people = append(people, p.Name+" (pending)")
		}
	}
	if len(people) > 0 {
		fmt.Fprintf(w, "Reviewers: %s\n", strings.Join(people, ", "))
	}
	fmt.Fprintf(w, "Comments:  %d\n", pr.CommentCount)
	fmt.Fprintf(w, "URL:       %s\n", pr.URL)
	if pr.Description != "" {
		fmt.Fprintf(w, "\n%s\n", pr.Description)
	}
}

func prView(ctx context.Context, c *command, args []string) error {
	id, err := c.parseWithID(args)
	if err != nil {
		return err
	}
	pr, err := c.client.GetPR(ctx, c.ws, c.repo, id)
	if err != nil {
		return err
	}
	return c.out(pr, func(w io.Writer) { printPR(w, pr) })
}

func prDiff(ctx context.Context, c *command, args []string) error {
	path := c.fs.String("path", "", "only this file")
	stat := c.fs.Bool("stat", false, "list changed files instead")
	id, err := c.parseWithID(args)
	if err != nil {
		return err
	}
	if *stat {
		stats, err := c.client.DiffStat(ctx, c.ws, c.repo, id)
		if err != nil {
			return err
		}
		return c.out(stats, func(w io.Writer) {
			for _, s := range stats {
				fmt.Fprintf(w, "%-9s %s\t+%d -%d\n", s.Status, s.Path, s.Added, s.Removed)
			}
		})
	}
	diff, err := c.client.Diff(ctx, c.ws, c.repo, id, *path)
	if err != nil {
		return err
	}
	return c.out(map[string]string{"diff": diff}, func(w io.Writer) { fmt.Fprint(w, diff) })
}

func prCreate(ctx context.Context, c *command, args []string) error {
	var reviewers stringList
	title := c.fs.String("title", "", "title (required)")
	body := c.fs.String("body", "", "description")
	bodyFile := c.fs.String("body-file", "", "read the description from a file")
	source := c.fs.String("source", "", "source branch (default: current branch)")
	dest := c.fs.String("dest", "", "destination branch (default: the repo's main branch)")
	c.fs.Var(&reviewers, "reviewer", "reviewer name, nickname or account id (repeatable)")
	noDefaults := c.fs.Bool("no-default-reviewers", false, "skip the repo's default reviewers")
	draft := c.fs.Bool("draft", false, "open as a draft")
	closeSource := c.fs.Bool("close-source-branch", false, "delete the source branch on merge")
	if err := c.parse(args, 0); err != nil {
		return err
	}
	if *title == "" {
		return usagef("--title is required")
	}
	description, err := readBody(*body, *bodyFile)
	if err != nil {
		return err
	}
	if *source == "" {
		if *source, err = gitremote.CurrentBranch(c.env.Dir); err != nil {
			return err
		}
	}
	if *dest == "" {
		if *dest, err = c.client.MainBranch(ctx, c.ws, c.repo); err != nil {
			return err
		}
	}
	pr, err := c.client.CreatePR(ctx, c.ws, c.repo, bitbucket.CreateInput{
		Title: *title, Description: description, Source: *source, Destination: *dest,
		Reviewers: reviewers, DefaultReviewers: !*noDefaults, Draft: *draft, CloseSourceBranch: *closeSource,
	})
	if err != nil {
		return err
	}
	return c.out(pr, func(w io.Writer) { fmt.Fprintf(w, "Created #%d: %s\n", pr.ID, pr.URL) })
}

func prEdit(ctx context.Context, c *command, args []string) error {
	var reviewers stringList
	title := c.fs.String("title", "", "new title")
	body := c.fs.String("body", "", "new description")
	bodyFile := c.fs.String("body-file", "", "read the new description from a file")
	dest := c.fs.String("dest", "", "new destination branch")
	c.fs.Var(&reviewers, "reviewer", "add a reviewer (repeatable)")
	id, err := c.parseWithID(args)
	if err != nil {
		return err
	}
	in := bitbucket.EditInput{Reviewers: reviewers}
	if c.visited("title") {
		in.Title = title
	}
	if c.visited("body") || c.visited("body-file") {
		description, err := readBody(*body, *bodyFile)
		if err != nil {
			return err
		}
		in.Description = &description
	}
	if c.visited("dest") {
		in.Destination = dest
	}
	if in.Title == nil && in.Description == nil && in.Destination == nil && len(in.Reviewers) == 0 {
		return usagef("edit needs at least one of --title, --body, --body-file, --dest, --reviewer")
	}
	pr, err := c.client.EditPR(ctx, c.ws, c.repo, id, in)
	if err != nil {
		return err
	}
	return c.out(pr, func(w io.Writer) { fmt.Fprintf(w, "Updated #%d: %s\n", pr.ID, pr.URL) })
}

func prComments(ctx context.Context, c *command, args []string) error {
	limit := c.fs.Int("limit", 100, "maximum comments")
	id, err := c.parseWithID(args)
	if err != nil {
		return err
	}
	comments, err := c.client.Comments(ctx, c.ws, c.repo, id, *limit)
	if err != nil {
		return err
	}
	return c.out(comments, func(w io.Writer) {
		if len(comments) == 0 {
			fmt.Fprintf(w, "No comments on #%d\n", id)
		}
		for _, cm := range comments {
			indent, where := "", ""
			if cm.ParentID > 0 {
				indent = "  ↳ "
			}
			if cm.Path != "" {
				where = fmt.Sprintf(" (%s:%d)", cm.Path, cm.Line)
			}
			fmt.Fprintf(w, "%s#%d %s%s: %s\n", indent, cm.ID, cm.Author, where, cm.Body)
		}
	})
}

func prComment(ctx context.Context, c *command, args []string) error {
	body := c.fs.String("body", "", "comment text")
	bodyFile := c.fs.String("body-file", "", "read the comment from a file")
	path := c.fs.String("path", "", "file for an inline comment")
	line := c.fs.Int("line", 0, "line for an inline comment (new side unless --old)")
	old := c.fs.Bool("old", false, "--line refers to the old side of the diff")
	replyTo := c.fs.Int("reply-to", 0, "reply to this comment id")
	id, err := c.parseWithID(args)
	if err != nil {
		return err
	}
	text, err := readBody(*body, *bodyFile)
	if err != nil {
		return err
	}
	if strings.TrimSpace(text) == "" {
		return usagef("comment needs --body or --body-file")
	}
	if *line > 0 && *path == "" {
		return usagef("--line needs --path")
	}
	cm, err := c.client.AddComment(ctx, c.ws, c.repo, id, bitbucket.CommentInput{
		Body: text, Path: *path, Line: *line, LineIsOld: *old, ParentID: *replyTo,
	})
	if err != nil {
		return err
	}
	return c.out(cm, func(w io.Writer) { fmt.Fprintf(w, "Added comment #%d on #%d\n", cm.ID, id) })
}

func reviewAction(verb string, act func(*bitbucket.Client, context.Context, string, string, int) error) handler {
	return func(ctx context.Context, c *command, args []string) error {
		id, err := c.parseWithID(args)
		if err != nil {
			return err
		}
		if err := act(c.client, ctx, c.ws, c.repo, id); err != nil {
			return err
		}
		return c.out(map[string]any{"id": id, "ok": true}, func(w io.Writer) { fmt.Fprintf(w, "%s #%d\n", verb, id) })
	}
}

var mergeStrategies = map[string]bool{"merge_commit": true, "squash": true, "fast_forward": true}

func prMerge(ctx context.Context, c *command, args []string) error {
	strategy := c.fs.String("strategy", "", "merge_commit, squash or fast_forward (default: the branch's setting)")
	message := c.fs.String("message", "", "merge commit message")
	closeSource := c.fs.Bool("close-source-branch", false, "delete the source branch")
	id, err := c.parseWithID(args)
	if err != nil {
		return err
	}
	if *strategy != "" && !mergeStrategies[*strategy] {
		return usagef("unknown --strategy %q", *strategy)
	}
	in := bitbucket.MergeInput{Strategy: *strategy, Message: *message}
	if c.visited("close-source-branch") {
		in.CloseSourceBranch = closeSource
	}
	pr, err := c.client.Merge(ctx, c.ws, c.repo, id, in)
	if err != nil {
		return err
	}
	return c.out(pr, func(w io.Writer) {
		if pr.State == "MERGE_IN_PROGRESS" {
			fmt.Fprintf(w, "Merge of #%d is still running: %s\n", id, pr.URL)
			return
		}
		fmt.Fprintf(w, "Merged #%d (%s)\n", id, pr.State)
	})
}

func prChecks(ctx context.Context, c *command, args []string) error {
	id, err := c.parseWithID(args)
	if err != nil {
		return err
	}
	statuses, err := c.client.Statuses(ctx, c.ws, c.repo, id)
	if err != nil {
		return err
	}
	return c.out(statuses, func(w io.Writer) {
		if len(statuses) == 0 {
			fmt.Fprintf(w, "No checks reported for #%d\n", id)
		}
		for _, s := range statuses {
			fmt.Fprintf(w, "%-11s %s\t%s\n", s.State, s.Name, s.URL)
		}
	})
}
