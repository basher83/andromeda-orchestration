# References and Learning Resources

Articles, tutorials, documentation, best practices, and educational content relevant to our technology stack.

## To Review

### Example Entry

- **URL**: <https://example.com/article>
- **Type**: Article / Tutorial / Documentation / Video
- **Use Case**: Key concepts or techniques covered
- **Date Added**: YYYY-MM-DD
- **Status**: To Review
- **Notes**: Why this is relevant to our project

---

<!-- Add new entries below this line -->

### Consul and Nomad Integration

- **URL**: <https://developer.hashicorp.com/consul/docs/nomad>
- **Type**: Official documentation
- **Use Case**: Complete guide for integrating Consul service mesh with Nomad for service discovery, health checking, and Connect sidecar proxies - essential reference for our Consul/Nomad infrastructure
- **Date Added**: 2025-01-05
- **Status**: To Review
- **Notes**: We're already running both Consul and Nomad but may not be using all integration features. Key topics: service discovery, health checks, Connect for mTLS, and native integration patterns. Should review against our current setup to identify gaps

### Consul Service Registration in Nomad

- **URL**: <https://developer.hashicorp.com/consul/docs/register/service/nomad>
- **Type**: Official documentation
- **Use Case**: Specific requirements and patterns for automatic service registration from Nomad jobs into Consul - critical for our service discovery setup
- **Date Added**: 2025-01-05
- **Status**: To Review
- **Notes**: This is the how-to for the integration mentioned above. Covers service stanza configuration, health checks, tags, and meta fields. Should audit our existing Nomad jobs (especially Traefik) to ensure they're properly registering with Consul

### Consul Load Balancing Integrations

- **URL**: <https://developer.hashicorp.com/consul/docs/connect/load-balancing>
- **Type**: Official documentation
- **Use Case**: Official guides for integrating Consul with load balancers - covers HAProxy, NGINX, F5, and Envoy but notably missing Traefik
- **Date Added**: 2025-01-05
- **Status**: To Review
- **Notes**: **GAP IDENTIFIED**: No official Traefik integration guide despite Traefik being a popular choice in containerized environments. We're using Traefik - might need to rely on community patterns or create our own integration approach. Check if Traefik's native Consul catalog provider is sufficient or if we need Consul Template

## Reviewing

<!-- Move entries here when actively reading/studying -->

## Applied

<!-- Move entries here when knowledge has been applied to the project -->

## Archived

<!-- Move entries here for reference but no longer immediately relevant -->
