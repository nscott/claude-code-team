---
name: Matrix: Post
description: Send a message to the Matrix collaboration channel
category: matrix
tags: [matrix, chat, collaboration, communication, status]
---

<!-- MATRIX:START -->

**Guardrails**

- Use this command to communicate status updates, questions, or coordination needs
- Messages should be concise and actionable
- Follow emoji conventions for message categorization:
  - 🚧 Work in progress / currently working on
  - ✅ Task completed / success
  - ❌ Error / failure / blocker
  - 🚨 Urgent / needs immediate attention
  - 💬 Question / needs response
  - 📋 Status update / information
  - 🔍 Investigation / debugging
  - ⚠️  Warning / potential issue
- Ensure MATRIX_USER and MATRIX_PASS environment variables are set
- Use @username to mention specific agents (e.g., @felix, @lysander)
- Keep messages relevant to the development collaboration

**Steps**

1. Verify environment variables are set:
   - MATRIX_USER: Your Matrix username (e.g., "lysander", "felix", "admin")
   - MATRIX_PASS: Your Matrix password
   - MATRIX_SERVER (optional): Matrix server URL (default: http://chat:8008)
   - MATRIX_ROOM_ALIAS (optional): Room alias (default: #development_collab:claude.local)

2. Compose a clear, concise message following conventions

3. Execute the post command using Bash:
   ```bash
   python3 scripts/matrix_collab.py post "your message here"
   ```

4. Verify success output: "Message sent successfully"

5. If you expect responses, use `/matrix:poll` to check for replies

**When to Use This Command**

- Starting work on a task: "🚧 Working on user authentication API"
- Completing a task: "✅ Completed inventory endpoint with tests"
- Encountering blockers: "❌ Database migration failed, needs review"
- Asking questions: "💬 @felix Should we use JWT or sessions for auth?"
- Urgent coordination: "🚨 Breaking change detected in payment API"
- Status updates: "📋 Progress update: 3/5 endpoints completed"
- Debugging: "🔍 Investigating performance issue in search queries"
- Warnings: "⚠️ Planning to refactor auth module, may affect other work"

**Message Formatting Best Practices**

1. **Start with emoji** to categorize the message type
2. **Be specific** about what you're working on or asking
3. **Mention users** when directing questions or requests
4. **Include context** like file names, function names, or PR numbers
5. **Keep it concise** - aim for one or two sentences

**Examples**

Post work started:
```bash
python3 scripts/matrix_collab.py post "🚧 Working on inventory API endpoints"
```

Post task completion:
```bash
python3 scripts/matrix_collab.py post "✅ Completed code review for PR #42 - approved with minor suggestions"
```

Post a question:
```bash
python3 scripts/matrix_collab.py post "💬 @lysander Can you review the database schema changes in openspec/specs/003-db-schema.md?"
```

Post an urgent issue:
```bash
python3 scripts/matrix_collab.py post "🚨 Tests failing in CI - authentication module needs immediate attention"
```

Post a status update:
```bash
python3 scripts/matrix_collab.py post "📋 API implementation 60% complete: auth ✅, inventory ✅, orders 🚧"
```

Post with special characters (use proper quoting):
```bash
python3 scripts/matrix_collab.py post "✅ Fixed bug in calculateTotal() - edge case with empty cart"
```

**Expected Output**

Success:
```
Message sent successfully
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

If message send fails:
```
Error: Failed to send message
```

**Coordination Workflow Example**

```bash
# 1. Post that you're starting work
python3 scripts/matrix_collab.py post "🚧 Starting work on payment integration"

# 2. Work on the task...

# 3. Post progress update
python3 scripts/matrix_collab.py post "📋 Payment API scaffold complete, implementing Stripe webhook handler"

# 4. Check for team updates
python3 scripts/matrix_collab.py sync

# 5. Post completion
python3 scripts/matrix_collab.py post "✅ Payment integration complete with unit tests"

# 6. Check for feedback
python3 scripts/matrix_collab.py sync
```

**Reference**

- Script location: `scripts/matrix_collab.py`
- Required env vars: MATRIX_USER, MATRIX_PASS
- Optional env vars: MATRIX_SERVER, MATRIX_ROOM_ALIAS
- Default server: http://chat:8008
- Default room: #development_collab:claude.local
- Message format: Plain text (m.text msgtype)
- Transaction ID: Auto-generated (timestamp + random suffix)

**Emoji Convention Reference**

| Emoji | Meaning | Example |
|-------|---------|---------|
| 🚧 | Work in progress | "🚧 Implementing user auth" |
| ✅ | Completed | "✅ Tests passing" |
| ❌ | Error/Failure | "❌ Build failed" |
| 🚨 | Urgent | "🚨 Production issue" |
| 💬 | Question | "💬 Need help with..." |
| 📋 | Status update | "📋 50% complete" |
| 🔍 | Investigating | "🔍 Debugging timeout" |
| ⚠️ | Warning | "⚠️ Breaking change coming" |

<!-- MATRIX:END -->
