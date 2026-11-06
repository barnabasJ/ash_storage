# US-ASCLEAN-07 — Report default-key deletion failure

Given a real default-key Disk upload and a Blob failure that leaves a directory at its key,

When transaction cleanup receives the native directory error `:eisdir` or `:eperm`,

Then the typed cleanup error retains both failures and the bytes remain available for recovery.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-07`.
