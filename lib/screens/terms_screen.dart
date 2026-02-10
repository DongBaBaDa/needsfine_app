import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.termsAndPolicy, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTermItem(l10n.serviceTerms, "https://needsfine.com/term.html"),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildTermItem(l10n.privacyPolicy, "https://needsfine.com/privacy.html"),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildTermItem(l10n.locationTerms, "https://needsfine.com/location.html"),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildTermItem(String title, String url) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: () => _launchURL(url),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    );
  }
}