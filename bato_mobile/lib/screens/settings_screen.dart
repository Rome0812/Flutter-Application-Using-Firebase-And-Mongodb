import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// ignore: camel_case_types
class settings_screen extends StatefulWidget {
  const settings_screen({super.key});

  @override
  State<settings_screen> createState() => _settings_screenState();
}

class _settings_screenState extends State<settings_screen> {
 

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeProvider>();

   
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [

            const SizedBox(height: 16),

            // Theme Settings
            Card(
              child: ListTile(
                leading: Icon(
                  themeModel.isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text("Dark Mode"),
                trailing: Switch(
                  value: themeModel.isDark,
                  onChanged: (_) => themeModel.toggleTheme(),
                ),
              ),
            ),
            const SizedBox(height: 16),

           
                  
                
              
            
          ],
        ),
      ),
    );
  }
}