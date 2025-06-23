import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hosp_test/payments/consultation_pay.dart';
import 'package:hosp_test/stores/medicine.dart';
import 'package:hosp_test/utils/config.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class DoctorCallListener extends StatefulWidget {
  final Widget child;

  const DoctorCallListener({super.key, required this.child});

  @override
  State<DoctorCallListener> createState() => _DoctorCallListenerState();
}

class _DoctorCallListenerState extends State<DoctorCallListener> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _callSubscription;
  StreamSubscription<DocumentSnapshot>? _activeCallSubscription;
  bool _isInCall = false;
  String? _currentCallId;
  Timer? _callStatusTimer;
  List<String> _filteredCompanies = [];
  List<String> _filteredCategories = [];

  // Medicine related variables
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _allMeds = [];
  List<Medicine> _filteredMeds = [];
  List<String> _allCompanies = [];
  List<String> _allCategories = [];
  String? _selectedCompany;
  String? _selectedCategory;
  String _searchText = '';
  bool _isLoadingMeds = false;
  String? _medicineError;

  @override
  void initState() {
    super.initState();
    _listenForNewCalls();
    _loadMedicines(); // Load medicines automatically on init
  }

  int get totalAmount {
    return _filteredMeds.fold<int>(
      0,
      (sum, item) => sum + ((item.price * (item.selectedCount ?? 0)).round()),
    );
  }

  Future<void> _loadMedicines() async {
    if (_allMeds.isNotEmpty) return; // Skip if already loaded

    setState(() {
      _isLoadingMeds = true;
      _medicineError = null;
    });

    try {
      final snap = await _firestore.collection('medicines').get();
      _allMeds = snap.docs.map((d) => Medicine.fromMap(d.data())).toList();

      // Extract unique companies and categories
      _allCompanies = _allMeds.map((m) => m.company).toSet().toList()..sort();
      _allCategories = _allMeds.map((m) => m.category).toSet().toList()..sort();
      _filteredCompanies = List.from(_allCompanies);
      _filteredCategories = List.from(_allCategories);
      // Initialize with all medicines
      _filteredMeds = List.from(_allMeds);

      setState(() {});
    } catch (e) {
      setState(() {
        _medicineError = 'Failed to load medicines: $e';
      });
    } finally {
      setState(() => _isLoadingMeds = false);
    }
  }

  void _updateFilters() {
    setState(() {
      // Update filtered categories based on selected company
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

      // Update filtered companies based on selected category
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

      // Final medicine filtering logic
      _filteredMeds = _allMeds.where((m) {
        final matchesCompany =
            _selectedCompany == null || m.company == _selectedCompany;
        final matchesCategory =
            _selectedCategory == null || m.category == _selectedCategory;
        final matchesSearch = _searchText.isEmpty ||
            m.name.toLowerCase().contains(_searchText.toLowerCase());
        return matchesCompany && matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _showMedicineSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            body: Padding(
              padding: MediaQuery.of(context)
                  .viewInsets
                  .add(const EdgeInsets.all(16.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Doctor's Prescription",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Search and Filter Controls
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search medicines...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _searchText = _searchController.text;
                          _updateFilters();
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      _searchText = value;
                      _updateFilters();
                    },
                    onChanged: (value) {
                      _searchText = value;
                      _updateFilters();
                    },
                  ),
                  const SizedBox(height: 10),

                  // Filter Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCompany,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Companies'),
                            ),
                            ..._filteredCompanies.map((company) {
                              return DropdownMenuItem<String>(
                                value: company,
                                child: Text(company),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCompany = value;
                              _updateFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCategory,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ..._filteredCategories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _updateFilters();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Reset Filters Button
                  ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchText = '';
                      _selectedCompany = null;
                      _selectedCategory = null;
                      _filteredCompanies = List.from(_allCompanies);
                      _filteredCategories = List.from(_allCategories);
                      _updateFilters();
                    },
                    child: const Text('Reset Filters'),
                  ),
                  const SizedBox(height: 10),

                  // Medicine List
                  if (_isLoadingMeds)
                    const Expanded(
                        child: Center(child: CircularProgressIndicator()))
                  else if (_medicineError != null)
                    Expanded(child: Center(child: Text(_medicineError!)))
                  else if (_filteredMeds.isEmpty)
                    const Expanded(
                        child: Center(child: Text('No medicines found')))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredMeds.length,
                        itemBuilder: (context, index) {
                          final medicine = _filteredMeds[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  medicine.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(medicine.name),
                              subtitle: Text(
                                '${medicine.company} • ${medicine.category} • ₹${medicine.price}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if ((medicine.selectedCount ?? 0) > 0) {
                                        medicine.selectedCount =
                                            (medicine.selectedCount ?? 0) - 1;
                                        _updateFilters();
                                      }
                                    },
                                  ),
                                  Text('${medicine.selectedCount ?? 0}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      medicine.selectedCount =
                                          (medicine.selectedCount ?? 0) + 1;
                                      _updateFilters();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Total Amount and Payment Button
                  Text(
                    "Total Amount: ₹$totalAmount",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final prescribedMeds = _allMeds
                          .where((m) => (m.selectedCount ?? 0) > 0)
                          .map((m) => {
                                'name': m.name,
                                'price': m.price,
                                'quantity': m.selectedCount,
                                'total': m.price * (m.selectedCount ?? 0),
                              })
                          .toList();

                      Navigator.pop(context);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => PaymentPage(
                      //       amount: totalAmount,
                      //       prescribedMedicines: prescribedMeds,
                      //     ),
                      //   ),
                      // );
                    },
                    child: const Text("Proceed to Payment"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Rest of your existing DoctorCallListener methods...
  void _listenForNewCalls() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _callSubscription = _firestore
        .collection('active_calls')
        .where('doctor_id', isEqualTo: userId)
        .where('status', isEqualTo: 'initiated')
        .snapshots()
        .listen((snapshot) {
      if (_isInCall || snapshot.docs.isEmpty) return;

      final callDoc = snapshot.docs.first;
      _isInCall = true;
      _currentCallId = callDoc.id;
      _joinCall(callDoc);
    });
  }

  Future<void> _updateDoctorStatus(String status) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('doctors').doc(userId).update({
        'working': status,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('Doctor status updated to: $status');
    } catch (e) {
      debugPrint('Error updating doctor status: $e');
    }
  }

  Future<void> _joinCall(DocumentSnapshot callDoc) async {
    final callID = callDoc.id;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _updateDoctorStatus('busy');

    _activeCallSubscription =
        callDoc.reference.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      final status = snapshot['status'];
      if (status == 'ended') {
        debugPrint('Call ended detected through Firestore listener');
        await _handleCallEnd(callDoc.reference);
      }
    });

    _callStatusTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      final doc = await callDoc.reference.get();
      if (!doc.exists || doc['status'] == 'ended') {
        await _handleCallEnd(callDoc.reference);
        timer.cancel();
      }
    });

    final doctorDoc = await _firestore.collection('doctors').doc(userId).get();
    final doctorName = doctorDoc.data()?['name'] ?? 'Doctor';

    await callDoc.reference.update({
      'status': 'ongoing',
      'started_at': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'chatButton',
            backgroundColor: Colors.black.withOpacity(0.5),
            mini: true,
            onPressed: () {
              _showMedicineSelection(context);
            },
            child: const Icon(Icons.notes, color: Colors.white),
          ),
          body: SafeArea(
            child: ZegoUIKitPrebuiltCall(
              appID: 834408230,
              appSign:
                  "d342fbf895ef4d7cae049320671b7489dca5be205ee94f5623e644744fa25df9",
              userID: userId,
              userName: doctorName,
              callID: callID,
              config: ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                ..topMenuBar.isVisible = true
                ..topMenuBar.buttons = [
                  ZegoCallMenuBarButtonName.showMemberListButton,
                  ZegoCallMenuBarButtonName.soundEffectButton,
                ],
            ),
          ),
        ),
      ),
    ).then((_) async {
      if (_isInCall) {
        await _handleCallEnd(callDoc.reference);
      }
      _isInCall = false;
      _currentCallId = null;
    });
  }

  Future<void> _handleCallEnd(DocumentReference callDocRef) async {
    _callStatusTimer?.cancel();
    _activeCallSubscription?.cancel();

    try {
      await callDocRef.update({
        'status': 'ended',
        'ended_at': FieldValue.serverTimestamp(),
      });
      debugPrint('Call marked as ended in Firestore');
      await _updateDoctorStatus('available');

      Future.delayed(const Duration(seconds: 5), () {
        callDocRef.delete().catchError((e) {
          debugPrint('Error deleting call document: $e');
        });
      });

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  @override
  void dispose() {
    if (_isInCall && _currentCallId != null) {
      _firestore.collection('active_calls').doc(_currentCallId!).update({
        'status': 'ended',
        'ended_at': FieldValue.serverTimestamp(),
      });
      _updateDoctorStatus('available');
    }

    _callSubscription?.cancel();
    _activeCallSubscription?.cancel();
    _callStatusTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
