#!/usr/bin/python
# Copyright (c) George Bolo <gbolo@linuxctl.com>
# SPDX-License-Identifier: MIT


import json

from ansible.module_utils.basic import AnsibleModule, env_fallback

from ..module_utils.nomad import NomadAPI
from ..module_utils.utils import del_none, is_subset


def run_module():
    # define available arguments/parameters a user can pass to the module
    job_acl_spec = {
        "namespace": {"type": "str", "aliases": ["Namespace"], "default": ""},
        "job_id": {"type": "str", "aliases": ["JobID"], "default": ""},
        "group": {"type": "str", "aliases": ["Group"], "default": ""},
        "task": {"type": "str", "aliases": ["Task"], "default": ""},
    }
    module_args = {
        "state": {
            "type": "str",
            "choices": ["present", "absent"],
            "default": "present",
        },
        "url": {
            "type": "str",
            "required": True,
            "fallback": (env_fallback, ["NOMAD_ADDR"]),
        },
        "validate_certs": {"type": "bool", "default": True},
        "connection_timeout": {"type": "int", "default": 10},
        "management_token": {
            "type": "str",
            "required": True,
            "no_log": True,
            "fallback": (env_fallback, ["NOMAD_TOKEN"]),
        },
        "name": {"type": "str", "required": True},
        "description": {"type": "str"},
        "rules": {"type": "str"},
        "job_acl": {"type": "dict", "default": {}, "options": job_acl_spec},
    }

    # seed the final result dict in the object. Default nothing changed ;)
    result = {
        "changed": False,
    }

    # the AnsibleModule object
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=False,
        required_if=[("state", "present", ("rules",))],
    )

    # the NomadAPI can init itself via the module args
    nomad = NomadAPI(module)

    policy_name = module.params.get("name")
    existing_policy = nomad.get_acl_policy(policy_name)
    desired_policy_body = del_none(
        {
            "Name": policy_name,
            "Description": module.params.get("description"),
            "Rules": module.params.get("rules"),
            "JobACL": {
                "Namespace": module.params.get("job_acl").get("namespace"),
                "JobID": module.params.get("job_acl").get("job_id"),
                "Group": module.params.get("job_acl").get("group"),
                "Task": module.params.get("job_acl").get("task"),
            },
        }
    )

    if module.params.get("state") == "absent" and existing_policy is not None:
        nomad.delete_acl_policy(policy_name)
        result["changed"] = True

    if module.params.get("state") == "present":
        if existing_policy is None:
            nomad.create_or_update_acl_policy(policy_name, json.dumps(desired_policy_body))
            result["policy"] = nomad.get_acl_policy(policy_name)
            result["changed"] = True
        else:
            # compare if we need to change anything about the policy
            if not is_subset(desired_policy_body, existing_policy):
                nomad.create_or_update_acl_policy(policy_name, json.dumps(desired_policy_body))
                result["policy"] = nomad.get_acl_policy(policy_name)
                result["changed"] = True

    # post final results
    if result.get("policy") is None and existing_policy is not None:
        result["policy"] = existing_policy

    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
