/**
 *  Copyright 2022 Martynas Jusevičius <martynas@atomgraph.com>
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
package com.atomgraph.linkeddatahub.server.event;

import com.atomgraph.core.util.jena.DataManager;
import com.atomgraph.linkeddatahub.apps.model.Application;
import org.apache.jena.rdf.model.Resource;

/**
 * Event that signals that a new ACL authorization is created.
 * 
 * @author {@literal Martynas Jusevičius <martynas@atomgraph.com>}
 */
public class AuthorizationCreated
{

    private final Application app;
    private final DataManager dataManager;
    private final Resource authorization;
    
    /**
     * Constructs the event from application and authorization.
     * 
     * @param app associated application
     * @param dataManager RDF data manager (TO-DO: replace with <code>LinkedDataClient</code>)
     * @param authorization associated authorization
     */
    public AuthorizationCreated(Application app, DataManager dataManager, Resource authorization)
    {
        this.app = app;
        this.dataManager = dataManager;
        this.authorization = authorization;
    }
    
    /**
     * Returns application resource.
     * 
     * @return application resource
     */
    public Application getApplication()
    {
        return app;
    }
    
    /**
     * Returns RDF data manager.
     * 
     * @return data manager
     */
    public DataManager getDataManager()
    {
        return dataManager;
    }
    
    /**
     * Returns authorization resource
     * 
     * @return authorization resource
     */
    public Resource getAuthorization()
    {
        return authorization;
    }
    
}
