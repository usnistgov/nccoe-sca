<?xml version="1.0"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="xs math" version="3.0">
  <xsl:output indent="yes" omit-xml-declaration="yes" />

  <xsl:param name="UUID"/>
  
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
        <xsl:value-of select="$SourceXML/map/PLATFORM/PLATFORMMANUFACTURERSTR"/>
      </Manufacturer>
      <Make_and_Model>
        <xsl:value-of select="$SourceXML/map/PLATFORM/PLATFORMMODEL"/>
      </Make_and_Model>
      <Serial_Number>
        <xsl:value-of select="$SourceXML/map/PLATFORM/PLATFORMSERIAL"/>
      </Serial_Number>

      <Product_Name>
        <xsl:value-of select="$SourceXML/map/PLATFORM/PLATFORMVERSION"/>
      </Product_Name>
      <UUID>
        <xsl:value-of select="$UUID"/>
      </UUID>

      <!--Components 1-to-n-->
      <Components>
        <!--Baseboards-->
        <xsl:for-each select="$SourceXML/map/COMPONENTS/*"> 
        <xsl:if test="COMPONENTCLASS/COMPONENTCLASSVALUE='00030003'">         
          <Component>            
            <Class>Baseboard</Class>
            <Manufacturer>
              <xsl:value-of select="MANUFACTURER"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="MODEL"/>
            </Model>
            <Serial>
              <xsl:value-of select="SERIAL"/>
            </Serial>
            <Revision>
            <xsl:value-of select="REVISION"/>              
            </Revision>
            <Version>             
            </Version>
            <Field_Replaceable>
              <xsl:value-of select="FIELDREPLACEABLE"/> 
            </Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$UUID"/>
            </Device>
          </Component>        
        </xsl:if>

        <!-- Storage Drive -->
        <xsl:if test="COMPONENTCLASS/COMPONENTCLASSVALUE='00070002'">         
          <Component>            
            <Class>Baseboard</Class>
            <Manufacturer>
              <xsl:value-of select="MANUFACTURER"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="MODEL"/>
            </Model>
            <Serial>
              <xsl:value-of select="SERIAL"/>
            </Serial>
            <Revision>
            <xsl:value-of select="REVISION"/>              
            </Revision>
            <Version>             
            </Version>
            <Field_Replaceable>
              <xsl:value-of select="FIELDREPLACEABLE"/> 
            </Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$UUID"/>
            </Device>
          </Component>        
        </xsl:if>

        <!-- Storage Drive -->
        <xsl:if test="COMPONENTCLASS/COMPONENTCLASSVALUE='00070002'">         
          <Component>            
            <Class>Storage Drive</Class>
            <Manufacturer>
              <xsl:value-of select="MANUFACTURER"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="MODEL"/>
            </Model>
            <Serial>
              <xsl:value-of select="SERIAL"/>
            </Serial>
            <Revision>
            <xsl:value-of select="REVISION"/>              
            </Revision>
            <Version>             
            </Version>
            <Field_Replaceable>
              <xsl:value-of select="FIELDREPLACEABLE"/> 
            </Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$UUID"/>
            </Device>
          </Component>        
        </xsl:if>

        <!-- CPU -->
        <xsl:if test="COMPONENTCLASS/COMPONENTCLASSVALUE='00070002'">         
          <Component>            
            <Class>CPU</Class>
            <Manufacturer>
              <xsl:value-of select="MANUFACTURER"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="MODEL"/>
            </Model>
            <Serial>
              <xsl:value-of select="SERIAL"/>
            </Serial>
            <Revision>
            <xsl:value-of select="REVISION"/>              
            </Revision>
            <Version>             
            </Version>
            <Field_Replaceable>
              <xsl:value-of select="FIELDREPLACEABLE"/> 
            </Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$UUID"/>
            </Device>
          </Component>        
        </xsl:if>
        
        <!-- Memory -->
        <xsl:if test="COMPONENTCLASS/COMPONENTCLASSVALUE='00060001'">         
          <Component>            
            <Class>Memory</Class>
            <Manufacturer>
              <xsl:value-of select="MANUFACTURER"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="MODEL"/>
            </Model>
            <Serial>
              <xsl:value-of select="SERIAL"/>
            </Serial>
            <Revision>
            <xsl:value-of select="REVISION"/>              
            </Revision>
            <Version>             
            </Version>
            <Field_Replaceable>
              <xsl:value-of select="FIELDREPLACEABLE"/> 
            </Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$UUID"/>
            </Device>
          </Component>        
        </xsl:if>

                
        <!-- NIC -->
        <xsl:if test="COMPONENTCLASS/COMPONENTCLASSVALUE='00090002'">         
          <Component>            
            <Class>Network Interface Card</Class>
            <Manufacturer>
              <xsl:value-of select="MANUFACTURER"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="MODEL"/>
            </Model>
            <Serial>
              <xsl:value-of select="SERIAL"/>
            </Serial>
            <Revision>
            <xsl:value-of select="REVISION"/>              
            </Revision>
            <Version>             
            </Version>
            <Field_Replaceable>
              <xsl:value-of select="FIELDREPLACEABLE"/> 
            </Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$UUID"/>
            </Device>
          </Component>        
        </xsl:if>

                
        <!-- BIOS -->
        <xsl:if test="COMPONENTCLASS/COMPONENTCLASSVALUE='00130003'">         
          <Component>            
            <Class>BIOS</Class>
            <Manufacturer>
              <xsl:value-of select="MANUFACTURER"/>
            </Manufacturer>
            <Model>
              <xsl:value-of select="MODEL"/>
            </Model>
            <Serial>
              <xsl:value-of select="SERIAL"/>
            </Serial>
            <Revision>
            <xsl:value-of select="REVISION"/>              
            </Revision>
            <Version>             
            </Version>
            <Field_Replaceable>
              <xsl:value-of select="FIELDREPLACEABLE"/> 
            </Field_Replaceable>
            <Addresses></Addresses>
            <Platform_Certificate></Platform_Certificate>
            <Platform_Certificate_URI></Platform_Certificate_URI>
            <Device>
              <xsl:value-of select="$UUID"/>
            </Device>
          </Component>        
        </xsl:if>
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