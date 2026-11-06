# Native attachment failure cleanup

## Problem and change

Current candidate base: `86887abaa1a1d86b14d67ad5cfde1e2f13ce5dd5`.
The earlier reproduction and completed package run belong to the preserved
`790dbc1082b9c160d4357de563fe3e101c519e70` candidate. Attach uploads before
creating its Blob. Blob-create refusal can leave the uploaded object. This
forward-applied patch keeps native service dispatch and actual actor/tenant
context while adding bounded cleanup. Root ran the current-base full suite;
it failed on the standard test database's missing ash_required function.
The corrected native analyzer/cleanup scope then passed. The full suite has
not passed on this current candidate.

For default paths, native before-transaction preparation puts the selected service/context/fresh key in immutable changeset context. The existing upload uses that plan. One after-transaction callback owns failure cleanup, including parent failure after upload. It checks native `exists?/2`: false preserves the primary error without DELETE, true deletes, and an existence error preserves structured unproven-cleanup evidence. Synchronous branches defer to it rather than deleting twice. Each action clears any stale private plan.

Custom callbacks retain original before-action timing, original inner action error options, and original returned errors. They can inspect changes made by an earlier before-action hook and can return reused keys. Automatic failure deletion therefore applies only to fresh native default keys. No custom-key uniqueness precondition is added.

`UploadCleanupFailed` retains operation and deletion errors with a bounded message. Cleanup uses the captured service and exact upload key. It does not scan unrelated resources or replace the caller's actor.

## Public call chain and source verification

`AshStorage.Operations.attach/4` → generated owner `attach_<name>` action → `AshStorage.Changes.Attach.change/3` → native service `upload/3` → `Ash.create/3` for Blob → parent update → `Ash.create/3` for attachment. Cleanup ends at the captured service's `delete/2`.

Historical dependency source verification used locked Ash 3.32.3 on base790.
Its public `rollback_on_error?` and before-/after-transaction callback contracts
were checked there. Root subsequently prepared this candidate's dependencies.
Its final lock selects Ash 3.37.3, AshSql 0.8.8 and Ecto 3.14.3. These are the
only three changed lock entries. AshSql 0.8.4 was retired for an Ecto query-cache
security defect; 0.8.8 requires Ash >=3.37.3. Retained registry output reports
Ecto 3.14.2 advisory EEF-CVE-2026-118391. The unrelated nimble_options pin remains
unchanged. Native dependency preparation and execution remain Root-owned.
Hooks are registered once in `change/3`, outside other hooks. Only default
planned-key inner actions disable ordinary error rollback so errors can return
before the parent reports failure. Forced rollback remains enabled.

The current-base source review checked all nine upstream commits between these
bases. The patch preserves `store_oban_variants/4` with original context options,
persisted service-option projection, row destruction before file deletion,
`Operations.delete_blob_file/3`, the existing reattach safety path and the
upstream behavior outside the narrow security lock update. The new upload plan changes only default fresh keys;
custom key resolution retains its original callback phase. Cleanup still uses
the exact captured service/key and actor/tenant context.

## Coverage, review and limits

Ten async private ETS cases exercise native authorization refusal, join refusal with retained distinct bytes, real default Disk deletion failure, original custom-path error behavior, success with tenant preservation, early and late parent rejection, original custom callback timing, a reused custom key that must remain present, and early native Disk rejection preserving a retained prefix object. Callback probes are asserted by the case after the native action returns. No service callback is replaced. The proposed scoped command is in [the topic guide](../../topics/attachment-failure-cleanup.md).

The preserved base790 default-only candidate subsequently passed its full
default package suite: 371 passed, 52 excluded integration cases, 1.9 seconds
ExUnit and 5.30 seconds wall time, exit0. That receipt includes the corrected
custom-path cases03/08 and reused-key case10. Earlier partial-run receipts stay
historical. The full receipt certifies only base790 and its dependencies; it
does not certify the current base868 candidate. Root's current-base full suite
returned exit2: 376/387 passed, 52 integration cases excluded, and all 11 failures
belonged to analyzer_oban_test.exs with missing ash_required. Its reported ExUnit
duration was 1.7 seconds. This is a retained failed full receipt. These ETS cases
do not prove SQL rollback.
Transactional-adapter evidence belongs to the application's standard database
and public owner action; no extra package database or runner was added.

Outer rollback after successful return, process death, custom-path parent failures, previous-object restoration, partial variants and arbitrary service side effects remain outside the guarantee. No general external-object atomicity claim is made.

## Current-base native test extension correction

Pinned AshPostgres 2.15.2 declares ash-functions version7. The retained TestRepo
snapshot declared version5. Its atomic analyzer writes require ash_required,
which the test database lacked. Root used the native migration generator. It
emitted only the TestRepo extensions snapshot version5→7 and
20261106230909_update_test_ash_functions_extensions_1.exs. The migration installs
ash_required with the native ANYCOMPATIBLE/jsonb signature and empty search_path.
It changes no application table, policy or analyzer assertion. Its down path
drops that function, as generated.

Root applied the migration to the standard ash_storage_test database, then ran
analyzer_oban_test.exs plus attach_failure_cleanup_test.exs. The retained log
reports 24 passed in 0.5 seconds; Root recorded exit0. Compiler warnings remain
visible in the logs, so this is not a warnings-as-errors quality pass. No second
current-base full-suite pass exists. Native S3/Azure exclusions remain unrun.

Source and log evidence is retained under tmp/current-upstream-cleanup-review:
full-suite.log, test-functions-generation.log, test-functions-migration.log and
functions-and-cleanup-scoped.log. This evidence does not relabel the older base790
receipt or claim publication, adoption, outer-rollback safety or SQL compensation
proof. The reviewer ran no compiler, tests, formatter, database or dependency
operation. It reviewed the exact three-entry lock diff and generated migration.

## Historical custom-key correction

The first candidate deleted custom keys on returned errors and documented a distinct-key precondition not present in the native DSL. The correction removes those synchronous deletion paths. Default after-transaction cleanup remains unchanged. The new public-action regression attaches twice to the same fixed custom key, refuses the second Blob creation, reloads the retained Blob, and verifies that the object still exists with the native replacement bytes. It deliberately does not claim old-byte restoration.

## Final scoped quality receipts

Root formatted the five changed native Elixir and migration files with the
package formatter. The Attach implementation hash remains
6b596668fa21624883f0e0d9d6db45b916a8e15d6c7b2578c5714b8d9231d2a8.
Root selected the package's actual .credo.exs explicitly. Credo analyzed 123
source files with 66 checks and found no issues, exit0. The earlier invocation
inherited the parent checkout's unavailable AshCredo plugin; its exit0 is not
analysis evidence. No ignored findings or checker changes were added.

The repository-local dependency audit against this native lock exited0 and
reported no vulnerabilities. Native mix hex.audit exited0 and reported no
retired or security advisory packages. The security lock changes are AshSql
0.8.8, its required Ash3.37.3, and Ecto3.14.3. NimbleOptions retains the upstream
pin. These receipts do not change the failed full-suite record or establish a
strict compiler pass for existing dev/test fixture warnings.
