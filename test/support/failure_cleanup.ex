defmodule AshStorage.Test.FailureCleanup.BreakDelete do
  @moduledoc false
  use Ash.Resource.Change

  @impl Ash.Resource.Change
  @spec change(changeset :: Ash.Changeset.t(), opts :: keyword(), context :: map()) ::
          Ash.Changeset.t()
  def change(changeset, _opts, %{actor: %{break_delete?: true}}) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      key = Ash.Changeset.get_attribute(changeset, :key)
      options = Ash.Changeset.get_attribute(changeset, :service_opts)
      path = Path.join(Map.fetch!(options, :root), key)
      File.rename!(path, path <> ".retained")
      File.mkdir!(path)
      Ash.Changeset.add_error(changeset, field: :filename, message: "Blob creation refused")
    end)
  end

  def change(changeset, _opts, _context), do: changeset
end

defmodule AshStorage.Test.FailureCleanup.Blob do
  @moduledoc false
  use Ash.Resource,
    domain: AshStorage.Test.FailureCleanup.Domain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshStorage.BlobResource]

  ets do
    private? true
  end

  blob do
  end

  policies do
    policy action(:create) do
      forbid_if actor_attribute_equals(:deny_blob?, true)
      authorize_if always()
    end

    policy action_type([:read, :update, :destroy]) do
      authorize_if always()
    end
  end

  changes do
    change AshStorage.Test.FailureCleanup.BreakDelete, on: [:create]
  end

  multitenancy do
    strategy :attribute
    attribute :tenant
  end

  attributes do
    uuid_primary_key :id
    attribute :tenant, :string
  end
end

defmodule AshStorage.Test.FailureCleanup.Attachment do
  @moduledoc false
  use Ash.Resource,
    domain: AshStorage.Test.FailureCleanup.Domain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshStorage.AttachmentResource]

  ets do
    private? true
  end

  attachment do
    blob_resource AshStorage.Test.FailureCleanup.Blob
    belongs_to_resource :post, AshStorage.Test.FailureCleanup.Post
  end

  policies do
    policy action(:create) do
      forbid_if actor_attribute_equals(:deny_join?, true)
      authorize_if always()
    end

    policy action_type([:read, :destroy]) do
      authorize_if always()
    end
  end

  multitenancy do
    strategy :attribute
    attribute :tenant
  end

  attributes do
    uuid_primary_key :id
    attribute :tenant, :string
  end
end

defmodule AshStorage.Test.FailureCleanup.Post do
  @moduledoc false
  use Ash.Resource,
    domain: AshStorage.Test.FailureCleanup.Domain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshStorage]

  ets do
    private? true
  end

  storage do
    service {AshStorage.Service.Test, []}
    blob_resource AshStorage.Test.FailureCleanup.Blob
    attachment_resource AshStorage.Test.FailureCleanup.Attachment
    has_many_attached :files

    has_many_attached :default_disk_files do
      service {AshStorage.Service.Disk, root: "tmp/native-failure-cleanup/objects"}
    end

    has_many_attached :disk_files do
      service {AshStorage.Service.Disk, root: "."}
      path fn context, _changeset -> context.actor.disk_path end
    end

    has_many_attached :reused_custom_files do
      path fn context, _changeset -> Path.join(context.tenant, "fixed-custom-key") end
    end

    has_many_attached :custom_files do
      path fn context, changeset ->
        prefix = Ash.Changeset.get_attribute(changeset, :path_prefix)
        send(context.actor.owner, {:custom_path, prefix})
        Path.join(prefix, AshStorage.generate_key())
      end
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  multitenancy do
    strategy :attribute
    attribute :tenant
  end

  attributes do
    uuid_primary_key :id
    attribute :tenant, :string
    attribute :path_prefix, :string, default: "initial"
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
end

defmodule AshStorage.Test.FailureCleanup.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource AshStorage.Test.FailureCleanup.Post
    resource AshStorage.Test.FailureCleanup.Blob
    resource AshStorage.Test.FailureCleanup.Attachment
  end
end
