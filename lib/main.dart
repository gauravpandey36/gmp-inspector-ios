import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const GMPInspectorApp());

class GMPInspectorApp extends StatelessWidget {
  const GMPInspectorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GMP Inspector',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.blue.shade700, secondary: Colors.tealAccent),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const InspectorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InspectorHome extends StatefulWidget {
  const InspectorHome({super.key});
  @override
  State<InspectorHome> createState() => _InspectorHomeState();
}

class _InspectorHomeState extends State<InspectorHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  
  String _claudeKey = '';
  String _geminiKey = '';
  String _selectedSkill = 'auto';
  
  // Image analysis state
  Uint8List? _imageBytes;
  String _imageReport = '';
  bool _imageAnalyzing = false;
  int _imageFindings = 0;
  double _imageTime = 0;
  
  // Video analysis state
  File? _videoFile;
  String _videoReport = '';
  bool _videoAnalyzing = false;
  int _videoFindings = 0;
  double _videoTime = 0;
  
  bool _ttsEnabled = true;

  static const String _systemPrompt = 'You are a GMP floor inspection co-pilot. Analyze photos/videos for compliance across 8 domains: Area Status, Equipment, GDP, Gowning, Materials, Environmental, EHS Safety, Line Clearance. For each finding: Severity (Critical/Major/Minor/Good Practice), Domain, Observation, Regulatory Reference, Recommended Action. Report only what you see. No fabrication. Cite regulations. This is a pre-screening aid.';

  // --- Mentra Live glasses feed (via the glasses bridge) ---
  static const String _bridgeUrl = 'https://gmp-glasses-bridge-production.up.railway.app';
  static const String _bridgeToken = 'gmp-glasses-2026';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTts();
    _loadKeys();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _claudeKey = prefs.getString('claude_key') ?? '';
      _geminiKey = prefs.getString('gemini_key') ?? '';
    });
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('claude_key', _claudeKey);
    await prefs.setString('gemini_key', _geminiKey);
  }

  // ============== IMAGE ANALYSIS (Claude) ==============
  
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() { _imageBytes = bytes; _imageReport = ''; });
  }

  Future<void> _pickFromGlasses() async {
    setState(() { _imageReport = ''; });
    try {
      final resp = await http.get(Uri.parse('$_bridgeUrl/latest.jpg?token=$_bridgeToken'));
      if (resp.statusCode == 200) {
        setState(() { _imageBytes = resp.bodyBytes; });
        await _analyzeImage();
      } else if (resp.statusCode == 404) {
        setState(() { _imageReport = 'No glasses photo yet. Press the button on your Mentra glasses, then tap "From Glasses" again.'; });
      } else {
        setState(() { _imageReport = 'Glasses fetch error ${resp.statusCode}'; });
      }
    } catch (e) {
      setState(() { _imageReport = 'Glasses error: $e'; });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _claudeKey.isEmpty) {
      if (_claudeKey.isEmpty) _showSettings();
      return;
    }
    setState(() { _imageAnalyzing = true; _imageReport = ''; });
    final sw = Stopwatch()..start();
    
    try {
      final b64 = base64Encode(_imageBytes!);
      final skillPrompt = {
        'auto': 'Analyze this photo from a pharmaceutical environment.',
        'qa': 'Analyze for QA Floor Operations.',
        'ehs': 'Analyze for EHS Safety.',
        'gdp': 'Analyze for GDP compliance.',
      }[_selectedSkill] ?? '';

      final resp = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _claudeKey, 'anthropic-version': '2023-06-01'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514', 'max_tokens': 3000,
          'system': _systemPrompt,
          'messages': [{'role': 'user', 'content': [
            {'type': 'image', 'source': {'type': 'base64', 'media_type': 'image/jpeg', 'data': b64}},
            {'type': 'text', 'text': skillPrompt}
          ]}]
        }),
      );
      sw.stop();
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = data['content'][0]['text'] as String;
        final findings = RegExp(r'\[\d+\]').allMatches(text).length;
        setState(() { _imageReport = text; _imageFindings = findings; _imageTime = sw.elapsedMilliseconds / 1000; });
        if (_ttsEnabled) _speakCriticals(text);
      } else {
        setState(() { _imageReport = 'Error ${resp.statusCode}: ${resp.body}'; });
      }
    } catch (e) {
      setState(() { _imageReport = 'Error: $e'; });
    }
    setState(() { _imageAnalyzing = false; });
  }

  // ============== VIDEO ANALYSIS (Gemini) ==============
  
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.isEmpty) return;
    setState(() { _videoFile = File(result.files.single.path!); _videoReport = ''; });
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
    if (video == null) return;
    setState(() { _videoFile = File(video.path); _videoReport = ''; });
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null || _geminiKey.isEmpty) {
      if (_geminiKey.isEmpty) _showSettings();
      return;
    }
    setState(() { _videoAnalyzing = true; _videoReport = ''; });
    final sw = Stopwatch()..start();
    
    try {
      // Upload video to Gemini File API
      final uploadUri = Uri.parse('https://generativelanguage.googleapis.com/upload/v1beta/files?key=$_geminiKey');
      final uploadReq = http.MultipartRequest('POST', uploadUri)
        ..files.add(await http.MultipartFile.fromPath('file', _videoFile!.path));
      final uploadResp = await uploadReq.send();
      final uploadBody = await uploadResp.stream.bytesToString();
      
      if (uploadResp.statusCode != 200) {
        setState(() { _videoReport = 'Upload error: $uploadBody'; _videoAnalyzing = false; });
        return;
      }
      
      final fileUri = jsonDecode(uploadBody)['file']['uri'] as String;
      
      // Wait for processing
      await Future.delayed(const Duration(seconds: 3));
      
      // Generate content with video
      final genUri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiKey');
      final genResp = await http.post(genUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [
            {'fileData': {'mimeType': 'video/mp4', 'fileUri': fileUri}},
            {'text': 'Analyze this pharmaceutical facility walkthrough video for GMP compliance. Focus on behavioral observations: personnel flow, gowning sequence, hand hygiene, airlock doors, equipment handling. For each finding: [SEVERITY] Domain: Observation | Regulatory Reference | Action.'}
          ]}],
          'systemInstruction': {'parts': [{'text': _systemPrompt}]},
          'generationConfig': {'maxOutputTokens': 3000, 'temperature': 0.3}
        }),
      );
      
      sw.stop();
      if (genResp.statusCode == 200) {
        final data = jsonDecode(genResp.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        final findings = RegExp(r'CRITICAL|MAJOR|MINOR|GOOD', caseSensitive: false).allMatches(text).length;
        setState(() { _videoReport = text; _videoFindings = findings; _videoTime = sw.elapsedMilliseconds / 1000; });
        if (_ttsEnabled) _speakCriticals(text);
      } else {
        setState(() { _videoReport = 'Error ${genResp.statusCode}: ${genResp.body}'; });
      }
    } catch (e) {
      setState(() { _videoReport = 'Error: $e'; });
    }
    setState(() { _videoAnalyzing = false; });
  }

  void _speakCriticals(String text) {
    final criticals = <String>[];
    for (final line in text.split('\n')) {
      if (line.toUpperCase().contains('CRITICAL') && line.contains(':')) {
        criticals.add(line.split(':').skip(1).join(':').trim());
      }
    }
    if (criticals.isNotEmpty) {
      _tts.speak('Attention: ${criticals.length} critical findings. ${criticals.take(3).join(". ")}');
    } else {
      _tts.speak('Analysis complete. No critical findings.');
    }
  }

  void _showSettings() {
    final claudeCtrl = TextEditingController(text: _claudeKey);
    final geminiCtrl = TextEditingController(text: _geminiKey);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('API Keys'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: claudeCtrl, decoration: const InputDecoration(labelText: 'Claude API Key', hintText: 'sk-ant-...'), obscureText: true),
        const SizedBox(height: 12),
        TextField(controller: geminiCtrl, decoration: const InputDecoration(labelText: 'Gemini API Key', hintText: 'AIza...'), obscureText: true),
      ]),
      actions: [
        TextButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('Cancel')),
        TextButton(onPressed: () {
          setState(() { _claudeKey = claudeCtrl.text.trim(); _geminiKey = geminiCtrl.text.trim(); });
          _saveKeys();
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GMP Inspector'),
        centerTitle: true,
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.camera_alt), text: 'Photo'),
          Tab(icon: Icon(Icons.videocam), text: 'Video'),
        ]),
        actions: [
          IconButton(icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off, color: _ttsEnabled ? Colors.tealAccent : Colors.grey),
            onPressed: () => setState(() => _ttsEnabled = !_ttsEnabled)),
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettings),
        ],
      ),
      body: TabBarView(controller: _tabController, children: [
        // TAB 1: IMAGE ANALYSIS
        _buildImageTab(),
        // TAB 2: VIDEO ANALYSIS
        _buildVideoTab(),
      ]),
    );
  }

  Widget _buildImageTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildSkillSelector(),
      const SizedBox(height: 12),
      if (_imageBytes != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_imageBytes!, height: 250, fit: BoxFit.cover))
      else _buildPlaceholder('📸', 'Take or select a photo'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text('Camera'),
          onPressed: () => _pickImage(ImageSource.camera), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.photo_library), label: const Text('Gallery'),
          onPressed: () => _pickImage(ImageSource.gallery), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, padding: const EdgeInsets.symmetric(vertical: 14)))),
      ]),
      const SizedBox(height: 8),
      ElevatedButton.icon(icon: const Icon(Icons.visibility), label: const Text('From Glasses (Mentra Live)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _imageAnalyzing ? null : _pickFromGlasses,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 12),
      ElevatedButton.icon(icon: _imageAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
        label: Text(_imageAnalyzing ? 'Analyzing...' : 'Inspect Photo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: _imageAnalyzing ? null : _analyzeImage,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      if (_imageReport.isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildStats(_imageTime, _imageFindings, 'Claude'),
        const SizedBox(height: 8),
        _buildReport(_imageReport),
      ],
    ]));
  }

  Widget _buildVideoTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
        child: const Text('Video analysis catches behavioral issues: personnel flow, gowning sequence, airlock doors, hand hygiene', style: TextStyle(color: Colors.green, fontSize: 12))),
      const SizedBox(height: 12),
      if (_videoFile != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.videocam, color: Colors.green), const SizedBox(width: 8),
          Expanded(child: Text(_videoFile!.path.split('/').last, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))]))
      else _buildPlaceholder('🎬', 'Record or select a video clip'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.videocam), label: const Text('Record'),
          onPressed: _recordVideo, style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 14)))),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.folder_open), label: const Text('Pick Video'),
          onPressed: _pickVideo, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, padding: const EdgeInsets.symmetric(vertical: 14)))),
      ]),
      const SizedBox(height: 12),
      ElevatedButton.icon(icon: _videoAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.slow_motion_video),
        label: Text(_videoAnalyzing ? 'Analyzing Video...' : 'Inspect Video', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: _videoAnalyzing ? null : _analyzeVideo,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      if (_videoReport.isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildStats(_videoTime, _videoFindings, 'Gemini'),
        const SizedBox(height: 8),
        _buildReport(_videoReport),
      ],
    ]));
  }

  Widget _buildSkillSelector() {
    return Row(children: ['Auto', 'QA', 'EHS', 'GDP'].map((s) {
      final val = s.toLowerCase();
      final selected = _selectedSkill == val;
      return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
        onTap: () => setState(() => _selectedSkill = val),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: selected ? Colors.blue.shade700 : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? Colors.blue : Colors.grey.shade700)),
          child: Text(s, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: selected ? FontWeight.bold : FontWeight.normal)))));
    }).toList());
  }

  Widget _buildPlaceholder(String icon, String text) {
    return Container(height: 200, decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800)),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 48)), const SizedBox(height: 8), Text(text, style: const TextStyle(color: Colors.grey))])));
  }

  Widget _buildStats(double time, int findings, String engine) {
    return Row(children: [
      _statCard('Time', '${time.toStringAsFixed(1)}s'),
      const SizedBox(width: 8),
      _statCard('Findings', '$findings'),
      const SizedBox(width: 8),
      _statCard('Engine', engine),
    ]);
  }

  Widget _statCard(String label, String value) {
    return Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade300)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))])));
  }

  Widget _buildReport(String report) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800)),
      child: SelectableText(report, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5, color: Colors.white70)));
  }

  @override
  void dispose() { _tts.stop(); _tabController.dispose(); super.dispose(); }
}
