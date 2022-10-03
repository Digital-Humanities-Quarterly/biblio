xquery version "3.1";

  (:declare boundary-space preserve;:)
(:  LIBRARIES  :)
  import module namespace dbfx="http://digitalhumanities.org/dhq/ns/biblio/lib"
    at "/Users/aclark/Documents/DHQ/biblio/apps/lib/biblio-functions.xql";
(:  NAMESPACES  :)
  declare namespace array="http://www.w3.org/2005/xpath-functions/array";
  declare namespace dbib="http://digitalhumanities.org/dhq/ns/biblio";
  declare namespace map="http://www.w3.org/2005/xpath-functions/map";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
(:  OPTIONS  :)
  declare option output:method "text";

(:~
  
  
  @author Ash Clark
  2022
 :)
 
(:  VARIABLES  :)
  
  declare variable $save-to-directory external := 
    'file:///Users/aclark/Documents/DHQ/';

(:  FUNCTIONS  :)
  
  declare function local:make-row($cells as xs:string*) {
    string-join($cells, '	')
  };
  
  declare function local:make-tsv($filename as xs:string, $header-row as xs:string*, $rows as xs:string*) {
    let $useHeader := local:make-row($header-row)
    let $tsv := string-join(($useHeader, $rows), '
')
    return file:write-text(concat($save-to-directory,$filename), $tsv)
  };

(:  MAIN QUERY  :)

let $biblioEntries := dbfx:bibliographic-records()
let $biblioTSV :=
  let $headerRow := (
      'Biblio ID', 'Pub. Year', 'Contributors', 'Title', 'Genre', 'Macro Title'
    )
  let $biblioRows :=
    for $entry in $biblioEntries
    let $id := $entry/@ID/data(.)
    let $year := ($entry//dbib:date)[1]
    let $authors :=
      let $names :=
        for $contributor in $entry/(dbib:author | dbib:translator | dbib:editor)
        return ($contributor/(dbib:familyName, dbib:corporateName))[1]
      return string-join($names, ' | ')
    let $title := $entry/dbib:title/normalize-space()
    let $genre := $entry/local-name()
    let $macroEntity := ($entry/*/dbib:title/normalize-space(), '')[1]
    let $cells := ( $id, $year, $authors, $title, $genre, $macroEntity )
    order by lower-case($id)
    return local:make-row($cells)
  return local:make-tsv('dhq-biblio-entries.tsv', $headerRow, $biblioRows)
let $articleSet := dbfx:article-set()[?pubDate()[exists(.) and . ne '']]
let $articleTSV :=
  let $headerRow := (
      'Article ID', 'Pub. Year', 'Volume and Issue', 'Authors', 'Title', 'Teaser', '# of Cited Works' 
    )
  let $articleRows :=
    for $articleMap in $articleSet
    let $id := ($articleMap?id, '')[1]
    let $authors := string-join($articleMap?authors(), " | ")
    let $title := ($articleMap?title(), '')[1]
    let $volume := $articleMap?volume()
    let $issue := $articleMap?issue()
    let $volIssue := 
      if ( exists($volume) ) then
        concat($volume,'.',$issue)
      else ''
    let $year := 
      let $date := $articleMap?pubDate()
      return
        if ( empty($date) ) then ''
        else substring($date, 1, 4)
    let $teaser := $articleMap?teaser()
    let $numCited := $articleMap?bibls()?total cast as xs:string
    let $cells := ($id, $year, $volIssue, $authors, $title, $teaser, $numCited)
    order by $volume, $issue
    return local:make-row($cells)
  return local:make-tsv('dhq-articles.tsv', $headerRow, $articleRows)
let $citationTSV :=
  let $headerRow := ( "DHQ Article ID", "Biblio Entry ID", "# of References" )
  let $citationRows :=
    for $article in $articleSet
    let $keyedBibls := $article?bibls()?keyed?*
    order by $article?id
    for $bibl in $keyedBibls
    let $cells := ( $article?id, $bibl?biblioId, $bibl?references cast as xs:string )
    return local:make-row($cells)
  return local:make-tsv('dhq-citations.tsv', $headerRow, $citationRows)
return ()
