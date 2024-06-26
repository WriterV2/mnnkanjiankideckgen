def log [msg: string] {
    const logfilename = 'kanji.log'
    print $msg
    if (not ($logfilename | path exists)) {
        touch $logfilename
    }
    open $logfilename | append ('[' + (date now | into string) + '] ' + $msg) | str trim | save -f $logfilename
}

def kanji-breakdown [kanji: string, existinglist: list<string> = []] -> list<string> {
    const qprefix = '.col-lg-6 > .kanjiItem'
    const qmid    = ' > .kanjiBreakdownIndent > .kanjiItem'
    const qsuffix = ' > div > a'

    if not ((is-kanji $kanji) and ($kanji | str length) > 1) { return }

    log ("Breaking down Kanji: " + $kanji)
    let url = ('https://www.kakimashou.com/dictionary/character/' + $kanji)
    try {
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
                    log ("- " + $part)
                    $result = ($result | prepend $part | flatten)
                }
            }
            $counter += 1

        }
        log ("Breaking down Kanji " + $kanji + $"...(ansi g)done(ansi reset)\n")
        if ($result | length) == 1 { return ($existinglist | append $kanji) }
        $existinglist ++ $result
    } catch {
        log ("Breaking down Kanji " + $kanji + $"...(ansi r)failed(ansi reset)\n")
        return $existinglist
    }
}

def dissected-kanji-list [vocab_kanji: list<string>] -> list<string> {
    mut result = []
    for kanji in $vocab_kanji {
        if ($kanji not-in $result) {
            $result = (kanji-breakdown $kanji $result)
            sleep 1sec
        }
    }
    $result
}

def is-kanji [kanji: string] -> boolean {
    sleep 1sec
    try {
        return (http get (('https://www.kakimashou.com/dictionary/character/' + $kanji)) | query web --query 'strong' | flatten | any { |s| $s == 'Jouyou' })
    } catch {
        log ($kanji + ' not recognized as character by kakimashou')
        return false
    }
    return false
}

def get-kanji-from-vocab [csv_filename: string] -> list<string> {
    mut result = []
    mut checked_chars = []
    log ("Extracting Kanji from " + $csv_filename)
    for vocab in (open $csv_filename| flatten) {
        for character in ($vocab.column0 | split chars -g) {
            if (($character not-in ($result | append $checked_chars)) and (is-kanji $character)) {
                $result = ($result | append $character)
                log ("-> extracted Kanji: " + $character)
            }
            $checked_chars = ($checked_chars | append $character)
        }
    }
    log $"Extracting Kanji...(ansi g)done(ansi reset)\n"
    $result
}

def add-details-to-kanji [final_kanji: list<string>] -> table {
    $final_kanji | wrap 'Front' | upsert 'Back' { |it| 
        sleep 1sec
        log ("Adding meaning for Kanji: " + $it.Front)
        let kanjidetails = (http get ('https://www.kakimashou.com/dictionary/character/' + $it.Front) | query web --query '.col-lg-9.col-md-9.col-sm-10 > h3') 
        if ($kanjidetails | length) > 0 {
            $kanjidetails | get 0 | get 0 | str trim
        } else {
            log ($"(ansi yb)Warning(ansi reset): No meanings and readings found for " + $it.Front + $"\nThe value was set to (ansi defb)'EMPTY'(ansi reset). Please edit the value manually.")
            "EMPTY"
        }
    }
}

# EXAMPLE
let kanjifromvocab = get-kanji-from-vocab testlist_vocabs.csv
let dissectedkanjilist = dissected-kanji-list $kanjifromvocab
let finallist = add-details-to-kanji $dissectedkanjilist 
$finallist | to csv -n | save -f 'testdeck.csv'
