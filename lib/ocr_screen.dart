
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  static const String apiKey = "K86805865788957";

  bool loading = false;
  String extractedText = "";

  Future<void> pickAndScanImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      loading = true;
      extractedText = "";
    });

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("https://api.ocr.space/parse/image"),
    );

    request.headers["apikey"] = apiKey;

    request.fields["language"] = "eng";
    request.fields["isOverlayRequired"] = "false";

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        result.files.single.bytes!,
        filename: result.files.single.name,
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

    setState(() {
      extractedText = text.trim();
      loading = false;
    });
  }

  Future<void> saveMedicines() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

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
        "taken": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Medicines saved to Firebase"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescription Scanner"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed:
                  loading ? null : pickAndScanImage,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Prescription"),
            ),
            const SizedBox(height: 20),
            if (loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.grey),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      extractedText.isEmpty
                          ? "OCR text will appear here."
                          : extractedText,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: extractedText.isEmpty
                  ? null
                  : saveMedicines,
              icon: const Icon(Icons.save),
              label:
                  const Text("Save Medicines"),
            ),
          ],
        ),
      ),
    );
  }
}