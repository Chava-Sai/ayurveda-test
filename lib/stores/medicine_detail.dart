import 'package:flutter/material.dart';
import 'package:hosp_test/services/viewchat_page.dart';
import 'package:hosp_test/stores/add_medicine.dart';
import 'package:hosp_test/stores/edit_medicine.dart';

class MedicineDetailPage extends StatelessWidget {
  final String medicineId;
  final Map<String, dynamic> medicineData;
  final String? category;

  const MedicineDetailPage({
    required this.medicineId,
    required this.medicineData,
    this.category,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: Text(
          medicineData['name'] ?? 'Medicine Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMedicinePage(
                    medicineId: medicineId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Key Information'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildCompactInfoCard(
                      'Price',
                      '₹${medicineData['price']?.toStringAsFixed(2) ?? 'N/A'}',
                      Icons.attach_money,
                      Colors.red,
                      constraints.maxWidth,
                    ),
                    _buildCompactInfoCard(
                      'Quantity',
                      medicineData['quantity']?.toString() ?? 'N/A',
                      Icons.scale,
                      Colors.blue,
                      constraints.maxWidth,
                    ),
                    _buildCompactInfoCard(
                      'Stock',
                      medicineData['stock']?.toString() ?? 'N/A',
                      Icons.inventory,
                      (medicineData['stock'] as int? ?? 0) > 10
                          ? Colors.green
                          : Colors.orange,
                      constraints.maxWidth,
                    ),
                    _buildCompactInfoCard(
                      'Category',
                      category ?? 'N/A',
                      Icons.category,
                      Colors.purple,
                      constraints.maxWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _buildDetailsCard(context),
            // const SizedBox(height: 20),
            // _buildUsageCard(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_services,
                  size: 36, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicineData['name'] ?? 'Unnamed Medicine',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    medicineData['genericName'] ?? 'Generic name not specified',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoCard(
      String title, String value, IconData icon, Color color, double maxWidth) {
    double cardWidth = double.infinity; // 12px spacing
    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 5,
        color: Color.fromARGB(255, 253, 255, 254),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Wrap title with Flexible
                    Flexible(
                      flex: 2,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 24),

                    /// Wrap value with Flexible
                    Flexible(
                      flex: 3,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Details'),
            const SizedBox(height: 10),
            _buildCompactDetailRow(
                'Company', medicineData['company'] ?? 'Unknown'),
            _buildCompactDetailRow(
                'Manufacturer', medicineData['manufacturer'] ?? 'Unknown'),
            _buildCompactDetailRow('Product Id', medicineData['id'] ?? 'N/A'),
            // _buildCompactDetailRow(
            //     'Expiry Date', medicineData['expiryDate'] ?? 'N/A'),
            // _buildCompactDetailRow(
            //     'Dosage Form', medicineData['dosageForm'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  // Widget _buildUsageCard(BuildContext context) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     color: Colors.white,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           _buildSectionTitle(context, 'Usage & Effects'),
  //           const SizedBox(height: 10),
  //           _buildCompactInfoItem(
  //               'Indications', medicineData['indications'] ?? 'Not specified'),
  //           _buildCompactInfoItem(
  //               'Dosage', medicineData['dosage'] ?? 'Not specified'),
  //           _buildCompactInfoItem(
  //               'Side Effects', medicineData['sideEffects'] ?? 'Not specified'),
  //           _buildCompactInfoItem('Contraindications',
  //               medicineData['contraindications'] ?? 'Not specified'),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCompactDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 14)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                foregroundColor: const Color(0xFF2E7D32),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMedicinePage(
                      medicineId: medicineId,
                      initialCategory: category,
                      initialData: medicineData,
                    ),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 6),
                  Text('Edit', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Implement order functionality
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Order',
                      style: TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
