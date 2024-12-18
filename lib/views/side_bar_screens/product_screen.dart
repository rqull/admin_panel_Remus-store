import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductScreen extends StatefulWidget {
  static const String id = '\product-screen';
  const ProductScreen({super.key});

  // @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _sizeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _categoriesList = [];

  List<String> _sizesList = [];
  String? _selectedCategory;

  bool _isEntered = false;

  final List<Uint8List> images = <Uint8List>[];

  chooseImage() async {
    final pickedImages = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (pickedImages == null) {
      print('No image');
    } else {
      for (var image in pickedImages.files) {
        setState(() {
          images.add(image.bytes!);
        });
      }
    }
  }

  _getCategories() {
    return _firestore.collection('categories').get().then(
      (QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          setState(() {
            _categoriesList.add(doc['categoryName']);
          });
        }
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    _getCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Enter product name',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Row(
                spacing: 20,
                children: [
                  Flexible(
                    child: TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product price';
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter Price',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: _buildDropDownField(),
                  ),
                ],
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter discount';
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Discount',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Enter Description',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Row(
                spacing: 10,
                children: [
                  Flexible(
                    child: SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: _sizeController,
                        onChanged: (value) {
                          setState(() {
                            _isEntered = true;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Add Size',
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _isEntered
                      ? Flexible(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _sizesList.add(_sizeController.text);
                                _sizeController.clear();
                                _isEntered = false;
                              });
                            },
                            child: Text('Add'),
                          ),
                        )
                      : Text(''),
                ],
              ),
              _sizesList.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          itemCount: _sizesList.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _sizesList.removeAt(index);
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _sizesList[index],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Text(''),
              GridView.builder(
                itemCount: images.length + 1,
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  return index == 0
                      ? Center(
                          child: IconButton(
                            onPressed: () {
                              chooseImage();
                            },
                            icon: Icon(
                              Icons.add,
                            ),
                          ),
                        )
                      : Image.memory(images[index - 1]);
                },
              ),
              InkWell(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    // Upload product to Firestore
                    print('uploading');
                  } else {
                    // please fill all the fields
                    print('not uploading');
                  }
                },
                child: Container(
                    width: MediaQuery.of(context).size.width - 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Center(
                      child: Text(
                        'Upload Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropDownField() {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: 'Select Category',
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: _categoriesList.map((value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }
}
