# US-ASCLEAN-03 — Preserve custom-path error behavior

Given a native custom-path Disk upload and a Blob failure that leaves a directory at that object path.

When the native owner action returns its original Blob creation error.

Then the action preserves that typed error and leaves the custom object and retained bytes alone. It does not add a cleanup error or claim ownership of the custom key.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-03`.
