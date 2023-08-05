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

  test "Combines paragraphs" do
    assert Orgmode.parse!("""
           First paragraph

           Second paragraph
           Second line of second paragraph
           """) == %{
             metadata: %{},
             sections: [
               %{
                 content: [
                   paragraph: "First paragraph",
                   paragraph: "Second paragraph\nSecond line of second paragraph"
                 ]
               }
             ]
           }
  end

  test "Parses tables" do
    assert Orgmode.parse!("""
           |col1|col2|
           |yep |nope|
           """) == %{
             metadata: %{},
             sections: [
               %{
                 content: [
                   table: %{
                     cells: [
                       ["col1", "col2"],
                       ["yep", "nope"]
                     ]
                   }
                 ]
               }
             ]
           }
  end
end
