import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import 'customer_login_screen.dart';
import 'worker_login_screen.dart';

void showLoginModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => LoginModal(),
  );
}

class LoginModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Watch simple language provider for rebuilds
    final langCode = Provider.of<LanguageProvider>(context).appLocale.languageCode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              AppLocalizations.get(langCode, 'choose_login'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 16),
            // Language Dropdown
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: languageProvider.appLocale.languageCode,
                      icon: Icon(Icons.language, color: Color(0xFF3E60FF)),
                      items: [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ta', child: Text('Tamil (தமிழ்)')),
                        DropdownMenuItem(value: 'kn', child: Text('Kannada (icon)')),
                        DropdownMenuItem(value: 'hi', child: Text('Hindi (हिंदी)')),
                      ],
                      onChanged: (String? val) {
                        if (val != null) {
                          languageProvider.changeLanguage(Locale(val));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            // Customer Login
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CustomerLoginScreen()),
                );
              },
              icon: Icon(Icons.person, size: 24),
              label: Text(
                AppLocalizations.get(langCode, 'customer_login'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3E60FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: Size(double.infinity, 56),
              ),
            ),
            SizedBox(height: 16),
            // Worker Login
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WorkerLoginScreen()),
                );
              },
              icon: Icon(Icons.directions_bus, size: 24),
              label: Text(
                AppLocalizations.get(langCode, 'worker_login'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00C567),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: Size(double.infinity, 56),
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.get(langCode, 'cancel'), style: TextStyle(color: Color(0xFF6B7280))),
            ),
          ],
        ),
      ),
    );
  }
}
