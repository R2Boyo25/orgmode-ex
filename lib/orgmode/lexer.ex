defmodule Orgmode.Lexer do
  import ExEarlyRet
  import Orgmode.Error
  @moduledoc """
  A lexer for Orgmode.
  """

  @doc """
      iex(1)> Orgmode.Lexer.lex(\"\"\"
      ...(1)> #+TITLE: This is a test
      ...(1)> #+DESCRIPTION: The description
      ...(1)> 
      ...(1)> * Test
      ...(1)> Hi!
      ...(1)> \"\"\")
      {:ok, [{:metadef, "TITLE", "This is a test"}, {:metadef, "DESCRIPTION", "The description"}, {:heading, "Test", 1}, {:text, "Hi!"}]}
  """
  def lex(text) do
    res = text
    |> String.split("\n")
    |> Enum.map(&String.trim/1) # might need to remove this later
    |> Enum.map(&lex_line/1)
    |> Enum.reduce({0, []}, &merge_paragraphs/2)
    |> get_second_tuple_element
    |> Enum.filter(fn (item) -> item != {} end)

    status = if Enum.any?(res, fn(item) -> item |> elem(0) == :error end), do: :error, else: :ok

    {status, res}
  end

  def get_second_tuple_element(acc) do
    acc |> elem(1)
  end

  def merge_paragraphs(token, acc) do
    {line_count, tokens} = acc
    
    case token do
      {:text, content} ->
        {0,
         with {last, rest} <- List.pop_at(tokens, -1, nil) do
           earlyret do            
             ret_if last == nil do
               [token]
             end

             ret_if last == {} do
               tokens ++ [token]
             end
             
             ret_if (last |> elem(0) != :text) or (line_count == 0) do
               tokens ++ [token]
             end
             
             rest ++ [{:text, (last |> elem(1)) <> "\n" <> content}]              
           end
         end
        }
      {} -> {line_count + 1, tokens ++ [token]}
      _ -> {0, tokens ++ [token]}
    end
  end

  @heading ~r/(\*+)\s*([^\n]+)/
  @metadef ~r/#\+([\w_]+):\s*([^\n]+)/
  @text    ~r/[^\n]*/
  
  def lex_line(line) do
    cond do
      line == "" -> {}
      String.match?(line, @heading) ->
        with [stars, content] <- tl Regex.run(@heading, line) do
          {:heading, content, String.length(stars)}
        end
      String.match?(line, @metadef) ->
        with [name, value] <- tl Regex.run(@metadef, line) do
          {:metadef, name, value}
        end
      String.match?(line, @text) ->
        with [content] <- Regex.run(@text, line) do
          {:text, content}
        end
      true -> {:error, "not implemented"}
    end
  end
end
