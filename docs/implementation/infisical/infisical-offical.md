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
    version: ">=1.1.3"
```

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

## Using this collection

You can either call modules by their Fully Qualified Collection Name (FQCN), such as infisical.vault.read_secrets, or you can call modules by their short name if you list the infisical.vault collection in the playbook’s collections keyword:

```yaml
vars:
  read_all_secrets_within_scope: "{{ lookup('infisical.vault.read_secrets', universal_auth_client_id='<>', universal_auth_client_secret='<>', project_id='<>', path='/', env_slug='dev', url='https://app.infisical.com') }}"

  # [{ "key": "HOST", "value": "google.com" }, { "key": "SMTP", "value": "gmail.smtp.edu" }]

  read_all_secrets_as_dict: "{{ lookup('infisical.vault.read_secrets', as_dict=True, universal_auth_client_id='<>', universal_auth_client_secret='<>', project_id='<>', path='/', env_slug='dev', url='https://app.infisical.com') }}"

  # { "SECRET_KEY_1": "secret-value-1", "SECRET_KEY_2": "secret-value-2" } -> Can be accessed as secrets.SECRET_KEY_1

  read_secret_by_name_within_scope: "{{ lookup('infisical.vault.read_secrets', universal_auth_client_id='<>', universal_auth_client_secret='<>', project_id='<>', path='/', env_slug='dev', secret_name='HOST', url='https://app.infisical.com') }}"
# { "key": "HOST", "value": "google.com" }
```

Using Universal Auth for authentication is the most straight-forward way to get started with using the Ansible collection.
To use Universal Auth, you need to provide the Client ID and Client Secret of your Infisical Machine Identity.

```yaml
lookup('infisical.vault.read_secrets', auth_method="universal-auth", universal_auth_client_id='<client-id>', universal_auth_client_secret='<client-secret>' ...rest)
```

You can also provide the auth_method, universal_auth_client_id, and universal_auth_client_secret parameters through environment variables:

```text
Parameter Name | Environment Variable Name
auth_method | INFISICAL_AUTH_METHOD
universal_auth_client_id | INFISICAL_UNIVERSAL_AUTH_CLIENT_ID
universal_auth_client_secret | INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET
```
