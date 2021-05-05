<?xml version="1.0"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="xs math" version="3.0">
  <xsl:output indent="yes" omit-xml-declaration="yes" />
  
  <xsl:template match="record">
    <xsl:variable name="SourceXML">
      <xsl:apply-templates select="json-to-xml(.)" />
    </xsl:variable>

    <xsl:call-template name="SourceXMLtoRecord">
      <xsl:with-param name="SourceXML" select="$SourceXML"/>
    </xsl:call-template>

  </xsl:template>
  <xsl:template name="SourceXMLtoRecord">
    <xsl:param name="SourceXML" />
    <!--Device-->
    <Device>
      <Manufacturer>
        <xsl:value-of select="$SourceXML/map/Header/Manufacturer"/>
      </Manufacturer>
      <Make_and_Model>
        <xsl:value-of select="$SourceXML/map/Header/Model"/>
      </Make_and_Model>
      <Serial_Number>
        <xsl:value-of select="$SourceXML/map/EKCertSerialNumber"/>
      </Serial_Number>
      <Original_Equipment_Manufacturer>
        <xsl:value-of select="$SourceXML/map/Header/OEM"/>
      </Original_Equipment_Manufacturer>
      <Original_Design_Manufacturer>
        <xsl:value-of select="$SourceXML/map/Header/ODM"/>
      </Original_Design_Manufacturer>
      <Product_Name>
        <xsl:value-of select="$SourceXML/map/TYPE1System/ProductName"/>
      </Product_Name>
      <UUID>
        <xsl:value-of select="$SourceXML/map/TYPE1System/UUID"/>
      </UUID>
      <SKU>
        <xsl:value-of select="$SourceXML/map/TYPE1System/SKU"/>
      </SKU>
      <Family>
        <xsl:value-of select="$SourceXML/map/TYPE1System/Family"/>
      </Family>
      <Configuration_Scan_Results></Configuration_Scan_Results>
      <!--Components 1-to-n-->
      <Components>
        <!--Baseboards-->
        <xsl:for-each select="$SourceXML/map/TYPE2Baseboards/*">
          <Component>
            <Class>Baseboard</Class>
            <Manufacturer>
              <xsl:value-of select="Manufacturer"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="Product"/>
            </Model>
            <Serial>
              <xsl:value-of select="SerialNumber"/>
            </Serial>
            <Revision>              
            </Revision>
            <Version>
              <xsl:value-of select="Version"/>
            </Version>
            <Field_Replaceable></Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$SourceXML/map/TYPE1System/UUID"/>
            </Device>
          </Component>
        </xsl:for-each>
        <xsl:for-each select="$SourceXML/map/TYPE4Processors/*">
          <xsl:if test="position()=1">
          <Component>
            <Class>CPU</Class>
            <Manufacturer>
              <xsl:value-of select="Manufacturer"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="Type"/>
            </Model>
            <Serial>
              <xsl:value-of select="SerialNumber"/>
            </Serial>
            <Revision>              
            </Revision>
            <Version>
              <xsl:value-of select="Version"/>
            </Version>
            <Field_Replaceable></Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$SourceXML/map/TYPE1System/UUID"/>
            </Device>
          </Component>
          </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="$SourceXML/map/TYPE17MemoryDevices/*">
          <xsl:if test="position()=1">
          <Component>
            <Class>Memory</Class>
            <Manufacturer>
              <xsl:value-of select="Manufacturer"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="Type"/>
            </Model>
            <Serial>
              <xsl:value-of select="SerialNumber"/>
            </Serial>
            <Revision>              
            </Revision>
            <Version>
              <xsl:value-of select="Version"/>
            </Version>
            <Field_Replaceable></Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$SourceXML/map/TYPE1System/UUID"/>
            </Device>
          </Component>
          </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="$SourceXML/map/TYPE22PortableBatteries/*">
          <xsl:if test="position()=1">
          <Component>
            <Class>Battery</Class>
            <Manufacturer>
              <xsl:value-of select="Manufacturer"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="Name"/>
            </Model>
            <Serial>
              <xsl:value-of select="SerialNumber"/>
            </Serial>
            <Revision>              
            </Revision>
            <Version>
              <xsl:value-of select="Version"/>
            </Version>
            <Field_Replaceable></Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$SourceXML/map/TYPE1System/UUID"/>
            </Device>
          </Component>
          </xsl:if>
        </xsl:for-each>
        
          <Component>
            <Class>BIOS</Class>
            <Manufacturer>
              <xsl:value-of select="$SourceXML/map/TYPE0BIOS/Vendor"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="Name"/>
            </Model>
            <Serial>
              <xsl:value-of select="SerialNumber"/>
            </Serial>
            <Revision>              
            </Revision>
            <Version>
              <xsl:value-of select="$SourceXML/map/TYPE0BIOS/Version"/>
            </Version>
            <Field_Replaceable></Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$SourceXML/map/TYPE1System/UUID"/>
            </Device>
          </Component>
          
        <!--Storage Drives-->
        <xsl:for-each select="$SourceXML/map/ComponentIdentifiers/*">
          <Component>
          <xsl:choose>
          <xsl:when test="componentType='Nvme'">
            <Class>Storage Drive</Class>
            </xsl:when>
            <xsl:when test="contains(componentName,'Mouse')">
            <Class>Mouse</Class>
            </xsl:when>
            <xsl:when test="contains(componentModel,'Keyboard')">
            <Class>Keyboard</Class>
            </xsl:when>
            <xsl:when test="contains(componentModel,'Wi-Fi')">
            <Class>Network Interface Card</Class>
            </xsl:when>
            <xsl:otherwise>
             <Class>Non Storage Drive</Class>
            </xsl:otherwise>
            </xsl:choose>
            <Manufacturer>
              <xsl:value-of select="componentManufacturer"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="componentModel"/>
            </Model>
            <Serial>
              <xsl:value-of select="componentSerial"/>
            </Serial>
            <Revision>
              <xsl:value-of select="componentRevision"/>
            </Revision>
            <Version></Version>
            <Field_Replaceable>
              <xsl:value-of select="fieldReplaceable"/>
            </Field_Replaceable>
            <Addresses>              
              <xsl:for-each select="componentAddress/*">
                <xsl:if test=". != ''">
                  <Address>
                    <xsl:value-of select="."/>
                  </Address>
                </xsl:if>
              </xsl:for-each>              
            </Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$SourceXML/map/TYPE1System/UUID"/>
            </Device>
          </Component>
        </xsl:for-each>

      </Components>
    </Device>
  </xsl:template>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*">
    <xsl:variable name="elementName">
      <xsl:choose>
        <xsl:when test="@key">
          <xsl:value-of select="@key"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="name()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$elementName}"  namespace="">
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>