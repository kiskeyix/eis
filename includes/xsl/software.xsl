<?xml version='1.0' encoding='UTF-8' ?>
<!-- 
Stylesheet to convert software XML output to HTML

Author: Luis Mondesi <lemsx1@gmail.com>

Date: 2006-04-04 15:44 EDT 
Usage: xsltproc software.xsl software.xml > software.html

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
    
    <xsl:template match="/node/package">
        <p class='description'><xsl:value-of select='@id' /></p>
        <div class="extra">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="version"> 
        <p class='version'>
            <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="desc">
        <p class='info'>
            <xsl:apply-templates />
        </p>
    </xsl:template>

</xsl:stylesheet>
