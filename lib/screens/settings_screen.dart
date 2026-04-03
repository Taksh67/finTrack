import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'budget_setup_screen.dart';
import '../services/firebase_sync_service.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isSyncing = false;

  void _syncNow() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log in to sync data')));
      return;
    }
    setState(() => _isSyncing = true);
    await FirebaseSyncService().syncExpenses();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Complete!')));
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
             decoration: BoxDecoration(color: Theme.of(context).primaryColor),
             accountName: Text(user != null ? 'Logged In' : 'Guest Mode'),
             accountEmail: Text(user?.email ?? 'Syncing is disabled for guests'),
             currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.grey),
             ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Data & Sync', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Now'),
            subtitle: const Text('Manually pull and push expenses'),
            trailing: _isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            onTap: _syncNow,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Budget Setup'),
            subtitle: const Text('Manage monthly limits for categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetSetupScreen())),
          ),
          const Divider(),
          ListTile(
            leading: Icon(user != null ? Icons.logout : Icons.login, color: user != null ? Colors.red : Colors.blue),
            title: Text(user != null ? 'Log Out' : 'Login / Register', style: TextStyle(color: user != null ? Colors.red : Colors.blue)),
            onTap: _logout,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About FinTrack'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}
