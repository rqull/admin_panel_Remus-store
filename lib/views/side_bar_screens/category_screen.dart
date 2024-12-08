import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  static const String id = '\category-screen';
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            alignment: Alignment.topLeft,
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Divider(
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
                    child: Text(
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
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.blue),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Upload Image',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 30,
            ),
            Container(
              width: 150,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Category Name',
                ),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.white),
                  side: WidgetStatePropertyAll(
                      BorderSide(color: Colors.blue.shade900))),
              onPressed: () {},
              child: Text('Save'),
            )
          ],
        ),
      ],
    );
  }
}
