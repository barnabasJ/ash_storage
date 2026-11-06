# US-ASCLEAN-09 — Avoid deletion before a Disk upload

Given a retained native Disk object at the new operation's tenant prefix,

When the owner rejects before upload and native existence checking confirms the planned child key is absent,

Then the original rejection remains, no cleanup failure replaces it, and the retained bytes remain readable.

The actual native filesystem rejects a DELETE beneath this retained regular-file prefix with `:enotdir`. This makes the existence guard observable without replacing the service.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-09`.
