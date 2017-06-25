package info.debatty.java.stringsimilarity;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.IOException;
import info.debatty.java.stringsimilarity.interfaces.NormalizedStringSimilarity;
import info.debatty.java.stringsimilarity.JaroWinkler;

public class Main {
    public static void main(String[] args) {
        try {
            String str1 = new String(Files.readAllBytes(Paths.get(args[0])));
            String str2 = new String(Files.readAllBytes(Paths.get(args[1])));
            NormalizedStringSimilarity sim = new JaroWinkler();
            System.out.println(sim.similarity(str1, str2));
        } catch (Exception e) {
            System.out.println("0");
        }
    }
}
