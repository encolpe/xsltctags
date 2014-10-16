<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<!--Expand the xpath to the current node -->
<xsl:template name="getXPath">
  <xsl:apply-templates select="." mode="expand-path"/>
</xsl:template>

<!-- Root -->
<xsl:template match="/" mode="expand-path">
  <xsl:text>/</xsl:text>
</xsl:template>

<!--Top-level node -->
<xsl:template match="/*" mode="expand-path">
  <xsl:text>/</xsl:text>
  <xsl:value-of select="name( )"/>
</xsl:template>

<!--Nodes with node parents -->
<xsl:template match="*/*" mode="expand-path">
  <xsl:variable name="thisPosition" select="count(preceding-sibling::*[name(current()) = name()])"/>
  <xsl:variable name="numFollowing" select="count(following-sibling::*[name(current()) = name()])"/>
  <xsl:apply-templates select=".." mode="expand-path"/>
  <xsl:text>/</xsl:text>
  <xsl:value-of select="name( )"/>
  <xsl:if test="$thisPosition + $numFollowing > 0">
    <xsl:value-of select="concat('[', $thisPosition + 1, ']')"/>
  </xsl:if>
</xsl:template>

<!--Attribute nodes -->
<xsl:template match="@*" mode="expand-path">
  <xsl:apply-templates select=".." mode="expand-path"/>
  <xsl:text>/@</xsl:text>
  <xsl:value-of select="name( )"/>
</xsl:template>

<!-- Text nodes  -->
<xsl:template match="text()" mode="expand-path">
  <xsl:variable name="thisPosition" select="count(preceding-sibling::text())"/>
  <xsl:variable name="numFollowing" select="count(following-sibling::text())"/>
  <xsl:text>text()</xsl:text>
  <xsl:if test="$thisPosition + $numFollowing > 0">
    <xsl:value-of select="concat('[', $thisPosition + 1, ']')"/>
  </xsl:if>
</xsl:template>

<!-- Processing Instruction nodes  -->
<xsl:template match="processing-instruction()" mode="expand-path">
  <xsl:variable name="thisPosition" select="count(preceding-sibling::processing-instruction())"/>
  <xsl:variable name="numFollowing" select="count(following-sibling::processing-instruction())"/>
  <xsl:text>processing-instruction()</xsl:text>
  <xsl:if test="$thisPosition + $numFollowing > 0">
    <xsl:value-of select="concat('[', $thisPosition + 1, ']')"/>
  </xsl:if>
</xsl:template>

<!-- Comment nodes  -->
<xsl:template match="comment()" mode="expand-path">
  <xsl:variable name="thisPosition" select="count(preceding-sibling::comment())"/>
  <xsl:variable name="numFollowing" select="count(following-sibling::comment())"/>
  <xsl:text>comment()</xsl:text>
  <xsl:if test="$thisPosition + $numFollowing > 0">
    <xsl:value-of select="concat('[', $thisPosition + 1, ']')"/>
  </xsl:if>
</xsl:template>


</xsl:stylesheet>
