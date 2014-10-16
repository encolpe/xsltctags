<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:dtd="http://saxon.sf.net/dtd"
  xmlns:func="http://exslt.org/functions"
  xmlns:exsl="http://exslt.org/common"
  xmlns:set="http://exslt.org/sets"
  xmlns:str="http://exslt.org/strings"
  version="1.0">

<!--
   -  This is XSLT 1.0.
   -  I made best efforts to write XSLTctags to run on a number of XSLT processors.
   -  (therefore XSLT 1.0 and not 2.0).  But because of some differences, I had to
   -  create separate XSLT with processor specific differences.
   -  The result is versions for xsltproc and saxon. (adapting to others should be
   -  straight forward if you can find or implement a line-number() function.
   -->

  <!--
     - Note: saxon and dtd namespaces are declared above, not because this template must use saxon, but rather
     - because there maybe some tagfields related to saxon extensions in XSLT being processed
     - with XSLTctags.
     -
     - Similarly, the func namespace is declared above, not because this template must use EXSLT, but rather
     - because there maybe some tagfields related to EXSLT's function extension in the XSLT being processed
     - with XSLTctags.
     -
     - Extension functions in the namespaces set and str are being used in this stylesheet.
     - Note: str:tokenize() is implemented as a function in the xsltctags-saxon.xsl stylesheet using
     -       XPath 2.0's tokenize() function because it is not implemented in saxon.
     - Note: exsl:node-set() is implemented in saxon and xsltproc
     -
     - The XSLT stylesheets that are processor specific have the processor name in them.
     - ie [xsltctags-saxon.xsl] and [xsltctags-xsltproc.xsl].  These stylesheets import
     - this stylesheet.
     -->

  <!--See ctag format http://ctags.sourceforge.net/FORMAT -->
  <!--Also see http://ctags.sourceforge.net/ctags.html -->
  <!--Also see :help ctags in vim-->

  <!--See: http://www.dpawson.co.uk/xsl/sect2/N2602.html#d3862e19-->

  <!--To do: tagfield "file" for tags that can only be accessed in the scope of the current file-->

  <!--to do: give functions with same name, but different parameter sets, different tagnames???-->

  <!--to do: Create ex command for reading in xsltctags for current file into a scratch buffer. To help with debugging.-->

  <xsl:import href="getXPath.xsl"/>
  <xsl:import href="simplifyPath.xsl"/>
  <xsl:import href="str.tokenize2.template.xsl"/>

  <xsl:output
    method="text"
    encoding="UTF-8"
    />

  <!--Stylesheet input parameters designed so user can specify xsl items to be tagged. I expect most users will use the defaults.-->
  <!--The appropriate attribute (@name, @href, @select or @match) will be used to define the 'ctag' tagname field.-->
  <!--@mode will also be used in the 'ctag' tagname field when available-->
  <!--Using a ; delimited string for convenience of passing in list of items to tag as a single string-->
  <xsl:param name="itemsToTag_name" select="'xsl:template;xsl:function;func:function;xsl:variable;xsl:param;xsl:key;xsl:namespace;xsl:attribute-set;xsl:character-map;xsl:call-template;xsl:element;xsl:attribute;xsl:processing-instruction;saxon:assign;saxon:call-template'"/>
  <xsl:param name="itemsToTag_href" select="'xsl:import;xsl:include;xsl:result-document'"/>
  <xsl:param name="itemsToTag_select" select="'xsl:apply-templates;xsl:apply-imports'"/>
  <xsl:param name="itemsToTag_match" select="'xsl:template'"/>
  <xsl:param name="tagSaxonDocType" select="'true'"/>  <!--Special Case pass in string 'true' to tag occurances of this saxon xslt extension-->
  <xsl:param name="tagxslinclude_content" select="'true'"/>
  <xsl:param name="tagxslimport_content" select="'true'"/>

  <!--itemsToTag_anonymous: Not actually tagged... but will be referenced in scope of other tags if applicable-->
  <!--This is important because xsl:variable can be defined inside a for-each... and have a different value through each iteration-->
  <xsl:param name="itemsToTag_anonymous" select="'xsl:for-each;xsl:for-each-group;xsl:if;xsl:when;xsl:choose'"/>

  <!--capture special characters in variables to simplify escaping later-->
  <xsl:variable name="DoubleQuote" select="'&#34;'"/>
  <xsl:variable name="SingleQuote" select='"&#39;"'/>
  <xsl:variable name="CurlyLeftBracket" select="'&#123;'"/>
  <xsl:variable name="CurlyRightBracket" select="'&#125;'"/>
  <xsl:variable name="whitespace" select="'&#x20;&#xa;&#xd;&#x09;'"/> <!--space,line feed,carriage return,tab-->
  <xsl:variable name="EMPTY" select="/.."/>  <!--The empty node-set-->

  <!--Below $kinds is an index/listing of the different tag kinds.-->
  <!--The information is compiled in $kinds because it needs to be reused frequently in this (xsltctags-common.xsl) stylesheet-->
  <!--I chose the letter and shortName (singular) values somewhat arbitrarily...-->
  <!--but tried to make the letters correspond to the name of the primary element.-->
  <!--Note some kinds have multiple element types.-->
  <xsl:variable name="kinds">
    <kind letter="S" shortName="stylesheet" pluralName="Stylesheet"><element>xsl:stylesheet</element><element>xsl:transform</element></kind>
    <kind letter="r" shortName="resultDocument" pluralName="Result Documents"><element type="href">xsl:result-document</element></kind>
    <!-- saxon:docytype, is special. Get's name from saxon:doctype/dtd:doctype/@name  So I don't define element/@type. Will deal with it specially-->
    <kind letter="d" shortName="saxonDocType" pluralName="Saxon Doctypes"><element>saxon:doctype</element></kind>
    <kind letter="i" shortName="include" pluralName="Includes"><element type="href">xsl:include</element></kind>
    <kind letter="o" shortName="import" pluralName="Imports"><element type="href">xsl:import</element></kind>
    <kind letter="p" shortName="parameter" pluralName="Parameters"><element type="name">xsl:param</element></kind>
    <kind letter="v" shortName="variable" pluralName="Variables"><element type="name">xsl:variable</element></kind>
    <kind letter="x" shortName="saxonAssign" pluralName="Saxon Assigns"><element type="name">saxon:assign</element></kind>
    <kind letter="k" shortName="key" pluralName="Keys"><element type="name">xsl:key</element></kind>
    <kind letter="t" shortName="attributeSet" pluralName="Attribute Sets"><element type="name">xsl:attribute-set</element></kind>
    <kind letter="h" shortName="characterMap" pluralName="Character Maps"><element type="name">xsl:character-map</element></kind>
    <kind letter="s" shortName="nameSpace" pluralName="Name Spaces"><element type="name">xsl:namespace</element></kind>
    <kind letter="e" shortName="element" pluralName="Elements"><element type="name">xsl:element</element></kind>
    <kind letter="b" shortName="attribute" pluralName="Attributes"><element type="name">xsl:attribute</element></kind>
    <kind letter="n" shortName="namedTemplate" pluralName="Named Templates"><element type="name">xsl:template</element></kind>
    <kind letter="m" shortName="matchedTemplate" pluralName="Matched Templates"><element type="match">xsl:template</element></kind>
    <kind letter="f" shortName="function" pluralName="Functions"><element type="name">xsl:function</element><element type="name">func:function</element></kind>
    <kind letter="a" shortName="appliedTemplate" pluralName="Applied Templates"><element type="select">xsl:apply-templates</element></kind>
    <kind letter="j" shortName="appliedImport" pluralName="Applied Imports"><element type="select">xsl:apply-imports</element></kind>
    <kind letter="c" shortName="calledTemplate" pluralName="Called Templates"><element type="name">xsl:call-template</element></kind>
    <!--Note: saxon:call-template/@name is typically created using an attribute template-->
    <!--The @name may not be defined in a predictable way that is easy to parse... so I may remove this.-->
    <!--Could be in <saxon:call-template name={here}>, or <xsl:attribute name="name">here with potential xsl inside...</xsl:attribute> or <xsl:attribute name="" select="here"/>-->
    <kind letter="l" shortName="saxonCalledTemplate" pluralName="Saxon Called Templates"><element type="name">saxon:call-template</element></kind>
    <kind letter="g" shortName="processingInstruction" pluralName="Processing Instructions"><element type="name">xsl:processing-instruction</element></kind>
  </xsl:variable>

  <!--$validKinds filters out only the kinds that are in $itemsToTag_name, $itemsToTag_href, $itemsToTag_select, $itemsToTag_match etc...-->
  <!--Only the kinds in $validKinds will be tagged-->
  <xsl:variable name="validKinds" select="exsl:node-set($kinds)[ kind/element/text()[contains($itemsToTag_name,.)] or
                                                                 kind/element/text()[contains($itemsToTag_href,.)] or
                                                                 kind/element/text()[contains($itemsToTag_select,.)] or
                                                                 kind/element/text()[contains($itemsToTag_match,.)] or
                                                                 (kind/element/text() = 'saxon:doctype' and $tagSaxonDocType='true' ) or
                                                                 (kind/element/text() = 'xsl:include' and $tagxslinclude_content='true' ) or
                                                                 (kind/element/text() = 'xsl:import' and $tagxslimport_content='true' ) or
                                                                 (kind/element/text() = 'xsl:stylesheet') or
                                                                 (kind/element/text() = 'xsl:transform')
                                                               ]
                                                               "/>

  <xsl:template name="getKindLetter">
    <xsl:param name="element" select="current()"/> <!--default is current() context if not called with param $element-->

    <xsl:variable name="kinds" select="$validKinds"/>

    <xsl:choose>
      <xsl:when test="$element/@name">
        <xsl:value-of select="$kinds/*[element/text()=name($element)]
                                         [element/@type='name']
                                    /@letter[1]"/>
      </xsl:when>
      <xsl:when test="$element/@match">
        <xsl:value-of select="$kinds/*[element/text()=name($element)]
                                         [element/@type='match']
                                    /@letter[1]"/>
      </xsl:when>
      <xsl:when test="$element/@select">
        <xsl:value-of select="$kinds/*[element/text()=name($element)]
                                         [element/@type='select']
                                    /@letter[1]"/>
      </xsl:when>
      <xsl:when test="$element/@href">
        <xsl:value-of select="$kinds/*[element/text()=name($element)]
                                         [element/@type='href']
                                    /@letter[1]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$kinds/*[element/text()=name($element)]
                                    /@letter[1]"/>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:template> <!-- end of xsl:template name="getKindLetter" -->

  <xsl:template name="getKindShortName">
    <xsl:param name="element" select="current()"/> <!-- default is current() context if not called with param $element-->

    <xsl:variable name="kinds" select="$validKinds"/>

    <xsl:choose>
      <xsl:when test="$element/@name">
        <xsl:value-of select="$kinds/kind[element/text()=name($element)]
                                         [element/@type='name']
                                   /@shortName[1]"/>
      </xsl:when>
      <xsl:when test="$element/@match">
        <xsl:value-of select="$kinds/kind[element/text()=name($element)]
                                         [element/@type='match']
                                    /@shortName[1]"/>
      </xsl:when>
      <xsl:when test="$element/@select">
        <xsl:value-of select="$kinds/kind[element/text()=name($element)]
                                         [element/@type='select']
                                    /@shortName[1]"/>
      </xsl:when>
      <xsl:when test="$element/@href">
        <xsl:value-of select="$kinds/kind[element/text()=name($element)]
                                         [element/@type='href']
                                    /@shortName[1]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$kinds/kind[element/text()=name($element)]
                                    /@shortName[1]"/>
      </xsl:otherwise>
    </xsl:choose>

    </xsl:template> <!-- end of xsl:template name="getKindShortName" -->

  <xsl:variable name="tags">
    <xsl:variable name="startRoute">
      <href>
        <xsl:attribute name="kind">
          <xsl:call-template name="getKindShortName">
            <xsl:with-param name="element" select="/*[1]"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="tagName">
          <xsl:call-template name="escapeTagField">
            <xsl:with-param name="input">
              <xsl:value-of select="concat('doc(',$SingleQuote)"/>
              <xsl:call-template name="simplifyPath">
                <xsl:with-param name="input" select="$fileName"/>
              </xsl:call-template>
              <xsl:value-of select="concat($SingleQuote,')')"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="value">
          <xsl:call-template name="simplifyPath">
            <xsl:with-param name="input" select="$fileName"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="originalValue">
          <xsl:value-of select="$fileName"/>
        </xsl:attribute>
      </href>
    </xsl:variable>

    <xsl:call-template name="getTags">
      <xsl:with-param name="xslDocument" select="/"/>
      <xsl:with-param name="route" select="exsl:node-set($startRoute)/href"/>
      <xsl:with-param name="itemsToTag_name" select="str:tokenize($itemsToTag_name,';')"/>
      <xsl:with-param name="itemsToTag_href" select="str:tokenize($itemsToTag_href,';')"/>
      <xsl:with-param name="itemsToTag_select" select="str:tokenize($itemsToTag_select,';')"/>
      <xsl:with-param name="itemsToTag_match" select="str:tokenize($itemsToTag_match,';')"/>
    </xsl:call-template>
  </xsl:variable> <!-- end of xsl:variable name="tags" -->

  <xsl:template name="getTags">
    <!--getTags calls itself recursively for each xsl:import and xsl:include-->
    <xsl:param name="xslDocument"/>
    <xsl:param name="route"/> <!-- getTags calls itself recursively for the xsl:include and xsl:import tags. $route is used to prevent circular walks.-->

    <!--The following parameters should each be a node-set() or node()*, and not the ; delimited string-->
    <xsl:param name="itemsToTag_name"/>
    <xsl:param name="itemsToTag_href"/>
    <xsl:param name="itemsToTag_select"/>
    <xsl:param name="itemsToTag_match"/>

    <!--tag occurances of each element type in $validKinds-->
    <!--Note: If @type is not defined in kind/element, then we don't need to look for an attribute with-->
    <!--this name.-->
    <xsl:for-each select="$validKinds/kind/element">
      <xsl:apply-templates select="$xslDocument//*[name()=current()/text()]
                                                  [@*[name()=current()/@type] or not(current()/@type)]
                                                  ">
        <xsl:with-param name="route" select="$route"/>
      </xsl:apply-templates>
    </xsl:for-each>

    <xsl:variable name="includeNewChild_hrefs">
      <xsl:if test="$tagxslinclude_content='true'">
        <xsl:call-template name="getChildhrefs">
          <xsl:with-param name="elementType" select="'xsl:include'"/>
          <xsl:with-param name="xslDocument" select="$xslDocument"/>
          <xsl:with-param name="route" select="$route"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="importNewChild_hrefs">
      <xsl:if test="$tagxslimport_content='true'">
        <xsl:call-template name="getChildhrefs">
          <xsl:with-param name="elementType" select="'xsl:import'"/>
          <xsl:with-param name="xslDocument" select="$xslDocument"/>
          <xsl:with-param name="route" select="$route"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>

    <!--Note: Route parameter is the exact route that has been followed.-->
          <!--Each thread of walked paths won't repeat walking to other paths along the route. But it may repeat walking to places that-->
          <!--other threads walked down.-->
          <!--Don't optimize and add sibling hrefs to the route because route is used to decode the path walked in the current thread.-->
    <xsl:for-each select="exsl:node-set($includeNewChild_hrefs)/href | exsl:node-set($importNewChild_hrefs)/href">
      <!--current_new_href is re-constructed relative to the $currentDocument_href-->
      <xsl:call-template name="getTags">
        <!--Note in document(), 2nd parameter specifies a node who's document the new document's uri will be calculated relative to-->
        <!--to do: check if document is available... in xslt 1.0, see http://www.dpawson.co.uk/xsl/sect2/N2602.html#d3862e49-->
        <xsl:with-param name="xslDocument" select="document(@originalValue,$xslDocument)"/>  <!--I'd like to be able to use doc-available() but that would be xpath 2.0-->
        <!--note: For new $route, adding $new_hrefs because we're committed to visiting them with this call of getTags-->
        <xsl:with-param name="route" select="$route | ."/>
        <xsl:with-param name="itemsToTag_name" select="$itemsToTag_name"/>
        <xsl:with-param name="itemsToTag_href" select="$itemsToTag_href"/>
        <xsl:with-param name="itemsToTag_select" select="$itemsToTag_select"/>
        <xsl:with-param name="itemsToTag_match" select="$itemsToTag_match"/>
      </xsl:call-template>
    </xsl:for-each>

  </xsl:template> <!-- end of <xsl:template name="getTags"> -->

  <xsl:template name="getChildhrefs">
    <xsl:param name="elementType"/>
    <xsl:param name="xslDocument"/>
    <xsl:param name="route"/>
    <!--for each relative href-->
    <xsl:for-each select="$xslDocument//*[name()=$elementType]/@href[not(contains(.,':') or starts-with(.,'\') or starts-with(.,'/'))][not(starts-with(.,$CurlyLeftBracket))]">
      <xsl:variable name="simplifiedCurrent">
        <xsl:call-template name="simplifyPath">
          <xsl:with-param name="input" select="concat($route[last()]/@value,'/../',.)"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="not($simplifiedCurrent=$route/href/@value)">
        <href>
          <xsl:attribute name="kind">
            <xsl:call-template name="getKindShortName">
              <xsl:with-param name="element" select=".."/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="tagName">
            <xsl:call-template name="getTagName">
              <xsl:with-param name="element" select=".."/>
              <xsl:with-param name="route" select="$route"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="value">
            <xsl:value-of select="$simplifiedCurrent"/>
          </xsl:attribute>
          <xsl:attribute name="originalValue">
            <xsl:value-of select="."/>
          </xsl:attribute>
        </href>
      </xsl:if>
    </xsl:for-each>
    <!--for each absolute href-->
    <xsl:for-each select="$xslDocument/*[name()=$elementType]/@href[contains(.,':') or starts-with(.,'\') or starts-with(.,'/')][not(starts-with(.,$CurlyLeftBracket))]">
      <xsl:variable name="simplifiedCurrent">
        <xsl:call-template name="simplifyPath">
          <xsl:with-param name="input" select="."/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="not($simplifiedCurrent=$route/href/@value)">
        <href>
          <xsl:attribute name="kind">
            <xsl:call-template name="getKindShortName">
              <xsl:with-param name="element" select=".."/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="tagName">
            <xsl:call-template name="getTagName">
              <xsl:with-param name="element" select=".."/>
              <xsl:with-param name="route" select="$route"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:attribute name="value">
            <xsl:value-of select="$simplifiedCurrent"/>
          </xsl:attribute>
          <xsl:attribute name="originalValue">
            <xsl:value-of select="."/>
          </xsl:attribute>
        </href>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!--root template-->
  <xsl:template match="/">
    <!--Uses exsl:node-set() to interpret $tags as a set of nodes-->
    <xsl:call-template name="ctags_header"/>
    <!--output the sorted tag list-->
    <xsl:for-each select="exsl:node-set($tags)/tag">
      <xsl:sort select="@tagname" order="ascending"/>
      <xsl:apply-templates select="." mode="xmltag_to_ctagRecord"/>
    </xsl:for-each>
  </xsl:template> <!-- end of root template <xsl:template match="/"> -->

  <xsl:template name="ctags_header">
    <!--Output ctags file header-->

    <xsl:text>!_TAG_FILE_FORMAT</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>2</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>/2=extended format/</xsl:text>
    <xsl:text>&#xa;</xsl:text> <!--new line-->

    <xsl:text>!_TAG_FILE_SORTED</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>1</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>/0=unsorted, 1=sorted, 2=foldcase/</xsl:text>
    <xsl:text>&#xa;</xsl:text> <!--new line-->

    <xsl:text>!_TAG_PROGRAM_AUTHOR</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>Darcy Parker</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>/darcyparker@gmail.com/</xsl:text>
    <xsl:text>&#xa;</xsl:text> <!--new line-->

    <xsl:text>!_TAG_PROGRAM_NAME</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>XSLTctags</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>/XSLTctags used XSLT processor: </xsl:text>
    <xsl:value-of select="system-property('xsl:vendor')"/>
    <xsl:text>, version: </xsl:text>
    <xsl:value-of select="system-property('xsl:version')"/>
    <xsl:text>/</xsl:text>
    <xsl:text>&#xa;</xsl:text> <!--new line-->

    <xsl:text>!_TAG_PROGRAM_URL</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>https://github.com/darcyparker/xsltctags</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>/official site/</xsl:text>
    <xsl:text>&#xa;</xsl:text> <!--new line-->

    <xsl:text>!_TAG_PROGRAM_VERSION</xsl:text>
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>0.0</xsl:text> <!--Not really tracking the version yet...-->
    <xsl:text>&#x9;</xsl:text> <!--tab-->
    <xsl:text>//</xsl:text>
    <!--No new line here... it will be added before writing each new ctag record-->

  </xsl:template> <!-- end of <xsl:template name="ctags_header"> -->

  <!--Transform internal xml tag record to the 'extended' ctag record format-->
  <xsl:template match="tag" mode="xmltag_to_ctagRecord">
    <xsl:text>&#xa;</xsl:text> <!--Add a new line before starting new record-->

    <xsl:value-of select="@tagname"/>
    <xsl:text>&#x9;</xsl:text>

    <xsl:value-of select="@tagfile"/>
    <xsl:text>&#x9;</xsl:text>

    <xsl:value-of select="@tagaddress"/>
    <xsl:text>;"</xsl:text>

    <!--Added the kind extended tag. (Note it is not proceed with kind:)-->
    <xsl:if test="extendedFields/@kind!=''">
      <xsl:text>&#x9;</xsl:text>
      <xsl:value-of select="extendedFields/@kind"/>
    </xsl:if>

    <!--Next, add remaining extended fields-->
    <xsl:for-each select="extendedFields/@*[local-name()!='kind']">
      <xsl:text>&#x9;</xsl:text>
      <xsl:value-of select="local-name()"/>
      <xsl:if test=".!='' or local-name()='file'">
        <xsl:text>:</xsl:text>
        <xsl:value-of select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template> <!-- End of <xsl:template match="tag" mode="xmltag_to_ctagRecord"> -->

  <!--*******************************************-->
  <!--templates to create internal xml tag record-->
  <!--*******************************************-->

  <xsl:template match="*[@name | @match | @select | @href | dtd:doctype/@name] | xsl:stylesheet | xsl:transform">
    <xsl:param name="route"/>
    <!--if further than 1 item in the route and this is a stylesheet, then in this case there will already be-->
    <!--a tag with this name because it was imported/included.  So don't create another tag. This stylesheet-->
    <!--will be organized under the import/include's tag.-->
    <xsl:if test="not( (name()='xsl:stylesheet' or name()='xsl:transform') and $route[2])">
      <tag>
        <xsl:attribute name="tagname">
          <xsl:call-template name="getTagName">
            <xsl:with-param name="element" select="."/>
            <xsl:with-param name="route" select="$route"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="tagfile"><xsl:value-of select="$route[last()]/@value"/></xsl:attribute>
        <xsl:attribute name="tagaddress"><xsl:call-template name="line-number"/></xsl:attribute>
        <extendedFields>
          <xsl:call-template name="addStandardExtendedFieldAttributes">
            <xsl:with-param name="route" select="$route"/>
          </xsl:call-template>
        </extendedFields>
      </tag>
    </xsl:if>
  </xsl:template>

  <!--getTagName is to be called in the context of an xsl node/element -->
  <xsl:template name="getTagName">
    <xsl:param name="element" select="current()"/>
    <xsl:param name="route"/>
    <xsl:choose>
      <xsl:when test="name($element)='xsl:stylesheet' or name($element)='xsl:transform'">
        <xsl:value-of select="concat('doc(',$SingleQuote,$route[last()]/@value,$SingleQuote,')')"/>
      </xsl:when>
      <xsl:when test="$element/@name">
        <xsl:call-template name="escapeTagField">
          <xsl:with-param name="input">
            <xsl:choose>
              <xsl:when test="starts-with($element/@name,$CurlyLeftBracket)">  <!--ends-with() not implemented in Xpath 1.0!-->
                <xsl:call-template name="removeWhiteSpaceFromXPath">
                  <xsl:with-param name="input" select="$element/@name"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$element/@name"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$element/@match">
        <xsl:call-template name="escapeTagField">
          <xsl:with-param name="input">
            <xsl:call-template name="removeWhiteSpaceFromXPath">
              <xsl:with-param name="input" select="$element/@match"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$element/@select">
        <xsl:call-template name="escapeTagField">
          <xsl:with-param name="input">
            <xsl:call-template name="removeWhiteSpaceFromXPath">
              <xsl:with-param name="input" select="$element/@select"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$element/@href">
        <xsl:call-template name="escapeTagField">
          <xsl:with-param name="input">
            <xsl:choose>
              <xsl:when test="starts-with($element/@href,$CurlyLeftBracket)"> <!--ends-with() not implemented in Xpath 1.0!-->
                <xsl:call-template name="removeWhiteSpaceFromXPath">
                  <xsl:with-param name="input" select="$element/@href"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:choose>
                  <!--when the path is relative, simplify the path-->
                  <xsl:when test="$element/@href[not(contains(.,':') or starts-with(.,'\') or starts-with(.,'/'))]">
                      <xsl:value-of select="concat('doc(',$SingleQuote)"/>
                      <xsl:call-template name="simplifyPath">
                        <xsl:with-param name="input" select="concat($route[last()]/@value,'/../',$element/@href)"/>
                      </xsl:call-template>
                      <xsl:value-of select="concat($SingleQuote,')')"/>
                  </xsl:when>
                  <!--otherwise the path is absolute-->
                  <xsl:otherwise>
                    <xsl:value-of select="concat('doc(',$SingleQuote)"/>
                    <xsl:call-template name="simplifyPath">
                      <xsl:with-param name="input" select="$element/@href"/>
                    </xsl:call-template>
                    <xsl:value-of select="concat($SingleQuote,')')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$element/dtd:doctype/@name">
        <xsl:call-template name="escapeTagField">
          <xsl:with-param name="input">
            <xsl:choose>
              <xsl:when test="starts-with($element/dtd:doctype/@name,$CurlyLeftBracket)"> <!--ends-with() not implemented in Xpath 1.0!-->
                <xsl:call-template name="removeWhiteSpaceFromXPath">
                  <xsl:with-param name="input" select="$element/dtd:doctype/@name"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$element/dtd:doctype/@name"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates select="$element/@mode" mode="appendModeToTagName"/>
  </xsl:template>  <!-- end of <xsl:template name="getTagName"> -->

  <xsl:template match="@mode" mode="appendModeToTagName">
    <xsl:text> mode="</xsl:text>
    <xsl:call-template name="escapeTagField">
      <xsl:with-param name="input" select="."/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <!--addStandardExtendedFieldAttributes is to be called in the context of an xsl node/element -->
  <xsl:template name="addStandardExtendedFieldAttributes">
    <xsl:param name="route"/>


    <!--kind and line are always added-->
    <xsl:attribute name="kind"><xsl:call-template name="getKindLetter"/></xsl:attribute>
    <xsl:attribute name="line"><xsl:call-template name="line-number"/></xsl:attribute>

    <!--only add column if it is defined. (not always defined for all xslt processors that xsltctags may be executed with.-->
    <xsl:variable name="column-number">
      <xsl:call-template name="column-number"/>
    </xsl:variable>
    <xsl:if test="$column-number != ''">
      <xsl:attribute name="column"><xsl:value-of select="$column-number"/></xsl:attribute>
    </xsl:if>

    <!--if there's a route > 1, add the file attribute-->
    <xsl:if test="$route[2]">
      <xsl:attribute name="file">
      </xsl:attribute>
    </xsl:if>

    <!--arity applies to xsl:template, xsl:function, xsl:apply-templates, xsl:call-template, others?-->
    <!--There will never be both xsl:with-param and xsl:param... so it should be safe to add together.-->
    <xsl:variable name="arity" select="count(xsl:with-param | xsl:param)"/>
    <xsl:if test="($arity &gt; 0)">
      <xsl:attribute name="arity"><xsl:value-of select="$arity"/></xsl:attribute>
    </xsl:if>

    <!--@saxon:memo-function may be added to xsl:function-->
    <xsl:if test="@saxon:memo-function">
      <xsl:attribute name="saxonMemoFunction">
        <xsl:call-template name="escapeTagField">
          <xsl:with-param name="input" select="@saxon:memo-function"/>
        </xsl:call-template>
      </xsl:attribute>
    </xsl:if>

    <!--@saxon:assignable may be added to xsl:variable-->
    <xsl:if test="@saxon:assignable">
      <xsl:attribute name="saxonAssignable">
        <xsl:call-template name="escapeTagField">
          <xsl:with-param name="input" select="@saxon:assignable"/>
        </xsl:call-template>
      </xsl:attribute>
    </xsl:if>

    <!--@required='yes' may be added to an xsl:param-->
    <xsl:if test="@required='yes'">
      <xsl:attribute name="required">yes</xsl:attribute>
    </xsl:if>

    <!--@tunnel='yes' may be added to an xsl:param-->
    <xsl:if test="@tunnel='yes'">
      <xsl:attribute name="tunnel">yes</xsl:attribute>
    </xsl:if>

    <xsl:call-template name="addScopeExtendedFieldAttribute">
      <xsl:with-param name="route" select="$route"/>
    </xsl:call-template>

    <xsl:attribute name="xpath">
      <xsl:call-template name="escapeTagField">
        <xsl:with-param name="input">
          <!--if there's a route > 1, prefix xpath with doc() for the current href-->
          <xsl:if test="$route[2]">
            <xsl:value-of select="concat('doc(',$SingleQuote,$route[last()]/@value,$SingleQuote,')')"/>
          </xsl:if>
          <xsl:call-template name="getXPath"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:attribute>

  </xsl:template> <!-- end of <xsl:template name="addStandardExtendedFieldAttributes"> -->

  <!--addScopeExtendedFieldAttribute is to be called in the context of an xsl node/element -->
  <xsl:template name="addScopeExtendedFieldAttribute">
    <xsl:param name="route"/>
    <!--XSLAncestors only includes those that are valid $kinds-->
    <xsl:variable name="XSLAncestors" select="ancestor::*[name()=$validKinds//element/text()] "/>

    <xsl:variable name="kindShortName">
      <xsl:call-template name="getKindShortName">
        <xsl:with-param name="element" select="$XSLAncestors[last()]"/>
      </xsl:call-template>
    </xsl:variable>

    <!--attributeName is the kind of the last item in the scope chain-->
    <xsl:variable name="attributeName">
      <xsl:choose>
        <xsl:when test="$kindShortName='stylesheet' and $route[2]">
          <xsl:value-of select="$route[last()]/@kind"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$kindShortName"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="$attributeName != ''">
      <xsl:attribute name="{$attributeName}">
        <!--if there's a route, prefix scope with the route-->
        <xsl:if test="$route[2]">
          <xsl:call-template name="getRouteContent">
            <xsl:with-param name="route" select="$route"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:call-template name="getScopeContent">
          <xsl:with-param name="XSLAncestors" select="$XSLAncestors"/>
          <xsl:with-param name="route" select="$route"/>
        </xsl:call-template>
      </xsl:attribute>
    </xsl:if>
  </xsl:template> <!-- end of <xsl:template name="addScopeExtendedFieldAttribute"> -->

  <xsl:template name="getRouteContent">
    <xsl:param name="route"/>
    <xsl:for-each select="$route[position()!=last()]">
      <xsl:value-of select="@tagName"/>
      <xsl:text>////</xsl:text>  <!--I decided to make the scope separator ////.  This is used by vim's tagbar to determine hiearachy-->
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="getScopeContent">
    <xsl:param name="XSLAncestors"/>
    <xsl:param name="route"/>

    <xsl:for-each select="$XSLAncestors">
      <xsl:sort select="count(ancestor::*)"/>

      <xsl:call-template name="getTagName">
        <xsl:with-param name="element" select="current()"/>
        <xsl:with-param name="route" select="$route"/>
      </xsl:call-template>

      <xsl:if test="not(position()=last())">
        <xsl:text>////</xsl:text>  <!--I decided to make the scope separator ////.  This is used by vim's tagbar to determine hiearachy-->
      </xsl:if>

    </xsl:for-each>
    </xsl:template> <!-- end of <xsl:template name="getScopeContent"> -->


  <!--This function cleans up white space in long Xpath expressions-->
  <!--Could be written better... but handles many use cases-->
  <xsl:template name="removeWhiteSpaceFromXPath">
    <xsl:param name="input"/>
    <!--Note: using str:tokenize2 template because str:tokenize() does not tokenize empty strings between delimiters-->
    <xsl:variable name="splitQuotes">
      <xsl:call-template name="str:tokenize2">
        <xsl:with-param name="string" select="$input"/>
        <xsl:with-param name="delimiters" select="$SingleQuote"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="splitDoubleQuotes">
      <xsl:call-template name="str:tokenize2">
        <xsl:with-param name="string" select="$input"/>
        <xsl:with-param name="delimiters" select="$DoubleQuote"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <!--when single quotes and no double quotes-->
      <xsl:when test="contains($input,$SingleQuote) and not(contains($input,$DoubleQuote))">
        <xsl:for-each select="exsl:node-set($splitQuotes)/*">
          <xsl:choose>
            <!--For odd values, remove excess whitespace-->
            <xsl:when test="position() mod 2 = 1">
              <xsl:value-of select="translate(.,$whitespace,'')"/>
            </xsl:when>
            <!--otherwise we're inside a quote... so just copy as is-->
            <xsl:otherwise>
              <xsl:value-of select="$SingleQuote"/>
              <xsl:value-of select="."/>
              <xsl:value-of select="$SingleQuote"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <!--when double quotes and no single quotes-->
      <xsl:when test="contains($input,$DoubleQuote) and not(contains($input,$SingleQuote))">
        <xsl:for-each select="exsl:node-set($splitDoubleQuotes)/*">
          <xsl:choose>
            <!--For odd values, remove excess whitespace-->
            <xsl:when test="position() mod 2 = 1">
              <xsl:value-of select="translate(.,$whitespace,'')"/>
            </xsl:when>
            <!--otherwise we're inside a quote... so just copy as is-->
            <xsl:otherwise>
              <xsl:value-of select="$DoubleQuote"/>
              <xsl:value-of select="."/>
              <xsl:value-of select="$DoubleQuote"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <!--when no single or double quotes-->
      <xsl:when test="not(contains($input,$SingleQuote)) and not(contains($input,$DoubleQuote))">
        <xsl:value-of select="translate($input,$whitespace,'')"/>
      </xsl:when>
      <xsl:otherwise> <!--there is mixed single and double quotes-->
        <xsl:value-of select="$input"/>  <!--Don't attempt to cleanup whitespace-->
      </xsl:otherwise>
    </xsl:choose>
    </xsl:template>  <!-- end of <xsl:template name="removeWhiteSpaceFromXPath"> -->

</xsl:stylesheet>
