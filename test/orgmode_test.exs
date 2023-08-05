defmodule OrgmodeTest do
  use ExUnit.Case
  doctest Orgmode
  doctest Orgmode.SimpleParser
  doctest Orgmode.Error
  doctest Orgmode.Parser
  doctest Orgmode.Parser.FSM
  doctest Orgmode.Lexer

  test "Parses a metadef" do
    Orgmode.parse!("#+TITLE: Much wow, such title!")
  end

  test "Parses the metadef document" do
    Orgmode.parse_file!("test/test-files/metadef.org")
  end
end
