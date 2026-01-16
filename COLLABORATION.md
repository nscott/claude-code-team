# Agent Collaboration Guide

This guide explains how Claude agents should collaborate via the Matrix development channel.

## Overview

All agents have access to a shared Matrix room (`#development_collab:claude.local`) for coordination and updates. Use this channel to:

- Share completed work and milestones
- Announce breaking changes or important updates
- Ask questions or report blockers
- Coordinate with other agents
- Request code reviews
- Receive feedback from the chief technology officer (who runs as Admin)

## Using the Matrix Collaboration Tool

The `matrix_collab.py` script provides a simple interface for reading and posting messages.

### Reading Messages

Check what's happening in the channel:

```bash
# Read last 20 messages
python3 scripts/matrix_collab.py read

# Read last 50 messages
python3 scripts/matrix_collab.py read --limit 50

# Check for new messages since you last checked
python3 scripts/matrix_collab.py sync
```

### Posting Messages

Share updates with other agents:

```bash
# Post a status update
python3 scripts/matrix_collab.py post "✅ Completed inventory validation endpoints"

# Report a blocker
python3 scripts/matrix_collab.py post "⚠️ Need review: PR #123 changes database schema"

# Ask a question
python3 scripts/matrix_collab.py post "❓ Should we use Zod or class-validator for the new DTOs?"
```

## Agent Credentials

Each agent type has its own credentials:

- **Backend Agent**: `lysander` / `lysander`
- **Code Reviewer**: `felix` / `felix`
- **CTO**: `admin` / `admin`

Set your agent's credentials via environment variables:

```bash
export MATRIX_USER=lysander
export MATRIX_PASS=lysander
```

Or pass them when running the script:

```bash
MATRIX_USER=felix MATRIX_PASS=felix python3 scripts/matrix_collab.py read
```

## Best Practices

### When to Check for Messages

1. **At the start of your session** - Check for new instructions or updates
2. **Before starting major work** - Ensure no conflicts with other agents
3. **After completing tasks** - Read any feedback or follow-up requests
4. **When blocked** - Check if others have shared relevant information

### When to Post Messages

1. **Task completion** - Share what you've finished
2. **Breaking changes** - Warn others about API changes, schema migrations, etc.
3. **Blockers** - Ask for help or clarification
4. **Questions** - Get input from other agents or humans
5. **Code review requests** - Ask for reviews on PRs from Felix and wait for the review before continuing

### Message Format Suggestions

Use emojis to categorize messages:

- ✅ Task completed
- 🚧 Work in progress
- ⚠️ Warning / breaking change
- ❌ Error / failure
- 🔍 Code review request
- ❓ Question
- 💡 Suggestion
- 📝 Documentation update

## Example Workflow

```bash
# 1. Check for new messages at session start
python3 scripts/matrix_collab.py sync

# 2. Do your work...

# 3. Announce completion
python3 scripts/matrix_collab.py post "✅ Backend: Added inventory CRUD endpoints in backend/src/inventory/"

# 4. Check for responses
python3 scripts/matrix_collab.py sync
```

## Python API (for advanced usage)

You can also import and use the client in Python scripts:

```python
from scripts.matrix_collab import MatrixClient

# Create client
client = MatrixClient(
    server="http://chat:8008",
    username="lysander",
    password="lysander"
)

# Read messages
messages = client.read_messages(limit=10)
for msg in messages:
    print(f"{msg['sender']}: {msg['body']}")

# Post message
client.post_message("✅ Task completed")

# Sync new messages
new_messages = client.sync_messages()
print(f"Got {len(new_messages)} new messages")
```

## Troubleshooting

### Connection Issues

If you can't connect to the Matrix server:

1. Check that the `chat` service is running: `docker ps | grep chat`
2. Use `http://chat:8008` as the server URL inside Docker containers
3. Use `http://localhost:8008` when running outside Docker

### Authentication Failed

If login fails:

1. Verify your username/password environment variables
2. Check available users in the startup script: `claude-code-team/chat-data/synapse-start.sh`
3. Test login with curl:
   ```bash
   curl -X POST http://chat:8008/_matrix/client/r0/login \
     -H "Content-Type: application/json" \
     -d '{"type":"m.login.password","user":"lysander","password":"lysander"}'
   ```

### Room Not Found

If the room doesn't exist:

1. Check that the `development_collab` room was created
2. Log into Element Web at http://localhost:8009 to verify
3. Check the chat service logs: `docker compose logs chat`
