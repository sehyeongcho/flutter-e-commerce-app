/// Edit Product Page
///
/// 데이터베이스에 저장된 제품 정보를 수정(업데이트)하기 위한 제품 수정 페이지 파일입니다.

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
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();

class EditPage extends StatefulWidget {
  const EditPage({Key? key, required this.data, required this.docId})
      : super(key: key);

  final Map<String, dynamic> data;
  final String docId;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _productnameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _image;
  final ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _productnameController.text = widget.data['productname'];
    _priceController.text = widget.data['price'].toString();
    _descriptionController.text = widget.data['description'];
  }

  Future getImage(ImageSource imageSource) async {
    final XFile? pickedImage = await imagePicker.pickImage(source: imageSource);
    final XFile? storedImage = await getURLImage(widget.data['url']);

    if (pickedImage != null) {
      setState(() {
        _image = XFile(pickedImage.path);
      });
    } else {
      setState(() {
        _image = storedImage;
      });
    }
  }

  Future<XFile> getURLImage(String url) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    XFile xfile = XFile(file.path);

    return xfile;
  }

  Widget _buildImageSection() {
    return _image != null
        ? SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.file(File(_image!.path)),
          )
        : SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.network(widget.data['url']),
          );
  }

  @override
  Widget build(BuildContext context) {
    initState();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Edit'),
        leadingWidth: 80,
        leading: TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              db.collection("product").doc(widget.docId).update({
                "productname": _productnameController.text,
                "price": int.parse(_priceController.text),
                "description": _descriptionController.text,
                "recentupdatetime": FieldValue.serverTimestamp(),
              }).then((value) async {
                if (_image == null) {
                  final XFile? storedImage =
                      await getURLImage(widget.data['url']);

                  setState(() {
                    _image = storedImage;
                  });
                }

                await storageRef
                    .child(widget.docId)
                    .putFile(File(_image!.path));

                db.collection("product").doc(widget.docId).update({
                  "url": await storageRef.child(widget.docId).getDownloadURL()
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
