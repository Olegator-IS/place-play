import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<String>> getCommunicationPreferences() async {
  final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('communicationPreferences')
      .get();
  return querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['nameRu'] as String? ?? '';
  }).toList();
}

Future<List<String>> getGamesInterestsFromFirestore() async {
  final QuerySnapshot querySnapshot =
  await FirebaseFirestore.instance.collection('listOfSports').get();
  return querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['nameRu'] as String? ?? '';
  }).toList();
}

Future<List<String>> getMeetingPreferences() async {
  final QuerySnapshot querySnapshot =
  await FirebaseFirestore.instance.collection('meetingPreferences').get();
  return querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['nameRu'] as String? ?? '';
  }).toList();
}

Future<List<String>> getActivityPreferences() async {
  final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('activityPreferences')
      .get();
  return querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['nameRu'] as String? ?? '';
  }).toList();
}

Future<List<String>> getFamilyStatus() async {
  final QuerySnapshot querySnapshot =
  await FirebaseFirestore.instance.collection('familyStatus').get();
  return querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['nameRu'] as String? ?? '';
  }).toList();
}

Future<List<String>> getOpennessPreferences() async {
  final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('opennessPreferences')
      .get();
  return querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['nameRu'] as String? ?? '';
  }).toList();
}

Future<List<String>> getPartnerPreferences() async {
  final QuerySnapshot querySnapshot =
  await FirebaseFirestore.instance.collection('partnerPreferences').get();
  return querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['nameRu'] as String? ?? '';
  }).toList();
}