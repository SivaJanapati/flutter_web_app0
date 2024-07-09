// widgets/record.dart
import 'package:flutter/material.dart';

class Record extends StatefulWidget {
  const Record({super.key});

  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  String? imageUrl;
  String? categoryName;
  String? status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          child: Text(imageUrl!),
        ),
        Text(categoryName!),
        Text(status!)
      ],
    );
  }
}
