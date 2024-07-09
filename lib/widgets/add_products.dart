// widgets/add_products.dart

import 'dart:io' as io;

import 'package:uuid/uuid.dart'; // Importing the UUID package
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:html' as html;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProducts extends StatefulWidget {
  const AddProducts({Key? key}) : super(key: key);

  @override
  _AddProductsState createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  @override
  void initState() {
    super.initState();
    fetchFieldNames();
  }

  // -------------TextEditing Controllers ----------------
  final TextEditingController _productnameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _maxquantityController = TextEditingController();
  final TextEditingController unitMeasureContoller = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _bgColorController = TextEditingController();
  final TextEditingController _tagLineController = TextEditingController();
  final TextEditingController _hsnNumController = TextEditingController();
  final TextEditingController _hsnDescController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _salesController = TextEditingController();

  // -------------------- Variables ---------------------

  String? _productId;
  String? _productName;
  String? _description;
  String? _maxQunatity;
  String? _unitmeasure;
  String? _productCategory;
  String? _status;
  String? _bgColor;
  String? _tagLine;
  String? _hsnNumber;
  String? _hsnDescription;
  String? selectedField;
  String? variantId;

  var _variantCount = 0;
  double? _gst;
  double? variation;
  double? tempReduction;
  double? tempDiscount;
  double? tempCost;
  double? tempMrp;
  double? tempSell;
  double? calcCost;
  double? calcMrp;
  double? calcSell;
  double? sales;

  List<String> fieldNames = [];
  List<io.File>? _imageFiles = [];
  List<html.File>? _webImageFiles = [];
  List<String> _imageUrls = [];
  final List<String> _tags = [];

  // -------------- Instances --------------
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // -------------- Functions --------------

  void _addProductToFirestore() async {
    // Retrieve values from text controllers and variables
    _productName = _productnameController.text.trim();
    _description = _descriptionController.text.trim();
    _maxQunatity = _maxquantityController.text.trim();
    _bgColor = _bgColorController.text.trim();
    _tagLine = _tagLineController.text.trim();
    _hsnNumber = _hsnNumController.text.trim();
    _hsnDescription = _hsnDescController.text.trim();
    _gst = double.tryParse(_gstController.text);
    sales = double.tryParse(_salesController.text);

    // Validate required fields
    if (_productName == null || _productName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a product name'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if (_description == null || _description!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a product description'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if (_maxQunatity == null || _maxQunatity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter max quantity'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if (_bgColor == null || _bgColor!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter Background Color'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if (_tagLine == null || _tagLine!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter Tagline'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if (_hsnNumber == null || _hsnNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter HSN Number'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if (_hsnDescription == null || _hsnDescription!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter HSN Description'),
        duration: Duration(seconds: 2),
      ));
      return;
    }

    // Generate a new UUID
    if (_productName == null || _productName!.length < 3) {
      throw Exception("Product name must have at least 3 characters");
    }

    // Prepare data to be stored in Firestore
    var productData = {
      "productId": _productId,
      'productTitle': _productName,
      "imageUrls": _imageUrls,
      'description': _description,
      "bgColor": _bgColor,
      "tagline": _tagLine,
      'maxQuantity':
          int.tryParse(_maxQunatity!) ?? 0, // Parse max quantity as integer
      'unitsOfMeasure': _unitmeasure,
      'productCategory': _productCategory,
      "discount": tempDiscount,
      'tags': _tags,
      'status': _status,
      "hsnNumber": _hsnNumber,
      "hsnDescription": _hsnDescription,
      "gst": _gst,
      "sales": sales,
    };

    // Add product to Firestore
    try {
      DocumentReference docRef =
          _firestore.collection('Products').doc(_productId);

      // Set the updated data back to the document
      await docRef.set(productData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product added successfully!'),
        duration: Duration(seconds: 2),
      ));
      // Optionally, clear fields after successful addition
      _productnameController.clear();
      _descriptionController.clear();
      _maxquantityController.clear();
      _tagsController.clear();
      _bgColorController.clear();
      _tagLineController.clear();
      _hsnNumController.clear();
      _hsnDescController.clear();
      _gstController.clear();
      _salesController.clear;

      setState(() {
        _tagLine = null;
        _hsnNumber = null;
        _hsnDescription = null;
        _gst = null;
        _unitmeasure = null;
        _productCategory = null;
        _bgColor = null;
        _status = null;
        tempCost = null;
        tempMrp = null;
        tempSell = null;
        tempDiscount = null;
        _imageFiles = [];
        _webImageFiles = [];
        _imageUrls = [];
        tempReduction = null;
        _variantCount = 0;
        sales = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add product: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _uploadAndAddImage() async {
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
            _webImageFiles!.add(files[0]);
          });

          final storageRef =
              _storage.ref().child('images/${DateTime.now().toString()}');
          final uploadTask = storageRef.putBlob(files[0]);

          try {
            await uploadTask;
            String downloadURL = await storageRef.getDownloadURL();
            setState(() {
              _imageUrls.add(downloadURL);
            });
            imageCache.clear();
            imageCache.clearLiveImages();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to upload image: $e'),
              duration: Duration(seconds: 2),
            ));
          }
        });
      });
    } else {
      // Mobile image picker
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _imageFiles!.add(io.File(pickedFile.path));
      });

      final storageRef =
          _storage.ref().child('images/${DateTime.now().toString()}');
      final uploadTask = storageRef.putFile(io.File(pickedFile.path));

      try {
        await uploadTask;
        String downloadURL = await storageRef.getDownloadURL();
        setState(() {
          _imageUrls.add(downloadURL);
        });
        imageCache.clear();
        imageCache.clearLiveImages();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload image: $e'),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  Future<void> fetchFieldNames() async {
    try {
      // Fetch the collection from Firestore
      CollectionReference collection =
          FirebaseFirestore.instance.collection('categories');
      QuerySnapshot snapshot = await collection.get();

      // Extract field names from the first document
      if (snapshot.docs.isNotEmpty) {
        List<String> fieldValues = snapshot.docs.map((doc) {
          return doc["categoryName"] as String;
        }).toList();
        setState(() {
          fieldNames = fieldValues;
        });
      }
    } catch (e) {
      print('Error fetching field names: $e');
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _tagsController.dispose();
    super.dispose();
  }

  // --------------------------------------- Widgets ---------------------------------------------

  Widget _pricing() {
    // --------------- Variables -------------------

    // --------------- Controllers ------------------

    TextEditingController variationController =
        TextEditingController(text: variation?.toString() ?? "");
    TextEditingController costPriceController =
        TextEditingController(text: calcCost?.toString() ?? "");
    TextEditingController reductionController =
        TextEditingController(text: tempReduction?.toString() ?? '');
    TextEditingController mrpController =
        TextEditingController(text: calcMrp?.toString() ?? "");
    TextEditingController sellingPriceController =
        TextEditingController(text: calcSell?.toString() ?? "");
    TextEditingController discountController =
        TextEditingController(text: (tempDiscount?.toString() ?? ''));

    // --------------- Functions ---------------------

    Future<void> uploadingToFirebase(Map<String, dynamic> newVariant) async {
      try {
        DocumentReference docRef = _firestore
            .collection('Products')
            .doc(_productId)
            .collection('Variants')
            .doc(variantId);

        // Set the updated data back to the document
        await docRef.set(newVariant, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Variant added successfully!'),
          duration: Duration(seconds: 2),
        ));
        // Optionally, clear fields after successful addition
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add variant: $e'),
          duration: const Duration(seconds: 2),
        ));
      }
    }

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Ensure the column takes minimum height

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Pricing", style: TextStyle(fontSize: 16)),
                ElevatedButton(
                  onPressed: () async {
                    _productName = _productnameController.text.trim();
                    if (_productName!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter a product name'),
                        duration: Duration(seconds: 2),
                      ));
                      return;
                    }

                    var variantData = <String, dynamic>{};

                    if (_variantCount == 0) {
                      _productName = _productnameController.text;

                      String prefix =
                          _productName!.substring(0, 3).toUpperCase();

                      // Generate 12 random digits from UUID
                      String uuidStr = _uuid
                          .v4()
                          .replaceAll('-', '')
                          .replaceAll(RegExp(r'[a-fA-F]'), '');
                      String randomDigits = uuidStr.substring(0, 13);

                      // Combine prefix and random digits
                      _productId = prefix + randomDigits;

                      if (tempCost != null &&
                          tempMrp != null &&
                          tempSell != null) {
                        variantData = {
                          "variantId": variantId,
                          "weight": variation,
                          "costPrice": tempCost,
                          "mrp": tempMrp,
                          "sellingPrice": tempSell
                        };
                      }
                    } else {
                      if ((calcCost != null &&
                          calcMrp != null &&
                          calcSell != null)) {
                        variantData = {
                          "variantId": variantId,
                          "weight": variation,
                          "costPrice": calcCost,
                          "mrp": calcMrp,
                          "sellingPrice": calcSell
                        };
                      }
                    }

                    await uploadingToFirebase(variantData);

                    setState(() {
                      if (_variantCount == 0) {
                        tempCost = double.tryParse(costPriceController.text);
                        tempMrp = double.tryParse(mrpController.text);
                        tempSell = double.tryParse(sellingPriceController.text);
                      }

                      variationController.text = "";
                      mrpController.text = "";
                      sellingPriceController.text = "";
                      costPriceController.text = "";
                      variation = null;
                      calcCost = null;
                      calcMrp = null;
                      calcSell = null;

                      _variantCount = _variantCount + 1;
                    });
                  },
                  child: const Text("Add Variant"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: TextField(
                    controller: variationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: "Variation",
                      hintText: "Type variation here...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      variation = double.tryParse(value);
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      variation = double.tryParse(variationController.text);

                      _productName = _productnameController.text;

                      String prefix =
                          _productName!.substring(0, 3).toUpperCase();

                      // Generate 12 random digits from UUID
                      String uuidStr = _uuid
                          .v4()
                          .replaceAll('-', '')
                          .replaceAll(RegExp(r'[a-fA-F]'), '');
                      String randomDigits = uuidStr.substring(0, 12);

                      // Combine prefix and random digits
                      variantId = prefix + variation.toString() + randomDigits;
                      print(variantId);

                      if ((_variantCount == 0)) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Variant Submitted successfully!'),
                          duration: Duration(seconds: 2),
                        ));
                      } else {
                        if (variation != null &&
                            tempCost != null &&
                            tempMrp != null &&
                            tempReduction != null &&
                            tempDiscount != null) {
                          calcCost =
                              double.tryParse(("${variation! * tempCost!}"));

                          calcCost =
                              double.tryParse(calcCost!.toStringAsFixed(2));

                          calcMrp = double.tryParse(
                              "${((tempMrp! * variation!) - ((tempReduction! / 100) * (tempMrp! * variation!)))}");

                          calcMrp =
                              double.tryParse(calcMrp!.toStringAsFixed(2));

                          calcSell = double.tryParse(
                              "${((tempMrp! * variation!) - ((tempReduction! / 100) * (tempMrp! * variation!))) - ((tempDiscount! / 100) * ((tempMrp! * variation!) - ((tempReduction! / 100) * (tempMrp! * variation!))))}");

                          calcSell =
                              double.tryParse(calcSell!.toStringAsFixed(2));

                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Variant Submitted successfully!'),
                            duration: Duration(seconds: 2),
                          ));
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content:
                                Text('Please fill in all fields correctly.'),
                            duration: Duration(seconds: 2),
                          ));
                        }
                      }
                    });
                  },
                  child: const Text("Confirm Variant"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: reductionController,
                    decoration: const InputDecoration(
                      labelText: "Reduction",
                      hintText: "Type reduction here...",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      tempReduction = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: mrpController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "MRP",
                      hintText: "Type MRP here...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => {
                      tempMrp = double.tryParse(value),
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Discount",
                      hintText: "Type discount here...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => {
                      tempDiscount = double.tryParse(value),
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: sellingPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Selling Price",
                      hintText: "Type selling price here...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => {
                      tempSell = double.tryParse(value),
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costPriceController,
              decoration: const InputDecoration(
                labelText: "Cost Price",
                hintText: "Type Cost Price here...",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => {
                tempCost = double.tryParse(value),
              },
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildProductInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                // Implement cancel functionality
              },
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addProductToFirestore,
              child: const Text("Add Product"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text("Product Information",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildGeneralInformation(),
        const SizedBox(height: 20),
        _buildMedia(),
        const SizedBox(height: 20),
        _buildQuantity(),
        const SizedBox(height: 20),
        _buildCategory(),
        const SizedBox(height: 20),
        _buildStatus(),
        const SizedBox(height: 20),
        _buildGst(),
        const SizedBox(height: 20),
        _pricing(),
      ],
    );
  }

  Widget _buildGeneralInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("General Information", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: _productnameController,
          decoration: const InputDecoration(
            labelText: "Product Name",
            hintText: "Type product name here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          maxLines: 3,
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: "Description",
            hintText: "Type product description here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bgColorController,
          decoration: const InputDecoration(
            labelText: "Product's Background Color",
            hintText: "Type Background Color here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _tagLineController,
          decoration: const InputDecoration(
            labelText: "TagLine",
            hintText: "Type TagLine here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _imageContainer() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(10),
      dashPattern: const [8, 4],
      color: const Color.fromRGBO(224, 226, 231, 1),
      strokeWidth: 2,
      child: SizedBox(
        width: 230,
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image,
                size: 30,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.all(15.0),
                child: Text("Click to add Image"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _uploadAndAddImage();
                },
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
    );
  }

  Widget _buildMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text("Photo", style: TextStyle(fontSize: 14)),
        const SizedBox(height: 10),
        (_imageFiles!.isNotEmpty || _webImageFiles!.isNotEmpty)
            ? Row(
                children: [
                  ..._webImageFiles!.map((file) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.network(
                          html.Url.createObjectUrlFromBlob(file),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )),
                  ..._imageFiles!.map((file) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.file(
                          file,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _uploadAndAddImage();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text("Add"),
                  ),
                ],
              )
            : _imageContainer(),
      ],
    );
  }

  Widget _buildQuantity() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _maxquantityController,
            decoration: const InputDecoration(
              labelText: "Max Quantity",
              hintText: "Type max quantity here...",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text("Unit of Measure : "),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Option',
              border: OutlineInputBorder(),
            ),
            value: _unitmeasure,
            items: <String>["Kg", "Litre"].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? value) {
              _unitmeasure = value;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _salesController,
            decoration: const InputDecoration(
              labelText: "Sales",
              hintText: "Enter Sales",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) => {
              sales = double.tryParse(value),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Category", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Select Option',
            border: OutlineInputBorder(),
          ),
          items: fieldNames.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          value: _productCategory,
          onChanged: (String? value) {
            _productCategory = value;
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: "Product Tags",
                  hintText: "Enter tags separated by commas",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Split the input by commas, trim whitespace, and add each tag to the list
                _tags.addAll(_tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty));

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('tags added successfully!'),
                  duration: Duration(seconds: 2),
                ));
              },
              child: const Text("Add Tags"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return Row(
      children: [
        const Text("Product Status : "),
        SizedBox(
          width: 400,
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Option',
              border: OutlineInputBorder(),
            ),
            items: <String>[
              'Draft',
              'Active',
              'Inactive',
              'Sold Out',
              "Coming Soon",
              "New Product"
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            value: _status,
            onChanged: (String? value) {
              _status = value;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGst() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("GST Details", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: _hsnNumController,
          decoration: const InputDecoration(
            labelText: "HSN Number",
            hintText: "Type HSN Number here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          maxLines: 2,
          controller: _hsnDescController,
          decoration: const InputDecoration(
            labelText: "HSN Description",
            hintText: "Type HSN Description here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _gstController,
          decoration: const InputDecoration(
            labelText: "GST",
            hintText: "Type GST here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.18,
              child: _buildDrawer(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: _buildProductInformation(),
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
