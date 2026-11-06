# US-ASCLEAN-04 — Preserve successful upload and tenant

As a developer, I want successful native attachments to remain usable.

Given an authorized actor and a unique tenant,

When native attach succeeds,

Then its Blob and join retain the tenant, and its exact stored bytes remain readable.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-04`.
