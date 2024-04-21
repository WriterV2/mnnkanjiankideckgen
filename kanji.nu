def kanji-breakdown [kanji: string, existinglist: list<string> = []] -> list<string> {
    const qprefix = '.col-lg-6 > .kanjiItem'
    const qmid    = ' > .kanjiBreakdownIndent > .kanjiItem'
    const qsuffix = ' > div > a'

    if not ((is-kanji $kanji) and (($kanji | str length) > 1)) { return }
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
            if ($part not-in ($result ++ $existinglist) and (is-kanji $part)) {
                $result = ($result | prepend $part | flatten)
            }
        }
        $counter += 1
    }

    if ($result | length) == 1 { return ($existinglist | append $kanji) }
    $existinglist ++ $result
}

def dissected-kanji-list [vocab_kanji: list<string>] -> list<string> {
    mut result = []
    for kanji in $vocab_kanji {
        $result = (kanji-breakdown $kanji $result)
        sleep 1sec
    }
    $result
}

def is-kanji [kanji: string] -> boolean {
    sleep 1sec
    ((http get ('https://lingweb.eva.mpg.de/kanji/cgi-bin/kanji.pl?SuchBegriff=' + $kanji) |
        query web --query '.japlem') | length) > 0
}

def get-kanji-from-vocab [csv_filename: string] -> list<string> {
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

def add-details-to-kanji [final_kanji: list<string>] -> table {
    #mut result = $final_kanji | wrap 'Front' | insert 'Back' ''
    $final_kanji | wrap 'Front' | upsert 'Back' { |it| 
        sleep 1sec
        let kanjidetails = (http get ('https://lingweb.eva.mpg.de/kanji/cgi-bin/kanji.pl?SuchBegriff=' + $it.Front) | query web --query '.smlink + table .japsm, .smlink + table .deu') 
        if ($kanjidetails | length) > 0 {
            $kanjidetails | each { str join } | group 2 | each { str join ' - ' } | str join "\n" 
        } else {
            "Nothing found. Please set the value manually."
        }
    }
}
