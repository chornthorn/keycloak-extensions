package com.khodecamp;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class KeycloakDemoModel {
    private String message;
    private Map<String, String> arttributes;
}
