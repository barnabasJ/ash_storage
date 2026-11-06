# US-ASCLEAN-06 — Remove upload after parent rejection

Given actual native service bytes observed after upload,

When a later parent callback rejects the action,

Then default-key transaction cleanup removes that exact uploaded object.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-06`.
