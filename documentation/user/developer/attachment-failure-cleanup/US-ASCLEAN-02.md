# US-ASCLEAN-02 — Preserve retained object on join refusal

As a developer, I want failed attachment creation to remove only its new upload.

Given one successful attachment and an actor denied creation of the next join,

When the next generated attach action fails,

Then the retained object remains readable and no new object remains.

Owner: `AshStorage.AttachFailureCleanupTest`, story `US-ASCLEAN-02`.
