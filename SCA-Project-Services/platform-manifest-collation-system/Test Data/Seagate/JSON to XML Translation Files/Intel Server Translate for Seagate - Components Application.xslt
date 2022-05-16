<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs math" version="3.0">
  <xsl:output indent="yes" omit-xml-declaration="yes" />

  <xsl:param name="UUID"/>

 <xsl:template match="record">
      <xsl:apply-templates select="json-to-xml(.)"/>
  </xsl:template>


  <!-- template for the first tag -->
  <xsl:template match="map" xpath-default-namespace="http://www.w3.org/2005/xpath-functions">
    <Device>
    <Manufacturer />
    <Make_and_Model />
     <Serial_Number />
    <Product_Name />
    <UUID>
      <xsl:value-of select="$UUID"/>
    </UUID>
    <Components>    
        <Component>
          <Class>Hard Drive</Class>
          <Manufacturer>
            <xsl:value-of select="map/string[@key='Manufacturer']"/>
          </Manufacturer>
          <Model>
            <xsl:value-of select="map/string[@key='Model']"/>
          </Model>
          <Serial>
            <xsl:value-of select="map/string[@key='SystemSN']"/>
          </Serial>
          <Revision>
            <xsl:value-of select="map/string[@key='drive_rev']"/>          
          </Revision>
          <Version>
          </Version>
          <Field_Replaceable></Field_Replaceable>
          <Addresses></Addresses>
          <Platform_Certificate></Platform_Certificate>
          <Platform_Certificate_URI></Platform_Certificate_URI>
          <Free_Text>
            <xsl:value-of select="map/string[@key='drive_name']"/> 
          </Free_Text>
          <Device>
            <xsl:value-of select="$UUID"/>
          </Device>
        </Component>
        </Components>
        </Device>
        </xsl:template>

  <!--
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
-->


</xsl:stylesheet>