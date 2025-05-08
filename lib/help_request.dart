import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HelpRequestForm extends StatefulWidget {
  @override
  _HelpRequestFormState createState() => _HelpRequestFormState();
}

class _HelpRequestFormState extends State<HelpRequestForm> {
  final _formKey = GlobalKey<FormState>();
  String? _title, _description, _category, _urgency, _location;
  DateTime? _preferredDateTime;

  // Categories and Urgency options
  List<String> categories = ['Food', 'Transport', 'Companionship', 'Medication', 'Other'];
  List<String> urgencies = ['Low', 'Medium', 'High'];

  // Save the form and submit to Firestore
  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Submit to Firestore
      FirebaseFirestore.instance.collection('requests').add({
        'title': _title,
        'description': _description ?? '',
        'category': _category,
        'urgency': _urgency,
        'preferred_date_time': _preferredDateTime,
        'location': _location,
        'status': 'Open',  // Default status
      });

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Submitted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help Request Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Title
              TextFormField(
                decoration: InputDecoration(labelText: 'Request Title'),
                onSaved: (value) => _title = value,
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              // Description
              TextFormField(
                decoration: InputDecoration(labelText: 'Description (Optional)'),
                onSaved: (value) => _description = value,
                maxLines: 3,
              ),
              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category'),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _category = value),
                onSaved: (value) => _category = value,
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              // Urgency Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Urgency'),
                items: urgencies.map((urgency) {
                  return DropdownMenuItem(
                    value: urgency,
                    child: Text(urgency),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _urgency = value),
                onSaved: (value) => _urgency = value,
                validator: (value) => value == null ? 'Please select urgency' : null,
              ),
              // Preferred Date/Time
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Preferred Time/Date (Pick a Date)'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );

                  if (pickedDate != null && pickedDate != _preferredDateTime)
                    setState(() {
                      _preferredDateTime = pickedDate;
                    });
                },
                controller: TextEditingController(
                    text: _preferredDateTime == null
                        ? ''
                        : DateFormat('MM/dd/yyyy').format(_preferredDateTime!)),
              ),
              // Location
              TextFormField(
                decoration: InputDecoration(labelText: 'Location'),
                onSaved: (value) => _location = value,
                validator: (value) => value!.isEmpty ? 'Please enter a location' : null,
              ),
              // Submit Button
              ElevatedButton(
                onPressed: _submitRequest,
                child: Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
