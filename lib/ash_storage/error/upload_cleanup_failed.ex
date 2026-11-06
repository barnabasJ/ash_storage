defmodule AshStorage.Error.UploadCleanupFailed do
  @moduledoc """
  A native attachment action failed and its uploaded object could not be removed.

  Both failures remain available for recovery. The message does not disclose
  object keys, service options, or uploaded content.
  `phase` is `:exists` when absence could not be established, or `:delete`
  when removal failed.
  """
  use Splode.Error, fields: [:operation_error, :cleanup_error, :phase], class: :framework

  @type t :: %__MODULE__{
          operation_error: term(),
          cleanup_error: term(),
          phase: :exists | :delete
        }

  @impl Exception
  @spec message(error :: t()) :: String.t()
  def message(_error),
    do: "Attachment failed and its uploaded object could not be removed"
end
