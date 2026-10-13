
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;

  const ChatScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final Color _purple = const Color(0xFF635BFF);

  bool _isSending = false;
  bool _isRecording = false;

  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _mediaStream;
  final List<html.Blob> _audioChunks = [];

  DocumentReference<Map<String, dynamic>> get _requestRef =>
      FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId);

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await FirestoreService.instance.sendMessage(
        requestId: widget.requestId,
        message: text,
      );

      if (mounted) _messageController.clear();
    } catch (e) {
      _showMessage('Unable to send message: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickPhoto() async {
    await _pickAttachment(
      type: FileType.image,
      messageType: 'image',
    );
  }

  Future<void> _pickDocument() async {
    await _pickAttachment(
      type: FileType.custom,
      messageType: 'document',
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
  }

  Future<void> _pickAttachment({
    required FileType type,
    required String messageType,
    List<String>? extensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: extensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final bytes = picked.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showMessage('Could not read the selected file.');
        return;
      }

      await _uploadBytes(
        bytes: bytes,
        fileName: picked.name,
        type: messageType,
      );
    } catch (e, stack) {
      debugPrint('FILE PICK ERROR: $e\n$stack');
      _showMessage('File selection failed: $e');
    }
  }

  Future<void> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String type,
  }) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please log in again.');
      }

      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_attachments')
          .child(user.uid)
          .child(safeName);

      final contentType = _contentType(fileName, type);

      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final url = await task.ref.getDownloadURL();

      await FirestoreService.instance.sendAttachmentUrl(
        requestId: widget.requestId,
        type: type,
        fileUrl: url,
        fileName: safeName,
      );

      _showMessage('Attachment sent successfully.');
    } catch (e, stack) {
      debugPrint('UPLOAD ERROR: $e\n$stack');
      _showMessage('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _contentType(String fileName, String type) {
    final name = fileName.toLowerCase();

    if (type == 'audio') return 'audio/webm';
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  Future<void> _startRecording() async {
    try {
      if (!html.MediaRecorder.isTypeSupported('audio/webm')) {
        _showMessage('This browser does not support audio recording.');
        return;
      }

      final stream =
          await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
      });

      _mediaStream = stream;
      _audioChunks.clear();

      final recorder = html.MediaRecorder(
        stream,
        {'mimeType': 'audio/webm'},
      );

      recorder.addEventListener('dataavailable', (event) {
        final dataEvent = event as html.BlobEvent;
        if (dataEvent.data != null && dataEvent.data!.size > 0) {
          _audioChunks.add(dataEvent.data!);
        }
      });

      recorder.addEventListener('stop', (event) async {
        await _saveRecording();
      });

      _mediaRecorder = recorder;
      recorder.start();

      if (mounted) setState(() => _isRecording = true);
      _showMessage('Recording started. Press stop when finished.');
    } catch (e, stack) {
      debugPrint('RECORDING ERROR: $e\n$stack');
      _stopMediaStream();
      _showMessage(
        'Could not record. Allow microphone access in browser settings.',
      );
    }
  }

  Future<void> _stopAndSendRecording() async {
    final recorder = _mediaRecorder;

    if (recorder == null) return;

    try {
      if (recorder.state == 'recording') {
        recorder.stop();
      }

      if (mounted) setState(() => _isRecording = false);
    } catch (e) {
      _showMessage('Unable to stop recording: $e');
      _stopMediaStream();
    }
  }

  Future<void> _saveRecording() async {
    try {
      if (_audioChunks.isEmpty) {
        _showMessage('No audio was recorded. Try again.');
        return;
      }

      final blob = html.Blob(_audioChunks, 'audio/webm');
      final reader = html.FileReader();

      final completer = Completer<Uint8List>();

      reader.onLoad.listen((_) {
        final result = reader.result;
        if (result is ByteBuffer) {
          completer.complete(result.asUint8List());
        } else {
          completer.completeError(
            Exception('Could not read recording data.'),
          );
        }
      });

      reader.onError.listen((_) {
        completer.completeError(
          Exception('Could not read recording data.'),
        );
      });

      reader.readAsArrayBuffer(blob);

      final bytes = await completer.future;

      _stopMediaStream();

      await _uploadBytes(
        bytes: bytes,
        fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.webm',
        type: 'audio',
      );
    } catch (e, stack) {
      debugPrint('SAVE RECORDING ERROR: $e\n$stack');
      _stopMediaStream();
      _showMessage('Could not send voice message: $e');
    }
  }

  void _stopMediaStream() {
    final stream = _mediaStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }

    _mediaStream = null;
    _mediaRecorder = null;
    _audioChunks.clear();
  }

  Future<void> _playVoice(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      _showMessage('Unable to play audio: $e');
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showMessage('Invalid document URL.');
      return;
    }

    try {
      html.window.open(uri.toString(), '_blank');
    } catch (e) {
      _showMessage('Unable to open document: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioPlayer.dispose();
    _stopMediaStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to open chat.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF24243A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Buddy Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ask, learn and grow together',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _requestRef.snapshots(),
        builder: (context, requestSnapshot) {
          if (requestSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load chat request.'),
            );
          }

          if (!requestSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final request = requestSnapshot.data!.data();

          if (request == null) {
            return const Center(child: Text('Chat request not found.'));
          }

          final juniorId = '${request['juniorId'] ?? ''}';
          final seniorId = '${request['seniorId'] ?? ''}';

          if (currentUser.uid != juniorId &&
              currentUser.uid != seniorId) {
            return const Center(
              child: Text('You do not have access to this chat.'),
            );
          }

          final accepted = request['status'] == 'accepted';

          return Column(
            children: [
              if (!accepted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFFFF1D6),
                  child: const Text(
                    'Chat is available after the request is accepted.',
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('requestId', isEqualTo: widget.requestId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Unable to load messages.'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final messages = snapshot.data!.docs.toList();

                    messages.sort((a, b) {
                      final aTime = a.data()['createdAt'] as Timestamp?;
                      final bTime = b.data()['createdAt'] as Timestamp?;

                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return aTime.compareTo(bTime);
                    });

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Start your learning conversation!'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data();
                        return _messageBubble(
                          data,
                          data['senderId'] == currentUser.uid,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildComposer(enabled: accepted),
            ],
          );
        },
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> data, bool isMine) {
    final type = '${data['type'] ?? 'text'}';
    final text = '${data['text'] ?? ''}';
    final url = '${data['fileUrl'] ?? ''}';
    final fileName = '${data['fileName'] ?? 'Attachment'}';

    Widget content;

    if (type == 'image' && url.isNotEmpty) {
      content = Image.network(
        url,
        width: 220,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) =>
            const Text('Unable to load photo.'),
      );
    } else if (type == 'audio' && url.isNotEmpty) {
      content = TextButton.icon(
        onPressed: () => _playVoice(url),
        icon: const Icon(Icons.play_circle_fill),
        label: const Text('Play voice message'),
      );
    } else if (type == 'document' && url.isNotEmpty) {
      content = TextButton.icon(
        onPressed: () => _openDocument(url),
        icon: const Icon(Icons.description_outlined),
        label: Flexible(
          child: Text(fileName, overflow: TextOverflow.ellipsis),
        ),
      );
    } else {
      content = Text(text.isEmpty ? 'Attachment unavailable.' : text);
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: isMine ? Colors.white : const Color(0xFF24243A),
            fontSize: 15,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildComposer({required bool enabled}) {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAEAF2))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Add photo',
            onPressed: enabled && !_isSending && !_isRecording
                ? _pickPhoto
                : null,
            icon: Icon(Icons.photo_outlined, color: _purple),
          ),
          IconButton(
            tooltip: 'Select document',
            onPressed: enabled && !_isSending && !_isRecording
                ? _pickDocument
                : null,
            icon: Icon(Icons.document_scanner_outlined, color: _purple),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: enabled && !_isSending && !_isRecording,
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Type a message...'
                    : 'Waiting for acceptance...',
                filled: true,
                fillColor: const Color(0xFFF5F5FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendText(),
            ),
          ),
          const SizedBox(width: 4),
          if (_isRecording)
            IconButton.filled(
              onPressed: _stopAndSendRecording,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.stop),
            )
          else if (!hasText)
            IconButton(
              tooltip: 'Record voice message',
              onPressed: enabled && !_isSending
                  ? _startRecording
                  : null,
              icon: Icon(Icons.mic_none, color: _purple),
            )
          else
            IconButton.filled(
              onPressed: enabled && !_isSending ? _sendText : null,
              style: IconButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
        ],
      ),
    );
  }
}
