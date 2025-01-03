import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VendorsScreen extends StatelessWidget {
  static const String id = 'vendors-screen';
  const VendorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _vendorsStream =
        FirebaseFirestore.instance.collection('vendors').snapshots();

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(10),
              child: Text(
                'Vendors',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _vendorsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return Card(
                  child: DataTable(
                    columnSpacing: 20,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Store Logo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Store Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Vendor Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Phone',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Address',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Join Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data()! as Map<String, dynamic>;
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              width: 50,
                              height: 50,
                              child: data['storeImage'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.network(
                                        data['storeImage'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CircleAvatar(
                                      child: Icon(Icons.store),
                                    ),
                            ),
                          ),
                          DataCell(Text(data['businessName'] ?? '')),
                          DataCell(Text(data['fullname'] ?? '')),
                          DataCell(Text(data['email'] ?? '')),
                          DataCell(Text(data['phone'] ?? '')),
                          DataCell(Text(data['address'] ?? '')),
                          DataCell(Text(
                            data['joinDate'] != null
                                ? DateFormat('MMM d, y').format(
                                    (data['joinDate'] as Timestamp).toDate(),
                                  )
                                : '',
                          )),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    data['approved'] == true
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                    color: data['approved'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('vendors')
                                        .doc(document.id)
                                        .update({
                                      'approved': !(data['approved'] ?? false),
                                    });
                                  },
                                  tooltip: data['approved'] == true
                                      ? 'Revoke Approval'
                                      : 'Approve Vendor',
                                ),
                                IconButton(
                                  icon: Icon(Icons.block, color: Colors.red),
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('vendors')
                                        .doc(document.id)
                                        .update({
                                      'blocked': !(data['blocked'] ?? false),
                                    });
                                  },
                                  tooltip: data['blocked'] == true
                                      ? 'Unblock Vendor'
                                      : 'Block Vendor',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
