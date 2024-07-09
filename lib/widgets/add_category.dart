// widgets/add_category.dart

import 'dart:io' as io;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCategory extends StatefulWidget {
  const AddCategory({Key? key}) : super(key: key);

  @override
  State<AddCategory> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  // ------------- Variables --------------

  io.File? _imageFile;
  String? _imageUrl;
  html.File? _webImageFile;
  String? _statusValue;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _categoryNameController = TextEditingController();

  // ------------- Functions --------------

  // Function to pick and upload an image

  Future<void> _pickAndUploadImage() async {
    if (kIsWeb) {
      // Web-specific image picker
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
          });

          final storageRef =
              _storage.ref().child('images/${DateTime.now().toString()}');
          final uploadTask = storageRef.putBlob(_webImageFile!);

          try {
            await uploadTask;
            String downloadURL = await storageRef.getDownloadURL();
            setState(() {
              _imageUrl = downloadURL;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to upload image: $e'),
              duration: const Duration(seconds: 2),
            ));
          }
        });
      });
    } else {
      // Mobile image picker
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _imageFile = io.File(pickedFile.path);
      });

      final storageRef =
          _storage.ref().child('images/${DateTime.now().toString()}');
      final uploadTask = storageRef.putFile(io.File(pickedFile.path));

      try {
        await uploadTask;
        String downloadURL = await storageRef.getDownloadURL();
        setState(() {
          _imageUrl = downloadURL;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload image: $e'),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  // Function to add category to Firestore
  Future<void> _addCategoryToFirestore() async {
    String categoryName = _categoryNameController.text.trim();
    if (categoryName.isEmpty || _imageUrl == null || _statusValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Category name or image URL or Status is missing!'),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    try {
      await _firestore.collection('categories').add({
        'categoryName': categoryName,
        'imageUrl': _imageUrl,
        "status": _statusValue,
      });
      // Clear the text field and reset image URL after successful upload
      setState(() {
        _categoryNameController.clear();
        _imageUrl = null;
        _imageFile = null;
        _webImageFile = null;
        _statusValue = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Category added successfully!'),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add category: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // Function to remove the selected image
  void _removeImage() {
    setState(() {
      _imageFile = null;
      _webImageFile = null;
      _imageUrl = null;
    });
  }

  // ------------ Widgets ---------------

  Widget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Product",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text("Products",
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
                  Icon(Icons.play_arrow, size: 13),
                  Text("Add Product",
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_3_rounded),
            label: const Text(
              "Sign In",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0, // Remove the elevation
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            width: 80,
            child: Image.asset("assets/images/logo1.png"),
          ),
          const SizedBox(height: 50),
          _buildDrawerItem(Icons.dashboard, "Dashboard"),
          const SizedBox(height: 10),
          _buildDrawerItem(Icons.category, "Categories"),
          const SizedBox(height: 10),
          _buildDrawerItem(Icons.production_quantity_limits_sharp, "Product"),
          const SizedBox(height: 10),
          _buildDrawerItem(Icons.branding_watermark, "Brand"),
          const SizedBox(height: 10),
          _buildDrawerItem(Icons.price_change, "Update Prices"),
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

  // Widget to build image placeholder
  Widget _buildImagePlaceholder() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(10),
      dashPattern: const [8, 4],
      color: const Color.fromRGBO(224, 226, 231, 1),
      strokeWidth: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 40, 5, 5),
        child: SizedBox(
          width: 350,
          height: 180,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image,
                  size: 35,
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    "Click to add Image",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _pickAndUploadImage,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text("Add"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Sidebar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.20,
              child: _buildDrawer(),
            ),
          ),
          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(50.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.cancel_sharp,
                                        color: Colors.grey),
                                    label: const Text('Cancel',
                                        style: TextStyle(color: Colors.grey)),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        side: const BorderSide(
                                            color: Colors.grey),
                                      ),
                                      elevation: 0, // Remove the elevation
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  ElevatedButton.icon(
                                    onPressed: _addCategoryToFirestore,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Category'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 50),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 350,
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(
                                                0.5), // Shadow color
                                            spreadRadius: 5, // Spread radius
                                            blurRadius: 7, // Blur radius
                                            offset: const Offset(
                                                0, 3), // Shadow position
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 40),
                                          const Text(
                                            "Thumbnail",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          (_imageFile != null ||
                                                  _webImageFile != null)
                                              ? Column(
                                                  children: [
                                                    (_webImageFile != null)
                                                        ? Image.network(
                                                            html.Url.createObjectUrlFromBlob(
                                                                _webImageFile!),
                                                            width: 230,
                                                            height: 200,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.file(
                                                            _imageFile!,
                                                            width: 230,
                                                            height: 200,
                                                            fit: BoxFit.cover,
                                                          ),
                                                    const SizedBox(height: 8),
                                                    ElevatedButton(
                                                      onPressed: _removeImage,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                      ),
                                                      child:
                                                          const Text("Remove"),
                                                    ),
                                                  ],
                                                )
                                              : _buildImagePlaceholder(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 40,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(
                                                0.5), // Shadow color
                                            spreadRadius: 5, // Spread radius
                                            blurRadius: 7, // Blur radius
                                            offset: const Offset(
                                                0, 3), // Shadow position
                                          ),
                                        ],
                                      ),
                                      height: 240,
                                      width: MediaQuery.of(context).size.width *
                                          0.6,
                                      child: Padding(
                                        padding: const EdgeInsets.all(50.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Category Name",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                    color: Colors.grey),
                                              ),
                                              child: TextField(
                                                controller:
                                                    _categoryNameController,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText:
                                                      "Type Category Name here...",
                                                  border: InputBorder.none,
                                                  hintStyle: TextStyle(
                                                    color: Color.fromRGBO(
                                                        133, 141, 157, 1),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 40,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(
                                                0.5), // Shadow color
                                            spreadRadius: 5, // Spread radius
                                            blurRadius: 7, // Blur radius
                                            offset: const Offset(
                                                0, 3), // Shadow position
                                          ),
                                        ],
                                      ),
                                      height: 240,
                                      width: MediaQuery.of(context).size.width *
                                          0.6,
                                      child: Padding(
                                        padding: const EdgeInsets.all(50.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Status",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              child: DropdownButtonFormField<
                                                  String>(
                                                decoration: InputDecoration(
                                                  labelText: 'Select Option',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                ),
                                                value: _statusValue,
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: "Active",
                                                    child: Text("Active"),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: "Inactive",
                                                    child: Text("Inactive"),
                                                  ),
                                                ],
                                                onChanged: (String? value) {
                                                  setState(() {
                                                    _statusValue = value;
                                                  });
                                                },
                                                validator: (value) => value ==
                                                        null
                                                    ? 'Please select a status'
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
