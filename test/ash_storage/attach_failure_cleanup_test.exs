defmodule AshStorage.AttachFailureCleanupTest do
  use ExUnit.Case, async: true

  alias AshStorage.Error.UploadCleanupFailed
  alias AshStorage.Operations
  alias AshStorage.Service.Context
  alias AshStorage.Test.FailureCleanup.{Blob, Post}

  setup do
    tenant = Ash.UUID.generate()
    actor = %{id: Ash.UUID.generate()}
    post = Ash.create!(Post, %{}, actor: actor, tenant: tenant)

    on_exit(fn ->
      for key <- AshStorage.Service.Test.list_keys(), String.starts_with?(key, tenant <> "/") do
        AshStorage.Service.Test.delete(key, Context.new([]))
      end
    end)

    %{post: post, actor: actor, tenant: tenant}
  end

  @tag story: "US-ASCLEAN-01"
  test "a refused Blob create removes the object uploaded by the owner action", ctx do
    actor = Map.put(ctx.actor, :deny_blob?, true)
    assert {:error, error} = attach(ctx, actor)
    assert %Ash.Error.Forbidden{} = error
    assert keys(ctx) == []
    assert %{results: []} = Ash.read!(Blob, actor: actor, tenant: ctx.tenant, page: [limit: 2])
  end

  @tag story: "US-ASCLEAN-02"
  test "a refused owner join removes the new object without deleting a retained upload", ctx do
    assert {:ok, %{blob: retained}} = attach(ctx, ctx.actor)
    actor = Map.put(ctx.actor, :deny_join?, true)
    assert {:error, _error} = attach(ctx, actor)
    assert keys(ctx) == [retained.key]
    assert {:ok, "new bytes"} = AshStorage.Service.Test.download(retained.key, [])
  end

  @tag story: "US-ASCLEAN-03"
  @tag :tmp_dir
  test "custom-path Blob failure preserves its original error without automatic deletion", ctx do
    disk_path = Path.join(ctx.tmp_dir, "new-object") |> Path.relative_to(File.cwd!())
    actor = Map.merge(ctx.actor, %{break_delete?: true, disk_path: disk_path})

    assert {:error, %Ash.Error.Invalid{errors: errors}} =
             Operations.attach(ctx.post, :disk_files, "retained bytes",
               filename: "proof.txt",
               actor: actor,
               tenant: ctx.tenant
             )

    assert Enum.any?(errors, &match?(%Ash.Error.Changes.InvalidAttribute{field: :filename}, &1))
    refute Enum.any?(errors, &is_struct(&1, UploadCleanupFailed))
    assert File.dir?(disk_path)
    assert File.read!(disk_path <> ".retained") == "retained bytes"
  end

  @tag story: "US-ASCLEAN-04"
  test "successful attachment retains the new object and original tenant", ctx do
    assert {:ok, %{blob: blob, attachment: attachment}} = attach(ctx, ctx.actor)
    assert blob.tenant == ctx.tenant
    assert attachment.tenant == ctx.tenant
    assert keys(ctx) == [blob.key]
    assert {:ok, "new bytes"} = AshStorage.Service.Test.download(blob.key, [])
  end

  @tag story: "US-ASCLEAN-05"
  test "rejection before upload preserves every retained object", ctx do
    assert {:ok, %{blob: retained}} = attach(ctx, ctx.actor)
    owner = self()

    changeset =
      ctx.post
      |> Ash.Changeset.for_update(
        :attach_files,
        %{io: "never uploaded", filename: "proof.txt"},
        actor: ctx.actor,
        tenant: ctx.tenant
      )
      |> Ash.Changeset.before_action(
        fn changeset ->
          send(owner, {:before_upload, keys(ctx)})
          Ash.Changeset.add_error(changeset, field: :filename, message: "Rejected before upload")
        end,
        prepend?: true
      )

    assert {:error, _error} = Ash.update(changeset)
    assert_received {:before_upload, [key]}
    assert key == retained.key
    assert keys(ctx) == [retained.key]
    assert {:ok, "new bytes"} = AshStorage.Service.Test.download(retained.key, [])
  end

  @tag story: "US-ASCLEAN-06"
  test "parent rejection after actual upload removes the default generated object", ctx do
    owner = self()

    changeset =
      ctx.post
      |> Ash.Changeset.for_update(
        :attach_files,
        %{io: "new bytes", filename: "proof.txt"},
        actor: ctx.actor,
        tenant: ctx.tenant
      )
      |> Ash.Changeset.before_action(fn changeset ->
        with %{results: [blob], more?: false} <-
               Ash.read!(Blob, actor: ctx.actor, tenant: ctx.tenant, page: [limit: 2]),
             {:ok, bytes} <- AshStorage.Service.Test.download(blob.key, []) do
          send(owner, {:uploaded, blob.key, bytes})
        end

        Ash.Changeset.add_error(changeset,
          field: :filename,
          message: "Parent rejected after upload"
        )
      end)

    assert {:error, _error} = Ash.update(changeset)
    assert_received {:uploaded, key, "new bytes"}
    assert {:error, :not_found} = AshStorage.Service.Test.download(key, [])
    assert keys(ctx) == []
  end

  @tag story: "US-ASCLEAN-07"
  test "default-key transaction cleanup preserves a real deletion failure", ctx do
    root = "tmp/native-failure-cleanup/objects"
    owned_path = Path.join(root, ctx.tenant)
    on_exit(fn -> File.rm_rf!(owned_path) end)
    actor = Map.put(ctx.actor, :break_delete?, true)

    assert {:error, %{errors: errors}} =
             Operations.attach(ctx.post, :default_disk_files, "retained bytes",
               filename: "proof.txt",
               actor: actor,
               tenant: ctx.tenant
             )

    assert %UploadCleanupFailed{
             operation_error: operation_error,
             cleanup_error: cleanup_error,
             phase: :delete
           } =
             Enum.find(errors, &is_struct(&1, UploadCleanupFailed))

    assert operation_error != nil
    assert cleanup_error in [:eisdir, :eperm]
    assert [key] = File.ls!(owned_path) |> Enum.filter(&String.ends_with?(&1, ".retained"))
    assert File.read!(Path.join(owned_path, key)) == "retained bytes"
  end

  @tag story: "US-ASCLEAN-08"
  test "custom path callback still observes changes from earlier before-action hooks", ctx do
    actor = Map.merge(ctx.actor, %{owner: self(), deny_blob?: true})

    changeset =
      ctx.post
      |> Ash.Changeset.for_update(
        :attach_custom_files,
        %{io: "custom bytes", filename: "proof.txt"},
        actor: actor,
        tenant: ctx.tenant
      )
      |> Ash.Changeset.before_action(
        fn changeset ->
          Ash.Changeset.force_change_attribute(changeset, :path_prefix, ctx.tenant)
        end,
        prepend?: true
      )

    assert {:error, _error} = Ash.update(changeset)
    assert_receive {:custom_path, prefix}
    assert prefix == ctx.tenant
    refute_received {:custom_path, _other}
    assert [key] = keys(ctx)
    assert {:ok, "custom bytes"} = AshStorage.Service.Test.download(key, [])
  end

  @tag story: "US-ASCLEAN-09"
  test "early Disk rejection does not delete an absent planned object or retained prefix", ctx do
    root = "tmp/native-failure-cleanup/objects"
    context = Context.new(root: root)
    on_exit(fn -> AshStorage.Service.Disk.delete(ctx.tenant, context) end)
    assert :ok = AshStorage.Service.Disk.upload(ctx.tenant, "retained native bytes", context)
    assert {:ok, false} = AshStorage.Service.Disk.exists?(ctx.tenant <> "/absent", context)
    assert {:error, :enotdir} = File.rm(Path.join([root, ctx.tenant, "absent"]))

    changeset =
      ctx.post
      |> Ash.Changeset.for_update(
        :attach_default_disk_files,
        %{io: "never uploaded", filename: "proof.txt"},
        actor: ctx.actor,
        tenant: ctx.tenant
      )
      |> Ash.Changeset.before_action(
        fn changeset ->
          Ash.Changeset.add_error(changeset, field: :filename, message: "Rejected before upload")
        end,
        prepend?: true
      )

    assert {:error, %Ash.Error.Invalid{errors: errors}} = Ash.update(changeset)
    assert Enum.any?(errors, &(Map.get(&1, :field) == :filename))
    refute Enum.any?(errors, &is_struct(&1, UploadCleanupFailed))
    assert {:ok, "retained native bytes"} = AshStorage.Service.Disk.download(ctx.tenant, context)
  end

  @tag story: "US-ASCLEAN-10"
  test "a refused attach does not delete an object referenced through a reused custom key", ctx do
    assert {:ok, %{blob: retained}} =
             Operations.attach(ctx.post, :reused_custom_files, "original bytes",
               filename: "proof.txt",
               actor: ctx.actor,
               tenant: ctx.tenant
             )

    actor = Map.put(ctx.actor, :deny_blob?, true)

    assert {:error, %Ash.Error.Forbidden{}} =
             Operations.attach(ctx.post, :reused_custom_files, "replacement bytes",
               filename: "proof.txt",
               actor: actor,
               tenant: ctx.tenant
             )

    assert [key] = keys(ctx)
    assert key == retained.key
    assert {:ok, "replacement bytes"} = AshStorage.Service.Test.download(key, [])
    assert {:ok, persisted} = Ash.get(Blob, retained.id, actor: ctx.actor, tenant: ctx.tenant)
    assert persisted.key == key
  end

  defp attach(ctx, actor),
    do:
      Operations.attach(ctx.post, :files, "new bytes",
        filename: "proof.txt",
        actor: actor,
        tenant: ctx.tenant
      )

  defp keys(ctx),
    do:
      AshStorage.Service.Test.list_keys()
      |> Enum.filter(&String.starts_with?(&1, ctx.tenant <> "/"))
end
