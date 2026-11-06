# US-ASCLEAN-01 — Remove upload after Blob-create refusal

As a developer, I want a refused Blob creation to leave no uploaded object.

Given an authorized owner action and an actor denied Blob creation,

When the real native attach uploads bytes and Blob creation returns an error,

Then the action returns its original authorization error and the unique tenant has no stored object or Blob row.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-01`.
