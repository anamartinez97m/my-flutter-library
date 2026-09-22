import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/tandem_chapter.dart';
import 'package:myrandomlibrary/model/tandem_reading.dart';
import 'package:myrandomlibrary/repositories/tandem_repository.dart';

/// Bottom sheet for adding or editing a tandem chapter entry.
/// Pops with `true` when the entry was saved.
class TandemChapterForm extends StatefulWidget {
  final TandemReading tandem;
  final Book bookA;
  final Book bookB;
  final TandemChapter? chapter;
  final int nextOrderIndex;

  const TandemChapterForm({
    super.key,
    required this.tandem,
    required this.bookA,
    required this.bookB,
    this.chapter,
    this.nextOrderIndex = 0,
  });

  @override
  State<TandemChapterForm> createState() => _TandemChapterFormState();
}

class _TandemChapterFormState extends State<TandemChapterForm> {
  static const _kBg = Color(0xFFFDF8F6);
  static const _kPrimary = Color(0xFF43102B);
  static const _kSub = Color(0xFF514348);
  static const _kText = Color(0xFF1C1B1A);

  late int _selectedBookId;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  bool _isSaving = false;

  bool get _isEditing => widget.chapter != null;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.chapter?.bookId ?? widget.bookA.bookId!;
    _startController = TextEditingController(
      text: widget.chapter?.startChapter.toString() ?? '',
    );
    _endController = TextEditingController(
      text: widget.chapter?.endChapter.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final start = int.tryParse(_startController.text.trim());
    var end = int.tryParse(_endController.text.trim());

    if (start == null || start < 1) {
      _showError(l10n.chapter_must_be_positive);
      return;
    }
    end ??= start;
    if (end < start) {
      _showError(l10n.invalid_chapter_range);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = TandemRepository(db);
      final chapter = TandemChapter(
        tandemChapterId: widget.chapter?.tandemChapterId,
        tandemId: widget.tandem.tandemId!,
        bookId: _selectedBookId,
        startChapter: start,
        endChapter: end,
        orderIndex: widget.chapter?.orderIndex ?? widget.nextOrderIndex,
        isRead: widget.chapter?.isRead ?? false,
      );
      if (_isEditing) {
        await repository.updateChapter(chapter);
      } else {
        await repository.addChapter(chapter);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('${l10n.error}: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0x80D5C2C7),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEditing ? l10n.edit_step : l10n.add_step,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            size: 24,
                            color: _kText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _BookToggle(
                              name: widget.bookA.name ?? l10n.unknown_title,
                              color: _kPrimary,
                              isSelected:
                                  _selectedBookId == widget.bookA.bookId,
                              onTap:
                                  () => setState(
                                    () =>
                                        _selectedBookId = widget.bookA.bookId!,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BookToggle(
                              name: widget.bookB.name ?? l10n.unknown_title,
                              color: _kPrimary,
                              isSelected:
                                  _selectedBookId == widget.bookB.bookId,
                              onTap:
                                  () => setState(
                                    () =>
                                        _selectedBookId = widget.bookB.bookId!,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ChapterField(
                            controller: _startController,
                            label: l10n.start_chapter,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChapterField(
                            controller: _endController,
                            label: l10n.end_chapter,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        l10n.end_chapter_hint,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          color: _kSub,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  _isEditing ? l10n.edit_step : l10n.add_step,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookToggle extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BookToggle({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFD5C2C7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? color : const Color(0xFF514348),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF1C1B1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _ChapterField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontFamily: 'Manrope', fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          color: Color(0xFF514348),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD5C2C7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD5C2C7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF43102B), width: 1.5),
        ),
      ),
    );
  }
}
