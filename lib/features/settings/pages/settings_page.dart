import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/settings_provider.dart';
import '../../../core/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.translate('settings'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(l10n.translate('language')),
            trailing: DropdownButton<String>(
              value: settings.locale.languageCode,
              onChanged: (code) => settings.setLocale(Locale(code!)),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.translate('theme_mode')),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (mode) => settings.setThemeMode(mode!),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.translate('system'))),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.translate('light'))),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.translate('dark'))),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.translate('global_font')),
            trailing: DropdownButton<String>(
              value: settings.globalFont,
              onChanged: (font) => settings.setGlobalFont(font!),
              items: [
                'Roboto',
                'Lato',
                'Open Sans',
                'Montserrat',
                'Merriweather',
                'Playfair Display',
              ].map((font) => DropdownMenuItem(value: font, child: Text(font))).toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
