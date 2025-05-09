import 'package:flutter/material.dart';

class CommunityForum extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CareMate Home")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Categories Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CategoryButton('Food'),
                CategoryButton('Fund'),
                CategoryButton('Health'),
                CategoryButton('Education'),
                CategoryButton('Shelter'),
                CategoryButton('Disability Support'),
              ],
            ),
            // Post Cards (You can query Firestore for posts)
            PostCard(
              name: 'Ibrahim Bin Saiful',
              location: 'Kedah',
              image: 'assets/food1.jpg',
              likes: 7,
              comments: 3,
            ),
            PostCard(
              name: 'Tan Chun Meng',
              location: 'Kelantan',
              image: 'assets/food2.jpg',
              likes: 10,
              comments: 2,
            ),
            PostCard(
              name: 'Subramanium A/L Aramugam',
              location: 'Terengganu',
              image: 'assets/food3.jpg',
              likes: 5,
              comments: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String categoryName;

  CategoryButton(this.categoryName);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Handle category click
      },
      child: Text(categoryName),
    );
  }
}

class PostCard extends StatelessWidget {
  final String name;
  final String location;
  final String image;
  final int likes;
  final int comments;

  PostCard({required this.name, required this.location, required this.image, required this.likes, required this.comments});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(name),
            subtitle: Text(location),
          ),
          Image.asset(image),
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red),
              Text('$likes Likes'),
              Icon(Icons.comment),
              Text('$comments Comments'),
            ],
          ),
        ],
      ),
    );
  }
}
