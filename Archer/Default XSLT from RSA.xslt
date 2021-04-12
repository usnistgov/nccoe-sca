<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:output indent="yes" />

  <xsl:template match="record">

    <xsl:copy>

      <xsl:apply-templates select="json-to-xml(.)/*"/>

    </xsl:copy>

  </xsl:template>

  <xsl:template match="*[@key]" xpath-default-namespace="http://www.w3.org/2005/xpath-functions">

    <xsl:element name="{@key}">

      <xsl:apply-templates/>

    </xsl:element>

  </xsl:template>



</xsl:stylesheet>