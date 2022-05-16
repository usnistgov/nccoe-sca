<?xml version="1.0"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="xs math" version="3.0">
	<xsl:output indent="yes" omit-xml-declaration="yes" />

	<xsl:template match="record">
  <Device>
	    <xsl:apply-templates select="json-to-xml(.)" />      
</Device>
	</xsl:template>

	<!-- template for the first tag -->
	<xsl:template match="map" 
  xpath-default-namespace="http://www.w3.org/2005/xpath-functions">
  
  <xsl:variable name="uuid" select="string[@key='uuid']" />

  <data>
  <events>
 

<!-- For each timestamp, create a record in Archer-->
<xsl:for-each select="/map/map/map/map/array/map">
<event_instance>


<!-- Get each event type -->
<xsl:variable name="eventkey" select="parent::*/@key" />
<xsl:element name="event"><xsl:value-of select="$eventkey" /></xsl:element>

<!-- Get each event category -->
<xsl:variable name="eventcategory" select="parent::*/parent::*/@key" />
<xsl:element name="event_category"><xsl:value-of select="$eventcategory" /></xsl:element>

<xsl:element name="timestamp"><xsl:value-of select="string[@key='Timestamp']" /></xsl:element>
<xsl:element name="message"><xsl:value-of select="number[@key='Message']" /></xsl:element>
<uuid><xsl:value-of select="$uuid" /></uuid>

</event_instance>
</xsl:for-each> 

 
 
   <!-- <xsl:apply-templates select="map/map/[@key='Events']" /> -->
  </events>

  <uefi_configuration_variables>
  <xsl:for-each select="/map/map/map[@key='Variables']/map">
<variable>
<xsl:variable name="variablekey" select="translate(@key,' ','_')" />

<variablename><xsl:value-of select="$variablekey" /></variablename>
<value><xsl:value-of select="string[@key='Value']" /></value>
<description><xsl:value-of select="string[@key='Name']" /></description>
<uuid><xsl:value-of select="$uuid" /></uuid>
</variable>
  </xsl:for-each>
  </uefi_configuration_variables>
  </data>  


  </xsl:template>

</xsl:stylesheet>