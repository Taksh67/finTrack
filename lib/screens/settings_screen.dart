import 'package:flutter/material.dart';
import 'budget_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Budget Setup'),
            subtitle: const Text('Manage monthly limits for categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetSetupScreen()));
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
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
