#!/usr/bin/python
# Copyright (c) George Bolo <gbolo@linuxctl.com>
# SPDX-License-Identifier: MIT


import json

from ansible.module_utils.basic import AnsibleModule, env_fallback

from ..module_utils.nomad import NomadAPI
from ..module_utils.utils import del_none


def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = {
        "url": {"type": "str", "required": True, "fallback": (env_fallback, ["NOMAD_ADDR"])},
        "validate_certs": {"type": "bool", "default": True},
        "connection_timeout": {"type": "int", "default": 10},
        "management_token": {
            "type": "str",
            "required": True,
            "no_log": True,
            "fallback": (env_fallback, ["NOMAD_TOKEN"]),
        },
        "namespace": {"type": "str", "default": "default"},
        "hcl_spec": {"type": "str", "required": True},
    }

    # seed the final result dict in the object. Default nothing changed ;)
    result = {
        "changed": False,
    }

    # the AnsibleModule object
    module = AnsibleModule(argument_spec=module_args, supports_check_mode=False)

    # the NomadAPI can init itself via the module args
    nomad = NomadAPI(module)

    result["parsed"] = nomad.parse_job(
        json.dumps(
            del_none(
                {
                    "namespace": module.params.get("namespace"),
                    "JobHCL": module.params.get("hcl_spec"),
                }
            )
        )
    )

    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
