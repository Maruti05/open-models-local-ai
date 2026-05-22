import 'database_service.dart';

class LocalFileContext {
  final String id;
  final String filename;
  final String content;
  final DateTime addedAt;

  LocalFileContext({
    required this.id,
    required this.filename,
    required this.content,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'content': content,
      'added_at': addedAt.toIso8601String(),
    };
  }
}

class FileContextService {
  FileContextService._privateConstructor();
  static final FileContextService instance = FileContextService._privateConstructor();

  // Adds a document to the local RAG database
  Future<LocalFileContext> ingestFile(String filename, String content) async {
    final fileContext = LocalFileContext(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filename: filename,
      content: content,
      addedAt: DateTime.now(),
    );

    final db = await DatabaseService.instance.database;
    await db.insert('file_contexts', fileContext.toMap());

    return fileContext;
  }

  // Retrieve all ingested documents
  Future<List<LocalFileContext>> getIngestedFiles() async {
    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('file_contexts', orderBy: 'added_at DESC');

    return List.generate(maps.length, (i) {
      return LocalFileContext(
        id: maps[i]['id'] as String,
        filename: maps[i]['filename'] as String,
        content: maps[i]['content'] as String,
        addedAt: DateTime.parse(maps[i]['added_at'] as String),
      );
    });
  }

  // Delete a document from local storage
  Future<void> deleteFile(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('file_contexts', where: 'id = ?', whereArgs: [id]);
  }

  // Generates the final injected system context instruction prompt from active files
  Future<String> buildSystemPromptWithContext(String baseSystemPrompt) async {
    final files = await getIngestedFiles();
    if (files.isEmpty) return baseSystemPrompt;

    final contextBuffer = StringBuffer();
    contextBuffer.writeln(baseSystemPrompt);
    contextBuffer.writeln('\n[ON-DEVICE RETRIEVAL-AUGMENTED CONTEXT ATTACHMENTS]');
    contextBuffer.writeln('The user has attached the following local documents for context reference. Refer to them to answer queries accurately:');

    for (var file in files) {
      contextBuffer.writeln('\n--- Document: ${file.filename} ---');
      contextBuffer.writeln(file.content);
    }
    contextBuffer.writeln('---------------------------------------');

    return contextBuffer.toString();
  }
}
