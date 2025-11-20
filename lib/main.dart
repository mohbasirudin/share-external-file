import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Manual',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ShareReceiverPage(),
    );
  }
}

class ShareReceiverPage extends StatefulWidget {
  const ShareReceiverPage({super.key});

  @override
  State<ShareReceiverPage> createState() => _ShareReceiverPageState();
}

class _ShareReceiverPageState extends State<ShareReceiverPage> {
  static const platform = MethodChannel('id.bee.sharemanual/share');

  String _shareType = 'none';
  String? _sharedText;
  String? _sharedSubject;
  List<Map<String, dynamic>> _sharedFiles = [];

  @override
  void initState() {
    super.initState();
    _getInitialSharedData();
    _setupShareListener();
  }

  Future<void> _getInitialSharedData() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getInitialShare',
      );

      if (result.isNotEmpty) {
        _handleSharedData(result);
      }
    } on PlatformException catch (e) {
      debugPrint("Error getting initial share: ${e.message}");
    }
  }

  void _setupShareListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final Map<dynamic, dynamic> data = call.arguments;
        _handleSharedData(data);
      }
    });
  }

  void _handleSharedData(Map<dynamic, dynamic> data) {
    setState(() {
      _shareType = data['type'] ?? 'none';
      _sharedText = data['text'];
      _sharedSubject = data['subject'];

      if (data['files'] != null) {
        _sharedFiles = List<Map<String, dynamic>>.from(
          (data['files'] as List).map(
            (file) => Map<String, dynamic>.from(file),
          ),
        );
      } else {
        _sharedFiles = [];
      }
    });
  }

  void _clearData() {
    setState(() {
      _shareType = 'none';
      _sharedText = null;
      _sharedSubject = null;
      _sharedFiles = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Share Manual'),
        actions: [
          if (_shareType != 'none')
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearData,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_shareType == 'none') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data yang di-share',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Share sesuatu dari aplikasi lain',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShareTypeChip(),
          const SizedBox(height: 16),

          if (_sharedText != null) ...[
            _buildTextCard(),
            const SizedBox(height: 16),
          ],

          if (_sharedFiles.isNotEmpty) ...[_buildFilesCard()],
        ],
      ),
    );
  }

  Widget _buildShareTypeChip() {
    IconData icon;
    String label;
    Color color;

    switch (_shareType) {
      case 'text':
        icon = Icons.text_fields;
        label = 'Text';
        color = Colors.blue;
        break;
      case 'file':
        icon = Icons.insert_drive_file;
        label = 'Single File';
        color = Colors.green;
        break;
      case 'files':
        icon = Icons.file_copy;
        label = 'Multiple Files (${_sharedFiles.length})';
        color = Colors.orange;
        break;
      default:
        icon = Icons.help_outline;
        label = 'Unknown';
        color = Colors.grey;
    }

    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Text Content',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_sharedSubject != null) ...[
              Text(
                'Subject:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _sharedSubject!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(height: 24),
            ],
            Text(_sharedText!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _sharedText!));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Text copied')));
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesCard() {
    final stats = _calculateFileStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_sharedFiles.length} File(s)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid view untuk files dengan thumbnail
            _buildFilesGrid(),
          ],
        ),
      ),
    );
  }

  String _calculateFileStats() {
    final counts = <String, int>{};
    for (var file in _sharedFiles) {
      final type = file['type'] ?? 'file';
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return counts.entries.map((e) => '${e.value} ${e.key}').join(', ');
  }

  Widget _buildFilesGrid() {
    // Jika ada thumbnail, tampilkan grid
    final hasAnyThumbnail = _sharedFiles.any((f) => f['thumbnail'] != null);

    if (hasAnyThumbnail && _sharedFiles.length > 1) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _sharedFiles.length,
        itemBuilder: (context, index) {
          return _buildThumbnailCard(_sharedFiles[index]);
        },
      );
    }

    // Jika tidak ada thumbnail atau single file, tampilkan list
    return Column(
      children: _sharedFiles.map((file) => _buildFileItem(file)).toList(),
    );
  }

  Widget _buildThumbnailCard(Map<String, dynamic> file) {
    final String? name = file['name'];
    final String? type = file['type'];
    final String? thumbnail = file['thumbnail'];
    final String? sizeFormatted = file['sizeFormatted'];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail atau icon
          if (thumbnail != null)
            Image.file(
              File(thumbnail),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFileIconPlaceholder(type);
              },
            )
          else
            _buildFileIconPlaceholder(type),

          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sizeFormatted != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sizeFormatted,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Type badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type?.toUpperCase() ?? 'FILE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIconPlaceholder(String? type) {
    final fileIcon = _getFileIcon(type);
    return Container(
      color: fileIcon.color.withOpacity(0.1),
      child: Icon(fileIcon.icon, size: 48, color: fileIcon.color),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    final String? name = file['name'];
    final String? type = file['type'];
    final String? path = file['path'];
    final String? thumbnail = file['thumbnail'];
    final String? mimeType = file['mimeType'];
    final String? sizeFormatted = file['sizeFormatted'];

    final fileIcon = _getFileIcon(type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fileIcon.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon.icon, color: fileIcon.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Unknown file',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sizeFormatted != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sizeFormatted,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (mimeType != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        mimeType,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  if (path != null) {
                    Clipboard.setData(ClipboardData(text: path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Path copied')),
                    );
                  }
                },
                tooltip: 'Copy path',
              ),
            ],
          ),

          // Thumbnail preview
          if (thumbnail != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(thumbnail),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        type == 'video'
                            ? Icons.videocam_off
                            : Icons.broken_image,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _getFileIcon(String? type) {
    switch (type) {
      case 'image':
        return (icon: Icons.image, color: Colors.blue);
      case 'video':
        return (icon: Icons.video_file, color: Colors.purple);
      case 'audio':
        return (icon: Icons.audio_file, color: Colors.orange);
      case 'pdf':
        return (icon: Icons.picture_as_pdf, color: Colors.red);
      case 'document':
        return (icon: Icons.description, color: Colors.blue[700]!);
      case 'spreadsheet':
        return (icon: Icons.table_chart, color: Colors.green[700]!);
      case 'presentation':
        return (icon: Icons.slideshow, color: Colors.orange[700]!);
      case 'archive':
        return (icon: Icons.folder_zip, color: Colors.amber[700]!);
      case 'apk':
        return (icon: Icons.android, color: Colors.green);
      case 'text':
        return (icon: Icons.text_snippet, color: Colors.teal);
      default:
        return (icon: Icons.insert_drive_file, color: Colors.grey);
    }
  }
}
