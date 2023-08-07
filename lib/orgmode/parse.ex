defmodule Orgmode.Parser do
  import Orgmode.Error
  import ExEarlyRet

  @moduledoc """
  Parses Org-mode files.
  """

  @doc """
  Parse a tokenized Org-mode file.

      iex> Orgmode.Parser.parse([{:metadef, "tItLe", "This is a test!"}, {:heading, "foo", 1, nil}, {:text, "Hello!"}, {:heading, "bar", 2, nil}, {:heading, "baz", 1, nil}])
      {:ok, %{sections: [%{name: "foo", level: 1, content: [{:paragraph, "Hello!"}], todo_state: nil}, %{name: "bar", level: 2, todo_state: nil}, %{name: "baz", level: 1, todo_state: nil}], metadata: %{title: "This is a test!"}}}
  """
  def parse(tokens) do
    earlyret do
      fsm = Orgmode.Parser.FSM.new()

      output =
        tokens
        |> Enum.reduce(fsm, &parse_line/2)

      {:ok, %{sections: output.sections, metadata: output.metadata}}
    end
  end

  def parse_line({:heading, name, level, todo_state}, acc) do
    transition(
      %{
        acc
        | tmp: %{
            name: name,
            level: level,
            todo_state:
              if(todo_state,
                do: Orgmode.Parser.FSM.str_to_atom(String.downcase(todo_state)),
                else: nil
              )
          }
      },
      :heading
    )
  end

  def parse_line({:text, text}, acc) do
    transition(%{acc | tmp: text}, :paragraph)
  end

  def parse_line({:metadef, name, value}, acc) do
    transition(%{acc | tmp: %{name: name, value: value}}, :metadata)
  end

  def parse_line({:table, cells}, acc) do
    transition(%{acc | tmp: %{cells: cells}}, :table)
  end

  def parse_line({:src, args, content}, acc) do
    transition(%{acc | tmp: %{args: args, content: content}}, :src)
  end

  bang("transition/2")

  @doc """
      iex> Orgmode.Parser.transition(%{Orgmode.Parser.FSM.new() | tmp: %{name: "AUTHor", value: "Kazani"}}, :metadata)
      %Orgmode.Parser.FSM{
          state: :metadata,
          sections: [],
          metadata: %{author: "Kazani"},
          tmp: %{name: "AUTHor", value: "Kazani"}
      }

      iex> Orgmode.Parser.transition(%{Orgmode.Parser.FSM.new() | state: :table}, :metadata)
      {:error, "invalid transition from table to metadata"}
  """
  def transition(fsm, state) do
    case Fsmx.transition(fsm, state) do
      {:error, message} -> {:error, message}
      {:ok, new_fsm} -> new_fsm
    end
  end
end
