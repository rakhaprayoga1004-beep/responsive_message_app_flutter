import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';
import '../../utils/snackbar_utils.dart';

class MessageTypesTab extends StatefulWidget {
  const MessageTypesTab({super.key});

  @override
  State<MessageTypesTab> createState() => _MessageTypesTabState();
}

class _MessageTypesTabState extends State<MessageTypesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      provider.loadMessageTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final messageTypes = provider.messageTypes;
        
        if (kDebugMode) {
          print('=== BUILDING TYPES TABLE ===');
          print('Total message types: ${messageTypes.length}');
          if (messageTypes.isNotEmpty) {
            print('First type: ${messageTypes[0].jenisPesan} (ID: ${messageTypes[0].id})');
          }
        }
        
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(provider),
                const SizedBox(height: 24),
                if (provider.isLoading)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading message types data...'),
                      ],
                    ),
                  )
                else if (messageTypes.isEmpty)
                  _buildEmptyState()
                else
                  _buildMessageTypesTable(messageTypes),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SettingsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jenis Pesan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B4D8A),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kelola kategori pesan dan SLA',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddDialog(context, provider),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Jenis Pesan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B4D8A),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.label_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada jenis pesan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol "Tambah Jenis Pesan" untuk membuat baru',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMessageTypesTable(List<MessageType> messageTypes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(),
          SizedBox(
            height: 400,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: messageTypes.length,
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final type = messageTypes[index];
                return _buildMessageTypeRow(type);
              },
            ),
          ),
          _buildTableFooter(messageTypes),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Jenis Pesan', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('SLA', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('External', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('Pesan', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildMessageTypeRow(MessageType type) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('#${type.id}')),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.jenisPesan,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (type.responderType != null && type.responderType!.isNotEmpty)
                  Text(
                    _getResponderName(type.responderType!),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              type.deskripsi ?? '-',
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${type.responseDeadlineHours}h',
                style: const TextStyle(fontSize: 11, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: type.allowExternal ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type.allowExternal ? 'Ya' : 'Tidak',
                style: TextStyle(
                  fontSize: 11,
                  color: type.allowExternal ? Colors.green : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: type.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 11,
                  color: type.isActive ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${type.messageCount}',
                style: const TextStyle(fontSize: 11, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableFooter(List<MessageType> messageTypes) {
    final totalMessages = messageTypes.fold<int>(0, (sum, type) => sum + type.messageCount);
    final activeTypes = messageTypes.where((t) => t.isActive).length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Total ${messageTypes.length} jenis pesan',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 20,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 16),
              Text(
                '$activeTypes aktif',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.message, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Total Pesan: $totalMessages',
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddMessageTypeDialog(
        onSave: (type) async {
          final newType = await provider.createMessageType(type);
          if (newType != null && context.mounted) {
            showSuccessSnackbar(context, 'Jenis pesan berhasil ditambahkan');
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }
        },
      ),
    );
  }

  String _getResponderName(String responderType) {
    switch (responderType) {
      case 'Guru_BK':
        return 'Guru BK';
      case 'Guru_Humas':
        return 'Guru Humas';
      case 'Guru_Kurikulum':
        return 'Guru Kurikulum';
      case 'Guru_Kesiswaan':
        return 'Guru Kesiswaan';
      case 'Guru_Sarana':
        return 'Guru Sarana';
      default:
        return responderType;
    }
  }
}

// Dialog untuk Tambah Jenis Pesan
class _AddMessageTypeDialog extends StatefulWidget {
  final Function(MessageType) onSave;

  const _AddMessageTypeDialog({required this.onSave});

  @override
  State<_AddMessageTypeDialog> createState() => _AddMessageTypeDialogState();
}

class _AddMessageTypeDialogState extends State<_AddMessageTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jenisPesanController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _deadlineController = TextEditingController(text: '72');
  String _responderType = 'Guru_BK';
  bool _allowExternal = true;
  bool _isActive = true;

  final List<Map<String, dynamic>> _responderOptions = [
    {'value': 'Guru_BK', 'label': 'Guru BK'},
    {'value': 'Guru_Humas', 'label': 'Guru Humas'},
    {'value': 'Guru_Kurikulum', 'label': 'Guru Kurikulum'},
    {'value': 'Guru_Kesiswaan', 'label': 'Guru Kesiswaan'},
    {'value': 'Guru_Sarana', 'label': 'Guru Sarana'},
  ];

  @override
  void dispose() {
    _jenisPesanController.dispose();
    _deskripsiController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Jenis Pesan Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _jenisPesanController,
                decoration: const InputDecoration(
                  labelText: 'Nama Jenis Pesan *',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Konsultasi Karir',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama jenis pesan harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _responderType,
                decoration: const InputDecoration(
                  labelText: 'Penanggung Jawab *',
                  border: OutlineInputBorder(),
                ),
                items: _responderOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value'] as String,
                    child: Text(opt['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _responderType = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  hintText: 'Penjelasan singkat tentang jenis pesan ini',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deadlineController,
                decoration: const InputDecoration(
                  labelText: 'Batas Waktu Respons (jam) *',
                  border: OutlineInputBorder(),
                  suffixText: 'jam',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Batas waktu harus diisi';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 1 || intValue > 720) {
                    return 'Harus antara 1-720 jam';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Izinkan pengirim eksternal'),
                subtitle: const Text('Non-siswa/guru dapat mengirim pesan'),
                value: _allowExternal,
                onChanged: (value) {
                  setState(() => _allowExternal = value);
                },
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF0B4D8A),
              ),
              SwitchListTile(
                title: const Text('Aktif'),
                subtitle: const Text('Jenis pesan ini dapat digunakan'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF0B4D8A),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B4D8A),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final type = MessageType(
        id: 0,
        jenisPesan: _jenisPesanController.text,
        responderType: _responderType,
        deskripsi: _deskripsiController.text.isEmpty ? null : _deskripsiController.text,
        responseDeadlineHours: int.parse(_deadlineController.text),
        colorCode: '#0d6efd',
        iconClass: 'fas fa-envelope',
        allowExternal: _allowExternal,
        isActive: _isActive,
        messageCount: 0,
      );
      widget.onSave(type);
    }
  }
}