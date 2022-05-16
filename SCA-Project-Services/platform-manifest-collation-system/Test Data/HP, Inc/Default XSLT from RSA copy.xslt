<?xml version="1.0"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="xs math" version="3.0">
	<xsl:output indent="yes" omit-xml-declaration="yes" />

	<xsl:template match="record">
  <hpinc>
	    <xsl:apply-templates select="json-to-xml(.)" />      
</hpinc>
	</xsl:template>

	<!-- template for the first tag -->
	<xsl:template match="map" 
  xpath-default-namespace="http://www.w3.org/2005/xpath-functions">
  
  <type>  <xsl:apply-templates select="string[@key='type']" />  </type>
  <uuid><xsl:value-of select="string[@key='uuid']" /></uuid>
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


</event_instance>
</xsl:for-each> 

 

<Last_Timestamp><xsl:value-of select="/map/map/map/string[@key='Last_Timestamp']" /></Last_Timestamp>
<Prev_Timestamp><xsl:value-of select="/map/map/map/string[@key='Prev_Timestamp']" /></Prev_Timestamp>
 
   <!-- <xsl:apply-templates select="map/map/[@key='Events']" /> -->
  </events>

  <uefi_configuration_variables>
  <xsl:for-each select="/map/map/map[@key='Variables']/map">
<variable>
<xsl:variable name="variablekey" select="translate(@key,' ','_')" />

<variablename><xsl:value-of select="$variablekey" /></variablename>
<value><xsl:value-of select="string[@key='Value']" /></value>
<description><xsl:value-of select="string[@key='Name']" /></description>
</variable>
  </xsl:for-each>
  </uefi_configuration_variables>
  </data>  


  </xsl:template>
  <!--
		<xsl:template match="map[@key='Events']" 
  xpath-default-namespace="http://www.w3.org/2005/xpath-functions">
<tmp>
sdfdsf
</tmp>

  </xsl:template>
  
 template to output a string value
  	<xsl:template match="string"
		xpath-default-namespace="http://www.w3.org/2005/xpath-functions">

		
			<xsl:value-of select="." />
		
	</xsl:template> -->

</xsl:stylesheet>