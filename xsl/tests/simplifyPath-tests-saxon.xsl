<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                >

  <xsl:import href="../simplifyPath.xsl"/> <!--simplifyPath template is imported from this template-->
  <xsl:import href="simplifyPath-tests.xsl"/> <!--tests for simplifyPath are here-->
  <xsl:output method="text"/>

  <!--wrapper for str:tokenize in saxon because this common xslt 1.0 extension function is not in saxon because saxon has xslt 2.0 tokenize()-->
  <xsl:function name="str:tokenize">
    <xsl:param name="input"/>
    <xsl:param name="delimiters"/>
    <xsl:sequence select="tokenize($input,$delimiters)"/>
  </xsl:function>

</xsl:stylesheet>
