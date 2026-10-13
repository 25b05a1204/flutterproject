
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;

  User? get user => FirebaseAuth.instance.currentUser;

  // 1. GET CURRENT USER PROFILE

  Future<Map<String, dynamic>> myProfile() async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final ref = db.collection('users').doc(currentUser.uid);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      return snapshot.data() ?? <String, dynamic>{};
    }

    final data = <String, dynamic>{
      'uid': currentUser.uid,
      'name': currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'Student',
      'email': currentUser.email ?? '',
      'role': 'junior',
      'branch': '',
      'year': 0,
      'points': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await ref.set(data, SetOptions(merge: true));

    return data;
  }

  // 2. UPDATE PROFILE

  Future<void> updateProfile({
    required String name,
    required String branch,
    required int year,
    required String role,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    await db.collection('users').doc(currentUser.uid).set({
      'uid': currentUser.uid,
      'name': name.trim(),
      'email': currentUser.email ?? '',
      'branch': branch.trim(),
      'year': year,
      'role': role.trim().toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await currentUser.updateDisplayName(name.trim());
  }

  // 3. CREATE A DOUBT

  Future<String> createDoubt({
    required String title,
    required String description,
    required String category,
    required String preferredYear,
    String? imageUrl,
    String? documentUrl,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    if (title.trim().isEmpty || description.trim().isEmpty) {
      throw Exception(
        'Please enter the doubt title and description.',
      );
    }

    final profile = await myProfile();

    final ref = await db.collection('doubts').add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'preferredYear': preferredYear,
      'juniorId': currentUser.uid,
      'juniorName': profile['name'] ?? 'Student',
      'juniorEmail': currentUser.email ?? '',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'seniorId': null,
      'seniorName': null,
      'requestId': null,
      'imageUrl': imageUrl,
      'documentUrl': documentUrl,
    });

    return ref.id;
  }

  // 4. UPLOAD FILE USING dart:io File
  // Retained for existing mobile/desktop code.

  Future<Map<String, String>> uploadAttachment({
    required File file,
    required String folder,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_'
        '${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'attachment'}';

    final ref = FirebaseStorage.instance
        .ref()
        .child(folder)
        .child(currentUser.uid)
        .child(fileName);

    final task = await ref.putFile(file);
    final url = await task.ref.getDownloadURL();

    return {
      'url': url,
      'name': fileName,
    };
  }

  // 5. SEND REQUEST TO A SENIOR

  Future<String> requestSenior({
    required String doubtId,
    required Map<String, dynamic> senior,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final seniorId = '${senior['uid'] ?? ''}';

    if (seniorId.isEmpty || seniorId == currentUser.uid) {
      throw Exception('Please select a valid senior.');
    }

    final profile = await myProfile();

    final doubtRef = db.collection('doubts').doc(doubtId);
    final doubtSnapshot = await doubtRef.get();

    if (!doubtSnapshot.exists) {
      throw Exception('Doubt not found. Please post your doubt again.');
    }

    final doubt = doubtSnapshot.data()!;

    if (doubt['juniorId'] != currentUser.uid) {
      throw Exception('You can only request help for your own doubt.');
    }

    if (doubt['status'] == 'solved') {
      throw Exception('This doubt is already solved.');
    }

    final existing = await db
        .collection('requests')
        .where('doubtId', isEqualTo: doubtId)
        .where('seniorId', isEqualTo: seniorId)
        .where('juniorId', isEqualTo: currentUser.uid)
        .get();

    for (final doc in existing.docs) {
      final status = doc.data()['status'];

      if (status == 'pending' || status == 'accepted') {
        return doc.id;
      }
    }

    final requestRef = db.collection('requests').doc();
    final notificationRef = db.collection('notifications').doc();

    final juniorName = '${profile['name'] ?? 'Student'}';
    final seniorName = '${senior['name'] ?? 'Senior'}';
    final doubtTitle = '${doubt['title'] ?? 'Study doubt'}';

    final batch = db.batch();

    batch.set(requestRef, {
      'requestId': requestRef.id,
      'doubtId': doubtId,
      'juniorId': currentUser.uid,
      'juniorName': juniorName,
      'seniorId': seniorId,
      'seniorName': seniorName,
      'doubtTitle': doubtTitle,
      'doubtDescription': doubt['description'] ?? '',
      'category': doubt['category'] ?? 'General',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': null,
    });

    batch.update(doubtRef, {
      'seniorId': seniorId,
      'seniorName': seniorName,
      'requestId': requestRef.id,
      'status': 'requested',
    });

    batch.set(notificationRef, {
      'recipientId': seniorId,
      'title': '📚 New doubt request',
      'body': '$juniorName needs help: $doubtTitle',
      'requestId': requestRef.id,
      'doubtId': doubtId,
      'type': 'doubt_request',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return requestRef.id;
  }

  // 6. INCOMING REQUESTS

  Stream<QuerySnapshot<Map<String, dynamic>>> myIncomingRequests() {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    return db
        .collection('requests')
        .where('seniorId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // 7. ACCEPT REQUEST

  Future<void> acceptRequest({
    required String requestId,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final requestRef = db.collection('requests').doc(requestId);
    final snapshot = await requestRef.get();

    if (!snapshot.exists) {
      throw Exception('Request not found.');
    }

    final request = snapshot.data()!;

    if (request['seniorId'] != currentUser.uid) {
      throw Exception(
        'Only the selected senior can accept this request.',
      );
    }

    if (request['status'] == 'accepted') return;

    if (request['status'] != 'pending') {
      throw Exception('This request is no longer pending.');
    }

    final doubtId = '${request['doubtId'] ?? ''}';
    final juniorId = '${request['juniorId'] ?? ''}';

    final profile = await myProfile();
    final seniorName = '${profile['name'] ?? 'Senior'}';
    final doubtTitle = '${request['doubtTitle'] ?? 'Study doubt'}';

    final batch = db.batch();

    batch.update(requestRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    if (doubtId.isNotEmpty) {
      batch.set(
        db.collection('doubts').doc(doubtId),
        {
          'seniorId': currentUser.uid,
          'seniorName': seniorName,
          'status': 'accepted',
          'requestId': requestId,
        },
        SetOptions(merge: true),
      );
    }

    batch.set(db.collection('notifications').doc(), {
      'recipientId': juniorId,
      'title': '🎉 Request accepted!',
      'body': '$seniorName accepted your request: $doubtTitle',
      'requestId': requestId,
      'doubtId': doubtId,
      'type': 'request_accepted',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 8. REJECT REQUEST

  Future<void> rejectRequest({
    required String requestId,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final requestRef = db.collection('requests').doc(requestId);
    final snapshot = await requestRef.get();

    if (!snapshot.exists) {
      throw Exception('Request not found.');
    }

    final request = snapshot.data()!;

    if (request['seniorId'] != currentUser.uid) {
      throw Exception(
        'Only the selected senior can reject this request.',
      );
    }

    if (request['status'] != 'pending') {
      throw Exception('This request is no longer pending.');
    }

    final juniorId = '${request['juniorId'] ?? ''}';
    final doubtId = '${request['doubtId'] ?? ''}';

    final batch = db.batch();

    batch.update(requestRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    if (doubtId.isNotEmpty) {
      batch.set(
        db.collection('doubts').doc(doubtId),
        {
          'seniorId': null,
          'seniorName': null,
          'requestId': null,
          'status': 'open',
        },
        SetOptions(merge: true),
      );
    }

    batch.set(db.collection('notifications').doc(), {
      'recipientId': juniorId,
      'title': 'Request update',
      'body': 'Your selected senior could not accept this request. '
          'You can choose another senior.',
      'requestId': requestId,
      'doubtId': doubtId,
      'type': 'request_rejected',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 9. MARK DOUBT AS SOLVED

  Future<void> markDoubtSolved(String doubtId) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final doubtRef = db.collection('doubts').doc(doubtId);
    final snapshot = await doubtRef.get();

    if (!snapshot.exists) {
      throw Exception('Doubt not found.');
    }

    final doubt = snapshot.data()!;

    if (doubt['juniorId'] != currentUser.uid) {
      throw Exception(
        'Only the junior who posted this doubt can solve it.',
      );
    }

    if (doubt['status'] == 'solved') return;

    final seniorId = '${doubt['seniorId'] ?? ''}';

    if (seniorId.isEmpty) {
      throw Exception('A senior must accept this doubt first.');
    }

    final requestId = '${doubt['requestId'] ?? ''}';
    final batch = db.batch();

    batch.update(doubtRef, {
      'status': 'solved',
      'solvedAt': FieldValue.serverTimestamp(),
    });

    if (requestId.isNotEmpty) {
      final requestRef = db.collection('requests').doc(requestId);
      final requestSnapshot = await requestRef.get();

      if (requestSnapshot.exists) {
        batch.update(requestRef, {
          'status': 'solved',
          'solvedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    batch.set(db.collection('notifications').doc(), {
      'recipientId': seniorId,
      'title': '✅ Doubt marked as solved',
      'body':
          '${doubt['juniorName'] ?? 'A junior'} marked '
          '"${doubt['title'] ?? 'a doubt'}" as solved.',
      'doubtId': doubtId,
      'requestId': requestId.isEmpty ? null : requestId,
      'type': 'doubt_solved',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      db.collection('users').doc(currentUser.uid),
      {'points': FieldValue.increment(10)},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // 10. MARK NOTIFICATION AS READ

  Future<void> markNotificationRead(String notificationId) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final ref = db.collection('notifications').doc(notificationId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw Exception('Notification not found.');
    }

    if (snapshot.data()?['recipientId'] != currentUser.uid) {
      throw Exception('You cannot update this notification.');
    }

    await ref.update({'read': true});
  }

  // 11. MY NOTIFICATIONS

  Stream<QuerySnapshot<Map<String, dynamic>>> myNotifications() {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    return db
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUser.uid)
        .snapshots();
  }

  // 12. SEND TEXT MESSAGE

  Future<void> sendMessage({
    required String requestId,
    required String message,
  }) async {
    final currentUser = user;
    final text = message.trim();

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    if (text.isEmpty) return;

    final snapshot = await db.collection('requests').doc(requestId).get();

    if (!snapshot.exists) {
      throw Exception('Chat request not found.');
    }

    final request = snapshot.data()!;

    final participant =
        request['juniorId'] == currentUser.uid ||
        request['seniorId'] == currentUser.uid;

    if (!participant) {
      throw Exception('You are not a participant in this chat.');
    }

    if (request['status'] != 'accepted') {
      throw Exception(
        'The senior must accept the request before chatting.',
      );
    }

    final profile = await myProfile();

    await db.collection('messages').add({
      'requestId': requestId,
      'senderId': currentUser.uid,
      'senderName': profile['name'] ?? 'Student',
      'text': text,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 13. SEND FILE USING dart:io File
  // Retained for existing mobile/desktop code.

  Future<void> sendAttachment({
    required String requestId,
    required File file,
    required String type,
    required String folder,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final snapshot = await db.collection('requests').doc(requestId).get();

    if (!snapshot.exists) {
      throw Exception('Chat request not found.');
    }

    final request = snapshot.data()!;

    final participant =
        request['juniorId'] == currentUser.uid ||
        request['seniorId'] == currentUser.uid;

    if (!participant) {
      throw Exception('You are not a participant in this chat.');
    }

    if (request['status'] != 'accepted') {
      throw Exception(
        'The senior must accept the request before chatting.',
      );
    }

    final uploaded = await uploadAttachment(
      file: file,
      folder: folder,
    );

    final profile = await myProfile();

    await db.collection('messages').add({
      'requestId': requestId,
      'senderId': currentUser.uid,
      'senderName': profile['name'] ?? 'Student',
      'text': '',
      'type': type,
      'fileUrl': uploaded['url'],
      'fileName': uploaded['name'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 14. SEND WEB ATTACHMENT URL
  // ChatScreen uploads bytes to Firebase Storage first,
  // then calls this method to save the message.

  Future<void> sendAttachmentUrl({
    required String requestId,
    required String type,
    required String fileUrl,
    required String fileName,
  }) async {
    final currentUser = user;

    if (currentUser == null) {
      throw Exception('Please log in again.');
    }

    final snapshot = await db.collection('requests').doc(requestId).get();

    if (!snapshot.exists) {
      throw Exception('Chat request not found.');
    }

    final request = snapshot.data()!;

    final participant =
        request['juniorId'] == currentUser.uid ||
        request['seniorId'] == currentUser.uid;

    if (!participant) {
      throw Exception('You are not a participant in this chat.');
    }

    if (request['status'] != 'accepted') {
      throw Exception(
        'The senior must accept the request before chatting.',
      );
    }

    final profile = await myProfile();

    await db.collection('messages').add({
      'requestId': requestId,
      'senderId': currentUser.uid,
      'senderName': profile['name'] ?? 'Student',
      'text': '',
      'type': type,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
