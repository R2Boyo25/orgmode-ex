defmodule Orgmode.Lexer do
  import ExEarlyRet

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
      {:ok, [{:metadef, "TITLE", "This is a test"}, {:metadef, "DESCRIPTION", "The description"}, {:heading, "Test", 1, nil}, {:text, "Hi!"}]}
  """
  def lex(text) do
    res =
      text
      |> String.split("\n")
      |> Enum.reduce({[], :normal}, &lex_line/2)
      |> elem(0)
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

  @merge_match ~r/^\s{2,}/

  @doc """
      iex> Orgmode.Lexer.merge_paragraphs({:text, "yeperdoodles"}, [{:text, "abc  "}])
      [{:text, "abc\\nyeperdoodles"}]
  """
  def merge_paragraphs(token, tokens) do
    case token do
      {:comment, _} ->
        tokens

      {:comment, _, _} ->
        tokens

      {:text, content} ->
        merge_if(tokens, token, :text, fn last ->
          separator = if String.match?(content, @merge_match), do: " ", else: "\n"

          {:text, String.trim(last |> elem(1)) <> separator <> String.trim(content)}
        end)

      {:table, rows} ->
        merge_if(tokens, token, :table, fn last -> {:table, (last |> elem(1)) ++ rows} end)

      _ ->
        tokens ++ [token]
    end
  end

  def split_arguments(args) do
    # TODO: Make this better.

    String.split(args)
  end

  def left_trim_block_equally(content) do
    left_padding = Enum.min(Enum.map(String.split(content, "\n"), fn line -> length Orgmode.SimpleParser.get_while(line, &Orgmode.SimpleParser.is_whitespace/1) end))

    Enum.join(Enum.map(String.split(content, "\n"), fn line -> String.slice(line, left_padding..-1) end), "\n")
  end
  
  @end_block ~r/#\+END_([\w]+)/i

  def lex_line(line, {tokens, state}) do
    case state do
      :normal ->
        lex_normal(line, tokens)

      :block ->
        cond do
          String.match?(line, @end_block) ->
            {with {last, rest} <- List.pop_at(tokens, -1, nil) do
                rest ++
                  [{last |> elem(0), split_arguments(last |> elem(1)), left_trim_block_equally(last |> elem(2))}]
              end, :normal}

          true ->
            {
              with {last, rest} <- List.pop_at(tokens, -1, nil) do
                rest ++
                  [
                    {last |> elem(0), last |> elem(1),
                     if((last_content = last |> elem(2)) != "",
                       do: last_content <> "\n" <> line,
                       else: line
                     )}
                  ]
              end,
              :block
            }
        end
    end
  end

  @heading ~r/(\*+)\s*((?:TODO|DONE)?)\s*([^\n]+)/
  @metadef ~r/#\+([\w_]+):\s*([^\n]+)/
  @text ~r/[^\n]*/
  @table ~r/\|(?:[^\n\|]*\|)+/
  @comment ~r/#\s+([^\n]*)/
  @begin_block ~r/#\+BEGIN_([\w]+)\s*([^\n]+)?/i

  def lex_normal(line, tokens) do
    cond do
      line == "" ->
        {tokens ++ [{}], :normal}

      String.match?(line, @comment) ->
        {tokens ++ [{:comment, List.last(Regex.run(@comment, line))}], :normal}

      String.match?(line, @begin_block) ->
        case tl(Regex.run(@begin_block, line)) do
          [type, args] ->
            {tokens ++ [{Orgmode.Parser.FSM.str_to_atom(String.downcase(type)), args, ""}],
             :block}

          [type] ->
            {tokens ++ [{Orgmode.Parser.FSM.str_to_atom(String.downcase(type)), nil, ""}], :block}
        end

      String.match?(line, @heading) ->
        with [stars, todo_state, content] <- tl(Regex.run(@heading, line)) do
          {tokens ++
             [
               {:heading, content, String.length(stars),
                if(todo_state != "", do: todo_state, else: nil)}
             ], :normal}
        end

      String.match?(line, @metadef) ->
        with [name, value] <- tl(Regex.run(@metadef, line)) do
          {tokens ++ [{:metadef, name, value}], :normal}
        end

      String.match?(line, @table) ->
        with table_cell <-
               line |> String.trim("|") |> String.split("|") |> Enum.map(&String.trim/1) do
          {tokens ++ [{:table, [table_cell]}], :normal}
        end

      String.match?(line, @text) ->
        with [content] <- Regex.run(@text, line) do
          {tokens ++ [{:text, content}], :normal}
        end
    end
  end
end
