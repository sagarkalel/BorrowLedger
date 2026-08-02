import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../data/models/udhari_quantity_model.dart';
import '../../data/repositories/udhari_quantity_repository.dart';

class UdhariQuantitySuggestions extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onQuantitySelected;

  const UdhariQuantitySuggestions({
    super.key,
    required this.controller,
    this.onQuantitySelected,
  });

  @override
  State<UdhariQuantitySuggestions> createState() =>
      _UdhariQuantitySuggestionsState();
}

class _UdhariQuantitySuggestionsState extends State<UdhariQuantitySuggestions> {
  final UdhariQuantityRepository _repository = UdhariQuantityRepository();
  List<UdhariQuantityModel> _suggestions = [];
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
    if (text.isNotEmpty && !_showSuggestions) return;
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final text = widget.controller.text.trim();
      final quantities = text.isEmpty
          ? await _repository.getTopQuantities(limit: 20)
          : await _repository.searchQuantities(text, limit: 20);

      if (mounted) {
        setState(() {
          _suggestions = quantities;
          _isLoading = false;
          _showSuggestions = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _selectQuantity(UdhariQuantityModel quantity) {
    widget.controller.text = quantity.quantity;
    setState(() => _showSuggestions = false);
    widget.onQuantitySelected?.call();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if ((_suggestions.isEmpty && !_isLoading) ||
        (_suggestions.length == 1 &&
            _suggestions.first.quantity == widget.controller.text.trim())) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tr = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
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
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 8),
            width: 62,
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
        itemBuilder: (context, index) {
          return _buildSuggestionChip(_suggestions[index]);
        },
      ),
    );
  }

  Widget _buildSuggestionChip(UdhariQuantityModel quantity) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isFrequent = quantity.usageCount >= 1;
    final borderColor = isFrequent
        ? colorScheme.primary.withValues(alpha: 0.28)
        : isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isFrequent
            ? colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.08)
            : colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: () => _selectQuantity(quantity),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quantity.quantity,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isFrequent ? FontWeight.w600 : FontWeight.w500,
                    color: isFrequent
                        ? colorScheme.primary
                        : colorScheme.onSurface,
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
                      color: colorScheme.surface.withValues(
                        alpha: isDark ? 0.2 : 0.75,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${quantity.usageCount > 10 ? "10+" : quantity.usageCount}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
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
