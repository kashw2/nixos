// Gates Shortcut story/epic creation on having read Tablogs KB article 163
// ("Shortcut Story Standards") in the current session.
//
//   mark  -> PostToolUse on Tablogs_Admin get_article; records a per-session
//            marker when article_id 163 was fetched.
//   gate  -> PreToolUse on shortcut stories-create / epics-create; denies the
//            call (nothing is created) until the marker exists.

const fs = require('fs')
const os = require('os')
const path = require('path')

const mode = process.argv[2]

let input = {}
try {
  input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}')
} catch {}

const sid = String(input.session_id || 'nosession').replace(/[^A-Za-z0-9_-]/g, '') || 'nosession'
const dir = path.join(os.homedir(), '.claude', '.kb163')
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
  if (aid === '163') {
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
          'Tablogs KB article 163 ("Shortcut Story Standards") has not been read in this session. ' +
          'Call mcp__claude_ai_Tablogs_Admin__get_article with article_id 163, then write the story to it: ' +
          '## Background / ## Problem / ## Solution / ## Expectation as top-level headings, @-prefixed repo-root file paths, ' +
          'falsifiable Expectation bullets, the matching task-type profile (Technical Area / Skill Set / Team / validation rules), ' +
          'the related-knowledge search steps, and the right story type. Then retry this call.'
      }
    })
  )
  process.exit(0)
}

process.exit(0)
