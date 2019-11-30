package org.astro;

import java.sql.Connection;

public class World {
    public static String name() {
        return "world: "+Connection.class.getName();
    }
}
