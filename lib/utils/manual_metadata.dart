/// `metadata_source` of a cover/description typed in Add/Edit Book.
const manualMetadataSource = 'manual';

String? _clean(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Cover, description and metadata source to save from Add/Edit Book.
///
/// Text that differs from the fetched values is marked as manual, so
/// refreshing the book doesn't replace it; clearing both lets them be
/// fetched again.
({String? coverUrl, String? description, String? source, String? fetchedAt})
resolveMetadataFields({
  required String coverText,
  required String descriptionText,
  String? fetchedCoverUrl,
  String? fetchedDescription,
  String? fetchedSource,
  String? fetchedAt,
}) {
  final coverUrl = _clean(coverText);
  final description = _clean(descriptionText);
  final edited =
      coverUrl != _clean(fetchedCoverUrl) ||
      description != _clean(fetchedDescription);
  if (!edited) {
    return (
      coverUrl: coverUrl,
      description: description,
      source: fetchedSource,
      fetchedAt: fetchedAt,
    );
  }
  final cleared = coverUrl == null && description == null;
  return (
    coverUrl: coverUrl,
    description: description,
    source: cleared ? null : manualMetadataSource,
    fetchedAt: cleared ? null : DateTime.now().toIso8601String(),
  );
}
