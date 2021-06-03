/**
 *  Copyright 2019 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package com.atomgraph.linkeddatahub.vocabulary;

import org.apache.jena.ontology.ObjectProperty;
import org.apache.jena.ontology.OntClass;
import org.apache.jena.ontology.OntModel;
import org.apache.jena.ontology.OntModelSpec;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.Resource;

/**
 *
 * @author Martynas Jusevičius {@literal <martynas@atomgraph.com>}
 */
public class ACL
{
    /** <p>The RDF model that holds the vocabulary terms</p> */
    private static OntModel m_model = ModelFactory.createOntologyModel(OntModelSpec.OWL_MEM, null);
    
    /** <p>The namespace of the vocabulary as a string</p> */
    public static final String NS = "http://www.w3.org/ns/auth/acl#";
    
    /** <p>The namespace of the vocabulary as a string</p>
     *  @see #NS */
    public static String getURI()
    {
        return NS;
    }
    
    /** <p>The namespace of the vocabulary as a resource</p> */
    public static final Resource NAMESPACE = m_model.createResource( NS );
    
    public static final OntClass Agent = m_model.createClass( NS + "Agent" );
    
    public static final OntClass Authorization = m_model.createClass( NS + "Authorization" );

    public static final OntClass Read = m_model.createClass( NS + "Read" );

    public static final OntClass Write = m_model.createClass( NS + "Write" );
    
    public static final OntClass Append = m_model.createClass( NS + "Append" );

    public static final OntClass AuthenticatedAgent = m_model.createClass( NS + "AuthenticatedAgent" );

    public static final ObjectProperty delegates = m_model.createObjectProperty( NS + "delegates" );

    public static final ObjectProperty owner = m_model.createObjectProperty( NS + "owner" );

    public static final ObjectProperty agent = m_model.createObjectProperty( NS + "agent" );
    
    public static final ObjectProperty agentClass = m_model.createObjectProperty( NS + "agentClass" );

    public static final ObjectProperty agentGroup = m_model.createObjectProperty( NS + "agentGroup" );

    public static final ObjectProperty mode = m_model.createObjectProperty( NS + "mode" );
    
    public static final ObjectProperty accessTo = m_model.createObjectProperty( NS + "accessTo" );

    public static final ObjectProperty accessToClass = m_model.createObjectProperty( NS + "accessToClass" );

}
