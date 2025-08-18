#!/usr/bin/python
# Copyright (c) George Bolo <gbolo@linuxctl.com>
# SPDX-License-Identifier: MIT


import json

from ansible.module_utils.basic import AnsibleModule, env_fallback

from ..module_utils.nomad import NomadAPI
from ..module_utils.utils import is_subset


def run_module():
    # define available arguments/parameters a user can pass to the module
    preemption_config_spec = {
        "system_scheduler_enabled": {
            "type": "bool",
            "aliases": ["SystemSchedulerEnabled"],
            "default": True,
        },
        "sys_batch_scheduler_enabled": {
            "type": "bool",
            "aliases": ["SysBatchSchedulerEnabled"],
            "default": False,
        },
        "batch_scheduler_enabled": {
            "type": "bool",
            "aliases": ["BatchSchedulerEnabled"],
            "default": False,
        },
        "service_scheduler_enabled": {
            "type": "bool",
            "aliases": ["ServiceSchedulerEnabled"],
            "default": False,
        },
    }
    module_args = {
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
        "scheduler_algorithm": {
            "type": "str",
            "choices": ["binpack", "spread"],
            "default": "binpack",
        },
        "memory_oversubscription_enabled": {"type": "bool", "default": False},
        "reject_job_registration": {"type": "bool", "default": False},
        "pause_eval_broker": {"type": "bool", "default": False},
        "preemption_config": {
            "type": dict,
            "aliases": ["PreemptionConfig"],
            "options": preemption_config_spec,
        },
    }

    # seed the final result dict in the object. Default nothing changed ;)
    result = {
        "changed": False,
    }

    # the AnsibleModule object
    module = AnsibleModule(argument_spec=module_args, supports_check_mode=False)

    # the NomadAPI can init itself via the module args
    nomad = NomadAPI(module)

    existing_config = nomad.get_scheduler_config().get("SchedulerConfig")
    desired_config = {
        "SchedulerAlgorithm": module.params.get("scheduler_algorithm"),
        "MemoryOversubscriptionEnabled": module.params.get("memory_oversubscription_enabled"),
        "RejectJobRegistration": module.params.get("reject_job_registration"),
        "PauseEvalBroker": module.params.get("pause_eval_broker"),
        "PreemptionConfig": {
            # repeat the defaults here since they do not seem to be respected from preemption_config_spec
            "SystemSchedulerEnabled": module.params.get("preemption_config").get("system_scheduler_enabled", True),
            "SysBatchSchedulerEnabled": module.params.get("preemption_config").get(
                "sys_batch_scheduler_enabled", False
            ),
            "BatchSchedulerEnabled": module.params.get("preemption_config").get("batch_scheduler_enabled", False),
            "ServiceSchedulerEnabled": module.params.get("preemption_config").get("service_scheduler_enabled", False),
        },
    }
    if not is_subset(desired_config, existing_config):
        nomad.update_scheduler_config(json.dumps(desired_config))
        result["changed"] = True

    result["scheduler_config"] = desired_config
    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
