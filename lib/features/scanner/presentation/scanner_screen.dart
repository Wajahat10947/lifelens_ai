import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ai_chat/data/gemini_service.dart';
import '../../voice/presentation/voice_assistant_screen.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../history/data/scan_history_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  final ImagePicker _picker = ImagePicker();

  Uint8List? _lastImage;
  String? _cameraError;
  bool _busy = false;
  bool _startingCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  // Open camera automatically
  Future<void> _startCamera() async {
    if (_startingCamera || _controller != null) return;

    _startingCamera = true;

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found');
      }

      // Prefer back camera on phones
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } catch (e) {
      debugPrint('Camera Error: $e');

      if (mounted) {
        setState(() {
          _cameraError = 'Camera unavailable. Use Gallery.';
        });
      }
    } finally {
      _startingCamera = false;
    }
  }

  // Open gallery
  Future<void> _openGallery() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (image != null) {
        await _openResult(image);
      }
    } catch (e) {
      debugPrint('Gallery Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Capture photo
  Future<void> _takePhoto() async {
    final camera = _controller;

    if (_busy || camera == null || !camera.value.isInitialized) {
      return;
    }

    setState(() => _busy = true);

    try {
      final image = await camera.takePicture();
      await _openResult(image);
    } catch (e) {
      debugPrint('Capture Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _detectMimeType(Uint8List bytes) {
    if (bytes.length < 12) return null;

    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return null;
  }

  // Open AI result screen
  Future<void> _openResult(XFile image) async {
    final bytes = await image.readAsBytes();

    if (!mounted) return;

    final mimeType = _detectMimeType(bytes);

    if (mimeType == null || bytes.lengthInBytes > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a JPEG, PNG or WebP under 5 MB')),
      );
      return;
    }

    setState(() => _lastImage = bytes);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VisionResultScreen(imageBytes: bytes, mimeType: mimeType),
      ),
    );
  }

  // Manage camera when app goes into background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final oldController = _controller;
      _controller = null;
      oldController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady = _controller?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen camera background
          if (cameraReady)
            CameraPreview(_controller!)
          else
            Center(
              child: _cameraError != null
                  ? Text(
                      _cameraError!,
                      style: const TextStyle(color: Colors.white),
                    )
                  : const CircularProgressIndicator(),
            ),

          // Camera scanning frame and controls
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'LifeLens Vision',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: Color(0xFF22D3EE)),
                    ],
                  ),
                ),

                const Spacer(),

                // Futuristic scan frame
                IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF22D3EE),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong,
                      size: 45,
                      color: Color(0xFF22D3EE),
                    ),
                  ),
                ),

                const Spacer(),

                const Text(
                  'Point camera at an object',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),

                const SizedBox(height: 25),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Gallery thumbnail
                      GestureDetector(
                        onTap: _busy ? null : _openGallery,
                        child: Container(
                          width: 62,
                          height: 62,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white),
                          ),
                          child: _lastImage == null
                              ? const Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                )
                              : Image.memory(_lastImage!, fit: BoxFit.cover),
                        ),
                      ),

                      // Center: Scan shutter
                      GestureDetector(
                        onTap: _busy || !cameraReady ? null : _takePhoto,
                        child: Container(
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                            child: _busy
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // Right: Voice assistance
                      IconButton.filled(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VoiceAssistantScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.mic),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          fixedSize: const Size(62, 62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Result screen
class VisionResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String mimeType;

  const VisionResultScreen({
    super.key,
    required this.imageBytes,
    required this.mimeType,
  });

  @override
  State<VisionResultScreen> createState() => _VisionResultScreenState();
}

final ScanHistoryService _historyService = ScanHistoryService();

bool _historySaved = false;

class _VisionResultScreenState extends State<VisionResultScreen> {
  final GeminiService _gemini = GeminiService();

  bool _loading = true;
  String _result = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final answer = await _gemini.analyzeImage(
        bytes: widget.imageBytes,
        mimeType: widget.mimeType,
      );

      if (!mounted) return;

      setState(() {
        _result = answer;
      });

      // Same image ko dobara analyze karne par
      // duplicate history entry nahi banayenge.
      if (!_historySaved) {
        try {
          await _historyService.saveScan(analysis: answer);

          if (!mounted) return;

          setState(() {
            _historySaved = true;
          });

          debugPrint('Scan saved successfully!');
        } catch (e) {
          debugPrint('History Save Error: $e');
        }
      }
    } catch (e) {
      debugPrint('Vision Error: $e');

      if (!mounted) return;

      setState(() {
        _result = 'Analysis failed. Please try again.: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const purple = Color(0xFF8B5CF6);
    const cyan = Color(0xFF22D3EE);

    final bgColor = isDark ? const Color(0xFF080C18) : const Color(0xFFF7F8FC);

    final cardColor = isDark ? const Color(0xFF141B2D) : Colors.white;

    final textColor = colors.onSurface;

    final markdownStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.7,
        color: textColor,
      ),
      h1: theme.textTheme.titleLarge?.copyWith(
        color: cyan,
        fontWeight: FontWeight.bold,
      ),
      h2: theme.textTheme.titleMedium?.copyWith(
        color: cyan,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        color: purple,
        fontWeight: FontWeight.w600,
      ),
      strong: TextStyle(
        color: isDark ? cyan : purple,
        fontWeight: FontWeight.bold,
      ),
      listBullet: TextStyle(color: textColor, fontSize: 15),
      blockSpacing: 14,
      listIndent: 22,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: purple.withValues(alpha: 0.25)),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text(
          'Vision Analysis',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        centerTitle: true,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),

          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // PAGE HEADING
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: cyan, size: 19),
                  SizedBox(width: 9),
                  Text(
                    'LIFELENS INTELLIGENCE',
                    style: TextStyle(
                      color: cyan,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'See Beyond the Image',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Discover details with the power of AI.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
              ),

              const SizedBox(height: 24),

              // CAPTURED IMAGE CARD
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: purple.withValues(alpha: 0.35)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              color: cyan,
                              size: 19,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Scanned Image',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 260,
                        width: double.infinity,
                        color: isDark
                            ? Colors.black26
                            : const Color(0xFFECEFF5),
                        child: Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // AI ANALYSIS CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: purple.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.06),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD HEADER
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.psychology_outlined,
                            color: purple,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Analysis',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Powered by Gemini',
                                style: TextStyle(color: cyan, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Divider(color: purple.withValues(alpha: 0.25)),
                    const SizedBox(height: 12),

                    // FORMATTED GEMINI RESPONSE
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: purple),
                              SizedBox(height: 16),
                              Text('Analyzing your image...'),
                            ],
                          ),
                        ),
                      )
                    else
                      MarkdownBody(
                        data: _result,
                        selectable: true,
                        styleSheet: markdownStyle,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ACTIONS
              if (!_loading) ...[
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _analyze,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Analyze Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Back to Scanner'),
              ),

              const SizedBox(height: 10),

              Text(
                'AI can make mistakes. Verify important details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
