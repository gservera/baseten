<?xml version="1.0" encoding="UTF-8" ?>
<!--
 ObjectModel.xsl
 BaseTen
 
 Copyright 2009 Marko Karppinen & Co. LLC.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
     http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output encoding="UTF-8" indent="no" method="text" />

    <xsl:template match="/">
        <xsl:text>graph G {&#10;</xsl:text>
        <xsl:text>&#9;rankdir="LR"&#10;</xsl:text>
        <xsl:text>&#9;node [shape = plaintext, style = rounded];&#10;</xsl:text>
        <xsl:apply-templates select="//entity" />
        
        <xsl:text>&#9;edge [];&#10;</xsl:text>
        <xsl:apply-templates select=".//relationship" mode="edge" />
        <xsl:text>}&#10;</xsl:text>
    </xsl:template>


    <xsl:template match="//entity">
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="./@id" />
        <xsl:text> [label = &lt;&#10;</xsl:text>
        <xsl:text>&#9;&#9;&lt;table border="1" cellspacing="0"&gt;&#10;</xsl:text>
        
        <xsl:text>&#9;&#9;&#9;&lt;tr&gt;&#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;&#9;&lt;td bgcolor="#e2bfc9"&gt;</xsl:text>
        <xsl:value-of select="./schemaName" />
        <xsl:text>.</xsl:text>
        <xsl:value-of select="./name" />
        <xsl:text>&lt;/td&gt;&#10;</xsl:text>
        <xsl:text>&#9;&#9;&#9;&lt;/tr&gt;&#10;</xsl:text>

        <xsl:apply-templates select="./attributes" />
        <xsl:apply-templates select="./relationships" />
        
        <xsl:text>&#9;&#9;&lt;/table&gt;&#10;</xsl:text>
        <xsl:text>&#9;&gt;];&#10;</xsl:text>
    </xsl:template>


    <xsl:template match="//attributes">
        <xsl:comment>Attributes</xsl:comment>
        <xsl:if test="0 &lt; count (./attribute [not (@isInherited = 'true')])">
            <xsl:text>&#9;&#9;&#9;&lt;tr&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&#9;&lt;td&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&#9;&#9;&lt;table border="0"&gt;&#10;</xsl:text>
            <xsl:apply-templates select="./attribute [not (@isInherited = 'true')]" />
            <xsl:text>&#9;&#9;&#9;&#9;&#9;&lt;/table&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&#9;&lt;/td&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&lt;/tr&gt;&#10;</xsl:text>
        </xsl:if>
    </xsl:template>


    <xsl:template match="//relationships">
        <xsl:comment>Relationships</xsl:comment>
        <xsl:if test="0 &lt; count (./relationship)">
            <xsl:text>&#9;&#9;&#9;&lt;tr&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&#9;&lt;td&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&#9;&#9;&lt;table border="0"&gt;&#10;</xsl:text>
            <xsl:apply-templates select="./relationship" />
            <xsl:text>&#9;&#9;&#9;&#9;&#9;&lt;/table&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&#9;&lt;/td&gt;&#10;</xsl:text>
            <xsl:text>&#9;&#9;&#9;&lt;/tr&gt;&#10;</xsl:text>
        </xsl:if>
    </xsl:template>


    <xsl:template match="//attribute">
        <xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;&lt;tr&gt;&#10;</xsl:text>

        <xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;&#9;&lt;td align="left" border="1" color="#aaaaaa"&gt;</xsl:text>
        <xsl:value-of select="./name" />
        <xsl:text>&lt;/td&gt;&#10;</xsl:text>

        <xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;&#9;&lt;td align="left" border="1" color="#aaaaaa"&gt;</xsl:text>
        <xsl:value-of select="./type" />
        <xsl:text>&lt;/td&gt;&#10;</xsl:text>

        <xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;&lt;/tr&gt;&#10;</xsl:text>
    </xsl:template>


    <xsl:template match="//relationship">
        <xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;&lt;tr&gt;&#10;</xsl:text>

        <xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;&#9;&lt;td align="left" border="1" color="#aaaaaa" port="</xsl:text>
        <xsl:value-of select="./name" />
        <xsl:text>"&gt;</xsl:text>
        <xsl:value-of select="./name" />
        <xsl:text>&lt;/td&gt;&#10;</xsl:text>

        <xsl:text>&#9;&#9;&#9;&#9;&#9;&#9;&lt;/tr&gt;&#10;</xsl:text>
    </xsl:template>
	
    
    <xsl:template match="//relationship" mode="edge">
        <xsl:variable name="entityName" select="../../@id" />
        <xsl:variable name="relName" select="./name" />
        <xsl:variable name="inverse" select="preceding::relationship [./target = $entityName and ./inverseRelationship = $relName][1]" />        
        <xsl:if test="$inverse">
            <xsl:text>&#9;</xsl:text>
            <xsl:value-of select="../../@id" />
            <xsl:text>:</xsl:text>
            <xsl:value-of select="./name" />
            <xsl:text>:c -- </xsl:text>
            <xsl:value-of select="./target" />
            <xsl:text>:</xsl:text>
            <xsl:value-of select="./inverseRelationship" />
            <xsl:text>:c </xsl:text>
            
            <xsl:text>[arrowhead = normal</xsl:text>
            <xsl:if test="./targetType = 'many'">
                <xsl:text>normal</xsl:text>
            </xsl:if>
            <xsl:text>, arrowtail = normal</xsl:text>
            <xsl:if test="$inverse/targetType = 'many'">
                <xsl:text>normal</xsl:text>
            </xsl:if>
            <xsl:text>]&#10;</xsl:text>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
