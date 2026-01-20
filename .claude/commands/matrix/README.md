# Matrix Chat Tools for Claude Code

This directory contains Matrix collaboration tools that allow Claude Code agents to communicate via a local Matrix chat server.

## Available Commands

### `/matrix:read`
Read recent messages from the Matrix collaboration channel.

**Usage:** Read historical messages to catch up on team activity
```bash
/matrix:read
```

**Parameters:**
- `--limit N`: Number of messages to read (default: 20)

**Example:**
```bash
python3 scripts/matrix_collab.py read --limit 50
```

---

### `/matrix:poll`
Wait for new messages, then continue polling for 5 seconds to collect responses.

**Usage:** Wait for responses after posting a question or request, or when waiting for new input after a task is complete.
```bash
/matrix:poll
```

**Behavior:**
- Polls every 1 second until the first message arrives (waits indefinitely)
- Once first message arrives, continues polling for 5 more seconds
- Returns all messages collected during the polling period
- Uses sync tokens to avoid duplicates

**Use Cases:**
- After posting a question that requires a response
- When coordinating synchronously with other agents
- After requesting approval or feedback
- During collaborative decision-making
- When waiting for new input

**Example:**
```bash
python3 scripts/matrix_collab.py post "💬 @felix Should we use REST or GraphQL?"
python3 scripts/matrix_collab.py poll  # Wait for response
```

---

### `/matrix:post`
Send a message to the Matrix collaboration channel.

**Usage:** Communicate status, questions, or coordination needs
```bash
/matrix:post
```

**Message Conventions:**
- 🚧 Work in progress
- ✅ Task completed
- ❌ Error/blocker
- 🚨 Urgent attention needed
- 💬 Question
- 📋 Status update
- 🔍 Investigation
- ⚠️ Warning

**Examples:**
```bash
python3 scripts/matrix_collab.py post "🚧 Working on inventory API"
python3 scripts/matrix_collab.py post "✅ Completed code review for PR #42"
python3 scripts/matrix_collab.py post "💬 @felix Can you review the auth changes?"
```

---

## Setup

### Required Environment Variables

```bash
export MATRIX_USER=lysander      # Your Matrix username
export MATRIX_PASS=lysander      # Your Matrix password
```

### Optional Environment Variables

```bash
export MATRIX_SERVER=http://chat:8008                      # Matrix server URL
export MATRIX_ROOM_ALIAS="#development_collab:claude.local" # Room alias
```

### Available Users

The Matrix server comes pre-configured with these users:
- `admin` (password: `admin`) - Admin/CTO
- `lysander` (password: `lysander`) - Backend developer
- `felix` (password: `felix`) - Code reviewer

---

## Typical Workflow

```bash
# 1. At session start - check for updates
python3 scripts/matrix_collab.py read

# 2. Post work status
python3 scripts/matrix_collab.py post "🚧 Starting work on payment API"

# 3. Work on task...

# 4. Check for team updates periodically
python3 scripts/matrix_collab.py poll

# 5. Post completion
python3 scripts/matrix_collab.py post "✅ Payment API complete with tests"

# 6. Check for responses
python3 scripts/matrix_collab.py poll
```
---

## Coordination Best Practices

1. **Start of Session**: Use `/matrix:read` to check for new messages
2. **Beginning Work**: Post a 🚧 message indicating what you're working on
3. **During Work**: Periodically sync to stay aware of team activity
4. **Questions**: Use 💬 and @mention specific agents
5. **Completion**: Post ✅ with clear description of what was done
6. **Blockers**: Post ❌ or 🚨 immediately to alert the team

---

## Integration with Agents

These commands are now available as slash commands in Claude Code:

```
/matrix:read   - Read recent messages
/matrix:poll   - Wait for responses (blocking)
/matrix:post   - Send a message
```

Agents can use these commands directly via the Skill tool, or execute the underlying Python script via Bash.

---

## Technical Details

**Script Location:** `scripts/matrix_collab.py`

**Permissions:** Configured in `.claude/settings.json`:
```json
"Bash(python3:scripts/matrix_collab.py*)"
```

**Cache Directory:** `~/.cache/matrix-collab/`
- Stores sync tokens per user
- Enables efficient polling without re-reading history

**Default Server:** http://chat:8008

**Default Room:** #development_collab:claude.local

---

## Troubleshooting

### "Environment variables not set"
```bash
export MATRIX_USER=lysander
export MATRIX_PASS=lysander
```

### "Connection error"
- Check that Matrix server is running: `docker-compose ps`
- Verify server URL in `MATRIX_SERVER` environment variable
- Ensure you're running inside the Docker network or have connectivity to the server

### "Failed to find room"
- Verify room alias matches: `#development_collab:claude.local`
- Check if room exists on the server
- Ensure user has joined the room

---

## Related Documentation

- [COLLABORATION.md](../../../COLLABORATION.md) - Multi-agent collaboration guide
- [AGENT_EXAMPLE.md](../../../AGENT_EXAMPLE.md) - Example agent workflow
- [scripts/matrix_collab.py](../../../scripts/matrix_collab.py) - Implementation details
