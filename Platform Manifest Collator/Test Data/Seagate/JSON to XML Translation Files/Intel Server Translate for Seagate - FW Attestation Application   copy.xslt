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
  <SeagateDriveFirmwareAttestation>  
    
    <UUID>
      <xsl:value-of select="$UUID"/>
    </UUID>
          <assessor_id>
            <xsl:value-of select="map/string[@key='assessor_id']"/>
          </assessor_id>
          <root_of_trust_id>
            <xsl:value-of select="map/string[@key='root_of_trust_id']"/>
          </root_of_trust_id>
          <root_of_trust_nonce>
            <xsl:value-of select="map/string[@key='root_of_trust_nonce']"/>
          </root_of_trust_nonce>
          <device_nonce>
            <xsl:value-of select="map/string[@key='device_nonce']"/>
          </device_nonce>
          <fw_version>
          <xsl:value-of select="map/string[@key='fw_version']"/>
          </fw_version>
          <secure_boot_device_state>
          <xsl:value-of select="map/string[@key='secure_boot_device_state']"/>
          </secure_boot_device_state>
          <signing_auth_database>
          <xsl:value-of select="map/string[@key='signing_auth_database']"/>
          </signing_auth_database>

        </SeagateDriveFirmwareAttestation>
        </xsl:template>

 
</xsl:stylesheet>