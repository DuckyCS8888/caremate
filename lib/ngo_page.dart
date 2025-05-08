import 'package:flutter/material.dart';
import 'ngo_details.dart';

class NGOPage extends StatelessWidget {
  NGOPage({super.key});

  // List of NGO services with descriptions and links
  final List<Map<String, String>> ngoServices = [
    {
      'name': 'Fund',
      'images': 'assets/images/fund.png',
      'link': 'https://www.fundsforngos.org/',
      'description': 'This service provides funding to underprivileged communities, supporting various development programs, including healthcare, education, and infrastructure projects.'
    },
    {
      'name': 'Food',
      'images': 'assets/images/food.png',
      'link': 'https://foodaidfoundation.org/',
      'description': 'Provides emergency food supplies to families and individuals in need, ensuring that no one goes hungry during times of crisis or poverty.'
    },
    {
      'name': 'Health',
      'images': 'assets/images/health.png',
      'link': 'https://ngobase.org/cwa/MY/HLT/health-ngos-charities-malaysia',
      'description': 'Our health services focus on providing free medical care, including vaccinations, health screenings, and treatment for various diseases.'
    },
    {
      'name': 'Education',
      'images': 'assets/images/education.png',
      'link': 'https://ngobase.org/cwa/MY/EDU/education-and-training-ngos-charities-malaysia',
      'description': 'Education is a powerful tool for empowerment. We provide educational support, including scholarships, tutoring, and school supplies to disadvantaged students.'
    },
    {
      'name': 'Shelter',
      'images': 'assets/images/shelter.png',
      'link': 'https://www.shelterhome.org/',
      'description': 'We provide temporary shelter and basic amenities to homeless individuals, offering a safe and comfortable environment to rebuild their lives.'
    },
    {
      'name': 'Disability Support',
      'images': 'assets/images/disability_support.png',
      'link': 'https://ngobase.org/cswa/MY/HLT.DS/disability-support-malaysia',
      'description': 'We offer a range of support services for individuals with disabilities, including mobility aids, therapy, and resources for living independently.'
    },
    {
      'name': 'Disaster Relief',
      'images': 'assets/images/disaster_relief.png',
      'link': 'https://mercy.org.my/',
      'description': 'In the wake of natural disasters, we provide emergency relief, including food, water, medical aid, and shelter to affected populations.'
    },
    {
      'name': 'Legal Aid',
      'images': 'assets/images/legal_aid.png',
      'link': 'https://www.ngosource.org/blog/ngos-providing-pro-bono-legal-services',
      'description': 'Our legal aid services assist those who cannot afford legal representation, helping them navigate complex legal systems and protect their rights.'
    },
    {
      'name': 'Employment',
      'images': 'assets/images/employment_assistance.png',
      'link': 'https://www.indeed.com/q-ngo-program-assistant-jobs.html',
      'description': 'We provide job training, resume building, and job placement assistance to individuals looking to re-enter the workforce after a period of unemployment.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NGO Services'),
        backgroundColor: Colors.orange,
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: ngoServices.length,
        itemBuilder: (context, index) {
          final ngo = ngoServices[index];
          return GestureDetector(
            onTap: () {
              // Navigate to the NGO detail page with the relevant information
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NGODetailPage(
                    title: ngo['name']!,
                    link: ngo['link']!,
                    description: ngo['description']!,
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
                  // Container for the image with a white background and rounded corners
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),  // Specify opacity using .withValues()
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      ngo['images']!,
                      width: 70.0,
                      height: 70.0,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    ngo['name']!,
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
    );
  }
}
