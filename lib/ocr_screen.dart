import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  // OCR.space API key
  static const String apiKey = "K86805865788957";

  bool loading = false;
  String extractedText = "";

  // ============================================================
  // PICK PRESCRIPTION IMAGE AND SCAN
  // ============================================================

  Future<void> pickAndScanImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Opens image selection on Chrome
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        return;
      }

      final Uint8List imageBytes = await image.readAsBytes();

      setState(() {
        loading = true;
        extractedText = "";
      });

      // ========================================================
      // SEND IMAGE TO OCR.SPACE
      // ========================================================

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://api.ocr.space/parse/image"),
      );

      request.headers["apikey"] = apiKey;

      request.fields["language"] = "eng";
      request.fields["isOverlayRequired"] = "false";
      request.fields["OCREngine"] = "2";

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          imageBytes,
          filename: image.name,
        ),
      );

      final response = await request.send();

      final body = await response.stream.bytesToString();

      final json = jsonDecode(body);

      String text = "";

      if (json["ParsedResults"] != null &&
          json["ParsedResults"].isNotEmpty) {
        text = json["ParsedResults"][0]["ParsedText"] ?? "";
      }

      if (!mounted) return;

      setState(() {
        extractedText = text.trim();
        loading = false;
      });

      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not detect text. Try a clearer prescription image.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "OCR failed: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // SAVE OCR MEDICINES TO FIREBASE
  // ============================================================

  Future<void> saveMedicines() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in."),
        ),
      );
      return;
    }

    if (extractedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No medicine information found."),
        ),
      );
      return;
    }

    try {
      final lines = extractedText
          .split("\n")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (final medicine in lines) {
        await FirebaseFirestore.instance
            .collection("medications")
            .add({
          "userId": user.uid,
          "name": medicine,
          "dosage": "",
          "time": "",
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Medicines saved to Firebase",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to save medicines: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF9),

      appBar: AppBar(
        title: const Text(
          "Prescription Scanner",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF4FBF9),
        elevation: 0,
        foregroundColor: const Color(0xFF193B35),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // ==================================================
            // HEADER CARD
            // ==================================================

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xFFDDF5EB),
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.document_scanner_rounded,
                    size: 42,
                    color: Color(0xFF39796B),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Scan Prescription",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF193B35),
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    "Upload a prescription image and SmartCare "
                    "will extract the text for you.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF52716A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // UPLOAD BUTTON
            // ==================================================

            SizedBox(
              height: 52,

              child: ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : pickAndScanImage,

                icon: const Icon(
                  Icons.upload_file_rounded,
                ),

                label: const Text(
                  "Upload Prescription",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9ED8C7),
                  foregroundColor: const Color(0xFF193B35),
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // OCR RESULT
            // ==================================================

            Expanded(
              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(
                    color: const Color(0xFFD5E9E2),
                  ),
                ),

                child: loading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF39796B),
                            ),

                            SizedBox(height: 16),

                            Text(
                              "Scanning prescription...",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF52716A),
                              ),
                            ),
                          ],
                        ),
                      )

                    : SingleChildScrollView(
                        child: extractedText.isEmpty
                            ? const Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,

                                children: [
                                  SizedBox(height: 60),

                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 60,
                                    color: Color(0xFF9ABBB1),
                                  ),

                                  SizedBox(height: 15),

                                  Text(
                                    "OCR text will appear here.",
                                    textAlign: TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF52716A),
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  Text(
                                    "Upload a prescription to begin.",
                                    textAlign: TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF7C9992),
                                    ),
                                  ),
                                ],
                              )

                            : Text(
                                extractedText,

                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Color(0xFF193B35),
                                ),
                              ),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // SAVE BUTTON
            // ==================================================

            SizedBox(
              height: 52,

              child: ElevatedButton.icon(
                onPressed:
                    extractedText.trim().isEmpty || loading
                        ? null
                        : saveMedicines,

                icon: const Icon(
                  Icons.save_rounded,
                ),

                label: const Text(
                  "Save Medicines",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF78B9A7),
                  foregroundColor: Colors.white,

                  disabledBackgroundColor:
                      const Color(0xFFE0EBE7),

                  disabledForegroundColor:
                      const Color(0xFF9AAFA9),

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}