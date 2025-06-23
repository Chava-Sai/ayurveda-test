import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hosp_test/stores/medicine.dart';

class EditMedicinePage extends StatefulWidget {
  final String medicineId;

  const EditMedicinePage({super.key, required this.medicineId});

  @override
  State<EditMedicinePage> createState() => _EditMedicinePageState();
}

class _EditMedicinePageState extends State<EditMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isUpdating = false;
  Medicine? _medicine;

  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _categoryController = TextEditingController();
  final _companyController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMedicine();
  }

  Future<void> _fetchMedicine() async {
    try {
      final doc =
          await _firestore.collection('medicines').doc(widget.medicineId).get();
      if (!doc.exists) {
        throw Exception('Medicine not found');
      }

      final data = doc.data()!;
      _medicine = Medicine.fromMap(data);

      _nameController.text = _medicine!.name;
      _priceController.text = _medicine!.price.toString();
      _quantityController.text = _medicine!.quantity;
      _descriptionController.text = _medicine!.description ?? '';
      _manufacturerController.text = _medicine!.manufacturer ?? '';
      _categoryController.text = _medicine!.category;
      _companyController.text = _medicine!.company;
      _stockController.text = _medicine!.stock.toString();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUpdating = true);

    try {
      final updated = Medicine(
        id: widget.medicineId,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        quantity: _quantityController.text.trim(),
        description: _descriptionController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        category: _categoryController.text.trim(),
        company: _companyController.text.trim(),
        selectedCount: null,
      );

      await _firestore
          .collection('medicines')
          .doc(widget.medicineId)
          .set(updated.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Enter $label';
        if (label == 'Price' && double.tryParse(value.trim()) == null)
          return 'Invalid price';
        if (label == 'Stock' && int.tryParse(value.trim()) == null)
          return 'Invalid stock';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _manufacturerController.dispose();
    _categoryController.dispose();
    _companyController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medicine'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(_companyController, 'Company'),
                    const SizedBox(height: 12),
                    _buildTextField(_categoryController, 'Category'),
                    const SizedBox(height: 12),
                    _buildTextField(_nameController, 'Medicine Name'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(_priceController, 'Price',
                                type: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildTextField(
                                _quantityController, 'Quantity')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildTextField(_stockController, 'Stock',
                                type: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_manufacturerController, 'Manufacturer'),
                    const SizedBox(height: 12),
                    // _buildTextField(_descriptionController, 'Description',
                    //     maxLines: 3),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _updateMedicine,
                      icon: const Icon(Icons.save),
                      label: Text(_isUpdating ? 'Updating...' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
