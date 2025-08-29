service {
  id = "vault-{{ inventory_hostname }}"
  name = "vault"
  port = 8200
  address = "{{ ansible_default_ipv4.address }}"
  tags = [
    "vault-cluster",
    "{{ vault_role }}",
    "{{ 'transit' if vault_role == 'master' else 'raft' }}"
  ]
  check {
    id = "vault-health"
    name = "Vault Health Check"
    http = "http://{{ ansible_default_ipv4.address }}:8200/v1/sys/health?standbyok=true&perfstandbyok=true"
    interval = "10s"
    timeout = "5s"
  }
}
