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
  final List<String> _categoriesList = [];
  String? _selectedCategory;

  List<Uint8List> images = <Uint8List>[];

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
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Product Information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          TextFormField(
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
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Flexible(
                child: TextFormField(
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
              const SizedBox(
                width: 20,
              ),
              Flexible(
                child: _buildDropDownField(),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          TextFormField(
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
          const SizedBox(
            height: 20,
          ),
          TextFormField(
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
          const SizedBox(
            height: 20,
          ),
          TextFormField(
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
          const SizedBox(
            height: 20,
          ),
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
            onTap: () {},
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
