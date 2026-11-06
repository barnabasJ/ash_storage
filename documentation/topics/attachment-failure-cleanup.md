# Attachment failure cleanup

`AshStorage.Operations.attach/4` invokes the generated owner `attach_<name>` action. `AshStorage.Changes.Attach.change/3` uploads using the selected native service and the caller's actor/tenant context.

For default paths, a before-transaction callback puts an immutable operation plan in the changeset context. It captures the service, actor/tenant context and fresh generated key. The existing upload uses that plan. One after-transaction callback checks that key through native `exists?/2` when the action reports failure. Confirmed absence preserves the original error without a DELETE. Confirmed presence invokes native deletion. An existence-check error returns a structured cleanup-unproven error. Each action clears any stale plan before preparing its own plan. No mutable coordinator or registry is used.

Custom path callbacks retain their original before-action timing and error behavior. They can return a reused key, so this change does not delete custom-path objects on failure. It does not infer exclusive object ownership from successful upload. A failed custom-path attempt can leave uploaded or overwritten bytes, as before this change.

Only the default planned-key path gives inner Blob, attachment and analyzer actions `rollback_on_error?: false`, so ordinary errors can return before the owner reports failure. Custom paths retain their pre-existing inner action options. Forced data-layer rollback is not disabled.

When deletion succeeds, the original operation error is returned. When existence checking or deletion returns an error, `AshStorage.Error.UploadCleanupFailed` retains `operation_error`, `cleanup_error` and `phase` (`:exists` or `:delete`). Its authored message contains no object key, service options, or uploaded content. The caller must treat this as unproven cleanup and retain recovery evidence.

Cleanup deletes only the newly uploaded source object selected by that attach operation. It does not scan other owners, purge existing supplied Blob references, replace the caller's identity, or use current configuration to rediscover a service. Default-path keys are fresh native-generated keys. No distinct-key condition is added to custom callbacks. This change supplies no conditional-create or overwrite-recovery protocol.

## Limits

This is native action cleanup, not a general transaction coordinator. The upload remains a before-action effect because eager analyzers can write parent attributes in the same action. Default-key cleanup covers failures delivered to that action's after-transaction callback. Custom paths retain their original behavior: evaluating their path earlier would change callback timing, and deleting a custom key could remove an object referenced by an existing attachment.

An outer transaction can roll back after a successful attach returns. Process death or termination can prevent callbacks. Native hooks do not provide a durable external-object rollback receipt for those cases. Applications must not claim complete external-storage atomicity. Actual data-layer rejection still requires transactional adapter execution; the private ETS cases prove parent-hook rejection, not SQL rollback.

The change does not restore previously replaced objects, retire partially generated variants, or compensate arbitrary custom service side effects. ETS tests have no SQL transaction and therefore do not prove metadata rollback. Real transactional adapter coverage remains a separate verification obligation.

## Behavioral coverage

`AshStorage.AttachFailureCleanupTest` exercises real generated owner actions with private native ETS resources. It uses the existing native Test service with unique tenant keys. It also uses native Disk and an actual file-to-directory transition to make default-key deletion fail with the platform directory errno (`:eisdir` or `:eperm`), without replacing a service callback. Ten cases cover default Blob-create refusal, join refusal with retained distinct bytes, default deletion failure, successful tenant preservation, rejection before and after actual upload, original custom-path errors/callback timing, a reused custom key, and early Disk rejection with a retained prefix object that would make an unnecessary DELETE fail with `:enotdir`. The reused-key case explicitly observes replacement bytes, not restoration of overwritten bytes.

The preserved base790 candidate completed its default package suite: 371 passed
and 52 excluded integration cases, exit0. That run includes corrected cases03/08
and reused-key case10. This current candidate is based on
`86887abaa1a1d86b14d67ad5cfde1e2f13ce5dd5`, whose lock selects Ash 3.37.2.
Its exact dependency sources and tests are not yet verified. The old receipt is
not a current-base pass. The designated test owner must run
`mix test test/ash_storage/attach_failure_cleanup_test.exs --max-cases 4 --warnings-as-errors`
and the full default suite with this candidate's unchanged pinned dependencies.
