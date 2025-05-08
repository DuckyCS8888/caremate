import 'package:flutter/material.dart';

import 'first_aid_data.dart';

class FirstAidDetailPage extends StatelessWidget {
  final String name;
  final String imagePath;

  // Constructor to receive the first aid item's name and images path
  const FirstAidDetailPage({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // Get the steps for the selected first aid skill
    final List<String> steps = firstAidSteps[name] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image of the first aid item
            Center(
              child: Image.asset(
                imagePath,
                width: 200.0,
                height: 200.0,
              ),
            ),
            const SizedBox(height: 20.0),
            // Display the steps
            Text(
              'First Aid Steps for $name:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            // Display each step dynamically
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.check_circle),
                    title: Text(steps[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
