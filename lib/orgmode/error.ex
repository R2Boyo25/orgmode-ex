defmodule Orgmode.Error do
  use Bang
  import Orgmode.SimpleParser

  defexception message: "There was an unknown error within Orgmode."

  def raise_on_error(returned_value) do
    case returned_value do
      {:ok, value} -> value
      {:error, message} -> raise Orgmode.Error, message: message
    end
  end

  @doc """
      iex> Orgmode.Error.extract_function_notation([], "a_potato/2")
      [a_potato: 2]
  """
  def extract_function_notation(existing, current) do
    [_, current] = get_while(current, &is_whitespace/1)

    if String.length(current) > 0 do
      [name, current] = get_while(current, &is_ident/1)

      [_, current] = get_while(current, fn char -> char == to_charcode("/") end, 1, 1)

      [arity, current] = get_while(current, &is_digit/1, 1)
      arity = String.to_integer(arity)

      (existing ++ [{String.to_existing_atom(name), arity}])
      |> extract_function_notation(current)
    else
      existing
    end
  end

  @doc """
      iex> Orgmode.Error.function_notation("a_potato/2 a_tomato/3")
      [a_potato: 2, a_tomato: 3]
  """
  def function_notation(notation) do
    extract_function_notation([], notation)
  end

  @doc """
      iex> :abc
      iex> Orgmode.Error.func_notation(quote do: "abc/1")
      [abc: 1]
  """
  def func_notation(from) do
    extracted_string = List.first(Tuple.to_list(Code.eval_quoted(from)))
    Orgmode.Error.function_notation(extracted_string)
  end

  defmacro bang(descriptor) do
    quote bind_quoted: [
            bang: {
              :bang,
              [
                context: Map.fetch!(__CALLER__, :module),
                imports: [
                  {
                    1,
                    Orgmode.Error
                  }
                ]
              ]
            },
            descriptor: Orgmode.Error.func_notation(descriptor)
          ] do
      @bang {descriptor, {Orgmode.Error, :raise_on_error}}
    end
  end
end
