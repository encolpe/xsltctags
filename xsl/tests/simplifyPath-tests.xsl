<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                >

  <xsl:import href="../simplifyPath.xsl"/> <!--simplifyPath template is imported from this template-->
  <xsl:output method="text"/>

  <xsl:template name="simplifyPath-Tests">
    <xsl:variable name="tests" select="'a\b/c~../a/b/c~a/../b~../../../a~../..~b/..~../b/../c/d~b/../b/../c/d~e/f/g/../..~h/i/j/k/../l/..~../../a/b/c/../../../d~a\b\c\..\d~a\b\c\..~a\b\c\..\d\..\..\e\..~\a\b\..~.\a\.\.\b\..\c\d\..\e\..\..~\\a\b\\c~/\/\b~path with spaces\this is a test\..~\abs\path with spaces\s\..'"/>
     <xsl:for-each select="str:tokenize($tests,'~')">
       <xsl:variable name="simplified">
         <xsl:call-template name="simplifyPath">
           <xsl:with-param name="input" select="."/>
         </xsl:call-template>
       </xsl:variable>
       <xsl:value-of select="."/>
       <xsl:text> simplified -> </xsl:text>
       <xsl:value-of select="$simplified"/>
       <xsl:text>&#xa;</xsl:text> <!--new line-->
     </xsl:for-each>
  </xsl:template>

  <xsl:template match="/">
    <xsl:call-template name="simplifyPath-Tests"/>
  </xsl:template>

</xsl:stylesheet>
