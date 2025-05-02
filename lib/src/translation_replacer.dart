import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Class to handle replacing string extensions with AppStrings keys.
class TranslationReplacer {
  final String directoryPath;
  final String extensionMethod; // Extension to search for (e.g., `.translate`)
  final String
  replacementFormat; // Replacement format (e.g., `AppStrings.key.trans(arguments: ...)`)

  TranslationReplacer({
    required this.directoryPath,
    required this.extensionMethod,
    required this.replacementFormat,
  });

  /// Start the replacement process
  void processFiles() {
    final directory = Directory(directoryPath);

    if (!directory.existsSync()) {
      print('Directory does not exist: $directoryPath');
      return;
    }

    // Recursively search for Dart files
    final dartFiles = directory
        .listSync(recursive: true)
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      _processFile(File(file.path));
    }
  }

  /// Process a single file
  void _processFile(File file) async {
    print('Processing file: ${file.path}');

    final content = await file.readAsString();
    final parseResult = parseString(content: content);

    // Visitor to find and replace the extensions
    final visitor = _TranslationVisitor(
      extensionMethod: extensionMethod,
      replacementFormat: replacementFormat,
    );

    parseResult.unit.visitChildren(visitor);

    // If replacements were made, write the updated content back to the file
    if (visitor.hasReplacements) {
      print('Replacements made in file: ${file.path}');
      await file.writeAsString(visitor.updatedContent);
    } else {
      print('No replacements found in file: ${file.path}');
    }
  }
}

/// Visitor to find and replace string extensions
class _TranslationVisitor extends RecursiveAstVisitor<void> {
  final String extensionMethod;
  final String replacementFormat;
  bool hasReplacements = false;
  String updatedContent = '';

  _TranslationVisitor({
    required this.extensionMethod,
    required this.replacementFormat,
  });

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == extensionMethod.replaceAll('.', '')) {
      // Extract the key and arguments
      final keyArgument = node.argumentList.arguments.firstWhere(
        (arg) => arg.toString().startsWith('key:'),
      );
      final argumentsArgument = node.argumentList.arguments.firstWhere(
        (arg) => arg.toString().startsWith('arguments:'),
      );

      final key = keyArgument.toString().split(':')[1].trim();
      final arguments = argumentsArgument.toString().split(':')[1].trim();

      // Create the replacement string
      final replacement = replacementFormat
          .replaceFirst('"key"', key)
          .replaceFirst('arguments: ...', 'arguments: $arguments');

      // Replace the old content in the source
      final oldContent = node.toSource();
      updatedContent = updatedContent.replaceFirst(oldContent, replacement);

      hasReplacements = true;
    }

    super.visitMethodInvocation(node);
  }
}

void main() {
  final replacer = TranslationReplacer(
    directoryPath: 'path/to/your/project', // Path to your Dart project
    extensionMethod: '.translate', // Extension method to search for
    replacementFormat:
        'AppStrings."key".trans(arguments: ...)', // Replacement format
  );

  replacer.processFiles();
}
