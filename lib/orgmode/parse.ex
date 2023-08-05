defmodule Orgmode.Parser do
  import Orgmode.Error
  import ExEarlyRet

  @moduledoc """
  Parses Org-mode files.
  """

  @doc """
  Parse a tokenized Org-mode file.

      iex> Orgmode.Parser.parse([{:metadef, "tItLe", "This is a test!"}, {:heading, "foo", 1}, {:text, "Hello!"}, {:heading, "bar", 2}, {:heading, "baz", 1}])
      {:ok, %{sections: [%{name: "foo", level: 1, content: [{:paragraph, "Hello!"}]}, %{name: "bar", level: 2}, %{name: "baz", level: 1}], metadata: %{title: "This is a test!"}}}
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

  def parse_line({:heading, name, level}, acc) do
    transition(%{acc | tmp: %{name: name, level: level}}, :heading)
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

  bang("transition/2")

  @doc """
      iex> Orgmode.Parser.transition(%{Orgmode.Parser.FSM.new() | tmp: %{name: "AUTHor", value: "Kazani"}}, :metadata)
      %Orgmode.Parser.FSM{
          state: :metadata,
          sections: [],
          metadata: %{author: "Kazani"},
          tmp: %{name: "AUTHor", value: "Kazani"}
      }
  """
  def transition(fsm, state) do
    case Fsmx.transition(fsm, state) do
      {:error, message} -> {:error, message}
      {:ok, new_fsm} -> new_fsm
    end
  end
end
