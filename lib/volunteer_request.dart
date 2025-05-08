import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'request_detail.dart';

class VolunteerRequestsView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Volunteer Requests')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'Open')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var requests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              return Card(
                child: ListTile(
                  title: Text(request['title']),
                  subtitle: Text('${request['category']} - ${request['urgency']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailPage(
                          requestId: request.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
