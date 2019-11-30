package org.astro;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;

public class World {
    public static String name() {
        Logger logger = LoggerFactory.getLogger(World.class);
        String message = "world: "+Connection.class.getName();
        logger.info("Message is {}", message);
        return message;
    }
}
