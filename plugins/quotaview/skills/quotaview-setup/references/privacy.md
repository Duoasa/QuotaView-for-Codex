# Local bridge data contract

Read for privacy questions or explaining stored data. Return to [setup](../SKILL.md).

## Explain privacy

The bridge stores only:

- one-way hashes of session and optional turn identifiers;
- the final workspace folder name, capped at 80 characters;
- a coarse tool category;
- lifecycle event, UTC timestamp, protocol version, installation ID, sequence;
- plugin health metadata.
- plan type, primary and optional Spark window used
  percentage/duration/reset time, normal Credits balance flags, limit-reached
  state, lifetime tokens, and up to the newest 190 daily token buckets.

These files remain local and events rotate after the newest 512 records. The
plugin does not upload them. Official Codex may use its own authenticated
network connection while serving the two read-only app-server requests.
QuotaView does not modify these files.
