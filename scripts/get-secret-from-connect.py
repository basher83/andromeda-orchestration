#!/usr/bin/env python3
"""
Fetch secrets from 1Password Connect
"""

import json
import os
import ssl
import sys
import urllib.request


def get_secret(item_title: str, field_label: str, vault_id: str | None = None) -> str:
    connect_host = os.environ.get("OP_CONNECT_HOST")
    connect_token = os.environ.get("OP_CONNECT_TOKEN")

    if not connect_host or not connect_token:
        print("Error: OP_CONNECT_HOST and OP_CONNECT_TOKEN must be set", file=sys.stderr)
        sys.exit(1)

    headers = {"Authorization": f"Bearer {connect_token}", "Content-Type": "application/json"}

    # Create SSL context that doesn't verify certificates
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    try:
        # If no vault specified, get the first one
        if not vault_id:
            vault_id = os.environ.get("OP_VAULT_ID")
            if not vault_id:
                req = urllib.request.Request(f"{connect_host}/v1/vaults", headers=headers)
                with urllib.request.urlopen(req, context=ctx) as response:
                    vaults = json.loads(response.read())
                    vault_id = vaults[0]["id"]

        # Get items in vault
        req = urllib.request.Request(f"{connect_host}/v1/vaults/{vault_id}/items", headers=headers)
        with urllib.request.urlopen(req, context=ctx) as response:
            items = json.loads(response.read())

        # Find item by title
        item = None
        for i in items:
            if i.get("title") == item_title:
                item = i
                break

        if not item:
            print(f"Error: Item '{item_title}' not found", file=sys.stderr)
            sys.exit(1)

        # Get full item details
        req = urllib.request.Request(f"{connect_host}/v1/vaults/{vault_id}/items/{item['id']}", headers=headers)
        with urllib.request.urlopen(req, context=ctx) as response:
            item_details = json.loads(response.read())

        # Find field
        for field in item_details.get("fields", []):
            if field.get("label") == field_label:
                print(field.get("value"))
                value = field.get("value", "")
                return str(value) if value is not None else ""

        print(f"Error: Field '{field_label}' not found", file=sys.stderr)
        sys.exit(1)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: get-secret-from-connect.py <item_title> <field_label>", file=sys.stderr)
        sys.exit(1)

    get_secret(sys.argv[1], sys.argv[2])
