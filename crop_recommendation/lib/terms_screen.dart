
import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'main.dart';
import 'generated/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

class TermsScreen extends StatefulWidget {
  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final StorageService _storageService = StorageService();
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/79bad45b6a18df751d0504ebb14e03f1.jpg'),
      size: Size(200, 200),
    );
    setState(() {});
  }

  Future<void> _acceptTerms(BuildContext context) async {
    await _storageService.setAcceptedTerms(true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = _paletteGenerator?.dominantColor?.color ?? Colors.green.shade800;
    final Color textColor = _paletteGenerator?.lightVibrantColor?.color ?? Colors.black;
    final Color buttonColor = _paletteGenerator?.vibrantColor?.color ?? Colors.green.shade800;
    final Color overlayColor = _paletteGenerator?.darkMutedColor?.color?.withOpacity(0.6) ?? Colors.black.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.termsAndConditions),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/79bad45b6a18df751d0504ebb14e03f1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: overlayColor,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      AppLocalizations.of(context)!.termsAndConditionsContent,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _acceptTerms(context),
                  child: Text(AppLocalizations.of(context)!.accept),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
