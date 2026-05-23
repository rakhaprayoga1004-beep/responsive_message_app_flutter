import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';
import '../../utils/snackbar_utils.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final _mailerSendFormKey = GlobalKey<FormState>();
  final _fonnteFormKey = GlobalKey<FormState>();

  // MailerSend controllers
  late TextEditingController _mailerSendApiTokenController;
  late TextEditingController _mailerSendDomainController;
  late TextEditingController _mailerSendDomainIdController;
  late TextEditingController _mailerSendFromEmailController;
  late TextEditingController _mailerSendFromNameController;
  bool _mailerSendIsActive = true;
  bool _obscureMailerSendToken = false;

  // Fonnte controllers
  late TextEditingController _fonnteApiTokenController;
  late TextEditingController _fonnteAccountTokenController;
  late TextEditingController _fonnteDeviceIdController;
  late TextEditingController _fonnteApiUrlController;
  late TextEditingController _fonnteCountryCodeController;
  bool _fonnteIsActive = true;
  bool _obscureFonnteApiToken = false;
  bool _obscureFonnteAccountToken = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _mailerSendApiTokenController = TextEditingController();
    _mailerSendDomainController = TextEditingController();
    _mailerSendDomainIdController = TextEditingController();
    _mailerSendFromEmailController = TextEditingController();
    _mailerSendFromNameController = TextEditingController();

    _fonnteApiTokenController = TextEditingController();
    _fonnteAccountTokenController = TextEditingController();
    _fonnteDeviceIdController = TextEditingController();
    _fonnteApiUrlController = TextEditingController();
    _fonnteCountryCodeController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mailerSend = Provider.of<SettingsProvider>(context).mailerSendConfig;
    final fonnte = Provider.of<SettingsProvider>(context).fonnteConfig;
    
    if (mailerSend != null) {
      _mailerSendApiTokenController.text = mailerSend.apiToken;
      _mailerSendDomainController.text = mailerSend.domain;
      _mailerSendDomainIdController.text = mailerSend.domainId;
      _mailerSendFromEmailController.text = mailerSend.fromEmail;
      _mailerSendFromNameController.text = mailerSend.fromName;
      _mailerSendIsActive = mailerSend.isActive;
    }
    
    if (fonnte != null) {
      _fonnteApiTokenController.text = fonnte.apiToken;
      _fonnteAccountTokenController.text = fonnte.accountToken;
      _fonnteDeviceIdController.text = fonnte.deviceId;
      _fonnteApiUrlController.text = fonnte.apiUrl;
      _fonnteCountryCodeController.text = fonnte.countryCode;
      _fonnteIsActive = fonnte.isActive;
    }
  }

  @override
  void dispose() {
    _mailerSendApiTokenController.dispose();
    _mailerSendDomainController.dispose();
    _mailerSendDomainIdController.dispose();
    _mailerSendFromEmailController.dispose();
    _mailerSendFromNameController.dispose();
    _fonnteApiTokenController.dispose();
    _fonnteAccountTokenController.dispose();
    _fonnteDeviceIdController.dispose();
    _fonnteApiUrlController.dispose();
    _fonnteCountryCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveMailerSendConfig() async {
    if (!_mailerSendFormKey.currentState!.validate()) return;

    final config = MailerSendConfig(
      apiToken: _mailerSendApiTokenController.text,
      domain: _mailerSendDomainController.text,
      domainId: _mailerSendDomainIdController.text,
      fromEmail: _mailerSendFromEmailController.text,
      fromName: _mailerSendFromNameController.text,
      smtpServer: 'smtp.mailersend.net',
      smtpUsername: '',
      smtpPassword: '',
      smtpPort: 587,
      smtpEncryption: 'tls',
      testDomain: _mailerSendDomainController.text,
      isActive: _mailerSendIsActive,
    );

    final success = await Provider.of<SettingsProvider>(context, listen: false)
        .updateMailerSendConfig(config);

    if (success && mounted) {
      showSuccessSnackbar(context, 'Konfigurasi MailerSend berhasil disimpan');
    }
  }

  Future<void> _saveFonnteConfig() async {
    if (!_fonnteFormKey.currentState!.validate()) return;

    final config = FonnteConfig(
      apiToken: _fonnteApiTokenController.text,
      accountToken: _fonnteAccountTokenController.text,
      deviceId: _fonnteDeviceIdController.text,
      apiUrl: _fonnteApiUrlController.text,
      email: '',
      password: '',
      countryCode: _fonnteCountryCodeController.text,
      isActive: _fonnteIsActive,
    );

    final success = await Provider.of<SettingsProvider>(context, listen: false)
        .updateFonnteConfig(config);

    if (success && mounted) {
      showSuccessSnackbar(context, 'Konfigurasi Fonnte berhasil disimpan');
    }
  }

  Future<void> _testMailerSendConnection() async {
    final config = MailerSendConfig(
      apiToken: _mailerSendApiTokenController.text,
      domain: _mailerSendDomainController.text,
      domainId: _mailerSendDomainIdController.text,
      fromEmail: _mailerSendFromEmailController.text,
      fromName: _mailerSendFromNameController.text,
      smtpServer: 'smtp.mailersend.net',
      smtpUsername: '',
      smtpPassword: '',
      smtpPort: 587,
      smtpEncryption: 'tls',
      testDomain: _mailerSendDomainController.text,
      isActive: true,
    );

    final result = await Provider.of<SettingsProvider>(context, listen: false)
        .testMailerSendConnection(config);

    if (result != null && mounted) {
      if (result.success) {
        showSuccessSnackbar(context, result.message);
      } else {
        showErrorSnackbar(context, result.message);
      }
    }
  }

  Future<void> _sendTestEmail() async {
    final email = await _showEmailInputDialog();
    if (email != null && email.isNotEmpty) {
      final config = MailerSendConfig(
        apiToken: _mailerSendApiTokenController.text,
        domain: _mailerSendDomainController.text,
        domainId: _mailerSendDomainIdController.text,
        fromEmail: _mailerSendFromEmailController.text,
        fromName: _mailerSendFromNameController.text,
        smtpServer: 'smtp.mailersend.net',
        smtpUsername: '',
        smtpPassword: '',
        smtpPort: 587,
        smtpEncryption: 'tls',
        testDomain: _mailerSendDomainController.text,
        isActive: true,
      );

      final result = await Provider.of<SettingsProvider>(context, listen: false)
          .sendTestEmail(email, config);

      if (result != null && mounted) {
        if (result.success) {
          showSuccessSnackbar(context, 'Email test berhasil dikirim ke $email');
        } else {
          showErrorSnackbar(context, 'Gagal mengirim email: ${result.error}');
        }
      }
    }
  }

  Future<void> _testFonnteConnection() async {
    final config = FonnteConfig(
      apiToken: _fonnteApiTokenController.text,
      accountToken: _fonnteAccountTokenController.text,
      deviceId: _fonnteDeviceIdController.text,
      apiUrl: _fonnteApiUrlController.text,
      email: '',
      password: '',
      countryCode: _fonnteCountryCodeController.text,
      isActive: true,
    );

    final result = await Provider.of<SettingsProvider>(context, listen: false)
        .testFonnteConnection(config);

    if (result != null && mounted) {
      if (result.success) {
        showSuccessSnackbar(context, result.message);
      } else {
        showErrorSnackbar(context, result.message);
      }
    }
  }

  Future<void> _sendTestWhatsApp() async {
    final phone = await _showPhoneInputDialog();
    if (phone != null && phone.isNotEmpty) {
      final config = FonnteConfig(
        apiToken: _fonnteApiTokenController.text,
        accountToken: _fonnteAccountTokenController.text,
        deviceId: _fonnteDeviceIdController.text,
        apiUrl: _fonnteApiUrlController.text,
        email: '',
        password: '',
        countryCode: _fonnteCountryCodeController.text,
        isActive: true,
      );

      final result = await Provider.of<SettingsProvider>(context, listen: false)
          .sendTestWhatsApp(phone, config);

      if (result != null && mounted) {
        if (result.success) {
          showSuccessSnackbar(context, 'WhatsApp test berhasil dikirim ke $phone');
        } else {
          showErrorSnackbar(context, 'Gagal mengirim WhatsApp: ${result.error}');
        }
      }
    }
  }

  void _viewLog(String logType) {
    // Navigate to log viewer - implement sesuai kebutuhan
    showInfoSnackbar(context, 'Fitur Log Viewer akan segera hadir');
  }

  Future<String?> _showEmailInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Test Email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email Tujuan',
            hintText: 'contoh@email.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPhoneInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Test WhatsApp'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nomor WhatsApp',
            hintText: '081234567890',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label harus diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label harus diisi';
            }
            return null;
          },
        ),
      ],
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konfigurasi Notifikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B4D8A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Atur layanan notifikasi email dan WhatsApp',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildStatusBanner(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMailerSendCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildFonnteCard()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Layanan Notifikasi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'MailerSend: ${_mailerSendFromEmailController.text}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.message, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Fonnte Device: ${_fonnteDeviceIdController.text}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _viewLog('email'),
                icon: const Icon(Icons.article, size: 16),
                label: const Text('Log Email'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _viewLog('whatsapp'),
                icon: const Icon(Icons.article, size: 16),
                label: const Text('Log WhatsApp'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMailerSendCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _mailerSendFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.email, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MailerSend Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Email Notification Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _mailerSendIsActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _mailerSendIsActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: _mailerSendIsActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _mailerSendApiTokenController,
                label: 'API Token',
                obscureText: _obscureMailerSendToken,
                onToggle: () {
                  setState(() {
                    _obscureMailerSendToken = !_obscureMailerSendToken;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _mailerSendDomainController,
                label: 'Domain',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _mailerSendDomainIdController,
                label: 'Domain ID',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _mailerSendFromEmailController,
                label: 'From Email',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _mailerSendFromNameController,
                label: 'From Name',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktifkan MailerSend'),
                value: _mailerSendIsActive,
                onChanged: (value) {
                  setState(() => _mailerSendIsActive = value);
                },
                activeColor: const Color(0xFF0B4D8A),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testMailerSendConnection,
                      icon: const Icon(Icons.science, size: 18),
                      label: const Text('Test Koneksi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendTestEmail,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Kirim Test Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4D8A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMailerSendConfig,
                  child: const Text('Simpan Konfigurasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFonnteCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _fonnteFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.message, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fonnte Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'WhatsApp Notification Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _fonnteIsActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _fonnteIsActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: _fonnteIsActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _fonnteApiTokenController,
                label: 'API Token',
                obscureText: _obscureFonnteApiToken,
                onToggle: () {
                  setState(() {
                    _obscureFonnteApiToken = !_obscureFonnteApiToken;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: _fonnteAccountTokenController,
                label: 'Account Token',
                obscureText: _obscureFonnteAccountToken,
                onToggle: () {
                  setState(() {
                    _obscureFonnteAccountToken = !_obscureFonnteAccountToken;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fonnteDeviceIdController,
                label: 'Device ID / Nomor',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fonnteApiUrlController,
                label: 'API URL',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fonnteCountryCodeController,
                label: 'Country Code',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktifkan Fonnte'),
                value: _fonnteIsActive,
                onChanged: (value) {
                  setState(() => _fonnteIsActive = value);
                },
                activeColor: const Color(0xFF0B4D8A),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _testFonnteConnection,
                      icon: const Icon(Icons.science, size: 18),
                      label: const Text('Test Koneksi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendTestWhatsApp,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Kirim Test WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveFonnteConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Simpan Konfigurasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}