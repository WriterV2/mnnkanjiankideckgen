def kanjicomponents [kanji: string] -> list {
    sleep 3sec
    try {
        [$kanji] | prepend (http get (['https://jisho.org/search/','%23kanji'] | str join $kanji) | query web --query '.dictionary_entry.on_yomi dd, .dictionary_entry.on_yomi dt' | str trim | group 2 | where { |x| $x.0.0 == 'Parts:' } | get 0.1 | compact --empty)
    }
}

def kanjibreakdown [kanji: string] -> list {
    mut l = (kanjicomponents $kanji)

    mut run = true
    while $run {
        mut stop = true
        for k in $l {
            let kl = (kanjicomponents $k)
            for letter in $kl {
                if ($letter not-in $l) and ($letter | is-not-empty) { 
                    $l = ($l | prepend $letter) 
                    $stop = false
                }
            }
        }
        if $stop { $run = false }
    }
    $l
}

# TODO: Try with kakimashou.com for potentially better and more direct kanji breakdowns and compare
