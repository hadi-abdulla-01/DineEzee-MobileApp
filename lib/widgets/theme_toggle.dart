import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return IconButton(
      icon: Icon(
        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () => themeProvider.toggleTheme(),
      tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.light_mode,
          size: 20,
          color: !themeProvider.isDarkMode 
              ? Theme.of(context).colorScheme.primary 
              : Colors.grey,
        ),
        const SizedBox(width: 8),
        Switch(
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleTheme(),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.dark_mode,
          size: 20,
          color: themeProvider.isDarkMode 
              ? Theme.of(context).colorScheme.primary 
              : Colors.grey,
        ),
      ],
    );
  }
}
