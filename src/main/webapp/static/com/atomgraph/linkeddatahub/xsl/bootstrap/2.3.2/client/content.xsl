<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
]>
<xsl:stylesheet version="3.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <!-- TEMPLATES -->

    <!-- content identity transform -->

    <xsl:template match="div[contains-token(@class, 'xhtml-content')]//div[contains-token(@class, 'span7')]" mode="content" priority="1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>

            <button type="button" class="btn btn-edit pull-right">
                <xsl:apply-templates select="key('resources', '&ac;EditMode', document(ac:document-uri('&ac;')))" mode="ac:label"/>
            </button>

            <xsl:copy-of select="*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@* | node()" mode="content">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- SELECT query -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = '&sp;Select'][sp:text]" mode="ldh:RenderContent" priority="1">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:param name="content-value" select="xs:anyURI(translate(@rdf:about, '.', '-'))" as="xs:anyURI"/>
        <!-- set $this variable value unless getting the query string from state -->
        <xsl:variable name="select-string" select="replace(sp:text, '\$this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
        <xsl:variable name="select-json" as="item()">
            <xsl:variable name="select-builder" select="ixsl:call(ixsl:get(ixsl:get(ixsl:window(), 'SPARQLBuilder'), 'SelectBuilder'), 'fromString', [ $select-string ])"/>
            <xsl:sequence select="ixsl:call($select-builder, 'build', [])"/>
        </xsl:variable>
        <xsl:variable name="select-json-string" select="ixsl:call(ixsl:get(ixsl:window(), 'JSON'), 'stringify', [ $select-json ])" as="xs:string"/>
        <xsl:variable name="select-xml" select="json-to-xml($select-json-string)" as="document-node()"/>
        <xsl:variable name="focus-var-name" select="$select-xml/json:map/json:array[@key = 'variables']/json:string[1]/substring-after(., '?')" as="xs:string"/>
        <!-- service can be explicitly specified on content using ldh:service -->
        <xsl:variable name="service-uri" select="xs:anyURI(ldh:service/@rdf:resource)" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>
        
        <xsl:choose>
            <!-- service URI is not specified or specified and can be loaded -->
            <xsl:when test="not($service-uri) or ($service-uri and exists($service))">
                <!-- window.LinkedDataHub.contents[{$content-value}] object is already created -->
                <!-- store the initial SELECT query (without modifiers) -->
                <ixsl:set-property name="select-query" select="$select-string" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-value)"/>
                <!-- store the first var name of the initial SELECT query -->
                <ixsl:set-property name="focus-var-name" select="$focus-var-name" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-value)"/>
                <xsl:if test="$service-uri">
                    <!-- store (the URI of) the service -->
                    <ixsl:set-property name="service-uri" select="$service-uri" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-value)"/>
                    <ixsl:set-property name="service" select="$service" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-value)"/>
                </xsl:if>

                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-limit">
                            <xsl:with-param name="limit" select="$page-size" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:document>
                </xsl:variable>
                <xsl:variable name="select-xml" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$select-xml" mode="ldh:replace-offset">
                            <xsl:with-param name="offset" select="0" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:document>
                </xsl:variable>

                <!-- store the transformed query XML -->
                <ixsl:set-property name="select-xml" select="$select-xml" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-value)"/>
                <!-- update progress bar -->
                <xsl:for-each select="$container//div[@class = 'bar']">
                    <ixsl:set-style name="width" select="'75%'" object="."/>
                </xsl:for-each>

                <xsl:call-template name="ldh:RenderContainer">
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="content-value" select="$content-value"/>
                    <xsl:with-param name="content" select="."/>
                    <xsl:with-param name="select-string" select="$select-string"/>
                    <xsl:with-param name="select-xml" select="$select-xml"/>
                    <xsl:with-param name="endpoint" select="$endpoint"/>
                    <xsl:with-param name="focus-var-name" select="$focus-var-name"/>
                    <xsl:with-param name="active-mode" select="if ($mode) then $mode else xs:anyURI('&ac;ListMode')"/>
                    <xsl:with-param name="replace-content" select="true()"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load service resource: <a href="{$service-uri}"><xsl:value-of select="$service-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- DESCRIBE/CONSTRUCT queries -->
    
    <xsl:template match="*[@rdf:about][rdf:type/@rdf:resource = ('&sp;Describe', '&sp;Construct')][sp:text]" mode="ldh:RenderContent" priority="1">
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        <!-- replace dots with dashes to avoid Saxon-JS treating them as field separators: https://saxonica.plan.io/issues/5031 -->
        <xsl:param name="content-value" select="xs:anyURI(translate(@rdf:about, '.', '-'))" as="xs:anyURI"/>
        <!-- set $this variable value unless getting the query string from state -->
        <xsl:variable name="query-string" select="replace(sp:text, '\$this', concat('&lt;', $uri, '&gt;'))" as="xs:string"/>
        <!-- service can be explicitly specified on content using ldh:service -->
        <xsl:variable name="service-uri" select="xs:anyURI(ldh:service/@rdf:resource)" as="xs:anyURI?"/>
        <xsl:variable name="service" select="key('resources', $service-uri, ixsl:get(ixsl:window(), 'LinkedDataHub.apps'))" as="element()?"/>
        <xsl:variable name="endpoint" select="($service/sd:endpoint/@rdf:resource/xs:anyURI(.), sd:endpoint())[1]" as="xs:anyURI"/>

        <xsl:choose>
            <!-- service URI is not specified or specified and can be loaded -->
            <xsl:when test="not($service-uri) or ($service-uri and exists($service))">
                <!-- window.LinkedDataHub.contents[{$content-value}] object is already created -->
                <xsl:if test="$service-uri">
                    <!-- store (the URI of) the service -->
                    <ixsl:set-property name="service-uri" select="$service-uri" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-value)"/>
                    <ixsl:set-property name="service" select="$service" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $content-value)"/>
                </xsl:if>

                <!-- update progress bar -->
                <xsl:for-each select="$container//div[@class = 'bar']">
                    <ixsl:set-style name="width" select="'75%'" object="."/>
                </xsl:for-each>

                <xsl:variable name="results-uri" select="ac:build-uri($endpoint, map{ 'query': $query-string })" as="xs:anyURI"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $results-uri)" as="xs:anyURI"/>
                
                <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                    <xsl:call-template name="onQueryContentLoad">
                        <xsl:with-param name="container" select="$container"/>
                        <xsl:with-param name="content-value" select="$content-value"/>
                        <xsl:with-param name="mode" select="$mode"/>
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load service resource: <a href="{$service-uri}"><xsl:value-of select="$service-uri"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- default content (RDF resource) -->
    
    <xsl:template match="*[*][@rdf:about]" mode="ldh:RenderContent">
        <xsl:param name="container" as="element()"/>

        <!-- hide progress bar -->
        <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'progress-bar']"/>
        
        <xsl:variable name="row-block" as="element()?">
            <xsl:apply-templates select="." mode="bs2:RowBlockContent"/>
        </xsl:variable>

        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$row-block/*"/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
    <!-- EVENT LISTENERS -->
    
    <!-- XHTML content edit button onclick -->
    
    <xsl:template match="div[contains-token(@class, 'xhtml-content')]//button[contains-token(@class, 'btn-edit')]" mode="ixsl:onclick">
        <xsl:variable name="button" select="." as="element()"/>
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'span7')]" as="element()"/>

        <xsl:variable name="xml-literal" as="document-node()">
            <xsl:document>
                <rdf:RDF>
                    <rdf:Description>
                        <rdf:type rdf:resource="&ldh;Content"/>
                        <rdf:value rdf:parseType="Literal">
                            <xsl:copy-of select="$container/*[not(. is $button)]"/>
                        </rdf:value>
                    </rdf:Description>
                </rdf:RDF>
            </xsl:document>
        </xsl:variable>
        <xsl:variable name="editor-html" as="element()*">
            <xsl:apply-templates select="$xml-literal//rdf:value/xhtml:*" mode="bs2:FormControl"/>
        </xsl:variable>
        
<!--        <xsl:message>
            $xml-literal: <xsl:value-of select="serialize($xml-literal)"/>
            $editor-html: <xsl:value-of select="serialize($editor-html)"/>
        </xsl:message>-->
        
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <xsl:copy-of select="$editor-html"/>
                
                <div class="form-actions">
                    <button type="button" class="btn btn-primary btn-save">
                        <xsl:value-of>
                            <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                        </xsl:value-of>
                    </button>
                </div>
            </xsl:result-document>
            
            <!-- call .wymeditor() on textarea to show WYMEditor -->
            <xsl:variable name="wymeditor" select="ixsl:call(ixsl:call(ixsl:window(), 'jQuery', [ . ]), 'wymeditor', [])"/>
            <xsl:variable name="content-uri" select="xs:anyURI(ac:uri() || '#' || ancestor::div[contains-token(@class, 'content')]/@id)" as="xs:anyURI"/>
            <xsl:message>$content-uri: <xsl:value-of select="$content-uri"/></xsl:message>
            <!-- replace dots which have a special meaning in Saxon-JS -->
            <xsl:variable name="escaped-content-uri" select="xs:anyURI(translate($content-uri, '.', '-'))" as="xs:anyURI"/>
            <!-- create new cache entry using content URI as key -->
            <ixsl:set-property name="{$escaped-content-uri}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
            <!-- store this content element -->
            <ixsl:set-property name="wymeditor" select="$wymeditor" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-uri)"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- resource content edit button onclick -->
    
    <xsl:template match="div[contains-token(@class, 'resource-content')]//button[contains-token(@class, 'btn-edit')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'resource-content')]" as="element()"/>
        <xsl:variable name="content-value" select="ixsl:get($container, 'dataset.contentValue')" as="xs:anyURI"/>
        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $content-value)"/>

        <!-- replace the middle column only -->
        <xsl:for-each select="$container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="offset2 span7">
                    <p>
                        <span></span>
                    </p>
                    
                    <div class="form-actions">
                        <button type="button" class="btn btn-primary btn-save">
                            <xsl:value-of>
                                <xsl:apply-templates select="key('resources', 'save', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))" mode="ac:label"/>
                            </xsl:value-of>
                        </button>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>
        
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': $request-uri, 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onTypeaheadResourceLoad">
                    <xsl:with-param name="resource-uri" select="$content-value"/>
                    <xsl:with-param name="typeahead-span" select="$container/div[contains-token(@class, 'span7')]/p/span[1]"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <!-- save xhtml-content onclick -->
    
    <xsl:template match="div[contains-token(@class, 'xhtml-content')]//button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'xhtml-content')]" as="element()"/>
        <xsl:variable name="textarea" select="ancestor::div[contains-token(@class, 'span7')]/textarea" as="element()"/>
        <xsl:sequence select="ixsl:call(ixsl:call(ixsl:window(), 'jQuery', [ $textarea ]), 'wymeditor', [])"/>
        <xsl:variable name="old-content-value" select="ldh:parse-html(string($textarea), 'text/html')" as="document-node()"/>
        <xsl:sequence name="store-html" select="ixsl:call($textarea, 'html', [])[current-date() lt xs:date('2000-01-01')]"/>
        <xsl:variable name="content-value" select="ldh:parse-html(string($textarea), 'text/html')" as="document-node()"/>

        <xsl:message>
            $old-content-value: <xsl:value-of select="serialize($old-content-value)"/>
            $content-value: <xsl:value-of select="ancestor::div[contains-token(@class, 'span7')]/textarea"/>
        </xsl:message>
    </xsl:template>

    <!-- save resource-content onclick -->
    
    <xsl:template match="div[contains-token(@class, 'resource-content')]//button[contains-token(@class, 'btn-save')]" mode="ixsl:onclick">
        <xsl:variable name="container" select="ancestor::div[contains-token(@class, 'resource-content')]" as="element()"/>
        <xsl:variable name="old-content-value" select="ixsl:get($container, 'dataset.contentValue')" as="xs:anyURI"/>
        <xsl:variable name="content-value" select="ixsl:get(preceding-sibling::span//input[@name = 'ou'], 'value')" as="xs:anyURI"/>

        <xsl:for-each select="$container">
            <!-- update @data-content-value value -->
            <ixsl:set-property name="dataset.contentValue" select="$content-value" object="."/>
            
            <xsl:call-template name="ldh:LoadContent">
                <xsl:with-param name="uri" select="$content-value"/>
            </xsl:call-template>
            
            <xsl:variable name="update-string" as="xs:string">
                <![CDATA[
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

DELETE
{
    GRAPH $this
    {
        $this ?seq ?content .
        ?content rdf:value $oldValue .
    }
}
INSERT
{
    GRAPH $this
    {
        $this ?seq ?content .
        ?content rdf:value $newValue .
    }
}
WHERE
{
    GRAPH $this
    {
        $this ?seq ?content .
        ?content rdf:value $oldValue .
    }
}
                ]]>
            </xsl:variable>
            <xsl:variable name="update-string" select="replace($update-string, '\$this', concat('&lt;', ac:uri(), '&gt;'))" as="xs:string"/>
            <xsl:variable name="update-string" select="replace($update-string, '\$oldValue', concat('&lt;', $old-content-value, '&gt;'))" as="xs:string"/>
            <xsl:variable name="update-string" select="replace($update-string, '\$newValue', concat('&lt;', $content-value, '&gt;'))" as="xs:string"/>

            <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), ac:uri())" as="xs:anyURI"/>
            <xsl:variable name="request" as="item()*">
                <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                    <xsl:call-template name="onContentUpdate">
                    </xsl:call-template>
                </ixsl:schedule-action>
            </xsl:variable>
            <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <!-- load content -->
    
    <xsl:template name="ldh:LoadContent">
        <xsl:context-item as="element()" use="required"/> <!-- container element -->
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:variable name="content-value" select="ixsl:get(., 'dataset.contentValue')" as="xs:anyURI"/> <!-- get the value of the @data-content-value attribute -->
        <xsl:variable name="mode" select="if (ixsl:contains(., 'dataset.contentMode')) then xs:anyURI(ixsl:get(., 'dataset.contentMode')) else ()" as="xs:anyURI?"/> <!-- get the value of the @data-content-mode attribute -->
        <xsl:variable name="container" select="." as="element()"/>
        <xsl:variable name="progress-container" select="if (contains-token(@class, 'row-fluid')) then ./div[contains-token(@class, 'span7')] else ." as="element()"/>

        <!-- show progress bar in the middle column -->
        <xsl:for-each select="$progress-container">
            <xsl:result-document href="?." method="ixsl:replace-content">
                <div class="progress-bar">
                    <div class="progress progress-striped active">
                        <div class="bar" style="width: 25%;"></div>
                    </div>
                </div>
            </xsl:result-document>
        </xsl:for-each>

        <xsl:variable name="request-uri" select="ldh:href($ldt:base, ldh:absolute-path(ldh:href()), $content-value)" as="xs:anyURI"/>
        <xsl:variable name="request" as="item()*">
            <ixsl:schedule-action http-request="map{ 'method': 'GET', 'href': ac:document-uri($request-uri), 'headers': map{ 'Accept': 'application/rdf+xml' } }">
                <xsl:call-template name="onContentLoad">
                    <xsl:with-param name="uri" select="$uri"/>
                    <xsl:with-param name="content-value" select="$content-value"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="mode" select="$mode"/>
                </xsl:call-template>
            </ixsl:schedule-action>
        </xsl:variable>
        <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>
    
    <!-- embed content -->
    
    <xsl:template name="onContentLoad">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="uri" as="xs:anyURI"/>
        <xsl:param name="content-value" as="xs:anyURI"/>
        <xsl:param name="container" as="element()"/>
        <xsl:param name="container-id" select="ixsl:get($container, 'id')" as="xs:string"/>
        <xsl:param name="mode" as="xs:anyURI?"/>
        
        <!-- for some reason Saxon-JS 2.3 does not see this variable if it's inside <xsl:when> -->
        <xsl:variable name="content" select="key('resources', $content-value, ?body)" as="element()?"/>
        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml' and $content">
                <!-- replace dots which have a special meaning in Saxon-JS -->
                <xsl:variable name="escaped-content-value" select="xs:anyURI(translate($content-value, '.', '-'))" as="xs:anyURI"/>
                <!-- create new cache entry using content URI as key -->
                <ixsl:set-property name="{$escaped-content-value}" select="ldh:new-object()" object="ixsl:get(ixsl:window(), 'LinkedDataHub.contents')"/>
                <!-- store this content element -->
                <ixsl:set-property name="content" select="$content" object="ixsl:get(ixsl:get(ixsl:window(), 'LinkedDataHub.contents'), $escaped-content-value)"/>

                <xsl:for-each select="$container//div[@class = 'bar']">
                    <!-- update progress bar -->
                    <ixsl:set-style name="width" select="'50%'" object="."/>
                </xsl:for-each>

                <xsl:apply-templates select="$content" mode="ldh:RenderContent">
                    <xsl:with-param name="uri" select="$uri"/>
                    <xsl:with-param name="container" select="$container"/>
                    <xsl:with-param name="mode" select="$mode"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- content could not be loaded as RDF -->
            <xsl:when test="?status = 406">
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <object data="{$content-value}"/>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load content resource: <a href="{$content-value}"><xsl:value-of select="$content-value"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- embed DESCRIBE/CONSTRUCT result -->
    
    <xsl:template name="onQueryContentLoad">
        <xsl:param name="container" as="element()"/>
        <xsl:param name="content-value" as="xs:anyURI"/>
        <xsl:param name="mode" as="xs:anyURI?"/>

        <xsl:choose>
            <xsl:when test="?status = 200 and ?media-type = 'application/rdf+xml'">
                <xsl:for-each select="?body">
                    <!-- hide progress bar -->
                    <ixsl:set-style name="display" select="'none'" object="$container//div[@class = 'progress-bar']"/>

                    <xsl:variable name="row-block" as="element()*">
                        <xsl:apply-templates select="." mode="bs2:RowBlockContent"/>
                    </xsl:variable>

                    <xsl:for-each select="$container">
                        <xsl:result-document href="?." method="ixsl:replace-content">
                            <xsl:copy-of select="$row-block"/>
                        </xsl:result-document>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$container">
                    <xsl:result-document href="?." method="ixsl:replace-content">
                        <div class="alert alert-block">
                            <strong>Could not load content resource: <a href="{$content-value}"><xsl:value-of select="$content-value"/></a></strong>
                        </div>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- inline content update -->
    
    <xsl:template name="onContentUpdate">
        <xsl:context-item as="map(*)" use="required"/>
    </xsl:template>
    
</xsl:stylesheet>