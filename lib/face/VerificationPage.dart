import '../face/RegistrationPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _checking = false;
  bool _verified = false;
  bool _alreadyRegistered = false;
  bool _continuing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;
    setState(() {
      _checking = true;
      _verified = false;
      _alreadyRegistered = false;
    });
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final name = userData?['name'] as String? ?? '';
        _nameController.text = name;
        final hasEmbedding = userData?['embedding'] != null;
        setState(() {
          _verified = true;
          _alreadyRegistered = hasEmbedding;
        });
      } else {
        setState(() {
          _verified = false;
          _alreadyRegistered = false;
        });
      }
    } catch (_) {
      setState(() {
        _verified = false;
        _alreadyRegistered = false;
      });
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  void _onEmailChanged(String value) {
    setState(() {
      _verified = false;
      _alreadyRegistered = false;
      _checking = false;
      _nameController.clear();
    });
  }

  Future<void> _continue() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || _checking || _continuing) return;
    
    setState(() => _continuing = true);
    final name = _nameController.text.trim();
    
    // Create or update user document in users collection
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .set({
            'name': name.isNotEmpty ? name : email,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) setState(() => _continuing = false);
      return;
    }
    
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistrationPage(initialEmail: email)),
    );
    if (mounted) setState(() => _continuing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorState = _emailController.text.isEmpty
        ? Colors.grey
        : (_checking ? Colors.grey : (_verified ? Colors.green : Colors.red));
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: colorState),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorState),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _checking ? Colors.blue : colorState,
                    width: 2,
                  ),
                ),
              ),
              onChanged: _onEmailChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(),
                hintText: _verified 
                    ? 'Edit name if needed' 
                    : 'Enter name for new record',
              ),
              enabled: true, // Always enabled
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_emailController.text.isEmpty)
                    const SizedBox.shrink()
                  else if (_checking) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Verifying...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (_verified) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _alreadyRegistered
                          ? 'Email already registered'
                          : 'Found in students',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'New user - can add record',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                Row(
                  spacing: 2,
                  children: [
                    Expanded(
                      // This makes the first button take equal space
                      child: ElevatedButton(
                        onPressed:
                            (_checking ||
                                _emailController.text.isEmpty ||
                                _verified)
                            ? null
                            : _verify,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          backgroundColor: Colors.blue,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          shadowColor: Theme.of(context).focusColor,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _checking ? 'Verifying...' : 'Verify',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!_checking)
                              const Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 20,
                              ),
                            if (_checking)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      // This makes the second button take equal space
                      child: ElevatedButton(
                        onPressed: (_emailController.text.isEmpty || 
                                   _checking || 
                                   _continuing)
                            ? null
                            : _continue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          backgroundColor: Colors.green,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          shadowColor: Theme.of(context).focusColor,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _continuing
                                  ? 'Continuing...'
                                  : (_verified 
                                      ? (_alreadyRegistered ? 'Edit' : 'Continue')
                                      : 'Add New'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!_continuing)
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            if (_continuing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
