# Infisical Official Documentation [REFERENCE](https://infisical.com/docs/integrations/platforms/ansible)

## Ansible version compatibility

Tested with the Ansible Core >= 2.12.0 versions, and the current development version of Ansible. Ansible Core versions prior to 2.12.0 have not been tested.
​

## Python version compatibility

This collection depends on the Infisical SDK for Python.
Requires Python 3.7 or greater.
​

## Collection Management

### Required Collections (requirements.yml)

```yaml
collections:
  - name: infisical.vault
    version: ">=1.1.3,<2.0"
```

**Note**: The version range `>=1.1.3,<2.0` ensures compatibility with tested versions from 1.1.3 (minimum required) up to but not including 2.0 (to prevent accidental breaking upgrades from major version changes).

### Installation

```bash
ansible-galaxy collection install -r requirements.yml
```

## Installing this collection

You can install the Infisical collection with the Ansible Galaxy CLI:

```bash
ansible-galaxy collection install infisical.vault
```

The python module dependencies are not installed by ansible-galaxy. They can be manually installed using pip:

```bash
pip install infisicalsdk
```

## Security Best Practices

**CRITICAL SECURITY NOTES**:
- **Never hardcode secrets** directly in playbooks or inventory files
- **Always prefer environment variables** for authentication credentials instead of inline values
- **Use `no_log: true`** on any Ansible tasks that handle tokens, secrets, or sensitive data
- **Store credentials securely** using environment variables or secure credential management systems
- **Review playbooks** before committing to ensure no secrets are exposed in version control

## Using this collection

You can either call modules by their Fully Qualified Collection Name (FQCN), such as infisical.vault.read_secrets, or you can call modules by their short name if you list the infisical.vault collection in the playbook’s collections keyword:

```yaml
vars:
  # SECURITY: Use environment variables instead of hardcoded credentials
  read_all_secrets_within_scope: "{{ lookup('infisical.vault.read_secrets', project_id='<>', path='/', env_slug='dev', url='https://app.infisical.com') }}"

  # [{ "key": "HOST", "value": "google.com" }, { "key": "SMTP", "value": "gmail.smtp.edu" }]

  read_all_secrets_as_dict: "{{ lookup('infisical.vault.read_secrets', as_dict=True, project_id='<>', path='/', env_slug='dev', url='https://app.infisical.com') }}"

  # { "SECRET_KEY_1": "secret-value-1", "SECRET_KEY_2": "secret-value-2" } -> Can be accessed as secrets.SECRET_KEY_1

  read_secret_by_name_within_scope: "{{ lookup('infisical.vault.read_secrets', project_id='<>', path='/', env_slug='dev', secret_name='HOST', url='https://app.infisical.com') }}"
# { "key": "HOST", "value": "google.com" }

tasks:
  - name: Example task using secrets
    debug:
      msg: "Secret retrieved successfully"
    vars:
      my_secret: "{{ lookup('infisical.vault.read_secrets', project_id='<project-id>', path='/', env_slug='dev', secret_name='API_KEY') }}"
    no_log: true  # SECURITY: Prevent secrets from appearing in logs
```

**Security Note**: The examples above use environment variables for authentication (`INFISICAL_UNIVERSAL_AUTH_CLIENT_ID` and `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET`). Always use `no_log: true` for tasks handling sensitive data to prevent secrets from appearing in Ansible logs.

Using Universal Auth for authentication is the most straight-forward way to get started with using the Ansible collection.
To use Universal Auth, you need to provide the Client ID and Client Secret of your Infisical Machine Identity.

```yaml
# SECURITY WARNING: Never hardcode credentials like this in production
lookup('infisical.vault.read_secrets', auth_method="universal-auth", universal_auth_client_id='<client-id>', universal_auth_client_secret='<client-secret>' ...rest)

# RECOMMENDED: Use environment variables instead (credentials automatically loaded)
lookup('infisical.vault.read_secrets', auth_method="universal-auth", project_id='<project-id>', path='/', env_slug='dev')
```

**RECOMMENDED APPROACH**: Provide the auth_method, universal_auth_client_id, and universal_auth_client_secret parameters through environment variables:

| Parameter Name | Environment Variable Name |
|---|---|
| auth_method | INFISICAL_AUTH_METHOD |
| universal_auth_client_id | INFISICAL_UNIVERSAL_AUTH_CLIENT_ID |
| universal_auth_client_secret | INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET |

**Security Best Practices for Universal Auth**:
- **Always use environment variables** for Client ID and Client Secret
- **Never commit credentials** to version control
- **Use `no_log: true`** on tasks that retrieve or handle secrets
- **Set restrictive permissions** on environment files containing credentials
- **Rotate credentials regularly** following your organization's security policy

```yaml
# Example secure task with proper logging controls
- name: Retrieve application configuration
  set_fact:
    app_config: "{{ lookup('infisical.vault.read_secrets', as_dict=True, project_id='proj123', path='/app', env_slug='prod') }}"
  no_log: true  # Prevents secrets from appearing in logs
```
