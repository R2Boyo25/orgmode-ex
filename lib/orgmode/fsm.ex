defmodule Orgmode.Parser.FSM do
  @moduledoc """
  Finite State Machine for the org-mode parser using FSMX.
  """

  defstruct [:state, :sections, :metadata, :tmp]

  use Fsmx.Struct,
    transitions: %{
      :begin => [:metadata, :heading, :paragraph, :table],
      :metadata => [:metadata, :heading, :paragraph, :table],
      :heading => [:paragraph, :table, :heading],
      :paragraph => [:paragraph, :heading, :table],
      :table => [:table, :paragraph, :heading]
    }

  @doc """
      iex> Orgmode.Parser.FSM.str_to_atom("this_is_a_test")
      :this_is_a_test
  """
  def str_to_atom(string) do
    try do
      String.to_existing_atom(string)
    rescue
      ArgumentError -> String.to_atom(string)
    end
  end

  def before_transition(struct, _, :heading) do
    {:ok, %{struct | sections: struct.sections ++ [struct.tmp]}}
  end

  def before_transition(struct, _, :paragraph) do
    {:ok, append_to_last_content(struct, {:paragraph, struct.tmp})}
  end

  def before_transition(struct, _, :metadata) do
    lowercased_name = String.downcase(struct.tmp.name)
    new_metadata = Map.put_new(struct.metadata, str_to_atom(lowercased_name), struct.tmp.value)

    {:ok, %{struct | metadata: new_metadata}}
  end

  def before_transition(struct, _, :table) do
    {:ok, append_to_last_content(struct, {:table, struct.tmp})}
  end

  def append_to_last_content(struct, element) do
    {last, rest} = List.pop_at(struct.sections, -1, %{})

    new_sections = rest ++ [Map.put(last, :content, Map.get(last, :content, []) ++ [element])]

    %{struct | sections: new_sections}
  end

  def new() do
    %Orgmode.Parser.FSM{state: :begin, sections: [], metadata: %{}}
  end
end
