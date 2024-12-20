import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductScreen extends StatefulWidget {
  static const String id = '/products';

  const ProductScreen({Key? key}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final SupabaseClient _productSupabase;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Uint8List> _images = [];
  String? selectedCategory;
  bool _isLoading = false;
  String _searchQuery = '';
  List<String> categories = [];
  List<String> _sizesList = [];
  bool _isEntered = false;

  @override
  void initState() {
    super.initState();
    _initSupabase();
    _fetchCategories();
  }

  void _initSupabase() {
    _productSupabase = SupabaseClient(
      'https://jiukiuyzjggwnmzkrhey.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppdWtpdXl6amdnd25temtyaGV5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzY0ODkwNiwiZXhwIjoyMDQ5MjI0OTA2fQ.LC73ZsEhO805P-mCGSv2Xnq5l5OAE4UOsmNs1NhMYZY',
    );
  }

  @override
  void dispose() {
    _productSupabase.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    _searchController.dispose();
    _sizeController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Fetch categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore.collection('categories').get();

      setState(() {
        categories.clear(); // Clear existing categories
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['categoryName'] != null) {
            categories.add(data['categoryName']);
          }
        }
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // Pick multiple images
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _images.addAll(result.files.map((file) => file.bytes!));
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  // Upload multiple images to Supabase
  Future<List<String>> _uploadProductImagesToSupabase() async {
    try {
      if (_images.isEmpty) return [];

      List<String> imageUrls = [];
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String sanitizedName =
          _productNameController.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      for (int i = 0; i < _images.length; i++) {
        final String newFileName = '${timestamp}_${sanitizedName}_$i.png';
        final String path = 'products/$newFileName';

        try {
          await _productSupabase.storage.from('products').uploadBinary(
                path,
                _images[i],
                fileOptions: const FileOptions(
                  contentType: 'image/png',
                  upsert: true,
                ),
              );

          print('Upload success: $path');
          final String imageUrl =
              _productSupabase.storage.from('products').getPublicUrl(path);
          print('Image URL: $imageUrl');
          imageUrls.add(imageUrl);
        } catch (uploadError) {
          print('Error uploading to Supabase: $uploadError');
        }
      }
      return imageUrls;
    } catch (e) {
      print('Error in _uploadProductImagesToSupabase: $e');
      return [];
    }
  }

  // Save product to Firestore
  Future<void> _uploadProduct() async {
    if (_productNameController.text.isEmpty ||
        _productPriceController.text.isEmpty ||
        _productDescriptionController.text.isEmpty ||
        _discountController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        selectedCategory == null ||
        _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select at least one image'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    EasyLoading.show(status: 'Uploading Product...');

    try {
      final List<String> imageUrls = await _uploadProductImagesToSupabase();

      await _firestore.collection('products').add({
        'productName': _productNameController.text,
        'productPrice': double.parse(_productPriceController.text),
        'description': _productDescriptionController.text,
        'category': selectedCategory,
        'imageUrls': imageUrls,
        'sizes': _sizesList,
        'discount': int.parse(_discountController.text),
        'quantity': int.parse(_quantityController.text),
        'uploadDate': DateTime.now(),
      });

      setState(() {
        _productNameController.clear();
        _productPriceController.clear();
        _productDescriptionController.clear();
        _discountController.clear();
        _quantityController.clear();
        selectedCategory = null;
        _images.clear();
        _sizesList.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product uploaded successfully')),
      );
    } catch (e) {
      print('Error uploading product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading product: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
      EasyLoading.dismiss();
    }
  }

  // Delete product
  Future<void> _deleteProduct(String docId, List<String> imageUrls) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
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

    setState(() => _isLoading = true);
    EasyLoading.show(status: 'Deleting Product...');

    try {
      // Delete all images from Supabase
      for (String imageUrl in imageUrls) {
        final Uri uri = Uri.parse(imageUrl);
        final List<String> segments = uri.pathSegments;
        final String fileName = segments.last;

        try {
          final List<FileObject> files = await _productSupabase.storage
              .from('products')
              .list(path: 'products');

          if (files.any((f) => f.name == fileName)) {
            await _productSupabase.storage
                .from('products')
                .remove(['products/$fileName']);
            print('Deleted file: $fileName');
          }
        } catch (e) {
          print('Error deleting file $fileName: $e');
        }
      }

      // Delete from Firestore
      await _firestore.collection('products').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Product',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Image Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: _images.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text('No images selected'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(8)),
                                        child: Image.memory(
                                          _images[index],
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 5,
                                        top: 5,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20)),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _images.removeAt(index);
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Select Images'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Product Form
                    TextFormField(
                      controller: _productNameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'Enter product name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _productPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: 'Enter product price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Discount',
                        hintText: 'Enter discount percentage',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'Enter product quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _productDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter product description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    // Size Input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(
                              labelText: 'Size',
                              hintText: 'Enter product size',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              filled: true,
                              fillColor: Colors.grey,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isEntered = value.isNotEmpty;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_isEntered)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _sizesList.add(_sizeController.text);
                                _sizeController.clear();
                                _isEntered = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Add Size'),
                          ),
                      ],
                    ),
                    if (_sizesList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _sizesList.map((size) {
                            return Chip(
                              label: Text(size),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () {
                                setState(() {
                                  _sizesList.remove(size);
                                });
                              },
                              backgroundColor: Colors.blue.shade100,
                              labelStyle:
                                  const TextStyle(color: Colors.black87),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 15),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      hint: const Text('Select Category'),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      items: categories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _uploadProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Upload Product',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Search Bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product List',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        filled: true,
                        fillColor: Colors.grey,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Product Grid
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('products').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Something went wrong'),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final products = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              data['productName']?.toString().toLowerCase() ??
                                  '';
                          final category =
                              data['category']?.toString().toLowerCase() ?? '';
                          final searchLower = _searchQuery.toLowerCase();
                          return name.contains(searchLower) ||
                              category.contains(searchLower);
                        }).toList();

                        if (products.isEmpty) {
                          return const Center(
                            child: Text('No products found'),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final doc = products[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(10),
                                          ),
                                          child: PageView.builder(
                                            itemCount: (data['imageUrls']
                                                        as List<dynamic>?)
                                                    ?.length ??
                                                0,
                                            itemBuilder: (context, imageIndex) {
                                              final imageUrls =
                                                  data['imageUrls']
                                                      as List<dynamic>?;
                                              return imageUrls != null &&
                                                      imageIndex <
                                                          imageUrls.length
                                                  ? Image.network(
                                                      imageUrls[imageIndex]
                                                          .toString(),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Center(
                                                          child: Icon(
                                                            Icons.error_outline,
                                                            color: Colors.red,
                                                            size: 40,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          right: 5,
                                          top: 5,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20)),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () => _deleteProduct(
                                                doc.id,
                                                (data['imageUrls']
                                                            as List<dynamic>?)
                                                        ?.map((url) =>
                                                            url.toString())
                                                        .toList() ??
                                                    [],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['productName']?.toString() ??
                                              'No name',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$ ${data['productPrice']?.toString() ?? '0'}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['category']?.toString() ??
                                              'No category',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
