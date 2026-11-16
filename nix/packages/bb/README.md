# bb

Bitbucket Cloud pull requests from the terminal (`bb pr …`) and as MCP tools (`bb mcp`) for
Claude Code. One binary, one REST client shared by both front ends.

## CLI

```sh
bb pr list [--state OPEN|MERGED|DECLINED|SUPERSEDED] [--limit N]
bb pr view <id>
bb pr diff <id> [--path FILE] [--stat]
bb pr create --title T [--body B | --body-file F] [--source BRANCH] [--dest BRANCH]
             [--reviewer NAME]... [--no-default-reviewers] [--draft] [--close-source-branch]
bb pr edit <id> [--title T] [--body B | --body-file F] [--dest BRANCH] [--reviewer NAME]...
bb pr comments <id> [--limit N]
bb pr comment <id> (--body B | --body-file F) [--path FILE --line N [--old]] [--reply-to ID]
bb pr approve | unapprove | request-changes | remove-request-changes | decline <id>
bb pr merge <id> [--strategy merge_commit|squash|fast_forward] [--message M] [--close-source-branch]
bb pr checks <id>
```

Every `pr` command takes `--repo WORKSPACE/REPO` (default: parsed from the `origin` remote) and
`--json`. `create` defaults the source to the current branch, the destination to the repo's main
branch, and adds the repo's default reviewers. `--reviewer` takes a display name, nickname or
account id.

## MCP

`bb mcp` serves `pr_list`, `pr_view`, `pr_diff`, `pr_create`, `pr_edit`, `pr_comments`,
`pr_comment`, `pr_approve`, `pr_unapprove`, `pr_request_changes`, `pr_remove_request_changes`,
`pr_merge`, `pr_decline` and `pr_checks` over stdio. Every tool takes `workspace` and `repo`.
`pr_edit`, `pr_merge` and `pr_decline` are marked destructive. Diffs over 100 KB are truncated and returned
with the changed-file list.

## Credentials

An Atlassian API token with scopes, sent as HTTP Basic `email:token`.

| Variable | Meaning |
|---|---|
| `BITBUCKET_EMAIL`, `BITBUCKET_API_TOKEN` | values (take precedence) |
| `BITBUCKET_EMAIL_FILE`, `BITBUCKET_API_TOKEN_FILE` | files holding the values |

`nix/users/keanu/keanu.nix` points the `*_FILE` variables at the sops secrets
`bitbucket/email` and `bitbucket/api_token`.

### Token scopes

| Operation | Scope |
|---|---|
| list, view, diff, comments, checks | `read:pullrequest:bitbucket` |
| create, edit, comment, approve, request changes, merge, decline | `write:pullrequest:bitbucket` |
| main branch, default reviewers | `read:repository:bitbucket` |
| reviewer names | `read:workspace:bitbucket`, `read:account` |
| author check | `read:user:bitbucket` |

A `403` from Bitbucket is reported with a hint that the token lacks a scope.
