import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class RegisteredFace {
  const RegisteredFace({
    required this.name,
    required this.embeddings,
  });

  final String name;
  final List<List<double>> embeddings;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'embeddings': embeddings,
    };
  }

  factory RegisteredFace.fromJson(Map<String, dynamic> json) {
    final embeddingsJson = json['embeddings'];
    return RegisteredFace(
      name: (json['name'] as String?)?.trim() ?? '',
      embeddings: embeddingsJson is List
          ? embeddingsJson
              .whereType<List<dynamic>>()
              .map(
                (embedding) => embedding
                    .whereType<num>()
                    .map((value) => value.toDouble())
                    .toList(),
              )
              .where((embedding) => embedding.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

class FaceDatabaseService {
  const FaceDatabaseService({
    File? databaseFile,
  }) : _databaseFile = databaseFile;

  final File? _databaseFile;

  Future<bool> get hasRegisteredFaces async {
    final faces = await loadFaces();
    return faces.any((face) => face.embeddings.isNotEmpty);
  }

  Future<List<RegisteredFace>> loadFaces() async {
    final file = await _resolveDatabaseFile();
    if (!await file.exists()) {
      return const [];
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RegisteredFace.fromJson)
          .where((face) => face.name.isNotEmpty && face.embeddings.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveFaceSample({
    required String name,
    required List<double> embedding,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Name cannot be empty.');
    }
    if (embedding.isEmpty) {
      throw ArgumentError.value(
        embedding,
        'embedding',
        'Embedding cannot be empty.',
      );
    }

    final faces = [...await loadFaces()];
    final existingIndex = faces.indexWhere(
      (face) => face.name.toLowerCase() == cleanName.toLowerCase(),
    );

    if (existingIndex >= 0) {
      final existing = faces[existingIndex];
      faces[existingIndex] = RegisteredFace(
        name: existing.name,
        embeddings: [
          ...existing.embeddings,
          embedding,
        ],
      );
    } else {
      faces.add(
        RegisteredFace(
          name: cleanName,
          embeddings: [embedding],
        ),
      );
    }

    final file = await _resolveDatabaseFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(faces.map((face) => face.toJson()).toList()),
    );
  }

  Future<File> _resolveDatabaseFile() async {
    final injectedFile = _databaseFile;
    if (injectedFile != null) {
      return injectedFile;
    }

    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/registered_faces.json');
  }
}
