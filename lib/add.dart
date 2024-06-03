/// Add Product Page
///
/// 새 제품을 데이터베이스에 추가하기 위한 제품 추가 페이지 파일입니다.
///
/// 사용자가 별도로 제품 이미지를 선택하지 않았다면 기본 이미지가 표시됩니다. 제품 이미지를 선택하지 않고 저장 버튼을 클릭하면 기본 이미지가 제품 이미지로 저장됩니다.
///
/// 이미지는 image-picker 플러그인을 통해 로드되고, 저장소에 업로드됩니다.

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

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

final db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();

class AddPage extends StatefulWidget {
  const AddPage({Key? key}) : super(key: key);

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _productnameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _image;
  final ImagePicker imagePicker = ImagePicker();
  final List<String> favoritelist = [];

  // The image should be loaded by image-picker plugin
  Future getImage(ImageSource imageSource) async {
    final XFile? pickedImage = await imagePicker.pickImage(source: imageSource);
    final XFile? defaultImage = await getAssetImage('logo.png');

    if (pickedImage != null) {
      setState(() {
        _image = XFile(pickedImage.path);
      });
    } else {
      setState(() {
        _image = defaultImage;
      });
    }
  }

  Future<XFile> getAssetImage(String path) async {
    final byteData = await rootBundle.load('assets/$path');
    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    XFile xfile = XFile(file.path);

    return xfile;
  }

  Widget _buildImageSection() {
    return (_image != null)
        ? SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.file(File(_image!.path)), //가져온 이미지를 화면에 띄워주는 코드
          )

        // A default image should be shown before you select an image
        : SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.asset('assets/logo.png'),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add'),
        leadingWidth: 80,
        leading: TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final product = <String, dynamic>{
                "productname": _productnameController.text,
                "price": int.parse(_priceController.text),
                "description": _descriptionController.text,
                "uid": FirebaseAuth.instance.currentUser?.uid,
                "url": "",
                "creationtime": FieldValue.serverTimestamp(),
                "recentupdatetime": FieldValue.serverTimestamp(),
                "favorite": favoritelist,
              };

              db
                  .collection("product")
                  .add(product)
                  .then((DocumentReference doc) async {
                print('DocumentSnapshot added with ID: ${doc.id}');

                // When you click the save button without selecting any image, the default image should be saved as the product's image
                if (_image == null) {
                  final XFile? defaultImage = await getAssetImage('logo.png');

                  setState(() {
                    _image = defaultImage;
                  });
                }

                // Image should be uploaded in the Storage (Do not save only the String "image URL" in your "Database")
                await storageRef.child(doc.id).putFile(File(_image!.path));

                db.collection("product").doc(doc.id).update({
                  "url": await storageRef.child(doc.id).getDownloadURL(),
                }).then(
                    (value) => print("DocumentSnapshot successfully updated!"),
                    onError: (e) => print("Error updating document $e"));
              });

              Navigator.pushNamed(context, '/');
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildImageSection(),
          const SizedBox(height: 12.0),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                getImage(ImageSource.gallery);
              },
              icon: const Icon(Icons.camera_alt),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: TextField(
              controller: _productnameController,
              decoration: const InputDecoration(
                filled: true,
                labelText: 'Product Name',
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                filled: true,
                labelText: 'Price',
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                filled: true,
                labelText: 'Description',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
