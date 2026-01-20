---
name: Matrix: Read
description: Read recent messages from the Matrix collaboration channel
category: matrix
tags: [matrix, chat, collaboration, communication]
---

<!-- MATRIX:START -->

**Guardrails**

- Only use this command when you need to read historical messages from the collaboration channel
- Use `/matrix:poll` instead if you want to check for new messages since last check
- Ensure MATRIX_USER and MATRIX_PASS environment variables are set
- Default limit is 10 messages; adjust --limit parameter as needed
- Messages are returned in chronological order (oldest first)

**Steps**

1. Verify environment variables are set:
   - MATRIX_USER: Your Matrix username (e.g., "lysander", "felix", "admin")
   - MATRIX_PASS: Your Matrix password
   - MATRIX_SERVER (optional): Matrix server URL (default: http://chat:8008)
   - MATRIX_ROOM_ALIAS (optional): Room alias (default: #development_collab:claude.local)

2. Execute the read command using Bash:
   ```bash
   python3 scripts/matrix_collab.py read --limit <number>
   ```
   
3. Parse the output which will be in the format:
   ```
   [YYYY-MM-DD HH:MM:SS] @username:server: message body
   ```

4. If no messages are found, output will be "No messages found"

5. Use the message history to understand:
   - Recent team activities and updates
   - Task assignments or completions
   - Questions or blockers from other agents
   - Coordination needs for your current work

**When to Use This Command**

- At the start of a work session to catch up on team activity
- When you need context about what other agents have been working on
- To review the conversation history for specific information
- When debugging collaborative workflows

**Examples**

Read last 10 messages (default):
```bash
python3 scripts/matrix_collab.py read
```

Read last 50 messages:
```bash
python3 scripts/matrix_collab.py read --limit 50
```

Read last 20 messages:
```bash
python3 scripts/matrix_collab.py read --limit 20
```

**Expected Output Format**

```
[2026-01-20 10:15:23] @lysander:claude.local: 🚧 Working on inventory API endpoints
[2026-01-20 10:18:45] @felix:claude.local: ✅ Code review completed for PR #42
[2026-01-20 10:22:11] @admin:claude.local: Please coordinate on database schema changes
```

**Error Handling**

If environment variables are not set, you'll see:
```
Error: MATRIX_USER and MATRIX_PASS environment variables must be set
Example: export MATRIX_USER=lysander MATRIX_PASS=lysander
```

If connection fails:
```
Error: Connection error: [connection details]
```

**Reference**

- Script location: `scripts/matrix_collab.py`
- Required env vars: MATRIX_USER, MATRIX_PASS
- Optional env vars: MATRIX_SERVER, MATRIX_ROOM_ALIAS
- Default server: http://chat:8008
- Default room: #development_collab:claude.local

<!-- MATRIX:END -->
