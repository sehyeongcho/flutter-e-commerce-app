// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';

final db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // [from Google sign in]
  // Profile Photo, UID, Email: all the information should be loaded
  Widget _buildProfilePage() {
    String? uid;
    String? emailAddress;
    String? profilePhoto;

    for (final providerProfile
        in FirebaseAuth.instance.currentUser!.providerData) {
      // ID of the provider (google.com, apple.com, etc.)
      final provider = providerProfile.providerId;

      // UID specific to the provider
      uid = providerProfile.uid;

      // Name, email address, and profile photo URL
      final name = providerProfile.displayName;
      emailAddress = providerProfile.email;
      profilePhoto = providerProfile.photoURL;
    }

    return ListView(
      children: [
        // Profile Photo
        SizedBox(
          width: double.infinity,
          height: 200,
          child: Image.network(profilePhoto!),
        ),
        const SizedBox(height: 12.0),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   uid!,
              //   style: const TextStyle(
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),

              // UID
              Text(
                "${FirebaseAuth.instance.currentUser?.uid}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12.0),
              dividerSection,
              const SizedBox(height: 12.0),

              // Email
              Text(
                emailAddress!,
              ),
            ],
          ),
        ),
        const SizedBox(height: 36.0),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Text(
            "Sehyeong Cho",
          ),
        ),
        const SizedBox(height: 12.0),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Text(
            "I promise to take the test honestly before GOD",
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        actions: <Widget>[
          // If you click the logout icon(Icons.exit_to_app) on the top right corner, it navigates to the Login Page
          // It should be logged out
          IconButton(
            icon: const Icon(
              Icons.exit_to_app,
              semanticLabel: 'logout',
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),

      // [from Anonymous sign in]
      body: (FirebaseAuth.instance.currentUser!.isAnonymous)
          ? ListView(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,

                  // image: default image
                  child: Image.asset('assets/logo.png'),
                ),
                const SizedBox(height: 12.0),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // uid: anonymous uid
                      Text(
                        "${FirebaseAuth.instance.currentUser?.uid}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      dividerSection,
                      const SizedBox(height: 12.0),

                      // email: String "Anomymous"
                      const Text(
                        "Anonymous",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36.0),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 0),

                  // Display your Name as a signature using Text widget
                  child: Text(
                    "Sehyeong Cho",
                  ),
                ),
                const SizedBox(height: 12.0),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 0),

                  // Display the Honor Code pledge "I promise to take the test honestly before GOD" using Text widget
                  child: Text(
                    "I promise to take the test honestly before GOD",
                  ),
                ),
              ],
            )
          : _buildProfilePage(),
    );
  }
}

Widget dividerSection = const Divider(
  height: 1.0,
  color: Colors.black,
);
