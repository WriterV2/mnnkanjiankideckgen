def kanji-breakdown [kanji: string, existinglist: list<string> = []] -> list {
    const qprefix = '.col-lg-6 > .kanjiItem'
    const qmid    = ' > .kanjiBreakdownIndent > .kanjiItem'
    const qsuffix = ' > div > a'

    if not (is-kanji $kanji) { return }
    let url = ('https://www.kakimashou.com/dictionary/character/' + $kanji)
    mut result = [(http get $url | query web --query ($qprefix + $qsuffix) | flatten)]

    mut run = true
    mut counter = 1

    while $run {
        mut query = $qprefix
        for i in 1..$counter { $query = ($query + $qmid) }
        $query = ($query + $qsuffix)
        let parts = (http get $url | query web --query $query | flatten)
        if ($parts | length) == 0 { $run = false; break }
        for part in $parts {
            if ($part not-in ($result ++ $existinglist)) {
                $result = ($result | prepend $part | flatten)
            }
        }
        $counter += 1
    }

    $existinglist ++ $result
}

def dissected-kanji-list [vocab_kanji: list<string>] -> list {
    mut result = []
    for kanji in $vocab_kanji {
        $result = (kanji-breakdown $kanji $result)
        sleep 1sec
    }
    $result
}

def is-kanji [kanji: string] -> boolean {
    ((http get ('https://lingweb.eva.mpg.de/kanji/cgi-bin/kanji.pl?SuchBegriff=' + $kanji) |
        query web --query '.japlem') | length) > 0
}

def get-kanji-from-vocab [csv_filename: string] -> list {
    mut result = []
    for vocab in (open $csv_filename| flatten) {
        for character in ($vocab.column0 | split chars -g) {
            sleep 1sec
            if (($character not-in $result) and (is-kanji $character)) {
                $result = ($result | append $character)
            }
        }
    }
    $result
}
