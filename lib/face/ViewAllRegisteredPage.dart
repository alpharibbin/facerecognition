import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../services/detection_service.dart';
import '../models/face_embedding.dart';
import 'VerificationPage.dart';
import 'RegistrationPage.dart';

class ViewAllRegisteredPage extends StatefulWidget {
  const ViewAllRegisteredPage({Key? key}) : super(key: key);

  @override
  State<ViewAllRegisteredPage> createState() => _ViewAllRegisteredPageState();
}

class _ViewAllRegisteredPageState extends State<ViewAllRegisteredPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _registeredFaces = [];
  final _detector = DetectionService();
  // Search state
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadRegisteredFaces();
    _syncOffline();
  }

  Future<void> _syncOffline() async {
    try {
      await _detector.init();
      await _detector.syncFromFirestore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Embeddings synced for offline use'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegisteredFaces() async {
    setState(() => _isLoading = true);
    try {
      // Get all users with embeddings from users collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('embedding', isNull: false)
          .get();

      _registeredFaces = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': doc.id,
          'imageUrl': data['imageUrl'] ?? '',
          'registeredAt': data['face_updated_at'] ?? '',
        };
      }).toList();

      _applyFilter();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading registered faces: $e'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filtered = _registeredFaces;
    } else {
      final q = _searchQuery.toLowerCase();
      _filtered = _registeredFaces.where((item) {
        final email = (item['email'] ?? '').toString().toLowerCase();
        final name = (item['name'] ?? '').toString().toLowerCase();
        return email.contains(q) || name.contains(q);
      }).toList();
    }
  }

  Future<void> _registerAgain(String email) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistrationPage(initialEmail: email)),
    ).then((_) => _loadRegisteredFaces());
  }

  Future<void> _deleteFace(String email, String name) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Face'),
        content: Text(
          'Are you sure you want to delete the face registration for ${name.isNotEmpty ? name : email}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .delete();

      // Delete from Hive (local storage)
      final box = await Hive.openBox<FaceEmbedding>('face_embeddings_box');
      final key = name.isNotEmpty ? name : email;
      await box.delete(key);

      // Reload the list
      await _loadRegisteredFaces();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face registration deleted successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting face: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    }
  }

  Future<void> _showStudentDetails(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();
      Map<String, dynamic>? data = doc.exists ? doc.data() : null;
      if (!mounted) return;
      final title = data == null ? 'No details found' : 'User Details';
      final message = data == null
          ? 'No details found for $email'
          : [
              'Email: $email', // email is the doc id
              if (data['name'] != null) 'Name: ${data['name']}',
            ].join('\n');
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load details: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _applyFilter();
                  });
                },
              )
            : const Text('Registered Faces'),
        actions: [
          if(!_isSearching)...[
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _syncOffline,
              tooltip: 'Sync for offline',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadRegisteredFaces,
              tooltip: 'Refresh list',
            ),
          ],
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                  _applyFilter();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Registered faces list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.face_retouching_natural,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No registered faces found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Use the + button to add new registrations',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final face = _filtered[index];
                      final email = (face['email'] ?? '').toString();
                      final name = (face['name'] ?? '').toString();
                      return InkWell(
                        onDoubleTap: () async {
                          // On double tap, show a sheet with re-register option
                          final action = await showModalBottomSheet<String>(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (ctx) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.info_outline),
                                      title: const Text('View Details'),
                                      onTap: () =>
                                          Navigator.pop(ctx, 'details'),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.person_add_alt),
                                      title: const Text('Register Again'),
                                      onTap: () =>
                                          Navigator.pop(ctx, 'register'),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      onTap: () =>
                                          Navigator.pop(ctx, 'delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                          if (!mounted) return;
                          if (action == 'details') {
                            await _showStudentDetails(email);
                          } else if (action == 'register') {
                            await _registerAgain(email);
                          } else if (action == 'delete') {
                            await _deleteFace(email, name);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.face,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isNotEmpty ? name : email,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: () => _registerAgain(email),
                                icon: const Icon(Icons.replay, size: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigoAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerificationPage()),
          ).then((_) => _loadRegisteredFaces());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
