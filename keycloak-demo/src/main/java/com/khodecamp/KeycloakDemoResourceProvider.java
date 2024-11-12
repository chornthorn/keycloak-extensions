package com.khodecamp;

import java.util.Map;

import org.keycloak.models.KeycloakSession;
import org.keycloak.services.resource.RealmResourceProvider;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
public class KeycloakDemoResourceProvider implements RealmResourceProvider {


    private final KeycloakSession session;

    @Override
    public Object getResource() {
        return this;
    }

    @Override
    public void close() {}

    @GET
    @Path("/hello")
    @Produces(MediaType.APPLICATION_JSON)
    public Response hello() {
        var arttributes = Map.of(
            "firstName", "John",
            "lastName", "Doe",
            "phone", "1234567890"
        );
        KeycloakDemoModel model = new KeycloakDemoModel("Hello, World!", arttributes);
        return Response.ok(model).build();
    }

}
