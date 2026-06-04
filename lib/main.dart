import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/settings_provider.dart';
import 'core/app_localizations.dart';
import 'features/editor/providers/editor_provider.dart';
import 'features/editor/pages/editor_page.dart';
import 'package:file_picker/src/platform/linux/file_picker_linux.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.linux) {
    FilePickerLinux.registerWith();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => EditorProvider()),
      ],
      child: const PepenApp(),
    ),
  );
}

class PepenApp extends StatelessWidget {
  const PepenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Pepen',
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        textTheme: GoogleFonts.getTextTheme(settings.globalFont),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1A1C1E),
        // textTheme: GoogleFonts.getTextTheme(...) is fine for the UI, 
        // but the editor container will be forced to white.
      ),
      home: const EditorPage(),
    );
  }
}
