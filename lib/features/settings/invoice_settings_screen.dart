import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/branch.dart';
import '../../models/invoice_print_settings.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/theme_toggle.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  Branch? _branch;
  InvoiceSettings _invoiceSettings = InvoiceSettings.defaultSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for unified mode
  final TextEditingController _unifiedPrefixController = TextEditingController();
  final TextEditingController _unifiedNextNumberController = TextEditingController();

  // Controllers for separate mode
  final TextEditingController _dineInPrefixController = TextEditingController();
  final TextEditingController _dineInNextNumberController = TextEditingController();
  final TextEditingController _onlinePrefixController = TextEditingController();
  final TextEditingController _onlineNextNumberController = TextEditingController();
  final TextEditingController _takeAwayPrefixController = TextEditingController();
  final TextEditingController _takeAwayNextNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _unifiedPrefixController.dispose();
    _unifiedNextNumberController.dispose();
    _dineInPrefixController.dispose();
    _dineInNextNumberController.dispose();
    _onlinePrefixController.dispose();
    _onlineNextNumberController.dispose();
    _takeAwayPrefixController.dispose();
    _takeAwayNextNumberController.dispose();
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
          _invoiceSettings = branch?.invoiceSettings ?? InvoiceSettings.defaultSettings();
          _updateControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading invoice settings: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  void _updateControllers() {
    _unifiedPrefixController.text = _invoiceSettings.unified.prefix;
    _unifiedNextNumberController.text = _invoiceSettings.unified.nextNumber.toString();
    
    _dineInPrefixController.text = _invoiceSettings.dineIn.prefix;
    _dineInNextNumberController.text = _invoiceSettings.dineIn.nextNumber.toString();
    
    _onlinePrefixController.text = _invoiceSettings.online.prefix;
    _onlineNextNumberController.text = _invoiceSettings.online.nextNumber.toString();
    
    _takeAwayPrefixController.text = _invoiceSettings.takeAway.prefix;
    _takeAwayNextNumberController.text = _invoiceSettings.takeAway.nextNumber.toString();
  }

  Future<void> _handleSave() async {
    if (_branch == null) return;

    setState(() => _isSaving = true);

    try {
      // Update settings from controllers
      final updatedSettings = InvoiceSettings(
        useUnifiedNumbering: _invoiceSettings.useUnifiedNumbering,
        unified: InvoiceNumbering(
          prefix: _unifiedPrefixController.text,
          nextNumber: int.tryParse(_unifiedNextNumberController.text) ?? 1,
        ),
        dineIn: InvoiceNumbering(
          prefix: _dineInPrefixController.text,
          nextNumber: int.tryParse(_dineInNextNumberController.text) ?? 1,
        ),
        online: InvoiceNumbering(
          prefix: _onlinePrefixController.text,
          nextNumber: int.tryParse(_onlineNextNumberController.text) ?? 1,
        ),
        takeAway: InvoiceNumbering(
          prefix: _takeAwayPrefixController.text,
          nextNumber: int.tryParse(_takeAwayNextNumberController.text) ?? 1,
        ),
      );

      await _firestoreService.updateInvoiceSettings(_branch!.id, updatedSettings.toMap());

      setState(() {
        _invoiceSettings = updatedSettings;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Invoice settings saved successfully'),
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
          'Invoice & Numbering',
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
                    'Configure prefixes and starting numbers for your invoices',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Unified Numbering Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Unified Invoice Numbering',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use one numbering sequence for all order types',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _invoiceSettings.useUnifiedNumbering,
                          onChanged: (value) {
                            setState(() {
                              _invoiceSettings = _invoiceSettings.copyWith(
                                useUnifiedNumbering: value,
                              );
                            });
                          },
                          activeColor: AppColors.primaryRed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Unified Mode
                  if (_invoiceSettings.useUnifiedNumbering) ...[
                    Text(
                      'Unified Numbering',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _unifiedPrefixController,
                            label: 'Prefix',
                            hint: 'e.g., INV-',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _unifiedNextNumberController,
                            label: 'Next Number',
                            hint: '1',
                            isDark: isDark,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Separate Mode
                  if (!_invoiceSettings.useUnifiedNumbering) ...[
                    Text(
                      'Separate Numbering per Order Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dine-in
                    _buildOrderTypeSection(
                      title: 'Dine-in Orders',
                      prefixController: _dineInPrefixController,
                      numberController: _dineInNextNumberController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Online
                    _buildOrderTypeSection(
                      title: 'Online Orders',
                      prefixController: _onlinePrefixController,
                      numberController: _onlineNextNumberController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Take-away
                    _buildOrderTypeSection(
                      title: 'Take-away Orders',
                      prefixController: _takeAwayPrefixController,
                      numberController: _takeAwayNextNumberController,
                      isDark: isDark,
                    ),
                  ],

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
                              'Save Invoice Settings',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
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
    );
  }

  Widget _buildOrderTypeSection({
    required String title,
    required TextEditingController prefixController,
    required TextEditingController numberController,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: prefixController,
                  label: 'Prefix',
                  hint: 'e.g., DI-',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: numberController,
                  label: 'Next Number',
                  hint: '1',
                  isDark: isDark,
                  isNumber: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
