xquery version "3.1";

  (:declare boundary-space preserve;:)
(:  LIBRARIES  :)
  import module namespace mrng="http://digitalhumanities.org/dhq/ns/meta-relaxng"
    at "../apps/lib/relaxng.xql";
(:  NAMESPACES  :)
  declare default element namespace "http://digitalhumanities.org/dhq/ns/biblio";
  declare namespace array="http://www.w3.org/2005/xpath-functions/array";
  declare namespace map="http://www.w3.org/2005/xpath-functions/map";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
(:  OPTIONS  :)
  declare option output:media-type "text/xml";
  declare option output:method "xml";

(:~
  
  
  @author Ashley M. Clark
  2020
 :)
 
 declare context item external := doc("../zotero_testing/dhq-biblio_genres.xml");
 
(:  VARIABLES  :)
  declare variable $xsl-crosswalk-location := "../apps/transforms/zotero-tei-to-biblio-items.xsl";


(:  FUNCTIONS  :)
  
  declare function local:get-corresponding-biblio-genre($biblStruct as element(tei:biblStruct)) {
    let $genreMaps := (
        map {
          'biblioGenre': 'ArchivalItem',
          'zoteroType': local:is-of-type(?, 'manuscript')
        }, map {
          'biblioGenre': 'Artwork',
          'zoteroType': local:is-of-type(?, 'artwork')
        }, map {
          'biblioGenre': 'BlogEntry',
          'zoteroType': local:is-of-type(?, ('blogPost', 'podcast'))
        }, map {
          'biblioGenre': 'Book',
          'zoteroType': local:is-of-type(?, 'book')
        }, map {
          'biblioGenre': 'BookInSeries',
          'zoteroType': local:is-of-type(?, ()) (: book? :)
        }, map {
          'biblioGenre': 'BookSection',
          'zoteroType': local:is-of-type(?, 'bookSection')
        }, map {
          'biblioGenre': 'ConferencePaper',
          'zoteroType': local:is-of-type(?, ('conferencePaper'))
        }, map {
          'biblioGenre': 'JournalArticle',
          'zoteroType': local:is-of-type(?, ('journalArticle', 'magazineArticle'))
        }, map {
          'biblioGenre': 'Other',
          'zoteroType': local:is-of-type(?, ())
        }, map {
          'biblioGenre': 'PhysicalMedia',
          'zoteroType': local:is-of-type(?, ())
        }, map {
          'biblioGenre': 'Posting',
          'zoteroType': local:is-of-type(?, 'forumPost')
        }, map {
          'biblioGenre': 'PublicGov',
          'zoteroType': local:is-of-type(?, ('bill', 'case', 'hearing', 'patent', 'statute'))
        }, map {
          'biblioGenre': 'Report',
          'zoteroType': local:is-of-type(?, 'report')
        }, map {
          'biblioGenre': 'Series',
          'zoteroType': local:is-of-type(?, ())
        }, map {
          'biblioGenre': 'Thesis',
          'zoteroType': local:is-of-type(?, 'thesis')
        }, map {
          'biblioGenre': 'VideoGame',
          'zoteroType': local:is-of-type(?, ())
        }, map {
          'biblioGenre': 'WebSite',
          'zoteroType': local:is-of-type(?, 'webpage')
        }
      )
    let $proposedGenre := $genreMaps[?zoteroType($biblStruct)][1]?biblioGenre
    return
      if ( exists($proposedGenre) ) then
        $proposedGenre
      else 'BiblioItem'
  };
  
  declare function local:is-of-type($biblStruct as element(tei:biblStruct), $types 
     as xs:string*) as xs:boolean {
    $biblStruct/@type = $types
  };


(:  MAIN QUERY  :)

let $zoteroEntries := //tei:body/tei:listBibl/tei:biblStruct
(: Test for fn:transform(). If it's not available, use the BaseX version. :)
let $transform := function($map as map(xs:string, item()*)) {
    let $w3cFn := function-lookup(xs:QName('fn:transform'), 1)
    let $basexFn := 
      function-lookup(QName('http://basex.org/modules/xslt', 'xslt:transform'), 3)
    return
      if ( exists($w3cFn) ) then $w3cFn($map)?output
      else if ( exists($basexFn) ) then
        $basexFn($map?source-node, $map?stylesheet-location, $map?stylesheet-params)
      else ()
  }
return
  <BiblioSet>
    <!-- Drop area for harvestable entries. -->
    <BiblioSet ready="true"> </BiblioSet>
    
    {
      for $record in $zoteroEntries
      let $genre := local:get-corresponding-biblio-genre($record)
      return (
          $transform( map {
              'stylesheet-location': $xsl-crosswalk-location,
              'source-node': $record,
              'stylesheet-params': map { QName((),'biblio-genre'): $genre }
            }),
          text { "&#xa;" }
        )
    }
  </BiblioSet>
