import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';
import '../../utils/snackbar_utils.dart';

class GeneralSettingsTab extends StatefulWidget {
  const GeneralSettingsTab({super.key});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _appNameController;
  late TextEditingController _appUrlController;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolAddressController;
  late TextEditingController _schoolPhoneController;
  late TextEditingController _schoolEmailController;
  late TextEditingController _adminEmailController;
  late TextEditingController _itemsPerPageController;
  String _selectedTimezone = 'Asia/Jakarta';
  String _selectedDateFormat = 'd/m/Y';
  bool _enableRegistration = true;
  bool _requireEmailVerification = false;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _appNameController = TextEditingController();
    _appUrlController = TextEditingController();
    _schoolNameController = TextEditingController();
    _schoolAddressController = TextEditingController();
    _schoolPhoneController = TextEditingController();
    _schoolEmailController = TextEditingController();
    _adminEmailController = TextEditingController();
    _itemsPerPageController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context).generalSettings;
    if (settings != null) {
      _appNameController.text = settings.appName;
      _appUrlController.text = settings.appUrl;
      _schoolNameController.text = settings.schoolName;
      _schoolAddressController.text = settings.schoolAddress;
      _schoolPhoneController.text = settings.schoolPhone;
      _schoolEmailController.text = settings.schoolEmail;
      _adminEmailController.text = settings.adminEmail;
      _itemsPerPageController.text = settings.itemsPerPage.toString();
      _selectedTimezone = settings.timezone;
      _selectedDateFormat = settings.dateFormat;
      _enableRegistration = settings.enableRegistration;
      _requireEmailVerification = settings.requireEmailVerification;
      _maintenanceMode = settings.maintenanceMode;
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    _adminEmailController.dispose();
    _itemsPerPageController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = GeneralSettings(
      appName: _appNameController.text,
      appUrl: _appUrlController.text,
      schoolName: _schoolNameController.text,
      schoolAddress: _schoolAddressController.text,
      schoolPhone: _schoolPhoneController.text,
      schoolEmail: _schoolEmailController.text,
      adminEmail: _adminEmailController.text,
      timezone: _selectedTimezone,
      dateFormat: _selectedDateFormat,
      timeFormat: 'H:i:s',
      itemsPerPage: int.tryParse(_itemsPerPageController.text) ?? 10,
      enableRegistration: _enableRegistration,
      requireEmailVerification: _requireEmailVerification,
      maintenanceMode: _maintenanceMode,
    );

    final success = await Provider.of<SettingsProvider>(context, listen: false)
        .updateGeneralSettings(settings);

    if (success && mounted) {
      showSuccessSnackbar(context, 'Pengaturan umum berhasil diperbarui');
    } else if (mounted) {
      showErrorSnackbar(context, 'Gagal memperbarui pengaturan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 32),
                _buildActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan Umum',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B4D8A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Konfigurasi dasar aplikasi dan informasi sekolah',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _appNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Aplikasi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apps),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nama aplikasi harus diisi' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _appUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Aplikasi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'URL aplikasi harus diisi' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _schoolNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Sekolah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _schoolPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Telepon Sekolah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _schoolEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Sekolah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _adminEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email Admin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _schoolAddressController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Alamat Sekolah',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTimezone,
                decoration: const InputDecoration(
                  labelText: 'Zona Waktu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: const [
                  DropdownMenuItem(value: 'Asia/Jakarta', child: Text('WIB (Jakarta)')),
                  DropdownMenuItem(value: 'Asia/Makassar', child: Text('WITA (Makassar)')),
                  DropdownMenuItem(value: 'Asia/Jayapura', child: Text('WIT (Jayapura)')),
                ],
                onChanged: (value) {
                  setState(() => _selectedTimezone = value!);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDateFormat,
                decoration: const InputDecoration(
                  labelText: 'Format Tanggal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: const [
                  DropdownMenuItem(value: 'd/m/Y', child: Text('31/12/2025')),
                  DropdownMenuItem(value: 'Y-m-d', child: Text('2025-12-31')),
                  DropdownMenuItem(value: 'm/d/Y', child: Text('12/31/2025')),
                ],
                onChanged: (value) {
                  setState(() => _selectedDateFormat = value!);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _itemsPerPageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Item per Halaman',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.list),
            helperText: 'Jumlah data yang ditampilkan per halaman (5-100)',
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Harus diisi';
            final intValue = int.tryParse(value!);
            if (intValue == null || intValue < 5 || intValue > 100) {
              return 'Harus antara 5-100';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Pengaturan Tambahan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Izinkan pendaftaran pengguna baru'),
          subtitle: const Text('Pengguna dapat mendaftar secara mandiri'),
          value: _enableRegistration,
          onChanged: (value) {
            setState(() => _enableRegistration = value);
          },
          activeColor: const Color(0xFF0B4D8A),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Wajib verifikasi email'),
          subtitle: const Text('Pengguna harus memverifikasi email sebelum login'),
          value: _requireEmailVerification,
          onChanged: (value) {
            setState(() => _requireEmailVerification = value);
          },
          activeColor: const Color(0xFF0B4D8A),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Mode pemeliharaan'),
          subtitle: const Text('Hanya admin yang dapat mengakses sistem'),
          value: _maintenanceMode,
          onChanged: (value) {
            setState(() => _maintenanceMode = value);
          },
          activeColor: const Color(0xFF0B4D8A),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            _initControllers();
            didChangeDependencies();
          },
          child: const Text('Reset'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B4D8A),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}