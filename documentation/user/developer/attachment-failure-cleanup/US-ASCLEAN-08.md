# US-ASCLEAN-08 — Preserve custom callback timing

Given a custom callback and a preceding parent before-action attribute change.

When native attach reaches the callback and Blob creation is refused.

Then the callback sees that changed attribute exactly once. The native custom-path error and uploaded bytes remain unchanged by automatic cleanup.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-08`.
