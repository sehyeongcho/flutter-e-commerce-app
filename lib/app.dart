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
import 'package:shrine/color_schemes.g.dart';
import 'package:provider/provider.dart';

import 'add.dart';
import 'home.dart';
import 'login.dart';
import 'profile.dart';
import 'wishlist.dart';

class ShrineApp extends StatelessWidget {
  const ShrineApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Shrine',
        initialRoute: '/',
        routes: {
          '/login': (BuildContext context) => const LoginPage(),
          '/': (BuildContext context) => const HomePage(),
          '/add': (BuildContext context) => const AddPage(),
          '/profile': (BuildContext context) => const ProfilePage(),
          '/wishlist': (BuildContext context) => const WishlistPage(),
        },
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
        ),
      ),
    );
  }
}
