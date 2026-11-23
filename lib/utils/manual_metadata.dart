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

/// Text for a cover/description field after a fetch returned [fetched]: the
/// fetched value, unless the user edited the field since it was last filled
/// with [baseline] or the fetch returned none. [baseline] is the new value
/// to compare against when saving.
({String text, String? baseline}) applyFetchedField({
  required String current,
  String? baseline,
  String? fetched,
}) {
  if (_clean(current) != _clean(baseline) || _clean(fetched) == null) {
    return (text: current, baseline: baseline);
  }
  return (text: fetched!, baseline: fetched);
}
