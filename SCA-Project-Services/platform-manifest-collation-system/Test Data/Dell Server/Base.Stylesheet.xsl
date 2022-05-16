<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs math" version="3.0">
  <xsl:output indent="yes" omit-xml-declaration="yes" />

  <xsl:param name="UUID"/>

  <xsl:template match="record">
    <Device>
      <xsl:apply-templates select="json-to-xml(.)" />
    </Device>

  </xsl:template>