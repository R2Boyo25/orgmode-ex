defmodule Orgmode.InlineParser do
  @moduledoc """
  Parses inline markup from Org-mode files.
  """

  @doc """
      iex> Orgmode.InlineParser.parse_inline("/te\\\\/st/")
      [{:italic, false}, "te\/st", {:italic, true}]

      iex> Orgmode.InlineParser.parse_inline("Org is a /plaintext markup syntax/ developed with *Emacs* in 2003. The canonical parser is =org-element.el=, which provides a number of functions starting with ~org-element-~.")
      [
        "Org is a ",
        {:italic, false},
        "plaintext markup syntax",
        {:italic, true},
        " developed with ",
        {:bold, false},
        "Emacs",
        {:bold, true},
        " in 2003. The canonical parser is ",
        {:verbatim, false},
        "org-element.el",
        {:verbatim, true},
        ", which provides a number of functions starting with ",
        {:code, false},
        "org-element-",
        {:code, true},
        "."
      ]
  """
  def parse_inline(text) do  
    text
    |> String.codepoints
    |> Enum.reduce({[], {[], :normal, false}}, &parse_inline_char/2)
    |> elem(0)
  end


  @doc """
      iex> Orgmode.InlineParser.add_to_last_item(["a", "b"], "c")
      ["a", "bc"]
  """
  def add_to_last_item(tokens, char) do
    if (length tokens) > 0 do
      {last, rest} = List.pop_at(tokens, -1, nil)

      if is_tuple(last) do
        tokens ++ [char]
      else
        rest ++ [last <> char]
      end
    else
      [char]
    end    
  end

  defp last_modifier_is(stack, is) do
    if (length stack) > 0 do
      {last, _} = List.pop_at(stack, -1, nil)

      last == is
    else
      false
    end
  end

  defp toggle_modifier(tokens, modifier_stack, mode, modifier) do
    last_is_same = last_modifier_is(modifier_stack, modifier)

    if last_is_same do
      {
        tokens ++ [{modifier, true}],
        {
          Enum.slice(modifier_stack, 0..-2),
          mode,
          false
        }
      }
    else
      {
        tokens ++ [{modifier, false}],
        {
          modifier_stack ++ [modifier],
          mode,
          false
        }
      }
    end
  end
  
  defp parse_inline_char(char, {tokens, {modifier_stack, mode, escaped}}) do
    if escaped do
      if char in ["\\", "=", "/", "~"] do
        {add_to_last_item(tokens, char), {modifier_stack, mode, false}}
      else
        {add_to_last_item(tokens, "\\" <> char), {modifier_stack, mode, false}}
      end
    else
      if char == "\\" do
        {tokens, {modifier_stack, mode, true}}
      else
        case mode do
          :normal ->
            case char do
              "/" -> toggle_modifier(tokens, modifier_stack, mode, :italic)
              "*" -> toggle_modifier(tokens, modifier_stack, mode, :bold)
              "_" -> toggle_modifier(tokens, modifier_stack, mode, :underline)
              "+" -> toggle_modifier(tokens, modifier_stack, mode, :strikethrough)
              "=" -> {tokens ++ [{:verbatim, false}], {modifier_stack, :verbatim, false}}
              "~" -> {tokens ++ [{:code, false}], {modifier_stack, :code, false}}
              _ -> {add_to_last_item(tokens, char), {modifier_stack, mode, false}}
            end
          :verbatim ->
            case char do
              "=" -> {tokens ++ [{:verbatim, true}], {modifier_stack, :normal, false}}
              _ -> {add_to_last_item(tokens, char), {modifier_stack, mode, false}}
            end
          :code ->
            case char do
              "~" -> {tokens ++ [{:code, true}], {modifier_stack, :normal, false}}
              _ -> {add_to_last_item(tokens, char), {modifier_stack, mode, false}}
            end
        end
      end
    end
  end
end
