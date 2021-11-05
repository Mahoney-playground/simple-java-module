package com.greetings;
import org.astro.World;

import java.util.Arrays;

public class Main {
    public static void main(String[] args) throws InterruptedException {
        System.out.format("Greetings %s!%n", World.name());
        System.out.println("Args: "+Arrays.asList(args));
        System.out.println("Props: "+System.getProperties());
        if (args.length > 0 && args[0].equals("sleep")) {
            Thread.sleep(1000 * 60);
        }
    }
}
