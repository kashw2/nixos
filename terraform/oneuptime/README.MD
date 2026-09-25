# OneUptime

Manages the OneUptime resources that the NixOS configuration needs credentials for: the per-host `Server` monitors consumed by the infrastructure agent, the telemetry ingestion key used by Alloy, and the runner registration.

The `Server` monitor type cannot be created from the dashboard. It is absent from every category in the monitor picker, while the agent's ingest endpoint (`/server-monitor/response/ingest/<secretKey>`) accepts only that type. The API still accepts it, which is the main reason this directory exists.

## Environment

| Variable | Source |
| --- | --- |
| `ONEUPTIME_API_KEY` | `oneuptime/mcp_api_key` |
| `TF_VAR_ONEUPTIME_RUNNER_KEY` | `oneuptime/runner_key` |
| `TF_VAR_SNMP_V3_AUTH_KEY` | `snmp/v3_auth_key` |
| `TF_VAR_SNMP_V3_PRIV_KEY` | `snmp/v3_priv_key` |
| `TF_VAR_NIXOS_STATE_PASSPHRASE` | `terraform_state_passphrase` |

All of these are exported automatically by the nushell wrapper on non-server hosts, from secrets placed by sops-nix. Servers do not receive `terraform_state_passphrase`, so run OpenTofu from a workstation.

## State

State is committed to this repository and encrypted with OpenTofu's native state encryption (AES-GCM, PBKDF2). The `encryption` block lives in `providers.tf` with `enforced = true`, so OpenTofu refuses to write plaintext rather than silently falling back when the passphrase is absent.

This is an OpenTofu feature. Terraform cannot read the state — use `tofu`, not `tf`.

Do not rename `key_provider.pbkdf2.sops`, `method.aes_gcm.sops`, or `encrypted_metadata_alias`. Those names are written into the encrypted state's metadata and renaming them makes the state undecryptable. Rotate the passphrase with a `fallback` block instead.

## Bootstrapping a new instance

Two steps cannot be automated, because the API needs a project and a key before it can do anything:

1. Sign up at `http://oneuptime.media.local` to create the first user and project.
2. Mint an API key with `ProjectOwner` at `.../dashboard/<PROJECT_ID>/settings/api-keys` and store it:

   ```bash
   sops set secrets/secrets.yaml '["oneuptime"]["mcp_api_key"]' '"<key>"'
   ```

Everything else is created by OpenTofu:

```bash
tofu init
tofu apply
```

Feed the outputs back into the configuration:

```bash
tofu output -json agent_keys      # -> oneuptime/agent_key/<host>, one per host
tofu output -json ingestion_token # -> oneuptime/ingestion_token
tofu output runner_id             # -> runner.settings.ONEUPTIME_RUNNER_ID in nix/hosts/media/configuration.nix
```

`runner_id` is an ObjectID rather than a credential, so it belongs in the host configuration instead of sops.

Then deploy:

```bash
colmena apply --on media
```

## Secrets that need no attention

`oneuptime/secret`, `oneuptime/encryption_secret`, `oneuptime/register_probe_key`, `oneuptime/probe_key` and `oneuptime/runner_key` are shared values generated once and held in sops, not issued by the server. They survive a database wipe. The probe self-registers with `register_probe_key`, so it needs no dashboard step.

