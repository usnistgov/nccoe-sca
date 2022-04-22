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
  <SeagateDriveFirmwareHash>  
    
    <UUID>
      <xsl:value-of select="$UUID"/>
    </UUID>
          <signing_auth_key_cert_hash>
            <xsl:value-of select="map/string[@key='signing_auth_key_cert_hash']"/>
          </signing_auth_key_cert_hash>
          <see_signing_auth_key_cert_hash>
            <xsl:value-of select="map/string[@key='see_signing_auth_key_cert_hash']"/>
          </see_signing_auth_key_cert_hash>
          <bfw_itcm_hash>
            <xsl:value-of select="map/string[@key='bfw_itcm_hash']"/>
          </bfw_itcm_hash>
          <bfw_idba_hash>
            <xsl:value-of select="map/string[@key='bfw_idba_hash']"/>
          </bfw_idba_hash>
          <servo_fw_hash>
          <xsl:value-of select="map/string[@key='servo_fw_hash']"/>
          </servo_fw_hash>
          <cfw_hash>
          <xsl:value-of select="map/string[@key='cfw_hash']"/>
          </cfw_hash>
          <see_fw_hash>
          <xsl:value-of select="map/string[@key='see_fw_hash']"/>
          </see_fw_hash>

        </SeagateDriveFirmwareHash>
        </xsl:template>

 
</xsl:stylesheet>