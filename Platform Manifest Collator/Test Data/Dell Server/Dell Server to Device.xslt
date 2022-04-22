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


  <!-- template for the first tag -->
  <xsl:template match="map" xpath-default-namespace="http://www.w3.org/2005/xpath-functions">
    <Manufacturer>
      <xsl:value-of select="array/map/string[@key='Manufacturer']" />
    </Manufacturer>
    <Make_and_Model>
      <xsl:value-of select="array/map/string[@key='Model']" />
    </Make_and_Model>
    <Serial_Number>
      <xsl:value-of select="array/map/string[@key='Serial']" />
    </Serial_Number>
    <Product_Name>Unknown</Product_Name>
    <UUID>
      <xsl:value-of select="$UUID"/>
    </UUID>
    <Components>


      <xsl:for-each select="map/array/map/array[@key='Processor']/map">
        <Component>
          <Class>CPU</Class>
          <Manufacturer>
            <xsl:value-of select="string[@key='Manufacturer']"/>
          </Manufacturer>
          <Model>
            <xsl:value-of select="string[@key='Model']"/>
          </Model>
          <Serial>
            <xsl:value-of select="string[@key='Serial']"/>
          </Serial>
          <Revision>
          </Revision>
          <Version>
            <xsl:value-of select="string[@key='Version']"/>
          </Version>
          <Field_Replaceable></Field_Replaceable>
          <Addresses></Addresses>
          <Platform_Certificate></Platform_Certificate>
          <Platform_Certificate_URI></Platform_Certificate_URI>
          <Device>
            <xsl:value-of select="$UUID"/>
          </Device>
        </Component>
      </xsl:for-each>


      <xsl:for-each select="map/array/map/array[@key='Memory']/map">
        <Component>
          <Class>Memory</Class>
          <Manufacturer>
            <xsl:value-of select="string[@key='Manufacturer']"/>
          </Manufacturer>
          <Model>
            <xsl:value-of select="string[@key='Model']"/>
          </Model>
          <Serial>
            <xsl:value-of select="string[@key='Serial']"/>
          </Serial>
          <Revision>
          </Revision>
          <Version>
            <xsl:value-of select="string[@key='Version']"/>
          </Version>
          <Field_Replaceable></Field_Replaceable>
          <Addresses></Addresses>
          <Platform_Certificate></Platform_Certificate>
          <Platform_Certificate_URI></Platform_Certificate_URI>
          <Device>
            <xsl:value-of select="$UUID"/>
          </Device>
        </Component>
      </xsl:for-each>

      <xsl:for-each select="map/array/map/array[@key='HardDrive']/map">
        <Component>
          <Class>Storage Drive</Class>
          <Manufacturer>
            <xsl:value-of select="string[@key='Manufacturer']"/>
          </Manufacturer>
          <Model>
            <xsl:value-of select="string[@key='Model']"/>
          </Model>
          <Serial>
            <xsl:value-of select="string[@key='Serial']"/>
          </Serial>
          <Revision>
            <xsl:value-of select="string[@key='Part Number']"/>
          </Revision>
          <Version>
            <xsl:value-of select="string[@key='Version']"/>
          </Version>
          <Field_Replaceable></Field_Replaceable>
          <Addresses></Addresses>
          <Platform_Certificate></Platform_Certificate>
          <Platform_Certificate_URI></Platform_Certificate_URI>
          <Device>
            <xsl:value-of select="$UUID"/>
          </Device>
        </Component>
      </xsl:for-each>

      <xsl:for-each select="map/array/map/array[@key='Network']/map">
        <Component>
          <Class>Network Interface Card</Class>
          <Manufacturer>
            <xsl:value-of select="string[@key='Manufacturer']"/>
          </Manufacturer>
          <Model>
            <xsl:value-of select="string[@key='Model']"/>
          </Model>
          <Serial>
            <xsl:value-of select="string[@key='Serial']"/>
          </Serial>
          <Revision>
          </Revision>
          <Version>
            <xsl:value-of select="string[@key='Version']"/>
          </Version>
          <Field_Replaceable></Field_Replaceable>
          <Addresses></Addresses>
          <Platform_Certificate></Platform_Certificate>
          <Platform_Certificate_URI></Platform_Certificate_URI>
          <Device>
            <xsl:value-of select="$UUID"/>
          </Device>
        </Component>
      </xsl:for-each>


      <xsl:for-each select="map/array/map/array[@key='TPM']/map">
        <Component>
          <Class>TPM</Class>
          <Manufacturer>
            <xsl:value-of select="string[@key='Manufacturer']"/>
          </Manufacturer>
          <Model>
            <xsl:value-of select="string[@key='Model']"/>
          </Model>
          <Serial>
            <xsl:value-of select="string[@key='Serial']"/>
          </Serial>
          <Revision>
          </Revision>
          <Version>
            <xsl:value-of select="string[@key='Version']"/>
          </Version>
          <Field_Replaceable></Field_Replaceable>
          <Addresses></Addresses>
          <Platform_Certificate></Platform_Certificate>
          <Platform_Certificate_URI></Platform_Certificate_URI>
          <Device>
            <xsl:value-of select="$UUID"/>
          </Device>
        </Component>
      </xsl:for-each>


      <xsl:for-each select="map/array/map/array[@key='Baseboard']/map">
        <Component>
          <Class>Baseboard</Class>
          <Manufacturer>
            <xsl:value-of select="string[@key='Manufacturer']"/>
          </Manufacturer>
          <Model>
            <xsl:value-of select="string[@key='Model']"/>
          </Model>
          <Serial>
            <xsl:value-of select="string[@key='Serial']"/>
          </Serial>
          <Revision>
          </Revision>
          <Version>
            <xsl:value-of select="string[@key='Version']"/>
          </Version>
          <Field_Replaceable></Field_Replaceable>
          <Addresses></Addresses>
          <Platform_Certificate></Platform_Certificate>
          <Platform_Certificate_URI></Platform_Certificate_URI>
          <Device>
            <xsl:value-of select="$UUID"/>
          </Device>
        </Component>
      </xsl:for-each>
    </Components>


  </xsl:template>


</xsl:stylesheet>