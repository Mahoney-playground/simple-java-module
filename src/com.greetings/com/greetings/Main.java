package com.greetings;
import org.astro.World;

import java.util.Arrays;
import java.util.HashSet;

public class Main {
    public static void main(String[] args) throws InterruptedException {

        System.out.format("Greetings %s!%n", World.name());

        var argSet = new HashSet<>(Arrays.asList(args));
        System.out.println("Args: "+argSet);

        if (argSet.contains("props")) {
            System.out.println("Props: " + System.getProperties());
        }

        if (argSet.contains("sleep")) {
            Thread.sleep(1000 * 10);
        }

        if (argSet.contains("die")) {
            System.exit(34);
        }
    }
}
