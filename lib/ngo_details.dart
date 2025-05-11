import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';  // Import the url_launcher package

class NGODetailPage extends StatelessWidget {
  final String title;
  final String link;
  final String description;

  const NGODetailPage({
    super.key,
    required this.title,
    required this.link,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
        style: GoogleFonts.comicNeue(
        fontSize: 26,
        fontWeight:
        FontWeight.w900, // Replace with your desired font family
        color: Colors.deepOrange,
        ),),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Description Container
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About $title',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16.0,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // Link to More Information
              Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Colors.orange,
                    size: 30.0,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Pass 'inApp: true' if you want to open the link inside the app's WebView,
                        // or 'inApp: false' to open it in the default browser.
                        _launchURL(link,
                            inApp: true); // Call the _launchURL method with inApp parameter
                      },
                      child: Text(
                        'Visit $title for more info',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url, {bool inApp = false}) async {
    final Uri uri = Uri.parse(url); // Convert string URL into Uri

    // Check if the URL can be launched
    if (await canLaunchUrl(uri)) {
      // If inApp is true, we open in the WebView, else we use the default browser
      await launchUrl(
        uri,
        mode: inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
        // Handle WebView and external app launch
        webOnlyWindowName: inApp
            ? '_self'
            : '_blank', // Open in the same window for WebView
      );
    } else {
      throw 'Could not launch $url'; // Throw an error if URL can't be opened
    }
  }
}