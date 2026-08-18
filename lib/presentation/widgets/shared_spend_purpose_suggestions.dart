import 'package:borrow_ledger/data/models/shared_spend_purpose_model.dart';
import 'package:borrow_ledger/data/repositories/shared_spend_purpose_repository.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SharedSpendPurposeSuggestions extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onPurposeSelected;

  const SharedSpendPurposeSuggestions({
    super.key,
    required this.controller,
    this.onPurposeSelected,
  });

  @override
  State<SharedSpendPurposeSuggestions> createState() =>
      _SharedSpendPurposeSuggestionsState();
}

class _SharedSpendPurposeSuggestionsState
    extends State<SharedSpendPurposeSuggestions> {
  final SharedSpendPurposeRepository _repository =
      SharedSpendPurposeRepository();
  List<SharedSpendPurposeModel> _suggestions = [];
  bool _isLoading = true;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text.trim().isNotEmpty && !_showSuggestions) return;
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final text = widget.controller.text.trim();
      final purposes = text.isEmpty
          ? await _repository.getTopPurposes(limit: 20)
          : await _repository.searchPurposes(text, limit: 20);

      if (!mounted) return;
      setState(() {
        _suggestions = purposes;
        _isLoading = false;
        _showSuggestions = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  void _selectPurpose(SharedSpendPurposeModel purpose) {
    widget.controller.text = purpose.purpose;
    setState(() => _showSuggestions = false);
    widget.onPurposeSelected?.call();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showSuggestions = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((_suggestions.isEmpty && !_isLoading) ||
        (_suggestions.length == 1 &&
            _suggestions.first.purpose == widget.controller.text.trim())) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 13,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              tr.suggestions,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (!_isLoading && _suggestions.isNotEmpty)
              Text(
                '  (${tr.tapToUse})',
                style: TextStyle(
                  fontSize: 10.5,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        if (_isLoading) _buildLoadingShimmer() else _buildSuggestionsList(),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 76,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) =>
            _buildSuggestionChip(_suggestions[index]),
      ),
    );
  }

  Widget _buildSuggestionChip(SharedSpendPurposeModel purpose) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isFrequent = purpose.usageCount >= 1;
    final chipColor = colorScheme.secondary;
    final borderColor = isFrequent
        ? chipColor.withValues(alpha: 0.28)
        : isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isFrequent
            ? chipColor.withValues(alpha: isDark ? 0.16 : 0.08)
            : colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: () => _selectPurpose(purpose),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  purpose.purpose,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isFrequent ? FontWeight.w600 : FontWeight.w500,
                    color: isFrequent ? chipColor : colorScheme.onSurface,
                  ),
                ),
                if (isFrequent) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${purpose.usageCount}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: chipColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
