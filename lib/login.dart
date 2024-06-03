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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Lottie.network(
                      'https://assets8.lottiefiles.com/packages/lf20_5ngs2ksb.json',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Use Google Sign-in
                  Center(
                    child: SizedBox(
                      width: 256,
                      height: 56,
                      child: Material(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: signInWithGoogle,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Ink.image(
                                  image: const AssetImage(
                                      'assets/google_logo.png'),
                                  height: 32,
                                  width: 32,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sign in with Google',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Use Anonymous Login(Guest)
                  Center(
                    child: SizedBox(
                      width: 256,
                      height: 56,
                      child: Material(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () async {
                            await FirebaseAuth.instance.signInAnonymously();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Ink.image(
                                  image:
                                      const AssetImage('assets/guest_logo.png'),
                                  height: 32,
                                  width: 32,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sign in with Guest',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
