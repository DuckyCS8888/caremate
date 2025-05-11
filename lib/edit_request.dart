import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditRequestPage extends StatefulWidget {
  final String requestId;
  final String currentTitle;
  final String currentDescription;
  final String currentCategory;
  final String currentUrgency;

  EditRequestPage({
    required this.requestId,
    required this.currentTitle,
    required this.currentDescription,
    required this.currentCategory,
    required this.currentUrgency,
  });

  @override
  _EditRequestPageState createState() => _EditRequestPageState();
}

class _EditRequestPageState extends State<EditRequestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedUrgency;
  bool _isLoading = false;

  // Available options for category and urgency
  final List<String> categories = [
    'Groceries',
    'Transport',
    'Companionship',
    'Medication',
    'Other',
  ];
  final List<String> urgencies = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.currentTitle;
    _descriptionController.text = widget.currentDescription;
    _selectedCategory =
        widget.currentCategory; // Set initial value to current category
    _selectedUrgency =
        widget.currentUrgency; // Set initial value to current urgency

    // Ensure that the selected value exists in the categories list
    if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
      _selectedCategory = null; // Reset if not found
    }

    // Ensure that the selected value exists in the urgencies list
    if (_selectedUrgency != null && !urgencies.contains(_selectedUrgency)) {
      _selectedUrgency = null; // Reset if not found
    }
  }

  Future<void> _updateRequest() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      // Show an error if any field is empty
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('All fields must be filled')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'category': _selectedCategory,
            'urgency': _selectedUrgency,
          })
          .then((_) {
            setState(() {
              _isLoading = false;
            });
            Navigator.pop(
              context,
            ); // Go back to the previous screen after updating
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Request Updated')));
          })
          .catchError((e) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating request: $e')),
            );
          });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Help Request",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900, // Replace with your desired font family
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field with Icon
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                icon: Icons.title,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 16),

              // Description Field with Icon
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                keyboardType: TextInputType.text,
                maxLines: 4,
              ),
              SizedBox(height: 16),

              // Category Dropdown
              _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              SizedBox(height: 16),

              // Urgency Dropdown
              _buildDropdown(
                label: 'Urgency',
                value: _selectedUrgency,
                items: urgencies,
                onChanged: (value) {
                  setState(() {
                    _selectedUrgency = value;
                  });
                },
              ),
              SizedBox(height: 24),

              // Update Button
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _updateRequest,
                    child: Text(
                      'Update Request',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      backgroundColor: Colors.deepOrangeAccent,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a styled text field with an icon
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepOrangeAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepOrangeAccent, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  // Helper method to build dropdown for category and urgency
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.arrow_drop_down, color: Colors.deepOrangeAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
    );
  }
}
