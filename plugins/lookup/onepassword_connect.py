#!/usr/bin/python

DOCUMENTATION = r"""
lookup: onepassword_connect
author: Custom implementation
version_added: "1.0.0"
short_description: Retrieve field values from 1Password Connect
description:
  - This lookup retrieves field values from 1Password Connect server
  - Requires OP_CONNECT_HOST and OP_CONNECT_TOKEN environment variables
options:
  _terms:
    description: Item title to retrieve
    required: true
  field:
    description: Field label to retrieve from the item
    required: true
  vault:
    description: Vault ID where the item is stored
    required: false
requirements:
  - requests
"""

EXAMPLES = r"""
- name: Retrieve password from 1Password Connect
  debug:
    msg: "{{ lookup('onepassword_connect', 'My Item', field='password') }}"

- name: Retrieve with specific vault
  debug:
    msg: "{{ lookup('onepassword_connect', 'My Item', field='password', vault='vault-id') }}"
"""

import json
import os

from ansible.errors import AnsibleError
from ansible.module_utils.urls import open_url
from ansible.plugins.lookup import LookupBase


class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):
        if not terms:
            raise AnsibleError("Item title is required")

        item_title = terms[0]
        field_label = kwargs.get("field")
        vault_id = kwargs.get("vault", os.environ.get("OP_VAULT_ID"))

        if not field_label:
            raise AnsibleError("field parameter is required")

        # Get Connect server details from environment
        connect_host = os.environ.get("OP_CONNECT_HOST")
        connect_token = os.environ.get("OP_CONNECT_TOKEN")

        if not connect_host or not connect_token:
            raise AnsibleError("OP_CONNECT_HOST and OP_CONNECT_TOKEN environment variables are required")

        headers = {"Authorization": f"Bearer {connect_token}", "Content-Type": "application/json"}

        try:
            # Get list of items
            if vault_id:
                items_url = f"{connect_host}/v1/vaults/{vault_id}/items"
            else:
                # Get all vaults first
                vaults_url = f"{connect_host}/v1/vaults"
                vaults_response = open_url(vaults_url, headers=headers, validate_certs=False)
                vaults = json.loads(vaults_response.read())

                if not vaults:
                    raise AnsibleError("No vaults found")

                vault_id = vaults[0]["id"]
                items_url = f"{connect_host}/v1/vaults/{vault_id}/items"

            # Get items
            items_response = open_url(items_url, headers=headers, validate_certs=False)
            items = json.loads(items_response.read())

            # Find item by title
            item = None
            for i in items:
                if i.get("title") == item_title:
                    item = i
                    break

            if not item:
                raise AnsibleError(f"Item '{item_title}' not found in vault")

            # Get full item details
            item_url = f"{connect_host}/v1/vaults/{vault_id}/items/{item['id']}"
            item_response = open_url(item_url, headers=headers, validate_certs=False)
            item_details = json.loads(item_response.read())

            # Find field
            for field in item_details.get("fields", []):
                if field.get("label") == field_label:
                    return [field.get("value")]

            raise AnsibleError(f"Field '{field_label}' not found in item '{item_title}'")

        except Exception as e:
            raise AnsibleError(f"Failed to retrieve from 1Password Connect: {str(e)}") from e
