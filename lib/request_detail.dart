import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestDetailPage extends StatelessWidget {
  final String requestId;

  const RequestDetailPage({Key? key, required this.requestId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('requests').doc(requestId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var request = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: ${request['title']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Description: ${request['description']}'),
                SizedBox(height: 10),
                Text('Category: ${request['category']}'),
                SizedBox(height: 10),
                Text('Urgency: ${request['urgency']}'),
                SizedBox(height: 10),
                Text('Location: ${request['location']}'),
                SizedBox(height: 10),
                Text('Preferred Date: ${request['preferred_date_time']}'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Accept the request
                    FirebaseFirestore.instance.collection('requests').doc(requestId).update({'status': 'In Progress'});
                    // Notify user or proceed to next step
                  },
                  child: Text('Accept Request'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
