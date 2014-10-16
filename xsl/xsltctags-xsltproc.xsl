<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:saxonlibxslt="http://icl.com/saxon"
  xmlns:str="http://exslt.org/strings"
  extension-element-prefixes="str"
  version="1.0">


  <xsl:import href="xsltctags-common.xsl"/>
  <xsl:import href="str.replace.function.xsl"/> <!--see: http://www.exslt.org/str/functions/replace/index.html-->

  <xsl:output
    method="text"
    encoding="UTF-8"
    />

  <xsl:param name="fileName"/>

  <!--template to escape Tag Fields ($input) string as required by ctags spec-->
  <xsl:template name="escapeTagField">
    <!--
      -  This function escapes tagfield strings to conform with ctags standard.
      -  Returns a string.
      -
      -  Notes on tag fields: (from http://ctags.sourceforge.net/FORMAT)
      -    When a value contains a "\t", this stands for a <Tab>.
      -    When a value contains a "\r", this stands for a <CR>.
      -    When a value contains a "\n", this stands for a <NL>.
      -    When a value contains a "\\", this stands for a single '\' character.
      -
      - Notes on implementation:
      -
      -    - str:replace can search/replace multiple strings at a time by passing in a node-set for
      -      the 2nd and 3rd parameter
      -    - Using str:split to create a node-set for the search and replacement strings.
      -      ~ is the delimiter for creating the node-set
      -    - str:replace returns a nodeset
      -    - str:concat concatenates the nodeset to a string
    -->
    <xsl:param name="input"/>
    <xsl:variable name="search" select="str:split('&#x9;~&#xd;~&#xa;~\','~')"/>
    <xsl:variable name="replace" select="str:split('\t~\r~\n~\\','~')"/>
    <xsl:value-of select="str:concat(str:replace($input,$search,$replace))"/>
  </xsl:template> <!--end of <xsl:template name="escapeTagField"> -->

<!--
   -    Note: libxslt implements some of saxon's extension functions.
   -          In particular, it was exciting to find that they have implemented saxon:line-number().
   -          However, I stumbled because they use a different namespace url than saxon does ?!?
   -          Since I need both the usual 'saxon' namespace and libxslt's version, I created an
   -          additional namespace prefix called "saxonlibxslt", so I can leverage their
   -          implementation of line-number().
   -          Found out about this by reading:
   -                  libxslt-1.1.22/libexslt/exslt.h
   -                  libxslt-1.1.22/libexslt/saxon.c
   -          When searching for a line-number() like function, I came across this:
   -            http://mail.gnome.org/archives/xslt/2004-August/msg00044.html
   -            - But I never noticed the different namespace url!!! (very subtle/confusing!)
   -            - But the thread made me convinced the function was implemented...
   -            - That lead me to the source code mentioned above...
   -          Other interesting namespaces with extension functions are documented in the source code.
   -->
  <xsl:template name="line-number">
    <xsl:value-of select="saxonlibxslt:line-number()"/>
  </xsl:template>

  <xsl:template name="column-number">
    <!--Not implemented in xsltproc-->
    <!--See https://bugzilla.gnome.org/show_bug.cgi?id=670610 -->
  </xsl:template>

</xsl:stylesheet>
