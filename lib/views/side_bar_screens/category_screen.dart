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

      // Debug: Print Supabase client status
      print('Supabase client initialized: ${supabase != null}');

      // Debug: List all buckets
      try {
        final buckets = await supabase.storage.listBuckets();
        print('Available buckets: ${buckets.map((b) => b.id).toList()}');
      } catch (e) {
        print('Error listing buckets: $e');
      }

      // Try to create bucket if it doesn't exist
      try {
        await supabase.storage.createBucket('categories');
        print('Bucket categories created successfully');
      } catch (e) {
        print('Create bucket error (might already exist): $e');
      }

      // Upload file
      try {
        final storageResponse =
            await supabase.storage.from('categories').uploadBinary(
                  path,
                  _image,
                  fileOptions: FileOptions(
                    contentType: 'image/png',
                    upsert: true,
                  ),
                );

        print('Upload success: $storageResponse');

        // Get public URL
        final String imageUrl =
            supabase.storage.from('categories').getPublicUrl(path);

        print('Image URL: $imageUrl');
        return imageUrl;
      } catch (uploadError) {
        print('Error detail saat upload: $uploadError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $uploadError')),
        );
        return null;
      }
    } catch (e) {
      print('Error umum: $e');
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

  // Stream untuk mendapatkan data kategori secara realtime
  Stream<QuerySnapshot> getCategories() {
    return _firestore
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Fungsi untuk menghapus kategori
  Future<void> _deleteCategory(String docId, String imageUrl) async {
    // Tampilkan dialog konfirmasi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Hapus dari Firestore
      await _firestore.collection('categories').doc(docId).delete();

      // Hapus dari Supabase storage
      try {
        final Uri uri = Uri.parse(imageUrl);
        final String path = uri.pathSegments.last;
        await supabase.storage.from('categories').remove([path]);
        print('File deleted from Supabase: $path');
      } catch (storageError) {
        print('Error deleting from Supabase: $storageError');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      print('Error deleting category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  // Fungsi untuk mengupdate nama kategori
  Future<void> _updateCategoryName(String docId, String currentName) async {
    final TextEditingController nameController = TextEditingController(text: currentName);
    
    String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Category Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter new category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newName != null && newName != currentName) {
      try {
        await _firestore.collection('categories').doc(docId).update({
          'categoryName': newName,
          'updatedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category name updated successfully')),
        );
      } catch (e) {
        print('Error updating category name: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating category name: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Form(
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
                const Divider(color: Colors.grey),
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 140,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            border: Border.all(color: Colors.grey.shade800),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: _image != null
                                ? Image.memory(_image)
                                : const Text(
                                    'Upload Image',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: const ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(Colors.blue),
                            ),
                            onPressed: pickImage,
                            child: const Text(
                              'Upload Image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 30),
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
                              backgroundColor:
                                  const WidgetStatePropertyAll(Colors.white),
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
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.grey),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Category List',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: getCategories(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No categories found'),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(data['categoryImage']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['categoryName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Tombol Edit
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _updateCategoryName(
                                        doc.id,
                                        data['categoryName'],
                                      ),
                                    ),
                                    // Tombol Delete
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteCategory(
                                        doc.id,
                                        data['categoryImage'],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
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
