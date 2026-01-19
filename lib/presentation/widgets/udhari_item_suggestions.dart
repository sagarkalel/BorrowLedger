import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/udhari_item_model.dart';
import '../../data/repositories/udhari_item_repository.dart';

class UdhariItemSuggestions extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onItemSelected;

  const UdhariItemSuggestions({
    super.key,
    required this.controller,
    this.onItemSelected,
  });

  @override
  State<UdhariItemSuggestions> createState() => _UdhariItemSuggestionsState();
}

class _UdhariItemSuggestionsState extends State<UdhariItemSuggestions> {
  final UdhariItemRepository _repository = UdhariItemRepository();
  List<UdhariItemModel> _suggestions = [];
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
    final text = widget.controller.text.trim();

    // Hide suggestions if user has typed something and selected an item
    if (text.isNotEmpty && !_showSuggestions) {
      return;
    }

    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final text = widget.controller.text.trim();
      final items = text.isEmpty
          ? await _repository.getTopItems(limit: 20)
          : await _repository.searchItems(text, limit: 20);

      if (mounted) {
        setState(() {
          _suggestions = items;
          _isLoading = false;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _selectItem(UdhariItemModel item) {
    widget.controller.text = item.itemName;
    setState(() => _showSuggestions = false);
    widget.onItemSelected?.call();

    // Re-enable suggestions after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if no suggestions
    if ((_suggestions.isEmpty && !_isLoading) ||
        (_suggestions.length == 1 &&
            _suggestions.first.itemName == widget.controller.text.trim())) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Header
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 2),
            Text(
              tr.suggestions,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            // const Spacer(),
            if (!_isLoading && _suggestions.isNotEmpty)
              Text(
                '  (${tr.tapToUse})',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),

        // Suggestions chips
        if (_isLoading)
          _buildLoadingShimmer(isDark)
        else
          _buildSuggestionsList(isDark),
      ],
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 8),
            width: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList(bool isDark) {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return _buildSuggestionChip(item, isDark);
        },
      ),
    );
  }

  Widget _buildSuggestionChip(UdhariItemModel item, bool isDark) {
    final isFrequent = item.usageCount >= 1;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectItem(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isFrequent
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.15),
                        AppTheme.primaryBlue.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isFrequent
                  ? (isDark ? Colors.grey[800] : Colors.grey[100])
                  : null,
              border: Border.all(
                color: isFrequent
                    ? (isDark
                          ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                          : AppTheme.primaryGreen.withValues(alpha: 0.2))
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item name
                Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isFrequent ? FontWeight.w600 : FontWeight.w500,
                    color: isFrequent
                        ? (isDark
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen)
                        : (isDark ? Colors.grey[300] : Colors.grey[800]),
                  ),
                ),

                // Usage count badge (only for frequent items)
                if (isFrequent == false) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(
                        alpha: isDark ? 0.3 : 0.2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.usageCount > 10 ? "10+" : item.usageCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.primaryGreen
                            : AppTheme.primaryGreen,
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
