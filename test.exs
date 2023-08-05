#IO.puts(inspect(Orgmode.parse("#+TITLE: Big wow, Much title!")))

require Orgmode

Orgmode.parse_file!("README.org")
