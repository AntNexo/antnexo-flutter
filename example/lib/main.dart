import 'package:antnexo/antnexo.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const ExampleApp());

/// The plugin's sample app (the full one comes with the Dart API).
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('AntNexo example')),
      body: const Center(child: Text('antnexo $sdkVersion')),
    ),
  );
}
