# Native attachment failure cleanup

| Story                             | Behavior                                                 | Test                                  |
| --------------------------------- | -------------------------------------------------------- | ------------------------------------- |
| [US-ASCLEAN-01](US-ASCLEAN-01.md) | Remove upload after Blob-create refusal                  | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-02](US-ASCLEAN-02.md) | Preserve retained object on join refusal                 | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-03](US-ASCLEAN-03.md) | Preserve original custom-path error behavior             | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-04](US-ASCLEAN-04.md) | Preserve successful upload and tenant                    | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-05](US-ASCLEAN-05.md) | Preserve retained bytes on early rejection               | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-06](US-ASCLEAN-06.md) | Remove upload after parent rejection                     | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-07](US-ASCLEAN-07.md) | Report default-key deletion failure                      | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-08](US-ASCLEAN-08.md) | Preserve custom callback timing                          | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-09](US-ASCLEAN-09.md) | Avoid deletion when early Disk rejection precedes upload | `AshStorage.AttachFailureCleanupTest` |
| [US-ASCLEAN-10](US-ASCLEAN-10.md) | Preserve a reused custom key after a later failed attach | `AshStorage.AttachFailureCleanupTest` |
