import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String documentNumber;
  final String documentType;

  const DocumentViewerScreen({
    super.key,
    required this.fileUrl,
    required this.documentNumber,
    required this.documentType,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final ApiService _apiService = ApiService();
  String? _localFilePath;
  bool _isLoading = true;
  bool _isPdf = false;
  bool _isImage = false;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializeViewer();
  }

  Future<void> _initializeViewer() async {
    try {
      // Determine file type
      final fileName = widget.fileUrl.split('/').last.toLowerCase();
      _isPdf = fileName.endsWith('.pdf');
      _isImage = fileName.endsWith('.jpg') || 
                fileName.endsWith('.jpeg') || 
                fileName.endsWith('.png') || 
                fileName.endsWith('.gif');

      print('File URL: ${widget.fileUrl}');
      print('Is PDF: $_isPdf, Is Image: $_isImage');

      if (_isPdf || _isImage) {
        await _downloadAndCacheFile();
      } else {
        setState(() {
          _error = 'Unsupported file type. Tap Download to open externally.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing viewer: $e');
      setState(() {
        _error = 'Failed to load document: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndCacheFile() async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.fileUrl.split('/').last;
      final localPath = '${tempDir.path}/$fileName';

      // Check if file already exists
      final file = File(localPath);
      if (await file.exists()) {
        print('File already cached: $localPath');
        setState(() {
          _localFilePath = localPath;
          _isLoading = false;
        });
        return;
      }

      print('Downloading file to: $localPath');

      // Download file using Dio with authentication
      final response = await _apiService.download(
        widget.fileUrl.replaceFirst('http://localhost:8001', ''),
        savePath: localPath,
      );

      if (await file.exists()) {
        print('File downloaded successfully: ${await file.length()} bytes');
        setState(() {
          _localFilePath = localPath;
          _isLoading = false;
        });
      } else {
        throw Exception('File not found after download');
      }
    } catch (e) {
      print('Error downloading file: $e');
      setState(() {
        _error = 'Failed to download file: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternally() async {
    try {
      final uri = Uri.parse(widget.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open file';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file externally: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _copyUrl() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.fileUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL copied to clipboard'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy URL: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.documentType} - ${widget.documentNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: _copyUrl,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy URL',
          ),
          IconButton(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open Externally',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isPdf && _localFilePath != null && _totalPages > 1
          ? _buildPdfControls()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading document...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_localFilePath == null) {
      return _buildErrorView();
    }

    if (_isPdf) {
      return _buildPdfView();
    } else if (_isImage) {
      return _buildImageView();
    }

    return _buildErrorView();
  }

  Widget _buildPdfView() {
    return PDFView(
      filePath: _localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onError: (error) {
        print('PDF Error: $error');
        setState(() {
          _error = 'Failed to display PDF: $error';
        });
      },
      onPageError: (page, error) {
        print('PDF Page Error: $error');
      },
      onViewCreated: (PDFViewController controller) {
        // PDF controller created
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
      },
    );
  }

  Widget _buildImageView() {
    return Center(
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(_localFilePath!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Failed to display image'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openExternally,
                    child: const Text('Open Externally'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unable to display document',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can still access the document using the options below:',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open External'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _copyUrl,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.fileUrl,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, color: AppColors.white),
            const SizedBox(width: 8),
            Text(
              'Page ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
} 