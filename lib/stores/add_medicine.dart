import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hosp_test/stores/medicine.dart';

class AddMedicinePage extends StatefulWidget {
  final String? initialCategory;
  final Map<String, dynamic>? initialData;
  final String? medicineId;

  const AddMedicinePage({
    this.initialCategory,
    this.initialData,
    this.medicineId,
    Key? key,
  }) : super(key: key);

  @override
  _AddMedicinePageState createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _categoryController = TextEditingController();
  final _companyController = TextEditingController();
  final _stockController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _categoryController.text = widget.initialCategory!;
    }

    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _priceController.text = widget.initialData!['price']?.toString() ?? '0.0';
      _quantityController.text =
          widget.initialData!['quantity']?.toString() ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _manufacturerController.text = widget.initialData!['manufacturer'] ?? '';
      _companyController.text = widget.initialData!['company'] ?? '';
      _categoryController.text = widget.initialData!['category'] ?? '';
      _stockController.text = widget.initialData!['stock']?.toString() ?? '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final id =
          widget.medicineId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final company = _companyController.text.trim();
      final category = _categoryController.text.trim();
      final stockText = _stockController.text.trim();
      final stock = int.tryParse(stockText) ?? 0;

      if (stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please enter a valid stock number greater than 0')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (company.isEmpty || category.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter company and category')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final priceText = _priceController.text.trim();
      if (priceText.isEmpty || double.tryParse(priceText) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final medicine = Medicine(
        id: id,
        name: _nameController.text.trim(),
        price: double.tryParse(priceText) ?? 0.0,
        quantity: _quantityController.text.trim(),
        description: _descriptionController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        stock: stock,
        category: category,
        company: company, selectedCount: null,
      );

      await _firestore.collection('medicines').doc(id).set(medicine.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.medicineId != null
              ? 'Medicine updated successfully!'
              : 'Medicine added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.medicineId == null) {
        _formKey.currentState?.reset();
        _companyController.clear();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medicine: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      backgroundColor: const Color(0xFFF5F5DC), // Parchment-like background
      appBar: AppBar(
        title: Text(
          widget.medicineId != null ? 'Edit Medicine' : 'Add Medicine',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50), // Ayurvedic green
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      _companyController,
                      'Company Name*',
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _categoryController,
                      'Category*',
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _nameController,
                      'Medicine Name*',
                      icon: Icons.medication,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _priceController,
                            'Price (₹)*',
                            prefixText: '₹ ',
                            keyboardType: TextInputType.number,
                            icon: Icons.currency_rupee,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _quantityController,
                            'Quantity*',
                            icon: Icons.scale,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _stockController,
                            'Stock Available*',
                            keyboardType: TextInputType.number,
                            icon: Icons.inventory,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _manufacturerController,
                      'Manufacturer',
                      icon: Icons.factory,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _descriptionController,
                      'Description (Benefits, Dosage)',
                      maxLines: 3,
                      icon: Icons.description,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.medicineId != null
                                        ? Icons.update
                                        : Icons.add_circle_outline,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.medicineId != null
                                        ? 'Update Medicine'
                                        : 'Add Medicine',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon:
            icon != null ? Icon(icon, color: const Color(0xFF4CAF50)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'Please enter ${label.replaceAll('*', '')}';
        }
        if (label.contains('Price') &&
            (value == null || double.tryParse(value) == null)) {
          return 'Enter valid price';
        }
        if (label.contains('Stock') &&
            (value == null || int.tryParse(value) == null)) {
          return 'Enter valid stock number';
        }
        return null;
      },
    );
  }
}