<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                >
   <!--XSLT 1.0 template to simplify paths.-->
   <!--Removes unecessary '..' from paths-->
   <!--tested in saxon 9.0 an xslt 2.0 processor and xsltproc 1.26-->
   <!--By Darcy Parker 3/22/2012 darcyparker@gmail.com-->
   <xsl:import href="str.tokenize2.template.xsl"/>

  <xsl:template name="simplifyPath">
    <xsl:param name="input"/>
    <xsl:variable name="inputPathFragments">
      <!--Note: the following called template is like exslt str:tokenize, but it will also tokenize empty strings in between delimiters -->
      <xsl:call-template name="str:tokenize2">
        <xsl:with-param name="string" select="translate($input,'\','/')"/>
        <xsl:with-param name="delimiters" select="'/'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="resultFragments">
      <xsl:apply-templates select="exsl:node-set($inputPathFragments)/*[1]" mode="simplifyPath"/>
    </xsl:variable>
    <xsl:for-each select="exsl:node-set($resultFragments)/*[position()!=last()]">
      <xsl:value-of select="concat(.,'/')"/>
    </xsl:for-each>
    <xsl:value-of select="exsl:node-set($resultFragments)/*[last()]"/>
  </xsl:template>

  <xsl:template match="*[text()!='..' and text()!='.' and count(following-sibling::*[text()='..']) &gt; 0]" mode="simplifyPath">
    <xsl:variable name="currentPosition" select="count(preceding-sibling::*)+1"/>
    <xsl:variable name="firstDotDotPosition" select="count(following-sibling::*[text()='..'][1]/preceding-sibling::*[position() &gt; $currentPosition])+1"/>
    <xsl:variable name="headFragments" select=". | following-sibling::*[position() &lt; $firstDotDotPosition]"/>
    <xsl:variable name="tailFragments" select="following-sibling::*[position() &gt; $firstDotDotPosition]"/>
    <!--$fragmentsWithOneReduction: removes the first '..' and its preceding fragment (which will not be '..' when inside this template)-->
    <xsl:variable name="fragmentsWithOneReduction">
      <!--Very important. $fragmentsWithOneReduction must be constructed as a copy and not as a set of referenced nodes.-->
      <!--otherwise queries of following-siblings and preceding-siblings will include the filtered nodes-->
        <xsl:apply-templates select="$headFragments[position() != last()] | $tailFragments" mode="identity-simplifyPath"/>
    </xsl:variable>
    <!--recurse-->
    <xsl:apply-templates select="exsl:node-set($fragmentsWithOneReduction)/*[1]" mode="simplifyPath"/>
  </xsl:template>

  <!--output fragment and move to next fragment-->
  <xsl:template match="*" mode="simplifyPath">
    <xsl:apply-templates select="." mode="identity-simplifyPath"/>
    <xsl:apply-templates select="following-sibling::*[1]" mode="simplifyPath"/>
  </xsl:template>

  <!--skip over fragment='.'-->
  <xsl:template match="*[text()='.']" mode="simplifyPath">
    <xsl:apply-templates select="following-sibling::*[1]" mode="simplifyPath"/>
  </xsl:template>

  <!--Identity Transform used by simplifyPath-->
  <xsl:template match="@*|node()" mode="identity-simplifyPath">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="identity-simplifyPath"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
