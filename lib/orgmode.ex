defmodule Orgmode do
  import ExEarlyRet
  import Orgmode.Error
  use Bang

  @moduledoc """
  Documentation for `Orgmode`.
  """

  bang("parse/1 parse/2")

  def parse(document, filename \\ nil) do
    earlyret do
      {status, lexed} = Orgmode.Lexer.lex(document)

      ret_if status == :error do
        {:error, lexed}
      end

      {status, parsed} = Orgmode.Parser.parse(lexed)

      ret_if status == :error do
        {:error, parsed}
      end

      if filename != nil do
        parsed = %{parsed | metadata: Map.put_new(parsed[:metadata], :title, filename)}
      end

      {:ok, parsed}
    end
  end

  bang("parse_file/1")

  def parse_file(filename) do
    earlyret do
      ret_if not File.exists?(filename) do
        {:error, "Org-mode file \"#{filename}\" does not exist."}
      end

      file_contents = File.read(filename)

      ret_if file_contents |> elem(0) == :error do
        file_contents
      end

      file_contents = file_contents |> elem(1)

      parse(file_contents)
    end
  end
end
