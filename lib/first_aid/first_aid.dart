import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'first_aid_detail.dart';

// Create a model to hold each first aid item
class _FirstAidItem {
  final String name;
  final String imagePath;

  _FirstAidItem(this.name, this.imagePath);
}

// List of first aid items with images
final List<_FirstAidItem> items = [
  _FirstAidItem('Skin Burn', 'assets/images/skin_burn.png'),
  _FirstAidItem('Heat Stroke', 'assets/images/heat_stroke.png'),
  _FirstAidItem('Bleeding', 'assets/images/bleeding.png'),
  _FirstAidItem('Poisoning', 'assets/images/poisoning.png'),
  _FirstAidItem('Heart Attack', 'assets/images/heart_attack.png'),
  _FirstAidItem('Choking', 'assets/images/choking.png'),
  _FirstAidItem('Sprains', 'assets/images/sprains.png'),
  _FirstAidItem('Fractures', 'assets/images/fractures.png'),
  _FirstAidItem('Drowning', 'assets/images/drowning.png'),
  _FirstAidItem('Allergic', 'assets/images/allergic.png'),
  _FirstAidItem('Hypothermia', 'assets/images/hypothermia.png'),
  _FirstAidItem('Severe Nosebleed', 'assets/images/nosebleed.png'),
];

// Method to open the dialer with 999 pre-filled
Future<void> _openDialer() async {
  final Uri url = Uri(scheme: 'tel', path: '999');
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    print('Could not launch dialer');
  }
}

class FirstAidPage extends StatefulWidget {
  const FirstAidPage({super.key});

  @override
  _FirstAidPageState createState() => _FirstAidPageState();
}

class _FirstAidPageState extends State<FirstAidPage> {
  // Search query to filter items
  TextEditingController _searchController = TextEditingController();
  List<_FirstAidItem> filteredItems = items;

  void _filterItems(String query) {
    setState(() {
      filteredItems = items
          .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Essential First Aid",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search bar for filtering first aid items
            TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                labelText: 'Search First Aid Item',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 10.0),
            // Grid view of first aid items
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FirstAidDetailPage(
                                name: item.name,
                                imagePath: item.imagePath,
                              ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              item.imagePath,
                              width: 60.0,
                              height: 60.0,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // SOS Button and Emergency Call
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _openDialer,
                    child: Container(
                      width: 90.0,
                      height: 90.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4.0),
                      ),
                      child: Center(
                        child: Text(
                          'SOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    'Emergency Call',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
