import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kV2Bg = Color(0xFFFDF8F6);
const _kV2Primary = Color(0xFF43102B);
const _kV2Sub = Color(0xFF514348);
const _kV2Text = Color(0xFF1C1B1A);
const _kV2InputBorder = Color(0xFF6B7280);

class TBRLimitSetting extends StatefulWidget {
  final bool useNewUi;

  const TBRLimitSetting({super.key, this.useNewUi = false});

  @override
  State<TBRLimitSetting> createState() => _TBRLimitSettingState();
}

class _TBRLimitSettingState extends State<TBRLimitSetting> {
  int _tbrLimit = 5; // Default value
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTBRLimit();
  }

  Future<void> _loadTBRLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final limit = prefs.getInt('tbr_limit') ?? 5;
    setState(() {
      _tbrLimit = limit;
      _controller.text = limit.toString();
    });
  }

  Future<void> _saveTBRLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tbr_limit', limit);
    setState(() {
      _tbrLimit = limit;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tbr_limit_set_to(limit.toString()),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _showEditDialog() {
    _controller.text = _tbrLimit.toString();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final currentValue = int.tryParse(_controller.text);
              final isValid =
                  currentValue != null &&
                  currentValue > 0 &&
                  currentValue <= 200;
              String? errorText;

              if (_controller.text.isNotEmpty) {
                if (currentValue == null || currentValue <= 0) {
                  errorText =
                      AppLocalizations.of(context)!.please_enter_valid_number;
                } else if (currentValue > 200) {
                  errorText =
                      AppLocalizations.of(context)!.maximum_limit_200_books;
                }
              }

              if (!widget.useNewUi) {
                return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.set_tbr_limit),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.max_tbr_books_description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.tbr_limit,
                          border: const OutlineInputBorder(),
                          suffixText: AppLocalizations.of(context)!.books,
                          helperText:
                              AppLocalizations.of(context)!.range_1_200_books,
                          errorText: errorText,
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed:
                          isValid
                              ? () {
                                _saveTBRLimit(currentValue);
                                Navigator.pop(context);
                              }
                              : null,
                      child: Text(AppLocalizations.of(context)!.save),
                    ),
                  ],
                );
              }

              return AlertDialog(
                backgroundColor: _kV2Bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                title: Row(
                  children: [
                    const Icon(
                      Icons.bookmark_add,
                      color: _kV2Primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.set_tbr_limit,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _kV2Primary,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.max_tbr_books_description,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: _kV2Sub,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {});
                      },
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: _kV2Text,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: AppLocalizations.of(context)!.tbr_limit,
                        suffixText: AppLocalizations.of(context)!.books,
                        helperText:
                            AppLocalizations.of(context)!.range_1_200_books,
                        errorText: errorText,
                        helperStyle: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: _kV2Sub,
                        ),
                        labelStyle: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          color: _kV2Primary,
                        ),
                        floatingLabelStyle: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: _kV2Primary,
                        ),
                        prefixIcon: const Icon(
                          Icons.format_list_numbered,
                          color: _kV2Primary,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _kV2InputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _kV2InputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: _kV2Primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red.shade400),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.red.shade400,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _kV2Primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isValid
                                  ? () {
                                    _saveTBRLimit(currentValue);
                                    Navigator.pop(context);
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kV2Primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _kV2Primary.withValues(
                              alpha: 0.3,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.save,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!widget.useNewUi) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(
            Icons.bookmark_add,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l10n.tbr_limit),
          subtitle: Text(l10n.max_tbr_books_subtitle(_tbrLimit.toString())),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
          onTap: _showEditDialog,
        ),
      );
    }

    return GestureDetector(
      onTap: _showEditDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1A27231E)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kV2Primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kV2Primary.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.bookmark_add,
                color: _kV2Primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tbr_limit,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kV2Text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.max_tbr_books_subtitle(_tbrLimit.toString()),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: _kV2Sub,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: _kV2Primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Helper function to get TBR limit from SharedPreferences
Future<int> getTBRLimit() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('tbr_limit') ?? 5;
}
