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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, size: 24),
              const SizedBox(width: 12),
              Text(
                l10n.translate('settings'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            context,
            l10n.translate('language'),
            DropdownButton<String>(
              value: settings.locale.languageCode,
              underline: const SizedBox(),
              onChanged: (code) => settings.setLocale(Locale(code!)),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
              ],
            ),
          ),
          const Divider(),
          _buildSettingItem(
            context,
            l10n.translate('theme_mode'),
            DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              onChanged: (mode) => settings.setThemeMode(mode!),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.translate('system'))),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.translate('light'))),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.translate('dark'))),
              ],
            ),
          ),
          const Divider(),
          _buildSettingItem(
            context,
            l10n.translate('global_font'),
            DropdownButton<String>(
              value: settings.globalFont,
              underline: const SizedBox(),
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
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF2C2C2C) 
                : Colors.white,
            ),
            child: trailing,
          ),
        ],
      ),
    );
  }
}
