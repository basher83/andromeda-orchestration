# Tailscale Codespace Configuration

## Install go binary for Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

## Start Tailscale Daemon

```bash
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
```

## Authenticate Tailscale

```bash
sudo tailscale up --accept-routes
```
