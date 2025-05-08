import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'first_aid_detail.dart';

// Create a model to hold each first aid item
class _FirstAidItem {
  final String name;
  final String imagePath;

  _FirstAidItem(this.name, this.imagePath);
}

// List of first aid items with image
final List<_FirstAidItem> items = [
  _FirstAidItem('Skin Burn', 'assets/image/skin_burn.png'),
  _FirstAidItem('Heat Stroke', 'assets/image/heat_stroke.png'),
  _FirstAidItem('Bleeding', 'assets/image/bleeding.png'),
  _FirstAidItem('Poisoning', 'assets/image/poisoning.png'),
  _FirstAidItem('Heart Attack', 'assets/image/heart_attack.png'),
  _FirstAidItem('Choking', 'assets/image/choking.png'),
  _FirstAidItem('Sprains', 'assets/image/sprains.png'),
  _FirstAidItem('Fractures', 'assets/image/fractures.png'),
  _FirstAidItem('Drowning', 'assets/image/drowning.png'),
  _FirstAidItem('Allergic', 'assets/image/allergic.png'), // Add image
  _FirstAidItem('Hypothermia', 'assets/image/hypothermia.png'), // Add image
  _FirstAidItem('Severe Nosebleed', 'assets/image/nosebleed.png'), // Add image
];


class FirstAidPage extends StatelessWidget {
  const FirstAidPage({super.key});

  // Method to open the dialer with 999 pre-filled
  Future<void> _openDialer() async {
    final Uri url = Uri(scheme: 'tel', path: '999');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Essential First Aid'),
        backgroundColor: Colors.orange, // Set the background color to orange
      ),
      body: Column(
        children: [
          // Grid view of first aid items
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FirstAidDetailPage(
                          name: item.name,
                          imagePath: item.imagePath,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
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
                            width: 70.0,
                            height: 70.0,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // SOS Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _openDialer,
              child: Container(
                width: 110.0,
                height: 110.0,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4.0),
                ),
                child: Center(
                  child: Text(
                    'SOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
