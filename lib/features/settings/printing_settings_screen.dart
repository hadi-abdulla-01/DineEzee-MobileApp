import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/branch.dart';
import '../../models/invoice_print_settings.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/theme_toggle.dart';

class PrintingSettingsScreen extends StatefulWidget {
  const PrintingSettingsScreen({super.key});

  @override
  State<PrintingSettingsScreen> createState() => _PrintingSettingsScreenState();
}

class _PrintingSettingsScreenState extends State<PrintingSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  Branch? _branch;
  PrintSettings _printSettings = PrintSettings.defaultSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _invoiceCustomWidthController = TextEditingController();
  final TextEditingController _kitchenCustomWidthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _invoiceCustomWidthController.dispose();
    _kitchenCustomWidthController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final branchId = authProvider.user?.branchId;

      if (branchId != null) {
        final branch = await _firestoreService.getBranchById(branchId);
        setState(() {
          _branch = branch;
          _printSettings = branch?.printSettings ?? PrintSettings.defaultSettings();
          _invoiceCustomWidthController.text = (_printSettings.invoiceCustomWidth ?? 80).toString();
          _kitchenCustomWidthController.text = (_printSettings.kitchenTicketCustomWidth ?? 80).toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading print settings: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (_branch == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedSettings = PrintSettings(
        invoicePrintSize: _printSettings.invoicePrintSize,
        invoiceCustomWidth: int.tryParse(_invoiceCustomWidthController.text) ?? 80,
        kitchenTicketPrintSize: _printSettings.kitchenTicketPrintSize,
        kitchenTicketCustomWidth: int.tryParse(_kitchenCustomWidthController.text) ?? 80,
      );

      await _firestoreService.updatePrintSettings(_branch!.id, updatedSettings.toMap());

      setState(() {
        _printSettings = updatedSettings;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Print settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Printing Settings',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Configure the paper size for your printed invoices and kitchen order tickets',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Invoice Print Size Section
                  _buildPrintSizeSection(
                    title: 'Invoice Print Size',
                    currentSize: _printSettings.invoicePrintSize,
                    customWidthController: _invoiceCustomWidthController,
                    onSizeChanged: (size) {
                      setState(() {
                        _printSettings = _printSettings.copyWith(invoicePrintSize: size);
                      });
                    },
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),
                  Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 24),

                  // Kitchen Ticket Print Size Section
                  _buildPrintSizeSection(
                    title: 'Kitchen Ticket Print Size',
                    currentSize: _printSettings.kitchenTicketPrintSize,
                    customWidthController: _kitchenCustomWidthController,
                    onSizeChanged: (size) {
                      setState(() {
                        _printSettings = _printSettings.copyWith(kitchenTicketPrintSize: size);
                      });
                    },
                    isDark: isDark,
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Print Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrintSizeSection({
    required String title,
    required PrintSize currentSize,
    required TextEditingController customWidthController,
    required Function(PrintSize) onSizeChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // A4 Option
        _buildRadioOption(
          value: PrintSize.a4,
          groupValue: currentSize,
          label: PrintSize.a4.displayName,
          onChanged: onSizeChanged,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Thermal 80mm Option
        _buildRadioOption(
          value: PrintSize.thermal80mm,
          groupValue: currentSize,
          label: PrintSize.thermal80mm.displayName,
          onChanged: onSizeChanged,
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Custom Option
        _buildRadioOption(
          value: PrintSize.custom,
          groupValue: currentSize,
          label: PrintSize.custom.displayName,
          onChanged: onSizeChanged,
          isDark: isDark,
        ),

        // Custom Width Input
        if (currentSize == PrintSize.custom) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Width (mm)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customWidthController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '80',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadioOption({
    required PrintSize value,
    required PrintSize groupValue,
    required String label,
    required Function(PrintSize) onChanged,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value == groupValue
              ? AppColors.primaryRed.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value == groupValue
                ? AppColors.primaryRed
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: value == groupValue ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<PrintSize>(
              value: value,
              groupValue: groupValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              activeColor: AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: value == groupValue ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Poppins',
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
