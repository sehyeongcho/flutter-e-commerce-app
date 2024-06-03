/// Wishlist Page
///
/// Provider 상태 관리를 사용하여 사용자가 위시리스트에 추가한 제품을 보여주는 위시리스트 페이지 파일입니다.
///
/// trash 아이콘을 클릭하면 위시리스트에서 항목이 삭제됩니다.

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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    context.read<MyAppState>().initFavorite();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, appState, child) {
        if (appState.wishlistState['wishlist'] == null) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text('Wish List'),
            ),
            body: const Center(
              child: Text('No favorites yet.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Wish List'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text('You have '
                    '${appState.wishlistState['wishlist'].length} favorites:'),
              ),

              // In the Wishlist page, show the items as ListView
              Expanded(
                child: ListView(
                  children: [
                    for (var product in appState.wishlistState['wishlist'])
                      BuildListTile(docId: product),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BuildListTile extends StatelessWidget {
  const BuildListTile({Key? key, required this.docId}) : super(key: key);

  final String docId;

  Future<Map<String, dynamic>> getProductInfo() async {
    final DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("product").doc(docId).get();
    return doc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return FutureBuilder<Map<String, dynamic>>(
      future: getProductInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(
            backgroundColor: Colors.grey,
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final productInfo = snapshot.data!;

          return Card(
            child: ListTile(
              leading: Image.network(
                productInfo['url'],
                width: 100,
                height: 100,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Delete'),
                    content: const Text('Are you sure you want to delete it?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Cancel'),
                      ),

                      // When trash icon is pressed, the item gets deleted from the wishlist
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, 'OK');
                          appState.removeFavorite(docId);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                productInfo['productname'] ?? '',
              ),
            ),
          );
        } else {
          return const Text('No data available.');
        }
      },
    );
  }
}
