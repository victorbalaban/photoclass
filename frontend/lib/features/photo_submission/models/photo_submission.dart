class PhotoSubmission {
  final String id;
  final String imageUrl;
  final String classificationTitle;
  final DateTime timestamp;

  PhotoSubmission({
    required this.id,
    required this.imageUrl,
    required this.classificationTitle,
    required this.timestamp,
  });
}