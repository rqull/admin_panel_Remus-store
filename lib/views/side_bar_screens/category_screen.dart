import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryScreen extends StatefulWidget {
  static const String id = '\category-screen';
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryNameController = TextEditingController();

  dynamic _image;
  String? fileName;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final supabase = Supabase.instance.client;

  pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        _image = result.files.first.bytes;
        fileName = result.files.first.name;
      });
    }
  }

  _uploadCategoryToSupabase() async {
    try {
      if (_image == null) return null;

      final String randomId = const Uuid().v4();
      final String path = 'categories/$randomId$fileName';

      // Cek apakah bucket exists
      final buckets = await supabase.storage.listBuckets();
      final categoriesBucket =
          buckets.any((bucket) => bucket.id == 'categories');

      if (!categoriesBucket) {
        print('Bucket categories tidak ditemukan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Storage bucket tidak ditemukan. Mohon periksa konfigurasi Supabase')),
        );
        return null;
      }

      // Upload file
      try {
        await supabase.storage.from('categories').uploadBinary(
              path,
              _image,
              fileOptions: FileOptions(
                contentType: 'image/png',
                upsert: true,
              ),
            );
      } catch (uploadError) {
        print('Error saat upload: $uploadError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $uploadError')),
        );
        return null;
      }

      // Get public URL
      final String imageUrl =
          supabase.storage.from('categories').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      print('Error uploading to Supabase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supabase error: $e')),
      );
      return null;
    }
  }

  _uploadToFirestore(String imageUrl) async {
    try {
      final String docId = const Uuid().v4();
      await _firestore.collection('categories').doc(docId).set({
        'categoryName': _categoryNameController.text,
        'categoryImage': imageUrl,
        'createdAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error uploading to Firestore: $e');
      return false;
    }
  }

  _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Upload image to Supabase
      final imageUrl = await _uploadCategoryToSupabase();
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Save to Firestore
      final success = await _uploadToFirestore(imageUrl);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _categoryNameController.clear();
        setState(() {
          _image = null;
          fileName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save category')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              alignment: Alignment.topLeft,
              child: const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Divider(
            color: Colors.grey,
          ),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    height: 140,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      border: Border.all(
                        color: Colors.grey.shade800,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _image != null
                          ? Image.memory(_image)
                          : const Text(
                              'Upload Image',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.blue),
                      ),
                      onPressed: () {
                        pickImage();
                      },
                      child: const Text(
                        'Upload Image',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                width: 30,
              ),
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _categoryNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter category name';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                  ),
                ),
              ),
              const SizedBox(width: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.white),
                        side: WidgetStatePropertyAll(
                          BorderSide(color: Colors.blue.shade900),
                        ),
                      ),
                      onPressed: _saveCategory,
                      child: const Text('Save'),
                    )
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }
}
