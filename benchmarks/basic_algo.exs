defmodule Benchmark.BasicAlgo do
  alias Freecodecamp.BasicAlgo

  @spec run(String.t(), module(), any()) :: module()
  def run(function_name, formatter, args \\ nil),
    do: __MODULE__ |> apply(String.to_atom(function_name), [formatter, args])

  # set config for benchmark here
  defp generic_benchee(map, formatter, before_each_function) do
    Benchee.run(
      map,
      before_each: before_each_function,
      time: 5,
      memory_time: 2,
      warmup: 4,
      formatters: [formatter]
    )
  end

  @spec mutation(module(), any()) :: module()
  def mutation(formatter, _args) do
    generic_benchee(
      %{
        "Enum.filter" => fn {string1, string2} ->
          mutation_gen([string1, string2], :enum_filter)
        end,
        "List comprehension" => fn {string1, string2} ->
          mutation_gen([string1, string2], :list_comprehension)
        end
      },
      formatter,
      fn _ ->
        {
          gen_string_input(),
          gen_string_input()
        }
      end
    )
  end

  @spec truncate_string(module(), any()) :: module()
  def truncate_string(formatter, _args) do
    generic_benchee(
      %{
        "BasicAlgo.truncate_string" => fn {string, pos} ->
          BasicAlgo.truncate_string(string, pos)
        end,
        "Charlist and Enum.split" => fn {string, pos} ->
          truncate_string_gen(string, pos, :enum_split)
        end,
        "String.split_at" => fn {string, pos} ->
          truncate_string_gen(string, pos, :string_split_at)
        end
      },
      formatter,
      fn _ ->
        {
          gen_string_input(),
          gen_int_input(-10_000..10_000)
        }
      end
    )
  end

  @spec get_index_to_ins(module(), any()) :: module()
  def get_index_to_ins(formatter, _args) do
    generic_benchee(
      %{
        "List comprehension" => fn {list_int, value} ->
          BasicAlgo.get_index_to_ins(list_int, value)
        end,
        "Enum.filter" => fn {list_int, value} ->
          get_index_to_ins_gen(list_int, value)
        end
      },
      formatter,
      fn _ ->
        {
          gen_list_int_input(-10_000..10_000),
          gen_int_input(-10_000..10_000)
        }
      end
    )
  end

  ##################################################
  ### Below are helpers for the main functions above
  ##################################################

  # TODO: 
  # StreamData.integer(1..1_000) |> Enum.take(30) |> Enum.random()
  # StreamData.integer(1..1_000) |> Enum.take(1) |> hd()
  @spec gen_list_int_input(Range.t()) :: list(integer)
  defp gen_list_int_input(range) do
    range
    |> StreamData.integer()
    |> StreamData.list_of()
    |> Enum.take(Enum.random(1..1_000))
    |> Enum.random()
  end

  @spec gen_int_input(Range.t()) :: integer()
  defp gen_int_input(range) do
    StreamData.integer(range)
    |> Enum.take(1)
    |> hd()
  end

  @spec gen_string_input :: String.t()
  defp gen_string_input do
    :alphanumeric
    |> StreamData.string(min_length: 3, max_length: 20)
    |> Enum.take(30)
    |> Enum.random()
  end

  @spec mutation_gen(list(String.t()), atom()) :: boolean()
  defp mutation_gen([target, source] = _list, :enum_filter) do
    enum_filter = mutation_list(target) |> Enum.filter(&(&1 in mutation_list(source)))
    enum_filter === mutation_list(source)
  end

  defp mutation_gen([target, source] = _list, :list_comprehension) do
    list_comprehension = for el <- mutation_list(target), el in mutation_list(source), do: el
    list_comprehension === mutation_list(source)
  end

  @spec mutation_list(String.t()) :: list(String.t())
  defp mutation_list(string) do
    String.downcase(string)
    |> String.split("", trim: true)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec truncate_string_gen(String.t(), integer(), atom()) :: String.t()
  defp truncate_string_gen(_words, len, _version) when len <= 0, do: "..."

  defp truncate_string_gen(words, len, :enum_split) do
    {trimmed_word, _} = String.to_charlist(words) |> Enum.split(len)
    to_string(trimmed_word) <> "..."
  end

  defp truncate_string_gen(words, len, :string_split_at) do
    {trimmed_word, _} = String.split_at(words, len)
    trimmed_word <> "..."
  end

  @spec get_index_to_ins_gen(list(integer), integer) :: integer
  defp get_index_to_ins_gen([], _value), do: 0

  defp get_index_to_ins_gen(list, value) do
    sorted_list = Enum.sort(list)

    sorted_list
    |> Enum.filter(&(&1 >= round(value)))
    |> do_get_index_to_ins(sorted_list)
  end

  defp do_get_index_to_ins([], _list), do: 0

  defp do_get_index_to_ins(result, list) do
    Enum.find_index(list, &(&1 == List.first(result)))
  end
end

alias Benchmark.BasicAlgo
alias Benchee.Formatters.{HTML, Console}

# BasicAlgo.run("mutation", Console)
BasicAlgo.run("get_index_to_ins", Console)

# Available functions (uncomment above):
#   - mutation
#   - truncate_string
#   - get_index_to_ins
