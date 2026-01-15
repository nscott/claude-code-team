#!/bin/bash
set -e

# Check if homeserver.yaml exists, if not generate it
if [ ! -f /data/homeserver.yaml ]; then
  echo "homeserver.yaml not found, generating config..."
  python -m synapse.app.homeserver \
    --server-name claude.local \
    --config-path /data/homeserver.yaml \
    --generate-config \
    --report-stats=no
  echo "Config generated successfully"

  # Merge overrides into homeserver.yaml
  if [ -f /data/homeserver_overrides.yaml ]; then
    echo "Applying homeserver_overrides.yaml..."
    python3 /data/merge_yaml_config.py /data/homeserver.yaml /data/homeserver_overrides.yaml
    echo "Overrides applied successfully"
  fi

  # Fix log file path in generated log config
  if [ -f /data/claude.local.log.config ]; then
    echo "Fixing log file path in claude.local.log.config..."
    sed -i 's|filename: /homeserver.log|filename: /data/homeserver.log|g' /data/claude.local.log.config
    echo "Log file path fixed"
  fi
fi

# Start Synapse in the background
/start.py &
SYNAPSE_PID=$!

# Wait for Synapse to be ready
echo "Waiting for Synapse to start..."
for i in {1..30}; do
  if curl -fSs http://localhost:8008/health > /dev/null 2>&1; then
    echo "Synapse is ready!"
    break
  fi
  sleep 1
done

# Define users to create (username:password:displayname format)
# Admin details are admin/admin
USERS=(
  "admin:admin:Admin (CTO)"
  "lysander:lysander:Lysander (Backend)"
  "felix:felix:Felix (Code Review)"
)

# Associative array to store user tokens
declare -A USER_TOKENS

# Create all users (always try, handle failures gracefully)
echo "Creating/verifying users..."
for user_entry in "${USERS[@]}"; do
  IFS=':' read -r username password displayname <<< "$user_entry"

  # Determine if this is the admin user
  if [ "$username" = "admin" ]; then
    IS_ADMIN="--admin"
  else
    IS_ADMIN="--no-admin"
  fi

  if register_new_matrix_user \
    -c /data/homeserver.yaml \
    --user "$username" \
    --password "$password" \
    $IS_ADMIN \
    http://localhost:8008 2>/dev/null; then
    echo "User '$username' created successfully"
  else
    echo "User '$username' already exists (skipping)"
  fi

  # Set display name (always try, even for existing users)
  if [ -n "$displayname" ]; then
    # Get and cache the user token
    USER_TOKEN=$(curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"m.login.password\",\"user\":\"$username\",\"password\":\"$password\"}" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$USER_TOKEN" ]; then
      USER_TOKENS[$username]=$USER_TOKEN
      curl -s -X PUT "http://localhost:8008/_matrix/client/r0/profile/@${username}:claude.local/displayname" \
        -H "Authorization: Bearer $USER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"displayname\":\"$displayname\"}" > /dev/null 2>&1
      echo "Display name set to '$displayname' for user '$username'"
    fi
  fi
done

# Get an access token for the admin user
echo "Setting up development_collab room..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
  -H "Content-Type: application/json" \
  -d '{"type":"m.login.password","user":"admin","password":"admin"}' | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
  echo "Failed to get admin access token, skipping room setup"
else
  # Try to create the room (will fail if it already exists with the alias)
  ROOM_RESPONSE=$(curl -s -X POST "http://localhost:8008/_matrix/client/r0/createRoom" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Development Collab",
      "topic": "A place to share development changes",
      "preset": "public_chat",
      "room_alias_name": "development_collab"
    }')

  ROOM_ID=$(echo "$ROOM_RESPONSE" | grep -o '"room_id":"[^"]*"' | cut -d'"' -f4)

  if [ -n "$ROOM_ID" ]; then
    echo "Room 'Development Collab' created successfully!"
    echo "Room ID: $ROOM_ID"
  else
    # Room already exists, get it by alias
    echo "Room already exists, looking up by alias..."
    ROOM_LOOKUP=$(curl -s -X GET "http://localhost:8008/_matrix/client/r0/directory/room/%23development_collab:claude.local" \
      -H "Authorization: Bearer $ADMIN_TOKEN")
    ROOM_ID=$(echo "$ROOM_LOOKUP" | grep -o '"room_id":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$ROOM_ID" ]; then
      echo "Found existing room: $ROOM_ID"
    else
      echo "Failed to find or create room, skipping user invites"
    fi
  fi

  # Invite and join all non-admin users to the room (always try for all users)
  if [ -n "$ROOM_ID" ]; then
    echo "Inviting users to #development_collab:claude.local..."

    for user_entry in "${USERS[@]}"; do
      IFS=':' read -r username password displayname <<< "$user_entry"

      # Skip admin user
      if [ "$username" = "admin" ]; then
        continue
      fi

      USER_ID="@${username}:claude.local"

      # Invite the user (ignore errors if already invited/joined)
      curl -s -X POST "http://localhost:8008/_matrix/client/r0/rooms/${ROOM_ID}/invite" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\":\"$USER_ID\"}" > /dev/null 2>&1

      # Get access token from cache or login if not cached
      USER_TOKEN="${USER_TOKENS[$username]}"

      if [ -z "$USER_TOKEN" ]; then
        # Token not cached, need to login
        sleep 2  # Rate limit protection
        LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8008/_matrix/client/r0/login \
          -H "Content-Type: application/json" \
          -d "{\"type\":\"m.login.password\",\"user\":\"$username\",\"password\":\"$password\"}")

        USER_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

        if [ -n "$USER_TOKEN" ]; then
          USER_TOKENS[$username]=$USER_TOKEN
        else
          echo "Failed to get token for user '$username'"
          echo "Login response: $LOGIN_RESPONSE"
        fi
      fi

      if [ -n "$USER_TOKEN" ]; then
        # Join the room as the user (ignore errors if already joined)
        JOIN_RESPONSE=$(curl -s -X POST "http://localhost:8008/_matrix/client/r0/rooms/${ROOM_ID}/join" \
          -H "Authorization: Bearer $USER_TOKEN" \
          -H "Content-Type: application/json" \
          -d '{}' 2>&1)

        if echo "$JOIN_RESPONSE" | grep -q '"room_id"'; then
          echo "User '$username' joined the room"
        else
          echo "User '$username' already in room (skipping)"
        fi
      fi
    done
  fi
fi

# Wait for Synapse process
wait $SYNAPSE_PID
