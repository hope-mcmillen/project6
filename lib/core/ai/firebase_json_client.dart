import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

/// Small seam for deterministic validation/timeout tests without a Firebase app.
abstract interface class AiJsonClient {
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  });
}

class FirebaseJsonClient implements AiJsonClient {
  FirebaseJsonClient({
    required this.firebaseAI,
    this.modelName = 'gemini-3.8-flash',
  });
  final FirebaseAI firebaseAI;
  final String modelName;
  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) async {
    final model = firebaseAI.generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.2,
      ),
    );
    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        if (jpeg != null) InlineDataPart('image/jpeg', jpeg),
      ]),
    ]);
    return response.text ?? '';
  }
}
