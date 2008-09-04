<?xml version='1.0' encoding='UTF-8' ?>
<!-- 
Stylesheet to convert LSHW XML output to HTML

Author: Luis Mondesi <lemsx1@gmail.com>

Date: 2006-04-04 15:44 EDT 
Usage: xsltproc lshw.xsl lshw.xml > lshw.html

This Stylesheet is made available under the terms of the GNU GPL.

See the file COPYING at the root of the source repository, or 
http://www.gnu.org/ for details.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" indent="yes" />         
    <xsl:template match="/">                         
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="/node"> 
        <div class='hostinfo'>
            <p class='hostname'>
                <b><xsl:value-of select='@id' /></b>
            </p>
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="/node/node[@id='core']">
        <div class="extra">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="description"> 
        <p class='description'>
            <b><xsl:apply-templates /></b>
        </p>
    </xsl:template>

    <xsl:template match="product">
        <p class='product'>
            <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="vendor">
        <p class='vendor'>
            <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="serial">
        <p class='serial'>
            <i>Serial:</i> <xsl:apply-templates />
        </p>
    </xsl:template>
    
    <xsl:template match="version">
        <p class='version'>
            <i>Version:</i> <xsl:apply-templates />
        </p>
    </xsl:template>
    
    <xsl:template match="businfo">
        <p class='businfo'>
            <i>Businfo:</i> <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="slot">
        <p class='slot'>
            <i>Slot:</i> <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="width|size|capacity|clock">
        <p class='units'>
            <xsl:apply-templates />
            <xsl:value-of select='@units' />
        </p>
    </xsl:template>

    <xsl:template match="capabilities">
        <div class="capabilities">
            <ul>
                <xsl:apply-templates />
            </ul>
        </div>
    </xsl:template>
    <xsl:template match="capability">
        <li>
            <xsl:choose>
                <xsl:when test="text() !=''">
                    <xsl:apply-templates />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select='@id' />
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>

    <xsl:template match="resources">
        <div class="resources">
            <ul>
                <xsl:apply-templates />
            </ul>
        </div>
    </xsl:template>
    <xsl:template match="resource">
        <li><xsl:value-of select='@type' />: <xsl:value-of select='@value' /></li>
    </xsl:template>

    <xsl:template match="configuration">
        <div class="configuration">
            <ul>
                <xsl:apply-templates />
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="setting">
        <li><xsl:value-of select='@id' />: <xsl:value-of select='@value' /></li>
    </xsl:template>

    <xsl:template match="physid">
        <p class='physid'>
            <i>PhysID:</i> <xsl:apply-templates />
        </p>
    </xsl:template>
    
    <xsl:template match="logicalname">
        <p class='logicalname'>
            <i>LogicalName:</i> <xsl:apply-templates />
        </p>
    </xsl:template>
    
    <xsl:template match="dev">
        <p class='device'>
            <i>Device:</i> <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="/node/node/node[@id='firmware']">
        <div class="firmware">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="/node/node/node[substring-before(@id,':')='cpu']">
        <div class="cpu">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="/node/node/node[@id='cpu']">
        <div class="cpu">
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="/node/node/node[substring-before(@id,':')='cpu']/node[substring-before(@id,':')='cache']">
        <div class="cache">
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="/node/node/node[substring-before(@id,':')='memory']">
        <div class="memory">
                <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="/node/node/node[@id='memory']">
        <div class="memory">
                <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="/node/node/node[@id='pci']">
        <div class="pci">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="/node/node/node[@id='pci']/node[@id='display']">
        <div class="vga">
            <xsl:apply-templates />
        </div>
    </xsl:template>

</xsl:stylesheet>
