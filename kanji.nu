http get (['https://jisho.org/search/','%23kanji'] | str join '日') | query web --query '.dictionary_entry.on_yomi dd, .dictionary_entry.on_yomi dt' | str trim | group 2 | where { |x| $x.0.0 == 'Parts:' } | get 0.1 | filter { |x| $x | is-not-empty }
