package com.khodecamp;

import org.keycloak.Config.Scope;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.services.resource.RealmResourceProvider;
import org.keycloak.services.resource.RealmResourceProviderFactory;

import com.google.auto.service.AutoService;

@AutoService(RealmResourceProviderFactory.class)
public class KeycloakDemoResourceProviderFactory implements RealmResourceProviderFactory {

    public static final String ID = "keycloak-demo";


    @Override
    public void close() {
       
    }

    @Override
    public RealmResourceProvider create(KeycloakSession session) {
        return new KeycloakDemoResourceProvider(session);
    }

    @Override
    public String getId() {
        return ID;
    }

    @Override
    public void init(Scope arg0) {
        
    }

    @Override
    public void postInit(KeycloakSessionFactory arg0) {

    }
}
