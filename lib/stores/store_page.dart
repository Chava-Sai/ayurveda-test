import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hosp_test/services/viewchat_page.dart';
import 'package:hosp_test/stores/add_medicine.dart';
import 'package:hosp_test/stores/medicine.dart';
import 'package:hosp_test/stores/medicine_detail.dart';

class MedicineListWithFilterPage extends StatefulWidget {
  const MedicineListWithFilterPage({Key? key}) : super(key: key);

  @override
  State<MedicineListWithFilterPage> createState() =>
      _MedicineListWithFilterPageState();
}

class _MedicineListWithFilterPageState
    extends State<MedicineListWithFilterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Medicine> _allMeds = [];
  List<String> _allCompanies = [];
  List<String> _allCategories = [];
  List<String> _filteredCompanies = [];
  List<String> _filteredCategories = [];

  String? _selectedCompany;
  String? _selectedCategory;
  String _searchText = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snap = await _firestore.collection('medicines').get();
      _allMeds = snap.docs.map((d) => Medicine.fromMap(d.data())).toList();

      _allCompanies = _allMeds.map((m) => m.company).toSet().toList()..sort();
      _allCategories = _allMeds.map((m) => m.category).toSet().toList()..sort();

      _filteredCompanies = List.from(_allCompanies);
      _filteredCategories = List.from(_allCategories);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load medicines: $e';
        _isLoading = false;
      });
    }
  }

  void _updateFilters() {
    setState(() {
      if (_selectedCompany != null) {
        _filteredCategories = _allMeds
            .where((m) => m.company == _selectedCompany)
            .map((m) => m.category)
            .toSet()
            .toList()
          ..sort();
        if (!_filteredCategories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
      } else {
        _filteredCategories = List.from(_allCategories);
      }

      if (_selectedCategory != null) {
        _filteredCompanies = _allMeds
            .where((m) => m.category == _selectedCategory)
            .map((m) => m.company)
            .toSet()
            .toList()
          ..sort();
        if (!_filteredCompanies.contains(_selectedCompany)) {
          _selectedCompany = null;
        }
      } else {
        _filteredCompanies = List.from(_allCompanies);
      }
    });
  }

  List<Medicine> get _filteredMeds {
    return _allMeds.where((m) {
      final matchesCompany =
          _selectedCompany == null || m.company == _selectedCompany;
      final matchesCategory =
          _selectedCategory == null || m.category == _selectedCategory;
      final matchesSearch = _searchText.isEmpty ||
          m.name.toLowerCase().contains(_searchText.toLowerCase());
      return matchesCompany && matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text(
          'Ayurvedic Medicine Inventory',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50), // Ayurvedic green
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: _loadMedicines,
            tooltip: 'Refresh',
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMedicinePage(
                    initialCategory: _selectedCategory,
                    initialData: _selectedCompany != null
                        ? {'company': _selectedCompany}
                        : null,
                  ),
                ),
              );
            },
            tooltip: 'Add Medicine',
            color: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
              )
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search Ayurvedic Medicines...',
                              prefixIcon:
                                  Icon(Icons.search, color: Color(0xFF4CAF50)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchText = value;
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedCompany,
                                decoration: InputDecoration(
                                  labelText: 'Filter by Company',
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF4CAF50)),
                                  prefixIcon: const Icon(Icons.business,
                                      color: Color(0xFF4CAF50)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF4CAF50)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF4CAF50)),
                                  ),
                                  //filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Companies',
                                        style: TextStyle(color: Colors.grey)),
                                  ),
                                  ..._filteredCompanies.map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c,
                                          style: const TextStyle(
                                              color: Colors.black87)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCompany = value;
                                    _updateFilters();
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Filter by Category',
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF4CAF50)),
                                  prefixIcon: const Icon(Icons.category,
                                      color: Color(0xFF4CAF50)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF4CAF50)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF4CAF50)),
                                  ),
                                  //filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Categories',
                                        style: TextStyle(color: Colors.grey)),
                                  ),
                                  ..._filteredCategories.map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c,
                                          style: const TextStyle(
                                              color: Colors.black87)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                    _updateFilters();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _filteredMeds.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.medication,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No medicines found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (_selectedCompany != null ||
                                        _selectedCategory != null ||
                                        _searchText.isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedCompany = null;
                                            _selectedCategory = null;
                                            _searchText = '';
                                          });
                                        },
                                        child: const Text(
                                          'Clear filters',
                                          style: TextStyle(
                                            color: Color(0xFF4CAF50),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: _filteredMeds.length,
                                itemBuilder: (context, idx) {
                                  final m = _filteredMeds[idx];
                                  return Card(
                                    elevation: 2,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MedicineDetailPage(
                                              medicineId: m.id,
                                              medicineData: m.toMap(),
                                              category: m.category,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.medication,
                                                color: const Color(0xFF4CAF50),
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    m.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '₹${m.price.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.green[700],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Text(
                                                        'Qty: ${m.quantity}',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[600]),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${m.company} • ${m.category}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
