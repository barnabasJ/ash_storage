# US-ASCLEAN-05 — Preserve retained bytes on early rejection

Given a retained object and a parent callback that rejects before upload,

When the generated default-key action fails,

Then the retained object remains readable and no new object remains.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-05`.
