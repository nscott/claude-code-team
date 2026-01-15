# Example: How an Agent Should Use Collaboration

This document shows concrete examples of how Claude agents should integrate Matrix collaboration into their workflow.

## Example 1: Backend Agent Starting a Task

```markdown
**User Request:** "Add inventory search endpoint with filtering"

**Agent Response:**

I'll add an inventory search endpoint with filtering capabilities. Let me first check for any recent related work in the collaboration channel.

[Agent runs: `python3 scripts/matrix_collab.py sync`]

I see there are no blocking issues. I'll proceed with implementing the search endpoint and post an update when complete.

[Agent implements the feature...]

[Agent runs: `python3 scripts/matrix_collab.py post "🚧 Backend: Working on inventory search endpoint with filtering in backend/src/inventory/inventory.controller.ts"`]

[After completion...]

[Agent runs: `python3 scripts/matrix_collab.py post "✅ Backend: Completed inventory search endpoint. Added filters for: lot number, expiration date, vaccine type. See backend/src/inventory/inventory.controller.ts:145"`]

The search endpoint is now complete. I've posted an update to the collaboration channel so other agents and team members are aware.
```

## Example 2: Frontend Agent Detecting a Blocker

```markdown
**User Request:** "Update the inventory page to use the new search endpoint"

**Agent Response:**

Let me check the collaboration channel for any updates about the inventory API.

[Agent runs: `MATRIX_USER=felix python3 scripts/matrix_collab.py read --limit 30`]

I can see from the messages that a new search endpoint was recently completed. Let me verify it exists and update the frontend accordingly.

[Agent checks the backend code and API...]

I notice the endpoint is missing TypeScript types in the frontend API client. Let me post a question.

[Agent runs: `MATRIX_USER=felix python3 scripts/matrix_collab.py post "❓ Frontend: The new inventory search endpoint needs OpenAPI types generated. Should I run 'npm run generate:openapi-fe' or is that pending?"`]

I'll wait for clarification before proceeding to ensure I'm using the correct types.
```

## Example 3: Agent Checking for Updates Proactively

```markdown
**Agent Internal Check at Session Start:**

[Agent runs: `python3 scripts/matrix_collab.py sync`]

**Messages received:**
```
--- 2 new message(s) ---
[2026-01-15 10:30:15] @admin:claude.local: Please hold off on any database migrations until I finish the backup
[2026-01-15 10:35:22] @felix:claude.local: 🔍 Code review needed: PR #456 changes the vaccine validation logic
```

The agent should acknowledge these messages in its decision-making:
- Avoid database schema changes
- Consider reviewing PR #456 if relevant to current work
```

## Example 4: Coordination Between Multiple Agents

```markdown
**Backend Agent:**
[Runs: `python3 scripts/matrix_collab.py post "⚠️ Backend: Breaking change - renamed /api/inventory/list to /api/inventory/search. Updated OpenAPI spec."`]

**Frontend Agent (later):**
[Runs: `python3 scripts/matrix_collab.py sync`]

Sees breaking change message, adjusts work accordingly:
[Runs: `MATRIX_USER=felix python3 scripts/matrix_collab.py post "✅ Frontend: Updated to use /api/inventory/search endpoint, regenerated API client"`]
```

## Example 5: Agent Requesting Code Review

```markdown
**Agent completing major refactor:**

[Agent runs: `python3 scripts/matrix_collab.py post "🔍 Backend: Refactored inventory service to use repository pattern. Significant changes in backend/src/inventory/. Review requested before merging to main."`]

This alerts other agents and human reviewers that important changes need review.
```

## Integration Pattern for Agent Prompts

When defining custom agents, include this in their system prompt:

```markdown
## Collaboration Protocol

You are [Agent Name] working in the Docket IIS codebase.

**At the start of each session:**
1. Run `python3 scripts/matrix_collab.py sync` to check for new messages
2. Read and acknowledge any relevant updates or blockers
3. Set your Matrix credentials: `export MATRIX_USER=[your_username]`

**During work:**
1. Post updates when starting significant tasks (🚧)
2. Post completions when finishing tasks (✅)
3. Post questions when blocked (❓)
4. Post warnings for breaking changes (⚠️)

**Before ending session:**
1. Post a summary of completed work
2. Check for any follow-up questions: `python3 scripts/matrix_collab.py sync`

**Your Matrix credentials:**
- Username: [agent_username]
- Password: [agent_password]
```

## CLI Integration

Agents can also integrate the Matrix client into bash scripts:

```bash
#!/bin/bash
# Example: Automated build script with Matrix notifications

export MATRIX_USER=lysander

python3 scripts/matrix_collab.py post "🚧 Starting automated build..."

if npm run build; then
    python3 scripts/matrix_collab.py post "✅ Build completed successfully"
else
    python3 scripts/matrix_collab.py post "❌ Build failed! Check logs for details"
    exit 1
fi
```

## Monitoring Messages in Real-Time

For long-running tasks, agents can periodically check for messages:

```python
import time
from scripts.matrix_collab import MatrixClient

client = MatrixClient(username="lysander", password="lysander")

# Check every 5 minutes during long task
for i in range(task_steps):
    # Do work...
    do_task_step(i)
    
    # Check for messages every 5 steps
    if i % 5 == 0:
        new_messages = client.sync_messages()
        if new_messages:
            print(f"Received {len(new_messages)} new messages")
            # Check for abort commands, priority changes, etc.
            for msg in new_messages:
                if "abort" in msg['body'].lower():
                    print("Abort requested, stopping task")
                    client.post_message("⚠️ Task aborted per request")
                    exit(0)
```
