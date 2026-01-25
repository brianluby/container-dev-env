# IDE Extensions (Continue, Cline)

This feature provides preinstalled AI extensions for the containerized IDE and templates their configuration so they can authenticate via environment variables.

Applies to: `main`

## Prerequisites

- Containerized IDE running: [Containerized IDE](containerized-ide.md)
- Secrets set up for any hosted providers you plan to use: [Secrets Management](secrets-management.md)

## Setup

1. Start the IDE (if not already):

```bash
docker compose -f src/docker/docker-compose.ide.yml up -d
```

2. Ensure provider keys are available in the IDE container environment (via secrets injection).

3. Open the Extensions panel and verify Continue and Cline are installed.

## Configuration

- Provider keys should come from environment variables (via secrets injection)
- If you are using MCP servers, regenerate configs after changing `.mcp/config.json`:

```bash
generate-configs.sh
```

## Verification

- Continue shows a configured provider/model
- Cline can see the workspace filesystem (and respects the workspace boundary)

## Troubleshooting

- Continue says "no API key": confirm the environment variable exists inside the IDE container
- Cline cannot see MCP servers: regenerate configs via `generate-configs.sh` and restart the IDE

## Related

- [MCP Integration](mcp.md)
- [Tool Compatibility](../reference/tool-compatibility.md)

## Next steps

- Add mobile notifications: [Mobile Access](mobile-access.md)
