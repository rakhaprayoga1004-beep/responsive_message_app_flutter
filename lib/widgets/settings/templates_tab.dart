import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/settings_models.dart';
import '../../utils/snackbar_utils.dart';

class TemplatesTab extends StatefulWidget {
  const TemplatesTab({super.key});

  @override
  State<TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<TemplatesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      provider.loadTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final templates = provider.templates;
        
        if (kDebugMode) {
          print('=== BUILDING TEMPLATES TAB ===');
          print('Provider isLoading: ${provider.isLoading}');
          print('Templates length: ${templates.length}');
          for (var i = 0; i < templates.length; i++) {
            print('   Template ${i+1}: ${templates[i].name}');
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
                        Text('Loading templates data...'),
                      ],
                    ),
                  )
                else if (templates.isEmpty)
                  _buildEmptyState()
                else
                  _buildTemplatesGrid(templates),
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
              'Template Respons',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B4D8A),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Template untuk respons cepat ke pesan',
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
          label: const Text('Tambah Template'),
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
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada template',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol "Tambah Template" untuk membuat baru',
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

  Widget _buildTemplatesGrid(List<ResponseTemplate> templates) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(ResponseTemplate template) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCategoryChip(template.category),
                          const SizedBox(width: 8),
                          _buildGuruTypeChip(template.guruType),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${template.useCount}x',
                        style: const TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: template.isActive 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          template.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 10,
                            color: template.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        template.defaultStatus,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(template.defaultStatus),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    switch (category) {
      case 'Konseling':
        color = Colors.purple;
        break;
      case 'Akademik':
        color = Colors.blue;
        break;
      case 'Fasilitas':
        color = Colors.red;
        break;
      case 'Informasi':
        color = Colors.teal;
        break;
      case 'Persetujuan':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Widget _buildGuruTypeChip(String guruType) {
    String label;
    Color color;
    if (guruType == 'ALL') {
      label = 'Global';
      color = Colors.blue;
    } else {
      label = guruType.replaceAll('Guru_', '');
      color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Diproses':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showAddDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddTemplateDialog(
        onSave: (template) async {
          final newTemplate = await provider.createTemplate(template);
          if (newTemplate != null && context.mounted) {
            showSuccessSnackbar(context, 'Template berhasil ditambahkan');
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }
        },
      ),
    );
  }
}

// Dialog untuk Tambah Template
class _AddTemplateDialog extends StatefulWidget {
  final Function(ResponseTemplate) onSave;

  const _AddTemplateDialog({required this.onSave});

  @override
  State<_AddTemplateDialog> createState() => _AddTemplateDialogState();
}

class _AddTemplateDialogState extends State<_AddTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'Umum';
  String _defaultStatus = 'Diproses';
  String _guruType = 'ALL';
  bool _isActive = true;

  final List<Map<String, dynamic>> _categoryOptions = [
    {'value': 'Umum', 'label': 'Umum'},
    {'value': 'Konseling', 'label': 'Konseling'},
    {'value': 'Akademik', 'label': 'Akademik'},
    {'value': 'Fasilitas', 'label': 'Fasilitas'},
    {'value': 'Informasi', 'label': 'Informasi'},
    {'value': 'Persetujuan', 'label': 'Persetujuan'},
    {'value': 'Penolakan', 'label': 'Penolakan'},
  ];

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'Disetujui', 'label': 'Disetujui'},
    {'value': 'Ditolak', 'label': 'Ditolak'},
    {'value': 'Diproses', 'label': 'Diproses'},
    {'value': 'Selesai', 'label': 'Selesai'},
  ];

  final List<Map<String, dynamic>> _guruTypeOptions = [
    {'value': 'ALL', 'label': 'Semua Guru'},
    {'value': 'Guru_BK', 'label': 'Guru BK'},
    {'value': 'Guru_Humas', 'label': 'Guru Humas'},
    {'value': 'Guru_Kurikulum', 'label': 'Guru Kurikulum'},
    {'value': 'Guru_Kesiswaan', 'label': 'Guru Kesiswaan'},
    {'value': 'Guru_Sarana', 'label': 'Guru Sarana'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Template Respons'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Template *',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Konsultasi Jurusan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama template harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori *',
                  border: OutlineInputBorder(),
                ),
                items: _categoryOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value'] as String,
                    child: Text(opt['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _category = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _defaultStatus,
                decoration: const InputDecoration(
                  labelText: 'Default Status *',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value'] as String,
                    child: Text(opt['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _defaultStatus = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _guruType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Guru *',
                  border: OutlineInputBorder(),
                ),
                items: _guruTypeOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value'] as String,
                    child: Text(opt['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _guruType = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Konten Template *',
                  border: OutlineInputBorder(),
                  hintText: 'Isi template respons...',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konten template harus diisi';
                  }
                  if (value.length < 10) {
                    return 'Konten minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktif'),
                subtitle: const Text('Template ini dapat digunakan'),
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
      final template = ResponseTemplate(
        id: 0,
        name: _nameController.text,
        content: _contentController.text,
        category: _category,
        defaultStatus: _defaultStatus,
        guruType: _guruType,
        isActive: _isActive,
        useCount: 0,
      );
      widget.onSave(template);
    }
  }
}