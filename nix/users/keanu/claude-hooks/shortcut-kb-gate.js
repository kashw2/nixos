// Gates Shortcut story/epic creation on having read Tablogs KB article 527
// ("Master of Puppets"), the root index of the knowledge base, in the
// current session.
//
//   mark  -> PostToolUse on Tablogs_Admin get_article; records a per-session
//            marker when article_id 527 was fetched.
//   gate  -> PreToolUse on shortcut create_story / create_epic; denies the
//            call (nothing is created) until the marker exists.

const fs = require('fs')
const os = require('os')
const path = require('path')

const ROOT_ID = '527'

const mode = process.argv[2]

let input = {}
try {
  input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}')
} catch {}

const sid = String(input.session_id || 'nosession').replace(/[^A-Za-z0-9_-]/g, '') || 'nosession'
const dir = path.join(os.homedir(), '.claude', '.kb' + ROOT_ID)
const marker = path.join(dir, sid)

function sweep() {
  // drop markers from sessions older than 7 days
  const cutoff = Date.now() - 7 * 24 * 60 * 60 * 1000
  try {
    for (const f of fs.readdirSync(dir)) {
      const p = path.join(dir, f)
      try {
        if (fs.statSync(p).mtimeMs < cutoff) fs.unlinkSync(p)
      } catch {}
    }
  } catch {}
}

if (mode === 'mark') {
  const aid = String(input?.tool_input?.article_id ?? '')
  if (aid === ROOT_ID) {
    fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(marker, new Date().toISOString())
    sweep()
  }
  process.exit(0)
}

if (mode === 'gate') {
  if (fs.existsSync(marker)) process.exit(0)
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason:
          'Tablogs KB article 527 ("Master of Puppets") has not been read in this session. ' +
          'Purpose: it is the root index every AI agent at Tablogs starts from. Every standard, rule and repo doc ' +
          'is reachable from it by plain article ID, including the ticket standards this story must follow. ' +
          'It is unpublished, so search_articles will not find it; fetch it by ID. ' +
          'Usage: call mcp__claude_ai_Tablogs_Admin__get_article with article_id 527 and read it in full. ' +
          'Walk down the tree: the Company & Commercial branch for the ticket standards, Repositories for the repo ' +
          'the story touches, and Engineering Docs for its topic. Each index entry has a "Read when" line; fetch ' +
          'only the entries that fit this story, do not re-fetch anything already read this session, and stop ' +
          'once you have enough. Follow whatever the ticket standard you land on says (story structure, story type, ' +
          'related-knowledge search). If an article disagrees with the code, the code wins: tell the user. ' +
          'Then retry this call.'
      }
    })
  )
  process.exit(0)
}

process.exit(0)
