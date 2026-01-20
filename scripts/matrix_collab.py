#!/usr/bin/env python3
"""
Matrix Collaboration Helper for Claude Agents
Allows agents to read and post messages to the development collaboration channel.
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class MatrixClient:
    """Simple Matrix client for agent collaboration."""

    def __init__(
        self,
        server: str = "http://localhost:8008",
        username: str = None,
        password: str = None,
        room_alias: str = "#development_collab:claude.local",
    ):
        self.server = server.rstrip("/")
        self.username = username
        self.password = password
        self.room_alias = room_alias
        self._token: Optional[str] = None
        self._room_id: Optional[str] = None

        # Cache directory for sync tokens
        self.cache_dir = Path.home() / ".cache" / "matrix-collab"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.sync_token_file = self.cache_dir / f"sync_token_{username}"

    def _request(
        self, method: str, path: str, data: dict = None, token: str = None
    ) -> dict:
        """Make an HTTP request to the Matrix server."""
        url = f"{self.server}{path}"
        headers = {"Content-Type": "application/json"}

        if token:
            headers["Authorization"] = f"Bearer {token}"

        body = json.dumps(data).encode("utf-8") if data else None

        try:
            req = Request(url, data=body, headers=headers, method=method)
            with urlopen(req) as response:
                return json.loads(response.read().decode("utf-8"))
        except HTTPError as e:
            error_body = e.read().decode("utf-8")
            try:
                error_data = json.loads(error_body)
                raise Exception(f"HTTP {e.code}: {error_data.get('error', error_body)}")
            except json.JSONDecodeError:
                raise Exception(f"HTTP {e.code}: {error_body}")
        except URLError as e:
            raise Exception(f"Connection error: {e.reason}")

    def login(self) -> str:
        """Login and get access token."""
        if self._token:
            return self._token

        response = self._request(
            "POST",
            "/_matrix/client/r0/login",
            {
                "type": "m.login.password",
                "user": self.username,
                "password": self.password,
            },
        )

        self._token = response.get("access_token")
        if not self._token:
            raise Exception("Failed to get access token")

        return self._token

    def get_room_id(self) -> str:
        """Get room ID from room alias."""
        if self._room_id:
            return self._room_id

        token = self.login()

        # URL encode the room alias
        encoded_alias = self.room_alias.replace("#", "%23").replace(":", "%3A")

        response = self._request(
            "GET", f"/_matrix/client/r0/directory/room/{encoded_alias}", token=token
        )

        self._room_id = response.get("room_id")
        if not self._room_id:
            raise Exception(f"Failed to find room {self.room_alias}")

        return self._room_id

    def read_messages(self, limit: int = 10) -> list[dict]:
        """Read recent messages from the room."""
        token = self.login()
        room_id = self.get_room_id()

        response = self._request(
            "GET",
            f"/_matrix/client/r0/rooms/{room_id}/messages?dir=b&limit={limit}",
            token=token,
        )

        messages = []
        for event in reversed(response.get("chunk", [])):
            if event.get("type") == "m.room.message":
                messages.append(
                    {
                        "sender": event.get("sender", "Unknown"),
                        "body": event.get("content", {}).get("body", ""),
                        "timestamp": event.get("origin_server_ts", 0),
                        "time": datetime.fromtimestamp(
                            event.get("origin_server_ts", 0) / 1000
                        ),
                    }
                )

        return messages

    def sync_messages(self) -> list[dict]:
        """Read only new messages since last sync."""
        token = self.login()
        room_id = self.get_room_id()

        # Read previous sync token
        since_param = ""
        if self.sync_token_file.exists():
            prev_token = self.sync_token_file.read_text().strip()
            since_param = f"&since={prev_token}"

        # Perform sync
        response = self._request(
            "GET",
            f'/_matrix/client/r0/sync?timeout=0&filter={{"room":{{"timeline":{{"limit":10}}}}}}{since_param}',
            token=token,
        )

        # Save new sync token
        next_batch = response.get("next_batch")
        if next_batch:
            self.sync_token_file.write_text(next_batch)

        # Extract messages
        rooms = response.get("rooms", {}).get("join", {})
        if room_id not in rooms:
            return []

        timeline = rooms[room_id].get("timeline", {})
        events = timeline.get("events", [])

        messages = []
        for event in events:
            if event.get("type") == "m.room.message":
                messages.append(
                    {
                        "sender": event.get("sender", "Unknown"),
                        "body": event.get("content", {}).get("body", ""),
                        "timestamp": event.get("origin_server_ts", 0),
                        "time": datetime.fromtimestamp(
                            event.get("origin_server_ts", 0) / 1000
                        ),
                    }
                )

        return messages

    def post_message(self, message: str) -> bool:
        """Post a message to the room."""
        token = self.login()
        room_id = self.get_room_id()

        # Generate transaction ID
        import random

        txn_id = f"m{int(datetime.now().timestamp())}{random.randint(1000, 9999)}"

        response = self._request(
            "PUT",
            f"/_matrix/client/r0/rooms/{room_id}/send/m.room.message/{txn_id}",
            {"msgtype": "m.text", "body": message},
            token=token,
        )

        return "event_id" in response

    def poll_messages(self) -> list[dict]:
        """Poll for new messages. Waits for first message, then continues for 5 more seconds."""
        import time

        all_messages = []
        first_message_time = None

        while True:
            messages = self.sync_messages()

            if messages:
                all_messages.extend(messages)

                # Record when first message arrived
                if first_message_time is None:
                    first_message_time = time.time()

            # If we haven't received a first message yet, or we're in the 5-second window
            if first_message_time is None or time.time() - first_message_time < 5:
                time.sleep(1)
            else:
                break

        return all_messages


def format_message(msg: dict) -> str:
    """Format a message for display."""
    time_str = msg["time"].strftime("%Y-%m-%d %H:%M:%S")
    return f"[{time_str}] {msg['sender']}: {msg['body']}"


def main():
    parser = argparse.ArgumentParser(
        description="Matrix Collaboration Helper for Claude Agents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s read                              # Read last 20 messages
  %(prog)s read --limit 50                   # Read last 50 messages
  %(prog)s sync                              # Check for new messages since last sync
  %(prog)s poll                              # Wait for new messages, then poll for 5 more seconds
  %(prog)s post "✅ Completed inventory API" # Post an update

Environment Variables (Required):
  MATRIX_USER         Username for authentication (required)
  MATRIX_PASS         Password for authentication (required)

Environment Variables (Optional):
  MATRIX_SERVER       Matrix server URL (default: http://chat:8008)
  MATRIX_ROOM_ALIAS   Room alias (default: #development_collab:claude.local)
        """,
    )

    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Read command
    read_parser = subparsers.add_parser("read", help="Read recent messages")
    read_parser.add_argument(
        "--limit", type=int, default=20, help="Number of messages to read (default: 20)"
    )

    # Sync command
    subparsers.add_parser("sync", help="Read only new messages since last sync")

    # Poll command
    subparsers.add_parser(
        "poll", help="Wait for new messages, then continue polling for 5 seconds"
    )

    # Post command
    post_parser = subparsers.add_parser("post", help="Post a message")
    post_parser.add_argument("message", help="Message content to post")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    # Get configuration from environment
    username = os.getenv("MATRIX_USER")
    password = os.getenv("MATRIX_PASS")

    if not username or not password:
        print(
            "Error: MATRIX_USER and MATRIX_PASS environment variables must be set",
            file=sys.stderr,
        )
        print(
            "Example: export MATRIX_USER=lysander MATRIX_PASS=lysander", file=sys.stderr
        )
        return 1

    client = MatrixClient(
        server=os.getenv("MATRIX_SERVER", "http://chat:8008"),
        username=username,
        password=password,
        room_alias=os.getenv("MATRIX_ROOM_ALIAS", "#development_collab:claude.local"),
    )

    try:
        if args.command == "read":
            messages = client.read_messages(limit=args.limit)
            if not messages:
                print("No messages found")
            else:
                for msg in messages:
                    print(format_message(msg))

        elif args.command == "sync":
            messages = client.sync_messages()
            if not messages:
                print("No new messages")
            else:
                print(f"--- {len(messages)} new message(s) ---")
                for msg in messages:
                    print(format_message(msg))

        elif args.command == "poll":
            print(
                "Polling for messages... (waiting for first message, then 5 more seconds)"
            )
            messages = client.poll_messages()
            if not messages:
                print("No messages received during polling")
            else:
                print(f"--- {len(messages)} message(s) received ---")
                for msg in messages:
                    print(format_message(msg))

        elif args.command == "post":
            if client.post_message(args.message):
                print("Message sent successfully")
            else:
                print("Error: Failed to send message", file=sys.stderr)
                return 1

        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
