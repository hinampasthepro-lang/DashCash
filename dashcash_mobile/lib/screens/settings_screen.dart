import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  bool _biometricsEnabled = true;
  String _accountTier = 'Basic Verified'; // Basic vs Fully Verified

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await _storage.read(key: 'biometrics_enabled');
    setState(() {
      _biometricsEnabled = bio != 'false';
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    setState(() {
      _biometricsEnabled = value;
    });
    await _storage.write(key: 'biometrics_enabled', value: value.toString());
  }

  void _showChangeMpinDialog() {
    final mpinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change 4-Digit MPIN'),
        content: TextField(
          controller: mpinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New 4-Digit MPIN',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (mpinController.text.length == 4) {
                await _storage.write(
                    key: 'user_mpin', value: mpinController.text);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('MPIN updated successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // Clear session storage / token
    await _storage.delete(key: 'jwt_token');

    if (!mounted) return;
    // Navigate back to Login screen and clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Settings'),
      ),
      body: ListView(
        children: [
          // Account Verification Tier Card
          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.blue),
            title: const Text('Account Status'),
            subtitle: Text('Current Tier: $_accountTier'),
            trailing: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ID submission flow coming soon!')),
                );
              },
              child: const Text('Upgrade ID'),
            ),
          ),
          const Divider(),

          // Security Settings Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Security & Privacy',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change MPIN'),
            subtitle: const Text('Update your 4-digit security PIN'),
            onTap: _showChangeMpinDialog,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Enable Face ID or Fingerprint login'),
            value: _biometricsEnabled,
            onChanged: _toggleBiometrics,
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Linked Devices'),
            subtitle: const Text('Manage trusted mobile sessions'),
            onTap: () {
              // TODO: Show active devices list
            },
          ),
          const Divider(),

          // Account Information & Links
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account & Connected Services',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account Information'),
            subtitle: const Text('Update email, mobile number, or address'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Linked Bank Accounts & Cards'),
            subtitle: const Text('Manage BPI, UnionBank, or cards'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('DashCash Card'),
            subtitle: const Text('Order, lock, or set physical card PIN'),
            onTap: () {},
          ),
          const Divider(),

          // Log Out Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
