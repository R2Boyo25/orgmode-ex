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
    res =
      text
      |> String.split("\n")
      # might need to remove this later
      |> Enum.map(&String.trim/1)
      |> Enum.map(&lex_line/1)
      |> Enum.reduce([], &merge_paragraphs/2)
      |> Enum.filter(fn item -> item != {} end)

    status = if Enum.any?(res, fn item -> item |> elem(0) == :error end), do: :error, else: :ok

    {status, res}
  end

  def merge_if(tokens, token, type, callback) do
    with {last, rest} <- List.pop_at(tokens, -1, nil) do
      earlyret do
        ret_if last == nil or last == {} do
          tokens ++ [token]
        end

        ret_if last |> elem(0) != type do
          tokens ++ [token]
        end

        rest ++ [callback.(last)]
      end
    end
  end

  def merge_paragraphs(token, tokens) do
    case token do
      {:text, content} ->
        merge_if(tokens, token, :text, fn last ->
          {:text, (last |> elem(1)) <> "\n" <> content}
        end)

      {:table, rows} ->
        merge_if(tokens, token, :table, fn last -> {:table, (last |> elem(1)) ++ rows} end)

      _ ->
        tokens ++ [token]
    end
  end

  @heading ~r/(\*+)\s*([^\n]+)/
  @metadef ~r/#\+([\w_]+):\s*([^\n]+)/
  @text ~r/[^\n]*/
  @table ~r/\|(?:[^\n\|]*\|)+/

  def lex_line(line) do
    cond do
      line == "" ->
        {}

      String.match?(line, @heading) ->
        with [stars, content] <- tl(Regex.run(@heading, line)) do
          {:heading, content, String.length(stars)}
        end

      String.match?(line, @metadef) ->
        with [name, value] <- tl(Regex.run(@metadef, line)) do
          {:metadef, name, value}
        end

      String.match?(line, @table) ->
        with table_cell <-
               line |> String.trim("|") |> String.split("|") |> Enum.map(&String.trim/1) do
          {:table, [table_cell]}
        end

      String.match?(line, @text) ->
        with [content] <- Regex.run(@text, line) do
          {:text, content}
        end

      true ->
        {:error, "not implemented"}
    end
  end
end
