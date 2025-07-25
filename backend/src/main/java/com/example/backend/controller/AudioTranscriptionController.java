package com.example.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class AudioTranscriptionController {

    @PostMapping("/transcribe")
    public ResponseEntity<Map<String, String>> transcrireAudio(@RequestParam("audioFile") MultipartFile audioFile) {
        try {
            System.out.println("=== [UPLOAD AUDIO] ===");
            System.out.println("Nom original : " + audioFile.getOriginalFilename());
            System.out.println("Taille reçue : " + audioFile.getSize() + " octets");

            if (audioFile.getSize() == 0) {
                return ResponseEntity.badRequest().body(Map.of("error", "Fichier audio vide"));
            }

            // 🔹 Déterminer l'extension correcte
            String originalFilename = audioFile.getOriginalFilename();
            String extension = ".wav";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf('.'));
            }
            System.out.println("Extension détectée : " + extension);

            // 🔹 Sauvegarder le fichier temporaire
            File fichierTemp = File.createTempFile("upload_audio_", extension);
            audioFile.transferTo(fichierTemp);
            System.out.println("Fichier temporaire créé : " + fichierTemp.getAbsolutePath());
            System.out.println("Taille fichier temporaire : " + fichierTemp.length() + " octets");

            // 🔹 Dossier temporaire pour Whisper
            String tempDir = System.getProperty("java.io.tmpdir");
            System.out.println("Répertoire temporaire Whisper : " + tempDir);

            // 🔹 Exécuter Whisper
            String transcription = executerWhisper(fichierTemp.getAbsolutePath(), tempDir);

            // 🔹 Nettoyage
            boolean deleted = fichierTemp.delete();
            System.out.println("Suppression du fichier temporaire : " + deleted);

            // 🔹 Réponse
            Map<String, String> response = new HashMap<>();
            response.put("transcript", transcription);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Erreur lors de la transcription : " + e.getMessage()));
        }
    }

    public String executerWhisper(String cheminFichierAudio, String outputDir) throws IOException, InterruptedException {
        System.out.println("=== [WHISPER EXECUTION] ===");
        System.out.println("Chemin fichier audio : " + cheminFichierAudio);
        System.out.println("Répertoire sortie Whisper : " + outputDir);

        ProcessBuilder pb = new ProcessBuilder(
                "whisper",
                cheminFichierAudio,
                "--model", "base",
                "--output_format", "txt",
                "--output_dir", outputDir
        );
        pb.redirectErrorStream(true);
        Process process = pb.start();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String ligne;
            while ((ligne = reader.readLine()) != null) {
                System.out.println("[Whisper LOG] " + ligne);
            }
        }

        int exitCode = process.waitFor();
        System.out.println("Code de sortie Whisper : " + exitCode);

        if (exitCode != 0) {
            throw new RuntimeException("Whisper a échoué avec le code : " + exitCode);
        }

        // 🔹 Localiser le fichier texte généré par Whisper
        String nomFichierTxt = new File(cheminFichierAudio).getName().replaceAll("\\.[^.]+$", ".txt");
        Path cheminTxt = Path.of(outputDir, nomFichierTxt);
        System.out.println("Fichier transcription attendu : " + cheminTxt);

        if (!Files.exists(cheminTxt)) {
            throw new RuntimeException("Fichier de transcription non trouvé : " + cheminTxt);
        }

        // 🔹 Lire et retourner la transcription
        String transcription = Files.readString(cheminTxt);
        Files.delete(cheminTxt);
        System.out.println("Fichier transcription supprimé après lecture");

        return transcription.trim();
    }
}
