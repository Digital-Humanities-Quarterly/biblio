xquery version "3.1";

  (:declare boundary-space preserve;:)
(:  LIBRARIES  :)
(:  NAMESPACES  :)
  (:declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";:)
  declare namespace array="http://www.w3.org/2005/xpath-functions/array";
  declare namespace map="http://www.w3.org/2005/xpath-functions/map";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
(:  OPTIONS  :)
  (:declare option output:indent "no";:)

(:~
  
  
  @author Ash Clark
  2022
 :)
 
(:  VARIABLES  :)
  

(:  FUNCTIONS  :)
  

(:  MAIN QUERY  :)

for $alphaGrp in db:open('biblio-public')
group by $firstLetter := lower-case(substring($alphaGrp/*/@ID/data(.), 1, 1))
order by $firstLetter
let $filename := 
 concat(db:property('biblio-all', 'inputpath'),'Biblio-',upper-case($firstLetter),'.xml')
let $biblioSet := document {
    <?xml-model href="../schema/dhqBiblio.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"?>,
    <BiblioSet xmlns="http://digitalhumanities.org/dhq/ns/biblio" ready="yes">
    { 
      for $entry in $alphaGrp
      let $id := $entry/*/@ID/data(.)
      order by lower-case($id)
      return $entry
    }
    </BiblioSet>
  }
return file:write($filename, $biblioSet, map {
    'method': 'xml',
    'indent': 'yes',
    'omit-xml-declaration': 'no',
    'encoding': 'UTF-8'
  })

