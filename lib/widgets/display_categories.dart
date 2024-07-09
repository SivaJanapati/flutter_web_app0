// widgets/display_categories.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;
import 'dart:html' as html;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DisplayCategories extends StatefulWidget {
  const DisplayCategories({super.key});

  @override
  State<DisplayCategories> createState() => _DisplayCategoriesState();
}

class _DisplayCategoriesState extends State<DisplayCategories> {
  String? _searchValue;
  bool _isLoading = false;
  String? _newCategoryName;
  String? _newStatus;
  String? _newImageUrl;
  XFile? _pickedImage;
  html.File? _webImageFile;
  io.File? _imageFile;

  List<DocumentSnapshot> _documents = [];

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _fetchDocuments();
    super.initState();
  }

  void _updateDocument(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(docId)
          .update(data);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Successfully updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update document: $e')));
    }
  }

  void _deleteDocument(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(docId)
          .delete();
      setState(() {
        _documents = [];
        _fetchDocuments();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete document: $e')));
    }
  }

  void _editStatus(String docId, String currentStatus) async {
    final newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';

    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(docId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status toggled successfully! New status: $newStatus'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to toggle status: $e'),
      ));
    }
  }

  Future<void> _fetchDocuments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('categories');

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _documents = querySnapshot.docs;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadImage(StateSetter setState) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Picking image...'), duration: Duration(seconds: 2)));
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoadEnd.listen((e) async {
          setState(() {
            _webImageFile = files[0];
            _newImageUrl = html.Url.createObjectUrlFromBlob(_webImageFile!);
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Uploading image...')));

          final storageRef =
              _storage.ref().child('images/${DateTime.now().toString()}');
          final uploadTask = storageRef.putBlob(_webImageFile!);

          try {
            await uploadTask;
            String downloadURL = await storageRef.getDownloadURL();
            setState(() {
              _newImageUrl = downloadURL;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Image uploaded successfully!')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to upload image: $e'),
              duration: const Duration(seconds: 2),
            ));
          }
        });
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _pickedImage = pickedFile;
        _imageFile = io.File(pickedFile.path);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Uploading image...')));

      final storageRef =
          _storage.ref().child('images/${DateTime.now().toString()}');
      final uploadTask = storageRef.putFile(_imageFile!);

      try {
        await uploadTask;
        String downloadURL = await storageRef.getDownloadURL();
        setState(() {
          _newImageUrl = downloadURL;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image uploaded successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload image: $e'),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.20,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            width: 80,
            child: Image.asset("assets/images/logo1.png"),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildDrawerItem(Icons.dashboard, "Dashboard"),
                const SizedBox(height: 10),
                _buildDrawerItem(Icons.category, "Categories"),
                const SizedBox(height: 10),
                _buildDrawerItem(
                    Icons.production_quantity_limits_sharp, "Product"),
                const SizedBox(height: 10),
                _buildDrawerItem(Icons.branding_watermark, "Brand"),
                const SizedBox(height: 10),
                _buildDrawerItem(Icons.price_change, "Update Prices"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // Handle navigation
      },
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Category",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_3_rounded, size: 30),
            label: const Text(
              "Sign In",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildFeaturesBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.15,
          height: 30,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(8),
            ),
            onChanged: (value) {
              setState(() {
                _searchValue = value.toLowerCase();
              });
            },
          ),
        ),
        const SizedBox(width: 30),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.cancel_sharp, color: Colors.grey),
          label: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: const BorderSide(color: Colors.grey),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayBar() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.72,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(1),
            spreadRadius: 4,
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Image',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildAppBar(),
            const SizedBox(height: 20),
            _buildFeaturesBar(),
            const SizedBox(height: 20),
            _buildDisplayBar(),
            Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(5.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Text('Error fetching data');
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No data found');
                  }

                  final documents = snapshot.data!.docs;
                  final filteredDocs =
                      _searchValue != null && _searchValue!.isNotEmpty
                          ? documents.where((doc) {
                              final categoryName =
                                  (doc['categoryName'] as String).toLowerCase();
                              return categoryName.contains(_searchValue!);
                            }).toList()
                          : documents;

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            children: [
                              TableCell(
                                verticalAlignment:TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(doc['imageUrl']),
                                        
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(doc['categoryName']),
                                ),
                              ),
                              TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(doc['status']),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 0,top: 0,right: 0,bottom: 0),
                                  child: Row(
                                    
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _showEditDialog(
                                              doc.id,
                                              doc['categoryName'],
                                              doc['imageUrl']);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_red_eye),
                                        onPressed: () {
                                          _editStatus(doc.id, doc['status']);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _deleteDocument(doc.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      String docId, String currentName, String currentImageUrl) {
    _newCategoryName = currentName;
    _newImageUrl = currentImageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Category Name'),
                    controller: TextEditingController(text: _newCategoryName),
                    onChanged: (value) {
                      _newCategoryName = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  (_pickedImage != null || _webImageFile != null)
                      ? (_webImageFile != null)
                          ? Image.network(
                              html.Url.createObjectUrlFromBlob(_webImageFile!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _imageFile!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                      : Image.network(
                          currentImageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                  const SizedBox(
                    height: 15,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _pickAndUploadImage(setState);
                      setState(() {});
                    },
                    child: const Text('Pick Image'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _newImageUrl = null;
                    _newCategoryName = null;
                    setState(() {
                      _pickedImage = null;
                      _webImageFile = null;
                      _imageFile = null;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (_newCategoryName != null || _newImageUrl != null) {
                      final data = <String, dynamic>{};
                      if (_newCategoryName != null) {
                        data['categoryName'] = _newCategoryName!;
                      }
                      if (_newImageUrl != null) {
                        data['imageUrl'] = _newImageUrl!;
                      }
                      _updateDocument(docId, data);
                    }
                    Navigator.of(context).pop();
                    _newImageUrl = null;
                    _webImageFile = null;
                    _pickedImage = null;
                    _imageFile = null;
                    _newCategoryName = null;
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrawer(),
            _buildMainArea(),
          ],
        ),
      ),
    );
  }
}
