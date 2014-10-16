<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:str="http://exslt.org/strings"
  version="1.0">

  <xsl:import href="xsltctags-common.xsl"/>

  <xsl:output
    method="text"
    encoding="UTF-8"
    />

  <xsl:param name="fileName"/>

  <!--template to escape tag fields ($input) string as required by ctags spec-->
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
    -->
    <xsl:param name="input"/>
    <xsl:value-of select="replace(replace(replace(replace(
                          $input, '\\',   '\\\\'),
                                  '&#x9;','\\t'),
                                  '&#xd;','\\r'),
                                  '&#xa;','\\n') "/>
  </xsl:template>

  <xsl:template name="line-number">
    <xsl:value-of select="saxon:line-number()"/>
  </xsl:template>

  <xsl:template name="column-number">
    <xsl:value-of select="saxon:column-number()"/>
  </xsl:template>

  <!--str:tokenize() is used in xsltctags-common.xsl.-->
  <!--str:tokenize() is an XSLT 1.0 extension defined by http://exslt.org/str/functions/tokenize/index.html-->
  <!--This is a wrapper around tokenize() since str:tokenize() is not implemented on saxon-->
  <xsl:function name="str:tokenize">
    <xsl:param name="input"/>
    <xsl:param name="delimiters"/>
    <xsl:sequence select="tokenize($input,$delimiters)"/>
  </xsl:function>

  <!--A useful namedTemplate to help generate the XSLTctags.vim configuration file with the -->
  <!--various kinds of XSLT elements to tag.-->
  <xsl:template name="createXSLTctagsvim">
    <xsl:result-document
      href="xsltctags.vim"
      method="text">
      <xsl:text>let g:tagbar_type_xslt = {</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'ctagstype' : 'xslt',</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'ctagsbin'  : 'D:\Users\dparker\Dropbox\xsltctags\xsltctags.cmd',</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'ctagsargs' : '-f - -p xsltproc ',</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'sort' : 0,</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'kinds'     : [</xsl:text><xsl:text>&#xa;</xsl:text>

      <xsl:for-each select="$kinds/kind">
        <xsl:text>\ '</xsl:text>
        <xsl:value-of select="@letter"/>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="@pluralName"/>
        <xsl:text>'</xsl:text>
        <xsl:if test="not(position()=last())">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
      </xsl:for-each>

      <xsl:text>\ ],</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'sro': '////',</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'kind2scope' : {</xsl:text><xsl:text>&#xa;</xsl:text>

      <xsl:for-each select="$kinds/kind">
        <xsl:text>\ '</xsl:text>
        <xsl:value-of select="@letter"/>
        <xsl:text>' : '</xsl:text>
        <xsl:value-of select="@shortName"/>
        <xsl:text>'</xsl:text>
        <xsl:if test="not(position()=last())">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
      </xsl:for-each>

      <xsl:text>\ },</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\ 'scope2kind' : {</xsl:text><xsl:text>&#xa;</xsl:text>

      <xsl:for-each select="$kinds/kind">
        <xsl:text>\ '</xsl:text>
        <xsl:value-of select="@shortName"/>
        <xsl:text>' : '</xsl:text>
        <xsl:value-of select="@letter"/>
        <xsl:text>'</xsl:text>
        <xsl:if test="not(position()=last())">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
      </xsl:for-each>

      <xsl:text>\}</xsl:text><xsl:text>&#xa;</xsl:text>
      <xsl:text>\}</xsl:text><xsl:text>&#xa;</xsl:text>
    </xsl:result-document>

    </xsl:template> <!-- end of <xsl:template name="createXSLTctagsvim"> -->

</xsl:stylesheet>
