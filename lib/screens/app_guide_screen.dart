import 'package:flutter/material.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.customerCenter, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildGuideSection(
            title: l10n.guideNearbyTitle,
            content: l10n.guideNearbyContent,
          ),
          _buildGuideSection(
            title: l10n.guideRankTitle,
            content: l10n.guideRankContent,
          ),
          _buildGuideSection(
            title: l10n.guideReviewTitle,
            content: l10n.guideReviewContent,
          ),
          _buildGuideSection(
            title: l10n.guideMyPageTitle,
            content: l10n.guideMyPageContent,
          ),
          _buildGuideSection(
            title: l10n.guideSearchTitle,
            content: l10n.guideSearchContent,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF3A3A3C),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF2F2F7), thickness: 1),
        ],
      ),
    );
  }
}
