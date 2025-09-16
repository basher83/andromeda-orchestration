# Infisical Ansible Patterns

Here are real‑world Ansible patterns showing how to pull secrets from Infisical via the lookup plugin and inject them into modules, environments, and templates using **Universal Auth** or **OIDC**.[1][2]

### Setup

Install the Infisical Ansible collection and Python SDK, then choose an authentication mode (Universal Auth or OIDC); the OIDC flow requires infisicalsdk version 1.0.10 or newer.[3][1]

- Collection install: ansible-galaxy collection install 'infisical.vault:>=1.1.3'; SDK: pip install infisicalsdk.[1][3]
- Universal Auth uses a client ID/secret; OIDC uses identity_id + JWT; both can be provided via environment variables for non-interactive runs.[4][1]

Example bootstrap task:

```yaml
- name: Prepare controller
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Install Infisical collection
      ansible.builtin.command: ansible-galaxy collection install 'infisical.vault:>=1.1.3'

    - name: Ensure infisicalsdk is present
      ansible.builtin.pip:
        name: infisicalsdk
```

### Auth via environment

Set these variables in shell, CI, or AWX credentials so playbooks can omit auth parameters in lookups.[5][1]

- Universal Auth: INFISICAL_AUTH_METHOD=universal-auth, INFISICAL_UNIVERSAL_AUTH_CLIENT_ID, INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET.[4][1]
- OIDC: INFISICAL_AUTH_METHOD=oidc-auth, INFISICAL_IDENTITY_ID, INFISICAL_JWT (requires infisicalsdk ≥ 1.0.10).[1][3]

### Pattern 1: Load all secrets as a dict

Pull a scoped set of secrets once and reuse as vars and environment for tasks/modules; this minimizes repeated API calls and centralizes access control by project, env_slug, and path.[6][1]

```yaml
- name: Retrieve app secrets once and use everywhere
  hosts: app_hosts
  become: false
  vars:
    infisical_project_id: "proj_xxx"
    infisical_env_slug: "prod"
    infisical_path: "/backend"
    infisical_url: "https://app.infisical.com"
  pre_tasks:
    - name: Pull secrets as a dict from Infisical
      ansible.builtin.set_fact:
        secrets: "{{ lookup('infisical.vault.read_secrets',
          as_dict=True,
          project_id=infisical_project_id,
          env_slug=infisical_env_slug,
          path=infisical_path,
          url=infisical_url) }}"
      no_log: true
  tasks:
    - name: Render config with secrets
      ansible.builtin.template:
        src: files/app.env.j2
        dest: /etc/myapp/app.env
        mode: "0600"

    - name: Start service with env from Infisical
      community.docker.docker_container:
        name: myapp
        image: ghcr.io/org/myapp:latest
        env: "{{ secrets }}"
        restart_policy: unless-stopped
      no_log: true
```

Notes

- lookup('infisical.vault.read_secrets', as_dict=True, ...) returns a dict, so secrets.MY_KEY is directly addressable in templates and env.[2][1]
- Scope by project_id, env_slug, and path to align with Infisical access control boundaries.[6][1]

Example template snippet:

```text
DB_HOST={{ secrets.DB_HOST }}
DB_USER={{ secrets.DB_USER }}
DB_PASS={{ secrets.DB_PASS }}
```

### Pattern 2: Fetch only what is needed

For minimal exposure, pull individual secrets and pass them to modules or templates.[1][2]

```yaml
- name: Minimal secret retrieval
  hosts: db_hosts
  gather_facts: false
  vars:
    pid: "proj_xxx"
    env: "prod"
    url: "https://app.infisical.com"
  tasks:
    - name: Read a single secret by name
      ansible.builtin.set_fact:
        db_password: >-
          {{ lookup('infisical.vault.read_secrets',
                    project_id=pid,
                    env_slug=env,
                    secret_name='DB_PASSWORD',
                    path='/db',
                    url=url).value }}
      no_log: true

    - name: Ensure database user with secret password
      community.postgresql.postgresql_user:
        name: appuser
        password: "{{ db_password }}"
        db: appdb
        state: present
      no_log: true
```

### Pattern 3: Use Universal Auth explicitly in playbooks

If environment variables are not preferred, pass Universal Auth parameters directly to the lookup.[4][1]

```yaml
- name: Universal Auth inline usage
  hosts: api_hosts
  vars:
    client_id: "{{ lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID') }}"
    client_secret: "{{ lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET') }}"
  tasks:
    - name: Pull secrets with explicit UA
      ansible.builtin.set_fact:
        secrets: "{{ lookup('infisical.vault.read_secrets',
          auth_method='universal-auth',
          universal_auth_client_id=client_id,
          universal_auth_client_secret=client_secret,
          project_id='proj_xxx',
          env_slug='staging',
          path='/api') }}"
      no_log: true
```

### Pattern 4: OIDC example (machine identity)

Use identity_id and a signed JWT from an OIDC provider to authenticate, which is ideal in CI environments and conforms to Infisical’s identity model.[7][1]

```yaml
- name: OIDC-based lookup
  hosts: ci_runner
  gather_facts: false
  tasks:
    - name: Read secrets via OIDC
      ansible.builtin.set_fact:
        secrets: "{{ lookup('infisical.vault.read_secrets',
          auth_method='oidc-auth',
          identity_id=lookup('env','INFISICAL_IDENTITY_ID'),
          jwt=lookup('env','INFISICAL_JWT'),
          project_id='proj_xxx',
          env_slug='dev',
          path='/build') }}"
      no_log: true
```

### Pattern 5: Group vars for team reuse

Centralize lookups in group_vars/all.yml so roles and playbooks just consume normalized variables without worrying about auth details.[1][2]

`group_vars/all.yml`:

```yaml
infisical_project_id: proj_xxx
infisical_env_slug: prod
infisical_path_backend: /backend
infisical_url: https://app.infisical.com

backend_secrets: >-
  {{ lookup('infisical.vault.read_secrets',
            as_dict=True,
            project_id=infisical_project_id,
            env_slug=infisical_env_slug,
            path=infisical_path_backend,
            url=infisical_url) }}
```

Usage in a role:

```yaml
- name: Launch backend
  community.docker.docker_container:
    name: backend
    image: ghcr.io/org/backend:stable
    env: "{{ backend_secrets }}"
  no_log: true
```

### Troubleshooting macOS "\_\_NSCFConstantString initialize"

On macOS controllers, Ansible can crash with "+[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called," which is an Objective‑C fork safety issue in Apple's runtime.[8][9]

Only set this if not already managed by mise.

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

If your environment already sets this via .mise.local.toml, do not modify that file.

- Workaround: export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES for the session or add it to the shell profile; this is a common fix used by Ansible users on macOS.[10][8]
- The message is seen across languages (Ruby/Python) on macOS; setting the variable avoids the crash during forked operations typical in Ansible.[11][9]

### References worth noting

- The read_secrets lookup supports returning an array of key/value or a dict via as_dict, and can target a specific secret_name.[1][2]

- Universal Auth is designed for non‑interactive environments and exchanges client ID/secret for a short‑lived access token to query Infisical.[12][4]

[1](https://infisical.com/docs/integrations/platforms/ansible)
[2](https://galaxy.ansible.com/ui/repo/published/infisical/vault/content/lookup/read_secrets/)
[3](https://galaxy.ansible.com/ui/repo/published/infisical/vault/content/)
[4](https://infisical.com/docs/documentation/platform/identities/universal-auth)
[5](https://infisical.com/docs/cli/commands/login)
[6](https://infisical.com/docs/documentation/platform/secrets-mgmt/concepts/access-control)
[7](https://infisical.com/docs/api-reference/overview/authentication)
[8](https://www.ansiblepilot.com/articles/macos-fork-error-ansible-troubleshooting/)
[9](https://github.com/ansible/ansible/issues/76631)
[10](https://forum.ansible.com/t/url-lookup-fails-on-my-apple-m1/34863)
[11](https://www.jdeen.com/blog/fix-ruby-macos-nscfconstantstring-initialize-error)
[12](https://infisical.com/docs/api-reference/endpoints/universal-auth/login)
[13](https://www.everythingdevops.dev/blog/managing-ansible-secrets-with-infisical)
[14](https://infisical.com/blog/infisical-update-december-2023)
[15](https://forum.ansible.com/t/dynamically-give-ansible-a-private-key-from-an-infisical-vault-terraform/40682)
[16](https://galaxy.ansible.com/ui/repo/published/infisical/vault/docs/)
[17](https://github.com/Infisical/ansible-collection/issues)
[18](https://stackoverflow.com/questions/52671926/rails-may-have-been-in-progress-in-another-thread-when-fork-was-called)
[19](https://infisical.com/blog/introducing-machine-identities)
[20](https://github.com/Infisical/infisical/issues/2044)
