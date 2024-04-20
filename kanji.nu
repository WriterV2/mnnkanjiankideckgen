def kanji-breakdown [kanji: string, existinglist: list<string> = []] -> list {
    const qprefix = '.col-lg-6 > .kanjiItem'
    const qmid    = ' > .kanjiBreakdownIndent > .kanjiItem'
    const qsuffix = ' > div > a'
    let url = ('https://www.kakimashou.com/dictionary/character/' + $kanji)

    mut result = [(http get $url | query web --query ($qprefix + $qsuffix) | flatten)]

    mut run = true
    mut counter = 1

    while $run {
        mut query = $qprefix
        for i in 1..$counter { $query = ($query + $qmid) }
        $query = ($query + $qsuffix)
        let parts = (http get $url | query web --query $query | flatten)
        if ($parts | length) == 0 {
            $run = false 
        } else {
            for part in $parts {
                if ($part not-in ($result ++ $existinglist)) {
                    $result = ($result | prepend $part | flatten)
                }
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
