---
name: Matrix: Poll
description: Wait for new messages, then continue polling for 5 seconds to collect responses
category: matrix
tags: [matrix, chat, collaboration, communication, polling, wait]
---

<!-- MATRIX:START -->

**Guardrails**

- Use this command when you expect responses to a question or request
- This is a blocking operation that will wait indefinitely for the first message
- After receiving the first message, continues polling for 5 more seconds to collect additional responses
- Ensures MATRIX_USER and MATRIX_PASS environment variables are set
- Returns all messages collected during the polling period
- Uses sync tokens, so only new messages since last sync are returned

**Steps**

1. Verify environment variables are set:
   - MATRIX_USER: Your Matrix username (e.g., "lysander", "felix", "admin")
   - MATRIX_PASS: Your Matrix password
   - MATRIX_SERVER (optional): Matrix server URL (default: http://chat:8008)
   - MATRIX_ROOM_ALIAS (optional): Room alias (default: #development_collab:claude.local)

2. Execute the poll command using Bash:
   ```bash
   python3 scripts/matrix_collab.py poll
   ```

3. The command will:
   - Print "Polling for messages... (waiting for first message, then 5 more seconds)"
   - Call sync every 1 second until a message arrives
   - Once first message arrives, continue polling for 5 more seconds
   - Return all messages collected during the polling window

4. Parse the output:
   - If no messages: "No messages received during polling"
   - If messages exist: "--- N message(s) received ---" followed by messages

5. Messages are formatted as:
   ```
   [YYYY-MM-DD HH:MM:SS] @username:server: message body
   ```

**When to Use This Command**

- After posting a question that requires a response
- When coordinating synchronously with other agents
- After requesting approval or feedback
- When waiting for task assignments
- During collaborative decision-making processes
- After posting a blocker or urgent issue that needs immediate response

**Typical Usage Pattern**

```bash
# 1. Post a question
python3 scripts/matrix_collab.py post "💬 @felix Should we use REST or GraphQL for the new API?"

# 2. Wait for response(s)
python3 scripts/matrix_collab.py poll

# 3. Process the responses and continue work
```

**Examples**

Wait for responses after posting a question:
```bash
python3 scripts/matrix_collab.py post "💬 @admin Need approval to modify database schema"
python3 scripts/matrix_collab.py poll
```

Wait for coordination messages:
```bash
python3 scripts/matrix_collab.py post "🚧 About to deploy changes to staging"
python3 scripts/matrix_collab.py poll  # Wait for any concerns or confirmations
```

**Expected Output - No Messages**

```
Polling for messages... (waiting for first message, then 5 more seconds)
No messages received during polling
```

**Expected Output - Messages Received**

```
Polling for messages... (waiting for first message, then 5 more seconds)
--- 2 message(s) received ---
[2026-01-20 12:15:30] @felix:claude.local: I think REST is better for this use case
[2026-01-20 12:15:35] @admin:claude.local: Agreed, keep it simple with REST
```

**Behavior Details**

1. **Initial Wait**: Polls every 1 second indefinitely until first message arrives
2. **Collection Window**: Once first message arrives, continues for exactly 5 more seconds
3. **Aggregation**: All messages during the polling period are collected and returned together
4. **Deduplication**: Uses sync tokens, so messages are not duplicated across calls

**Timeout Considerations**

- This command does NOT have a timeout for the initial wait
- It will block until at least one message arrives
- If you need a timeout, consider using `/matrix:sync` in a loop with your own timeout logic
- Press Ctrl+C to manually interrupt if needed

**Coordination Workflow Example**

```bash
# Agent 1: Post work intention
python3 scripts/matrix_collab.py post "🚧 Planning to refactor authentication module"

# Agent 1: Wait for team feedback
python3 scripts/matrix_collab.py poll

# Agent 1: Process responses
# If approved, continue
# If concerns raised, address them

# Agent 1: Post status
python3 scripts/matrix_collab.py post "✅ Authentication refactor complete"
```

**Error Handling**

If environment variables are not set:
```
Error: MATRIX_USER and MATRIX_PASS environment variables must be set
Example: export MATRIX_USER=lysander MATRIX_PASS=lysander
```

If connection fails:
```
Error: Connection error: [connection details]
```

To interrupt polling:
```
Press Ctrl+C to cancel waiting
```

**Comparison with Other Commands**

| Command | Behavior | Use Case |
|---------|----------|----------|
| `/matrix:poll` | Waits for first message, then 5 more seconds | Expecting responses to a question |
| `/matrix:read` | Shows recent history | Catch up on conversation |

**Reference**

- Script location: `scripts/matrix_collab.py`
- Required env vars: MATRIX_USER, MATRIX_PASS
- Optional env vars: MATRIX_SERVER, MATRIX_ROOM_ALIAS
- Polling interval: 1 second
- Collection window: 5 seconds after first message
- Initial timeout: None (waits indefinitely)
- Default server: http://chat:8008
- Default room: #development_collab:claude.local

**Best Practices**

1. **Use for synchronous coordination**: When you need immediate feedback
2. **Post context first**: Always post a clear question/request before polling
3. **Handle no responses**: Have a fallback plan if polling returns no messages
4. **Mention specific agents**: Use @username to get targeted responses

<!-- MATRIX:END -->
