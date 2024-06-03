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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shrine/login.dart';
import 'package:provider/provider.dart';

import 'edit.dart';

final db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Query your items using Prices (ASC & DESC order)
  // Create at least 6 products (The price of all products must be set differently)
  final Stream<QuerySnapshot> _productsOrderedByASC =
      db.collection('product').orderBy('price').snapshots();
  final Stream<QuerySnapshot> _productsOrderedByDESC =
      db.collection('product').orderBy('price', descending: true).snapshots();
  String _dropdownValue = "ASC";

  @override
  void initState() {
    super.initState();
    context.read<MyAppState>().initFavorite();
  }

  void dropdownCallback(String? selectedValue) {
    if (selectedValue is String) {
      setState(() {
        _dropdownValue = selectedValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (!snapshot.hasData) {
            return const LoginPage();
          } else {
            // Add a 'user' collection to your firestore
            // When you Sign-in for the first time, a document named with uid has to be created
            db
                .collection("user")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get()
                .then(
              (DocumentSnapshot doc) {
                initState();

                final userDocData = doc.data() as Map<String, dynamic>?;

                // [Anonymous sign in]
                if (FirebaseAuth.instance.currentUser!.isAnonymous) {
                  // In the document, make uid, status_message fields and store uid from current user
                  final user = <String, dynamic>{
                    "uid": FirebaseAuth.instance.currentUser?.uid,

                    // For status_message field, store "I promise to take the test honestly before GOD" as default
                    "status_message":
                        "I promise to take the test honestly before GOD",
                    "wishlist": userDocData?['wishlist'],
                  };

                  db
                      .collection("user")
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .set(user)
                      .then((value) => print("Success"));
                } else {
                  // [Google sign in]
                  String? uid;
                  String? emailAddress;
                  String? profilePhoto;
                  String? name;

                  for (final providerProfile
                      in FirebaseAuth.instance.currentUser!.providerData) {
                    // ID of the provider (google.com, apple.com, etc.)
                    final provider = providerProfile.providerId;

                    // UID specific to the provider
                    uid = providerProfile.uid;

                    // Name, email address, and profile photo URL
                    name = providerProfile.displayName;
                    emailAddress = providerProfile.email;
                    profilePhoto = providerProfile.photoURL;
                  }

                  // In the document, make name, email, uid, status_message fields and store name(displayName), email, uid from Google account information
                  final user = <String, dynamic>{
                    "name": name,
                    "email": emailAddress,
                    // "uid": uid,
                    "uid": FirebaseAuth.instance.currentUser?.uid,

                    // For status_message field, store "I promise to take the test honestly before GOD" as default
                    "status_message":
                        "I promise to take the test honestly before GOD",
                    "wishlist": userDocData?['wishlist'],
                  };

                  db
                      .collection("user")
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .set(user)
                      .then((value) => print("Success"));
                }
              },
            );

            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Main'),
                leading: IconButton(
                  icon: const Icon(
                    Icons.account_circle,
                    semanticLabel: 'profile',
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                actions: <Widget>[
                  // Add cart icon next to the add icon in the AppBar
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart,
                      semanticLabel: 'wishlist',
                    ),

                    // When it is tapped, it navigates to Wishlist page
                    onPressed: () {
                      Navigator.pushNamed(context, '/wishlist');
                    },
                  ),

                  // When you click the Add icon on the Appbar, you can add a new product to your database
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      semanticLabel: 'add',
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/add');
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Create Dropdown Selector to query the items (Price ASC & DESC)
                      DropdownButton<String>(
                        items: const [
                          DropdownMenuItem(child: Text("ASC"), value: "ASC"),
                          DropdownMenuItem(child: Text("DESC"), value: "DESC"),
                        ],
                        value: _dropdownValue,
                        onChanged: dropdownCallback,
                      ),
                    ],
                  ),
                  Expanded(
                    child: (_dropdownValue == "ASC"
                        ? StreamBuilder<QuerySnapshot>(
                            stream: _productsOrderedByASC,
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.hasError) {
                                return const Text('Something went wrong');
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text("Loading");
                              }

                              return GridView(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 8 / 11,
                                ),
                                children: snapshot.data!.docs
                                    .map((DocumentSnapshot document) {
                                      Map<String, dynamic> data = document
                                          .data()! as Map<String, dynamic>;

                                      // Each card should have product Image, Name, Price
                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Consumer<MyAppState>(
                                              builder:
                                                  (context, appState, child) {
                                                print(
                                                    "initialization: ${appState.wishlistState['wishlist']}");

                                                // When the user adds an item in detail page, the item's card displays a checkbox icon with Stack widget
                                                return (appState.wishlistState[
                                                                'wishlist'] ==
                                                            null ||
                                                        !appState.wishlistState[
                                                                'wishlist']
                                                            .contains(
                                                                document.id))

                                                    // Image
                                                    ? AspectRatio(
                                                        aspectRatio: 11 / 8,

                                                        // Do not use default images, put your images in your firestore storage
                                                        child: Image.network(
                                                          data['url'],
                                                          fit: BoxFit.fitWidth,
                                                        ),
                                                      )
                                                    : Stack(
                                                        children: [
                                                          AspectRatio(
                                                            aspectRatio: 11 / 8,
                                                            child:
                                                                Image.network(
                                                              data['url'],
                                                              fit: BoxFit
                                                                  .fitWidth,
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              IconButton(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(0),
                                                                alignment: Alignment
                                                                    .centerRight,
                                                                icon: const Icon(
                                                                    Icons
                                                                        .check_box),
                                                                iconSize: 20,
                                                                onPressed: () =>
                                                                    {},
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      );
                                              },
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16.0, 12.0, 16.0, 8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    // Name
                                                    Text(
                                                      data['productname'],
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                    ),

                                                    // Price
                                                    Text(
                                                      data['price'].toString(),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                TextButton(
                                                  child: const Text('more'),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            DetailPage(
                                                                data: data,
                                                                docId: document
                                                                    .id),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                    .toList()
                                    .cast(),
                              );
                            },
                          )
                        : StreamBuilder<QuerySnapshot>(
                            stream: _productsOrderedByDESC,
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.hasError) {
                                return const Text('Something went wrong');
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text("Loading");
                              }

                              return GridView(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 8 / 11,
                                ),
                                children: snapshot.data!.docs
                                    .map((DocumentSnapshot document) {
                                      Map<String, dynamic> data = document
                                          .data()! as Map<String, dynamic>;

                                      // Each card should have product Image, Name, Price
                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Consumer<MyAppState>(
                                              builder:
                                                  (context, appState, child) {
                                                print(
                                                    "initialization: ${appState.wishlistState['wishlist']}");

                                                // When the user adds an item in detail page, the item's card displays a checkbox icon with Stack widget
                                                return (appState.wishlistState[
                                                                'wishlist'] ==
                                                            null ||
                                                        !appState.wishlistState[
                                                                'wishlist']
                                                            .contains(
                                                                document.id))

                                                    // Image
                                                    ? AspectRatio(
                                                        aspectRatio: 11 / 8,

                                                        // Do not use default images, put your images in your firestore storage
                                                        child: Image.network(
                                                          data['url'],
                                                          fit: BoxFit.fitWidth,
                                                        ),
                                                      )
                                                    : Stack(
                                                        children: [
                                                          AspectRatio(
                                                            aspectRatio: 11 / 8,
                                                            child:
                                                                Image.network(
                                                              data['url'],
                                                              fit: BoxFit
                                                                  .fitWidth,
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              IconButton(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(0),
                                                                alignment: Alignment
                                                                    .centerRight,
                                                                icon: const Icon(
                                                                    Icons
                                                                        .check_box),
                                                                iconSize: 20,
                                                                onPressed: () =>
                                                                    {},
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      );
                                              },
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16.0, 12.0, 16.0, 8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    // Name
                                                    Text(
                                                      data['productname'],
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                    ),

                                                    // Price
                                                    Text(
                                                      data['price'].toString(),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                TextButton(
                                                  child: const Text('more'),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            DetailPage(
                                                                data: data,
                                                                docId: document
                                                                    .id),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                    .toList()
                                    .cast(),
                              );
                            },
                          )),
                  ),
                ],
              ),
            );
          }
        });
  }
}

class DetailPage extends StatefulWidget {
  const DetailPage({Key? key, required this.data, required this.docId})
      : super(key: key);

  final Map<String, dynamic> data;
  final String docId;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<MyAppState>().initFavorite();
  }

  String convertTime(dynamic time) {
    final timestamp = time;
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp.seconds * 1000 + (timestamp.nanoseconds / 1000000).round(),
    );

    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // create a Floating Action Button
      // before adding to wishlist: shopping_cart icon
      // after adding to wishlist: check icon
      floatingActionButton: FloatingActionButton(
        child: Consumer<MyAppState>(
          builder: (context, appState, child) {
            return (appState.wishlistState['wishlist'] == null ||
                    !appState.wishlistState['wishlist'].contains(widget.docId))
                ? const Icon(Icons.shopping_cart)
                : const Icon(Icons.check);
          },
        ),

        // when the floating action button is pressed, the item is added to wishlist
        onPressed: () {
          context.read<MyAppState>().toggleFavorite(widget.docId);
        },
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Detail'),
        actions: <Widget>[
          // When you click the pencil icon(Icons.create), you can modify(update) the information of the item
          IconButton(
            icon: const Icon(
              Icons.create,
              semanticLabel: 'edit',
            ),
            onPressed: () {
              if (FirebaseAuth.instance.currentUser!.uid ==
                  widget.data['uid']) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditPage(data: widget.data, docId: widget.docId),
                  ),
                );
              }
            },
          ),

          // When you click the trash icon(Icons.delete), you can delete the item
          IconButton(
            icon: const Icon(
              Icons.delete,
              semanticLabel: 'delete',
            ),
            onPressed: () async {
              // If the UID is different from yours (if you are not the author of the post), it should not be Modified or Deleted (you can use Firestore Document Fields or Security Rules)
              if (FirebaseAuth.instance.currentUser!.uid ==
                  widget.data['uid']) {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Delete'),
                    content: const Text('Are you sure you want to delete it?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          db
                              .collection("product")
                              .doc(widget.docId)
                              .delete()
                              .then(
                                (doc) => print("Document deleted"),
                                onError: (e) =>
                                    print("Error updating document $e"),
                              );

                          db.collection("user").get().then((querySnapshot) {
                            for (var docSnapshot in querySnapshot.docs) {
                              docSnapshot.reference.update({
                                "wishlist":
                                    FieldValue.arrayRemove([widget.docId]),
                              });
                            }
                          });

                          await storageRef.child(widget.docId).delete();

                          Navigator.pop(context, 'OK');
                          Navigator.pop(context);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),

      // Detail page should have Product Image, Name, Price and Description
      body: ListView(
        children: [
          // Image
          FittedBox(
            child: Image.network(widget.data['url']),
            fit: BoxFit.fitWidth,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      // Name
                      child: Text(
                        widget.data['productname'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StreamBuilder(
                        stream: db
                            .collection('product')
                            .doc(widget.docId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          return FavoriteWidget(
                              data: widget.data, docId: widget.docId);
                        }),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Price
                Text(widget.data['price'].toString()),
                const SizedBox(height: 16.0),
                dividerSection,
                const SizedBox(height: 16.0),

                // Description
                Text(widget.data['description']),
                const SizedBox(height: 16.0),

                // Show UID & creation time & recent update time (Use FieldValue.serverTimestamp())
                Text("Creator: ${widget.data['uid']}"),
                Text("${convertTime(widget.data['creationtime'])} Created"),
                Text(
                    "${convertTime(widget.data['recentupdatetime'])} Modified"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget dividerSection = const Divider(
  height: 1.0,
  color: Colors.black,
);

class FavoriteWidget extends StatefulWidget {
  const FavoriteWidget({Key? key, required this.data, required this.docId})
      : super(key: key);

  final Map<String, dynamic> data;
  final String docId;

  @override
  State<FavoriteWidget> createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  late int _favoriteCount = widget.data['favorite'].length;
  bool flag = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(0),
          child: IconButton(
            padding: const EdgeInsets.all(0),
            alignment: Alignment.centerRight,
            icon: const Icon(Icons.thumb_up),
            color: Colors.red,

            // If the IconButton(thumb_up) is pressed for the first time, the number is added by 1
            onPressed: !widget.data['favorite']
                    .contains(FirebaseAuth.instance.currentUser!.uid)
                ? () {
                    _favoriteCount += 1;

                    // The data should be preserved after logout or re-login (The UID of the user who clicked the thumb up button should be recorded)
                    // Each item must be stored individually
                    db.collection("product").doc(widget.docId).update({
                      "favorite": FieldValue.arrayUnion(
                          [FirebaseAuth.instance.currentUser!.uid]),
                    }).then((value) {
                      // Then, a SnackBar should appear
                      if (flag == true) {
                        const snackBar = SnackBar(
                          content: Text('I LIKE IT!'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        setState(() {
                          flag = false;
                        });
                      } else {
                        const snackBar = SnackBar(
                          content: Text('You can only do it once!'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    });
                  }

                // Even if you press the button more than once, you can only increase the number of likes by 1 per item
                : () {
                    // At that time, a SnackBar gives you a caution
                    const snackBar = SnackBar(
                      content: Text('You can only do it once!'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
          ),
        ),
        SizedBox(
          width: 18,
          child: SizedBox(
            child: Text('$_favoriteCount',
                style: const TextStyle(
                  color: Colors.red,
                )),
          ),
        ),
      ],
    );
  }
}

class MyAppState extends ChangeNotifier {
  Map<String, dynamic> wishlistState = {};

  void initFavorite() {
    db
        .collection("user")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get()
        .then(
      (DocumentSnapshot doc) {
        if (doc.data() != null) {
          wishlistState = doc.data() as Map<String, dynamic>;
          print("wishlist: ${wishlistState['wishlist']}");
          notifyListeners();
        }
      },
    );
  }

  void toggleFavorite([String? product]) {
    db.collection("user").doc(FirebaseAuth.instance.currentUser!.uid).update({
      "wishlist": FieldValue.arrayUnion([product]),
    }).then((value) {
      db
          .collection("user")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get()
          .then(
        (DocumentSnapshot doc) {
          wishlistState = doc.data() as Map<String, dynamic>;
          print("wishlist: ${wishlistState['wishlist']}");
          notifyListeners();
        },
      );
    });
  }

  void removeFavorite(String product) {
    db.collection("user").doc(FirebaseAuth.instance.currentUser!.uid).update({
      "wishlist": FieldValue.arrayRemove([product]),
    }).then((value) {
      db
          .collection("user")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get()
          .then(
        (DocumentSnapshot doc) {
          wishlistState = doc.data() as Map<String, dynamic>;
          print("wishlist: ${wishlistState['wishlist']}");
          notifyListeners();
        },
      );
    });
  }
}
