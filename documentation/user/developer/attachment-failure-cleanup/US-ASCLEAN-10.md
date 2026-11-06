# US-ASCLEAN-10 — Preserve a reused custom key on failed attach

Given a successful native attachment whose custom path returns a fixed key.

When a later native attach uploads replacement bytes to that same key and its Blob creation is refused.

Then the retained Blob row still references the existing object and automatic cleanup does not delete it. Native custom-path overwrite behavior leaves the replacement bytes at that key. This test does not claim to restore the previous bytes.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-10`.
