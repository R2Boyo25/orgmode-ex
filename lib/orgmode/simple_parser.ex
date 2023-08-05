defmodule Orgmode.SimpleParser do
  def _join_with_empty_string(to_join) do
    Enum.join(to_join, "")
  end

  @doc """
      iex(1)> Orgmode.SimpleParser.get_while("abc123", &Orgmode.SimpleParser.is_alpha/1)
      ["abc", "123"]

      iex(2)> Orgmode.SimpleParser.get_while("abc123", &Orgmode.SimpleParser.is_digit/1)
      ["", "abc123"]

      iex(3)> Orgmode.SimpleParser.get_while("abc123", &Orgmode.SimpleParser.is_digit/1, 1)
      ** (Orgmode.Error) Expected at least 1 matching characters.

      iex(4)> Orgmode.SimpleParser.get_while("abc123", &Orgmode.SimpleParser.is_alpha/1, 1, 2)
      ** (Orgmode.Error) Expected at most 2 matching characters.
  """
  def get_while(str, func, min \\ 0, max \\ -1) when is_function(func, 1) and is_bitstring(str) do
    [head, remaining] =
      str
      |> String.codepoints()
      |> Enum.split_while(fn char -> func.(List.first(String.to_charlist(char))) end)
      |> Tuple.to_list()
      |> Enum.map(&_join_with_empty_string/1)

    len = String.length(head)

    cond do
      len < min ->
        raise Orgmode.Error, message: "Expected at least #{min} matching characters."

      len > max and max >= 0 ->
        raise Orgmode.Error, message: "Expected at most #{max} matching characters."

      true ->
        [head, remaining]
    end
  end

  @doc """
      iex(1)> Orgmode.SimpleParser.to_charcode("a")
      97
      
      iex(2)> Orgmode.SimpleParser.to_charcode("/")
      47
      
      iex(3)> Orgmode.SimpleParser.to_charcode("!")
      33
  """
  def to_charcode(char) do
    List.first(String.to_charlist(char))
  end

  @doc """
      iex(1)> Orgmode.SimpleParser.is_alpha(?a)
      true
      
      iex(2)> Orgmode.SimpleParser.is_alpha(?A)
      true
      
      iex(3)> Orgmode.SimpleParser.is_alpha(Orgmode.SimpleParser.to_charcode(" "))
      false
  """
  def is_alpha(char) do
    char in ?a..?z or char in ?A..?Z
  end

  @doc """
      iex(1)> Orgmode.SimpleParser.is_digit(?1)
      true
      
      iex(2)> Orgmode.SimpleParser.is_digit(?0)
      true
      
      iex(3)> Orgmode.SimpleParser.is_digit(?7)
      true
      
      iex(4)> Orgmode.SimpleParser.is_digit(?b)
      false
      
      iex(5)> Orgmode.SimpleParser.is_digit(Orgmode.SimpleParser.to_charcode("/"))
      false
  """
  def is_digit(char) do
    char in ?0..?9
  end

  @doc """
      iex(1)> Orgmode.SimpleParser.is_alnum(?1)
      true
      
      iex(2)> Orgmode.SimpleParser.is_alnum(?0)
      true
      
      iex(3)> Orgmode.SimpleParser.is_alnum(?7)
      true
      
      iex(4)> Orgmode.SimpleParser.is_alnum(?b)
      true
      
      iex(5)> Orgmode.SimpleParser.is_alnum(?a)
      true
      
      iex(6)> Orgmode.SimpleParser.is_alnum(?A)
      true
      
      iex(7)> Orgmode.SimpleParser.is_alnum(Orgmode.SimpleParser.to_charcode(" "))
      false
      
      iex(8)> Orgmode.SimpleParser.is_alnum(Orgmode.SimpleParser.to_charcode("/"))
      false
  """
  def is_alnum(char) do
    is_alpha(char) or is_digit(char)
  end

  @doc ~S"""
      iex(1)> Orgmode.SimpleParser.is_whitespace(Orgmode.SimpleParser.to_charcode(" ")) 
      true
      
      iex(2)> Orgmode.SimpleParser.is_whitespace(Orgmode.SimpleParser.to_charcode("\t"))
      true
      
      iex(3)> Orgmode.SimpleParser.is_whitespace(?a)                                    
      false

      iex(4)> Orgmode.SimpleParser.is_whitespace(Orgmode.SimpleParser.to_charcode("\n"))                                    
      true
  """
  def is_whitespace(char) do
    # expand to contain all in https://en.wikipedia.org/wiki/Whitespace_character#Unicode
    char in [
      to_charcode(" "),
      to_charcode("\n"),
      to_charcode("\t"),
      to_charcode("\v"),
      to_charcode("\f"),
      to_charcode("\r")
    ]
  end

  @doc """
      iex(1)> Orgmode.SimpleParser.is_ident(?_)
      true
      iex(2)> Orgmode.SimpleParser.is_ident(?a)
      true
      iex(3)> Orgmode.SimpleParser.is_ident(?B)
      true
      iex(4)> Orgmode.SimpleParser.is_ident(Orgmode.SimpleParser.to_charcode("/"))
      false
      iex(5)> Orgmode.SimpleParser.is_ident(Orgmode.SimpleParser.to_charcode(" "))
      false
      iex(6)> Orgmode.SimpleParser.is_ident(Orgmode.SimpleParser.to_charcode("!"))
      true
      iex(7)> Orgmode.SimpleParser.is_ident(?2)                                   
      true
  """
  def is_ident(char) do
    char == to_charcode("_") or is_alnum(char) or char == to_charcode("!")
  end
end
