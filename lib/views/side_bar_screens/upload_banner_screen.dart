import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadBannerScreen extends StatefulWidget {
  static const String id = '\banner-screen';
  const UploadBannerScreen({super.key});

  @override
  State<UploadBannerScreen> createState() => _UploadBannerScreenState();
}

class _UploadBannerScreenState extends State<UploadBannerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  dynamic _image;
  String? fileName;
  bool _isLoading = false;
  String _searchQuery = '';
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

  Future<String?> _uploadBannerToSupabase() async {
    try {
      if (_image == null) return null;

      // Debug: Print Supabase client status
      print('Supabase client initialized: ${supabase != null}');

      // Debug: List all buckets
      try {
        final buckets = await supabase.storage.listBuckets();
        print('Available buckets: ${buckets.map((b) => b.name).join(', ')}');
      } catch (e) {
        print('Error listing buckets: $e');
      }

      // Generate file name with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = 'banner_$timestamp.png';
      final String path = 'banners/$newFileName';

      // Upload file
      try {
        final storageResponse =
            await supabase.storage.from('banners').uploadBinary(
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
            supabase.storage.from('banners').getPublicUrl(path);

        print('Image URL: $imageUrl');
        return imageUrl;
      } catch (uploadError) {
        print('Error uploading to Supabase: $uploadError');
        return null;
      }
    } catch (e) {
      print('Error in _uploadBannerToSupabase: $e');
      return null;
    }
  }

  Future<bool> _uploadToFirestore(String imageUrl) async {
    try {
      final String docId = const Uuid().v4();
      await _firestore.collection('banners').doc(docId).set({
        'image': imageUrl,
        'createdAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error uploading to Firestore: $e');
      return false;
    }
  }

  _saveBanner() async {
    setState(() {
      _isLoading = true;
    });

    String? imageUrl = await _uploadBannerToSupabase();
    if (imageUrl != null) {
      bool success = await _uploadToFirestore(imageUrl);
      if (success) {
        setState(() {
          _image = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner uploaded successfully')),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload banner to Firestore')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload banner image')),
      );
    }
  }

  Stream<QuerySnapshot> getBanners() {
    if (_searchQuery.isEmpty) {
      return _firestore
          .collection('banners')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Search by file name in the URL
      return _firestore
          .collection('banners')
          .orderBy('image')
          .startAt([_searchQuery]).endAt([_searchQuery + '\uf8ff']).snapshots();
    }
  }

  Future<void> _deleteBanner(String docId, String imageUrl) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse the URL and extract the file path
      final Uri uri = Uri.parse(imageUrl);
      print('Full URL being processed: $imageUrl');
      print('URL Path segments: ${uri.pathSegments}');

      // The file path should be everything after "banners/"
      final int bannersIndex = uri.pathSegments.indexOf('banners');
      if (bannersIndex == -1 || bannersIndex == uri.pathSegments.length - 1) {
        throw Exception('Invalid file path structure');
      }

      // Get the file path after "banners/"
      final String filePath = uri.pathSegments[bannersIndex + 1];
      print('Attempting to delete file with path: $filePath');

      // Try to delete from Supabase
      try {
        // List files in the bucket first to verify
        final List<FileObject> files =
            await supabase.storage.from('banners').list();
        print('Files in bucket: ${files.map((f) => f.name).join(', ')}');

        // Check if file exists
        if (files.any((f) => f.name == filePath)) {
          print('File found in bucket, proceeding with deletion');
          await supabase.storage.from('banners').remove([filePath]);
          print('File successfully deleted from Supabase');
        } else {
          print('File not found in bucket: $filePath');
          throw Exception('File not found in storage bucket');
        }
      } catch (storageError) {
        print('Supabase deletion error: $storageError');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage error: $storageError')),
        );
        return;
      }

      // If Supabase deletion was successful, delete from Firestore
      try {
        await _firestore.collection('banners').doc(docId).delete();
        print('Firestore document deleted');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner deleted successfully')),
        );
      } catch (firestoreError) {
        print('Firestore deletion error: $firestoreError');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database error: $firestoreError')),
        );
      }
    } catch (e) {
      print('General error: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Upload Banner',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.width *
                            0.4 *
                            9 /
                            16, // 16:9 ratio
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: _image != null
                              ? Image.memory(_image)
                              : const Text(
                                  'Upload Banner Image (16:9)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue),
                          ),
                          onPressed: pickImage,
                          child: const Text(
                            'Pick Banner Image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      if (_image != null)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveBanner,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Upload Banner'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Banners',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search banners...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: getBanners(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No banners found'));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: snapshot.data!.docs.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          data['image'],
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBanner(
                              doc.id,
                              data['image'],
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.7),
                            ),
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
