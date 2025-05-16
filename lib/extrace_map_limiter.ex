defmodule Extrace.MapLimiter do
  @moduledoc """
  Formatting & Trimming output to selected fields.

  This module handles formatting `Map` & `Struct`.
  more details can be found `:recon_map`.
  """
  import Inspect.Algebra

  @type label :: atom
  @type pattern :: map | (map -> boolean)
  @type limit :: :all | :none | atom | binary | [any]

  @spec install :: :ok
  def install do
    opts = Application.get_env(:extrace, :inspect_opts, pretty: true)
    opts = [{:inspect_fun, &__MODULE__.limit_inspect/2} | opts]
    Application.put_env(:extrace, :inspect_opts, opts)
  end

  @spec limit(struct, limit) :: :ok
  def limit(%module{}, limit) do
    :recon_map.limit(module, %{__struct__: module}, limit)
  end

  @spec limit(label, pattern, limit) :: :ok
  def limit(label, pattern, limit) do
    :recon_map.limit(label, pattern, limit)
  end

  @spec remove(label | struct) :: true
  def remove(label) when is_atom(label), do: :recon_map.remove(label)
  def remove(%module{}), do: :recon_map.remove(module)

  @doc false
  def limit_inspect(term, opts) when is_map(term) do
    case term do
      %module{} ->
        # struct data
        case process_map(term) do
          {_, term} ->
            infos = struct_infos(module, term)

            Inspect.Any.inspect(
              term,
              Macro.inspect_atom(:literal, module),
              infos,
              opts
            )

          _ ->
            Inspect.inspect(term, opts)
        end

      _ ->
        # map data
        term
        |> process_map()
        |> inspect_limited_map(opts)
    end
  end

  def limit_inspect(term, opts) do
    Inspect.inspect(term, opts)
  end

  defp struct_infos(module, map) do
    for %{field: field} = info <- module.__info__(:struct),
        field in Map.keys(map),
        do: info
  end

  defp process_map(old_term) do
    with true <- :recon_map.is_active(),
         {label, term} <- :recon_map.process_map(old_term),
         true <- Map.keys(old_term) != Map.keys(term) do
      {label, term}
    else
      _ ->
        old_term
    end
  end

  defp inspect_limited_map({_label, map}, opts) do
    opts = %{opts | limit: min(opts.limit, map_size(map))}
    map = Map.to_list(map)
    open = color("%{", :map, opts)
    sep = color(",", :map, opts)
    close = color("}", :map, opts)

    traverse_fun =
      if Inspect.List.keyword?(map) do
        &Inspect.List.keyword/2
      else
        sep = color(" => ", :map, opts)

        fn {key, value}, opts ->
          concat(concat(to_doc(key, opts), sep), to_doc(value, opts))
        end
      end

    container_doc(open, map ++ [:...], close, opts, traverse_fun, separator: sep, break: :strict)
  end

  defp inspect_limited_map(map, opts) do
    Inspect.Map.inspect(map, opts)
  end
end
