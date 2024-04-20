def kanjibreakdown [kanji: string] -> list {
    const qprefix = '.col-lg-6 > .kanjiItem'
    const qmid    = ' > .kanjiBreakdownIndent > .kanjiItem'
    const qsuffix = ' > div > a'
    let url = ('https://www.kakimashou.com/dictionary/character/' + $kanji)

    mut result = [(http get $url | query web --query ($qprefix + $qsuffix) | flatten)]

    mut run = true
    mut counter = 1

    while $run {
        mut query = $qprefix
        for i in 1..$counter {
            $query = ($query + $qmid)
        }
        $query = ($query + $qsuffix)
        let parts = (http get $url | query web --query $query | flatten)
        if ($parts | length) == 0 {
            $run = false 
        } else {
            $result = ($result | prepend $parts | flatten) 
        }
        $counter = $counter + 1
    }

    $result
}
