# haproxylb

A lightweight Docker image that generates an HAProxy load balancer configuration from environment variables. Based on `haproxy:lts`, no extra runtime dependencies — just a shell script.

## Quick start

```yaml
services:
  haproxy:
    image: dottgonzo/haproxylb:stable
    network_mode: host
    restart: always
    environment:
      BACKENDS: "10.0.0.1,10.0.0.2,10.0.0.3"
      SERVICES: "80:30080:http,6443:6443:tcp"
```

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `BACKENDS` | yes | Comma-separated list of backend IPs (e.g. `10.0.0.1,10.0.0.2`) |
| `SERVICES` | yes | Comma-separated list of service definitions (see format below) |
| `HAPROXY_CONFIG_PATH` | no | Override config path (default: `/usr/local/etc/haproxy/haproxy.cfg`) |

### SERVICES format

Each service entry follows the pattern:

```
<listen_port>:<target_port>:<mode>[:<options>]
```

| Field | Description |
|---|---|
| `listen_port` | Port HAProxy listens on |
| `target_port` | Port on the backend servers |
| `mode` | `http` or `tcp` |
| `options` | Optional. `proxy_protocol` to enable PROXY protocol v2 (only for `http` mode) |

Multiple options can be separated by `;`.

### Example

```
BACKENDS=192.168.1.10,192.168.1.11,192.168.1.12
SERVICES=80:30080:http:proxy_protocol,6443:6443:tcp
```

This generates:

- **Port 80** — HTTP load balancer forwarding to port 30080 on all backends, with PROXY protocol v2
- **Port 6443** — TCP load balancer forwarding to port 6443 on all backends, with TCP health checks

## Build

```bash
docker build -t haproxylb .
```

Multi-arch build and push:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t dottgonzo/haproxylb:stable . --push
```

## Generated configuration

The container generates an HAProxy config at startup with:

- **Global**: `tune.ssl.default-dh-param 2048`
- **Defaults**: HTTP mode, 5s connect / 50s client & server timeouts
- **Frontend** per service: binds `listen_port`, sets mode, optional `tcplog` for TCP
- **Backend** per service: `roundrobin` balancing, health checks, optional `send-proxy-v2`

See `haproxy.example.cfg` for a full example of the generated output.

## License

Apache-2.0
