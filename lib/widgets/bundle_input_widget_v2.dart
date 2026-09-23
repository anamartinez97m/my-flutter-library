import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Data class to hold information about a single book in a bundle
class BundleBookData {
  String? sagaNumber;
  String? title;
  String? author;
  int? pages;
  int? publicationYear;
  String? status; // Status value like 'Yes', 'No', 'Started', etc.

  BundleBookData({
    this.sagaNumber,
    this.title,
    this.author,
    this.pages,
    this.publicationYear,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'sagaNumber': sagaNumber,
      'title': title,
      'author': author,
      'pages': pages,
      'publicationYear': publicationYear,
      'status': status,
    };
  }

  factory BundleBookData.fromMap(Map<String, dynamic> map) {
    return BundleBookData(
      sagaNumber: map['sagaNumber'] as String?,
      title: map['title'] as String?,
      author: map['author'] as String?,
      pages: map['pages'] as int?,
      publicationYear: map['publicationYear'] as int?,
      status: map['status'] as String?,
    );
  }
}

class BundleInputWidgetV2 extends StatefulWidget {
  final bool initialIsBundle;
  final int? initialBundleCount;
  final List<BundleBookData>? initialBundleBooks;
  final List<Map<String, dynamic>>? statusOptions; // List of status options
  final Function(bool isBundle, int? count, List<BundleBookData>? bundleBooks)
  onChanged;
  final bool editMode; // If true, only show title and nsaga fields
  final Color? titleColor;
  final bool showDetailsTitle;
  final bool useNewUi;

  const BundleInputWidgetV2({
    super.key,
    required this.initialIsBundle,
    this.initialBundleCount,
    this.initialBundleBooks,
    this.statusOptions,
    required this.onChanged,
    this.editMode = false, // Default to false (show all fields)
    this.titleColor,
    this.showDetailsTitle = true,
    this.useNewUi = false,
  });

  @override
  State<BundleInputWidgetV2> createState() => _BundleInputWidgetV2State();
}

class _BundleInputWidgetV2State extends State<BundleInputWidgetV2> {
  late bool _isBundle;
  late TextEditingController _bundleCountController;
  List<BundleBookData> _bundleBooks = [];
  int _visibleBookCount = 10;

  @override
  void initState() {
    super.initState();
    _isBundle = widget.initialIsBundle;
    final initialCount =
        widget.initialBundleCount ??
        (widget.initialBundleBooks?.isNotEmpty == true
            ? widget.initialBundleBooks!.length
            : widget.useNewUi
            ? 0
            : null);
    _bundleCountController = TextEditingController(
      text: initialCount?.toString() ?? '',
    );

    // Initialize bundle books
    if (widget.initialBundleBooks != null &&
        widget.initialBundleBooks!.isNotEmpty) {
      _bundleBooks = List.from(widget.initialBundleBooks!);
    }
    if (widget.useNewUi && initialCount != null) {
      while (_bundleBooks.length < initialCount) {
        _bundleBooks.add(BundleBookData(status: 'No'));
      }
    }

    _bundleCountController.addListener(_onCountChanged);
  }

  @override
  void dispose() {
    _bundleCountController.dispose();
    super.dispose();
  }

  void _onCountChanged() {
    final count = int.tryParse(_bundleCountController.text);
    if (count != null && count >= 0) {
      setState(() {
        // Adjust list to match count
        while (_bundleBooks.length < count) {
          _bundleBooks.add(BundleBookData(status: 'No')); // Default status
        }
        if (_bundleBooks.length > count) {
          _bundleBooks = _bundleBooks.sublist(0, count);
        }
      });
    }
    _notifyChange();
  }

  void _notifyChange() {
    final count = int.tryParse(_bundleCountController.text);
    widget.onChanged(
      _isBundle,
      count,
      _bundleBooks.isEmpty ? null : _bundleBooks,
    );
  }

  void _changeCount(int delta) {
    final current = int.tryParse(_bundleCountController.text) ?? 0;
    final next = current + delta;
    _bundleCountController.text = (next < 0 ? 0 : next).toString();
    _bundleCountController.selection = TextSelection.collapsed(
      offset: _bundleCountController.text.length,
    );
  }

  InputDecoration _v2InputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7A6A71), fontSize: 14),
      filled: true,
      fillColor: const Color(0x66FDF8F6),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E2DE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5D2641), width: 1.5),
      ),
    );
  }

  Widget _v2Field({
    required String label,
    required String initialValue,
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required Key fieldKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF7A6A71),
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: fieldKey,
          initialValue: initialValue,
          decoration: _v2InputDecoration(hint),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            color: Color(0xFF270008),
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildV2(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const primary = Color(0xFF5D2641);
    const text = Color(0xFF270008);
    const secondary = Color(0xFF7A6A71);
    const border = Color(0xFFE8E2DE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() => _isBundle = !_isBundle);
            _notifyChange();
          },
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A5D2641),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _isBundle,
                    activeColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (value) {
                      setState(() => _isBundle = value ?? false);
                      _notifyChange();
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.this_is_a_bundle,
                        style: const TextStyle(
                          color: text,
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.bundle_description,
                        style: const TextStyle(
                          color: secondary,
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isBundle) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.library_books_outlined,
                        color: primary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.number_of_books_in_bundle.toUpperCase(),
                            style: const TextStyle(
                              color: secondary,
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .55,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.bundle_count_input_hint,
                            style: const TextStyle(
                              color: secondary,
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0x99FDF8F6),
                    border: Border.all(color: border.withValues(alpha: .7)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _v2CountButton(
                        Icons.remove,
                        () => _changeCount(-1),
                        false,
                      ),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _bundleCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: text,
                            fontFamily: 'Manrope',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primary),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            suffixText: ' BOOKS',
                            suffixStyle: TextStyle(
                              color: secondary,
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                      ),
                      _v2CountButton(Icons.add, () => _changeCount(1), true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_bundleBooks.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'VOLUMES IN THIS BUNDLE',
                style: TextStyle(
                  color: text,
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _bundleBooks.length < _visibleBookCount
                  ? _bundleBooks.length
                  : _visibleBookCount,
              (index) => _buildV2BookCard(context, index),
            ),
            if (_visibleBookCount < _bundleBooks.length)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      final next = _visibleBookCount + 10;
                      _visibleBookCount =
                          next < _bundleBooks.length
                              ? next
                              : _bundleBooks.length;
                    });
                  },
                  icon: const Icon(Icons.expand_more),
                  label: Text(
                    l10n.show_more_bundle_volumes(
                      _bundleBooks.length - _visibleBookCount,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _v2CountButton(IconData icon, VoidCallback onPressed, bool filled) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: filled ? const Color(0xFF5D2641) : Colors.white,
          foregroundColor: filled ? Colors.white : const Color(0xFF270008),
          side:
              filled
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFFE8E2DE)),
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  Widget _buildV2BookCard(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    final book = _bundleBooks[index];
    final isRead = book.status == 'Yes';

    void update(VoidCallback change) {
      setState(change);
      _notifyChange();
    }

    return Container(
      key: ValueKey('bundle_card_$index'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E2DE)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A5D2641),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D2641),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Vol. ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              FilterChip(
                selected: isRead,
                showCheckmark: false,
                avatar: Icon(
                  isRead ? Icons.check_circle : Icons.circle_outlined,
                  color:
                      isRead
                          ? const Color(0xFF5D2641)
                          : const Color(0xFF7A6A71),
                  size: 18,
                ),
                label: Text(l10n.read_label),
                onSelected:
                    (selected) =>
                        update(() => book.status = selected ? 'Yes' : 'No'),
                selectedColor: const Color(0x66FDF8F6),
                backgroundColor: const Color(0x66FDF8F6),
                side: const BorderSide(color: Color(0xFFE8E2DE)),
                labelStyle: const TextStyle(
                  color: Color(0xFF7A6A71),
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 25, color: Color(0x80E8E2DE)),
          _v2Field(
            fieldKey: ValueKey('title_$index'),
            label: l10n.book_title,
            initialValue: book.title ?? '',
            hint: l10n.enter_book_title,
            onChanged:
                (value) =>
                    update(() => book.title = value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _v2Field(
                  fieldKey: ValueKey('saga_$index'),
                  label: l10n.saga_number,
                  initialValue: book.sagaNumber ?? '',
                  hint: l10n.eg_1_or_1_5,
                  onChanged:
                      (value) => update(
                        () => book.sagaNumber = value.isEmpty ? null : value,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _v2Field(
                  fieldKey: ValueKey('pages_$index'),
                  label: l10n.pages,
                  initialValue: book.pages?.toString() ?? '',
                  hint: '250',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged:
                      (value) => update(() => book.pages = int.tryParse(value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _v2Field(
            fieldKey: ValueKey('author_$index'),
            label: l10n.authors,
            initialValue: book.author ?? '',
            hint: l10n.enter_author_names,
            onChanged:
                (value) =>
                    update(() => book.author = value.isEmpty ? null : value),
          ),
          const SizedBox(height: 10),
          _v2Field(
            fieldKey: ValueKey('year_$index'),
            label: l10n.original_publication_year,
            initialValue: book.publicationYear?.toString() ?? '',
            hint: l10n.eg_2020,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged:
                (value) =>
                    update(() => book.publicationYear = int.tryParse(value)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useNewUi) return _buildV2(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(
            AppLocalizations.of(context)!.this_is_a_bundle,
            style:
                widget.titleColor != null
                    ? TextStyle(color: widget.titleColor)
                    : null,
          ),
          subtitle: Text(AppLocalizations.of(context)!.bundle_description),
          value: _isBundle,
          onChanged: (value) {
            setState(() {
              _isBundle = value ?? false;
            });
            _notifyChange();
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_isBundle) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _bundleCountController,
            decoration: InputDecoration(
              labelText:
                  AppLocalizations.of(context)!.number_of_books_in_bundle,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.library_books),
              hintText: AppLocalizations.of(context)!.eg_3,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          if (_bundleBooks.isNotEmpty) ...[
            if (widget.showDetailsTitle) ...[
              Text(
                AppLocalizations.of(context)!.bundle_book_details,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            ...List.generate(_bundleBooks.length, (index) {
              final bookData = _bundleBooks[index];
              final bookTitle =
                  (bookData.title != null && bookData.title!.isNotEmpty)
                      ? bookData.title!
                      : 'Book ${index + 1}';
              final statusValue = bookData.status ?? 'No';

              // Determine icon and color based on status
              IconData statusIcon;
              Color statusColor;
              if (statusValue == 'Yes') {
                statusIcon = Icons.check_circle;
                statusColor = Theme.of(context).colorScheme.primary;
              } else if (statusValue == 'Started') {
                statusIcon = Icons.play_circle;
                statusColor = Theme.of(context).colorScheme.secondary;
              } else {
                statusIcon = Icons.circle_outlined;
                statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
              }

              return Card(
                key: ValueKey('bundle_card_$index'),
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and title
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color:
                                        statusValue == 'Yes'
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : null,
                                  ),
                                ),
                                Text(
                                  statusValue,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status dropdown - only show when NOT in edit mode
                      if (!widget.editMode &&
                          widget.statusOptions != null &&
                          widget.statusOptions!.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: statusValue,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.status,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items:
                              widget.statusOptions!.map((status) {
                                final value = status['value'] as String;
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _bundleBooks[index].status = value;
                            });
                            _notifyChange();
                          },
                        ),
                      if (!widget.editMode) const SizedBox(height: 8),
                      // N_Saga input
                      TextFormField(
                        key: ValueKey('saga_$index'),
                        initialValue: bookData.sagaNumber ?? '',
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.saga_number,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          hintText: AppLocalizations.of(context)!.eg_1_or_1_5,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _bundleBooks[index].sagaNumber =
                                value.isEmpty ? null : value;
                          });
                          _notifyChange();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Book Title input
                      TextFormField(
                        key: ValueKey('title_$index'),
                        initialValue: bookData.title ?? '',
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.book_title,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          hintText:
                              AppLocalizations.of(context)!.enter_book_title,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _bundleBooks[index].title =
                                value.isEmpty ? null : value;
                          });
                          _notifyChange();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Author input - only show when NOT in edit mode
                      if (!widget.editMode)
                        TextFormField(
                          key: ValueKey('author_$index'),
                          initialValue: bookData.author ?? '',
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.authors,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            hintText:
                                AppLocalizations.of(
                                  context,
                                )!.enter_author_names,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _bundleBooks[index].author =
                                  value.isEmpty ? null : value;
                            });
                            _notifyChange();
                          },
                        ),
                      if (!widget.editMode) const SizedBox(height: 8),
                      // Pages input - only show when NOT in edit mode
                      if (!widget.editMode)
                        TextFormField(
                          key: ValueKey('pages_$index'),
                          initialValue: bookData.pages?.toString() ?? '',
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.pages,
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: 'e.g., 250',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _bundleBooks[index].pages = int.tryParse(value);
                            });
                            _notifyChange();
                          },
                        ),
                      if (!widget.editMode) const SizedBox(height: 8),
                      // Original Publication Year input - only show when NOT in edit mode
                      if (!widget.editMode)
                        TextFormField(
                          key: ValueKey('year_$index'),
                          initialValue:
                              bookData.publicationYear?.toString() ?? '',
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(
                                  context,
                                )!.original_publication_year,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            hintText: AppLocalizations.of(context)!.eg_2020,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _bundleBooks[index]
                                  .publicationYear = int.tryParse(value);
                            });
                            _notifyChange();
                          },
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ],
    );
  }
}
