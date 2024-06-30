// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, prefer_const_literals_to_create_immutables, unused_local_variable, unnecessary_null_comparison, prefer_interpolation_to_compose_strings

import 'dart:ui';
import 'developerinfo.dart';
import 'package:share_plus/share_plus.dart';
import '/main.dart';
import 'home_page.dart';
// import 'package:app/pages/home_page.dart';
//import 'package:app/pages/login.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

Future<void> signOut(BuildContext context) async {
  try {
    await supabase.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  } catch (e) {
    // Handle sign-out errors
    print('Error signing out: $e');
  }
}

String currentTimestamp = DateTime.now().toString();

//before expriy thing
// final noteStream = supabase.from('notes').stream(primaryKey: ['id']);
final noteStream = supabase.from('sunset_votes').stream(primaryKey: ['id']).gt(
    'expires_at',
    currentTimestamp); // Filter out expired events; // Filter out expired events

// Create a note wihtout expiry
Future<void> createNote(bool choice, BuildContext context) async {
  var user = supabase.auth.currentUser;
  if (user != null) {
    // Get the start and end of the current day
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    var response = await supabase
        .from('sunset_votes')
        .select()
        .eq('user_id', user.id)
        .gte('created_at', startOfDay.toIso8601String())
        .lte('created_at', endOfDay.toIso8601String());

    if ((response as List).isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only create one vote per day.'),
        ),
      );
      return;
    }

    // If the user has not created a vote within the last hour, create the note
    String? username = user.userMetadata?['username'];
    if (username != null) {
      String capitalizedUsername =
          username.substring(0, 1).toUpperCase() + username.substring(1);

// Get the start and end of the current day
      DateTime now = DateTime.now();
      DateTime endOfDay =
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

// Set expiration time to the end of the current day
      String expirationTime = endOfDay.toIso8601String();

      await supabase.from('sunset_votes').insert({
        'vote': choice,
        'name': capitalizedUsername,
        'created_at': now.toIso8601String(),
        'expires_at': expirationTime,
        'user_id': user.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote submitted!'),
        ),
      );
      Navigator.pop(context);
    } else {
      throw Exception('Username not found in user metadata.');
    }
  } else {
    throw Exception('User not authenticated or user data not available.');
  }
}

class HomePageAfterAuth extends StatelessWidget {
  const HomePageAfterAuth({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int yesCount = 0;
    int noCount = 0;
    return Scaffold(
      body: Stack(
        children: [
          // Background image with blur effect
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/sun.jpg', // Replace with your image path
                  fit: BoxFit.cover, // Ensure the image covers the whole screen
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 2.0, // Horizontal blur intensity
                    sigmaY: 2.0, // Vertical blur intensity
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(
                        0.2), // Optional overlay for better text readability
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Column(
            children: [
              // AppBar remains on top of the background image
              Container(
                color: Colors.transparent,
                child: AppBar(
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sunset',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Voter',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  actions: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.info),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DeveloperInfo()),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        signOut(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logging out...')),
                        );
                      },
                    ),
                  ],
                  elevation: 0,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // List of votes
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: noteStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(
                                30.0), // Adjust top margin as needed
                            child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        25), // Apply border radius here
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 1,
                                        offset: Offset(
                                            0, 1), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(16),
                                    title: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: 'No votes yet! ',
                                            style:
                                                TextStyle(color: Colors.orange),
                                          ),
                                          TextSpan(
                                            text:
                                                'Looks like you\'re the first one here! ',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          TextSpan(
                                            text: '🌅✨ ',
                                            style:
                                                TextStyle(color: Colors.orange),
                                          ),
                                        ],
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Be the first to cast your vote and make the sunset experience even better! 📸🔥',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor:
                                          Colors.orange.withOpacity(0.2),
                                      child: Icon(
                                        Icons.sentiment_satisfied,
                                        color: Colors.orange,
                                        size: 30,
                                      ),
                                    ),
                                    tileColor: Colors.transparent,
                                  ),
                                )),
                          );
                        }
                        final votes = snapshot.data!;
                        yesCount =
                            votes.where((vote) => vote['vote'] == true).length;
                        noCount =
                            votes.where((vote) => vote['vote'] == false).length;

                        return ListView.builder(
                          itemCount: votes.length,
                          itemBuilder: (context, index) {
                            final vote = votes[index];
                            final voterName = vote['name'];
                            bool voteResult = vote['vote'] ? true : false;

                            return Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    25), // Apply border radius here
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: '$voterName ',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                      TextSpan(
                                        text: 'has voted: ',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: voteResult
                                            ? 'It\'s going to be a spectacular sunset today! 🌅🎉'
                                            : 'Oh no, it seems the sunset might not be great today. 😕',
                                        style: TextStyle(
                                          color: voteResult
                                              ? Colors.orange
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    voteResult
                                        ? '🎉 Enjoy the beautiful sunset and don\'t forget to snap some pics! 📸'
                                        : '⛅ Maybe try to catch the sunset another day. Stay positive and have a great day! 🌈',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: voteResult
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  child: Icon(
                                    voteResult ? Icons.sunny : Icons.cloud_off,
                                    color:
                                        voteResult ? Colors.orange : Colors.red,
                                    size: 30,
                                  ),
                                ),
                                tileColor: Colors.transparent,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // FloatingActionButton remains on top of the background image
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return SimpleDialog(
                                title: Row(
                                  children: [
                                    Text(
                                      "Cast your Vote!",
                                      style: TextStyle(
                                          fontFamily: 'Poppins', fontSize: 18),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "🎉",
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Will be the sunset good?",
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18),
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            createNote(
                                              true,
                                              context,
                                            );
                                            // Do not close the dialog here
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 24),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            "Yes",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            createNote(
                                              false,
                                              context,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 24),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            "No",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          width: 200,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange,
                                Colors.deepOrange,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 4,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Cast your Vote!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
