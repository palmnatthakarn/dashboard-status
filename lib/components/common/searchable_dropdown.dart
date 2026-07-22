import 'package:flutter/material.dart';

import 'user_avatar.dart';

/// A single item in a [SearchableDropdown].
class SearchableDropdownItem {
  final String id;
  final String label;
  final String? subtitle;

  const SearchableDropdownItem({
    required this.id,
    required this.label,
    this.subtitle,
  });
}

/// A compact filter button that opens an overlay dropdown with search.
///
/// Usage:
/// ```dart
/// SearchableDropdown(
///   fieldLabel: 'ร้าน',
///   allLabel: 'ทุกร้าน',
///   searchHint: 'ค้นหาร้าน...',
///   icon: Icons.store_rounded,
///   items: shops.map((s) => SearchableDropdownItem(id: s.id, label: s.name)).toList(),
///   selectedId: _selectedShopId,
///   onChanged: (id, label) => setState(() { _selectedId = id; _selectedName = label; }),
/// )
/// ```
class SearchableDropdown extends StatefulWidget {
  /// Short label displayed above the selected value (e.g. "ร้าน").
  final String fieldLabel;

  /// Label shown when nothing is selected (e.g. "ทุกร้าน").
  final String allLabel;

  /// Placeholder inside the search field.
  final String searchHint;

  /// Icon shown on the left side of the trigger button.
  final IconData icon;

  final List<SearchableDropdownItem> items;

  /// The currently selected item id, or null for "all".
  final String? selectedId;

  /// Called when the user picks an option.
  /// `id` and `label` are both null when the user selects the "all" option.
  final void Function(String? id, String? label) onChanged;

  /// Accent colour used for the active/selected state.
  final Color accentColor;

  /// Width of the trigger button. Defaults to 200.
  final double width;

  /// Width of the dropdown panel. Defaults to 280.
  final double dropdownWidth;

  const SearchableDropdown({
    super.key,
    required this.fieldLabel,
    required this.allLabel,
    required this.searchHint,
    required this.icon,
    required this.items,
    required this.selectedId,
    required this.onChanged,
    this.accentColor = const Color(0xFF3B82F6),
    this.width = 200,
    this.dropdownWidth = 280,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isOpen = false;
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _searchFocusNode.unfocus();
    final overlay = _overlay;
    if (overlay != null && overlay.mounted) {
      overlay.remove();
    }
    _overlay = null;
    _isOpen = false;
  }

  void _toggle() {
    if (_isOpen) {
      _removeOverlay();
      if (mounted) setState(() {});
    } else {
      _searchController.clear();
      _overlay = _buildOverlay();
      final overlayState = Overlay.maybeOf(context);
      if (overlayState == null) return;
      overlayState.insert(_overlay!);
      _isOpen = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
          if (mounted) setState(() {});
        },
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 48),
              child: Material(
                elevation: 8,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                child: _SearchableDropdownPanel(
                  items: widget.items,
                  selectedId: widget.selectedId,
                  allLabel: widget.allLabel,
                  searchHint: widget.searchHint,
                  searchController: _searchController,
                  focusNode: _searchFocusNode,
                  width: widget.dropdownWidth,
                  accentColor: widget.accentColor,
                  onSelect: (id, label) {
                    widget.onChanged(id, label);
                    _removeOverlay();
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        widget.selectedId != null && widget.selectedId!.isNotEmpty;
    final selectedLabel = hasSelection
        ? (widget.items
                  .where((i) => i.id == widget.selectedId)
                  .firstOrNull
                  ?.label ??
              widget.allLabel)
        : widget.allLabel;

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (_isOpen || hasSelection)
                ? widget.accentColor.withValues(alpha: 0.08)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (_isOpen || hasSelection)
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: (_isOpen || hasSelection)
                    ? widget.accentColor
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.fieldLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: (_isOpen || hasSelection)
                            ? widget.accentColor
                            : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      selectedLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: (_isOpen || hasSelection)
                      ? widget.accentColor
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dropdown panel ───────────────────────────────────────────────────────────

class _SearchableDropdownPanel extends StatefulWidget {
  final List<SearchableDropdownItem> items;
  final String? selectedId;
  final String allLabel;
  final String searchHint;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final double width;
  final Color accentColor;
  final void Function(String? id, String? label) onSelect;

  const _SearchableDropdownPanel({
    required this.items,
    required this.selectedId,
    required this.allLabel,
    required this.searchHint,
    required this.searchController,
    required this.focusNode,
    required this.width,
    required this.accentColor,
    required this.onSelect,
  });

  @override
  State<_SearchableDropdownPanel> createState() =>
      _SearchableDropdownPanelState();
}

class _SearchableDropdownPanelState extends State<_SearchableDropdownPanel> {
  String _query = '';
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) {
        setState(() => _query = widget.searchController.text.toLowerCase());
      }
    };
    widget.searchController.addListener(_listener);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
              .where(
                (i) =>
                    i.label.toLowerCase().contains(_query) ||
                    (i.subtitle?.toLowerCase().contains(_query) ?? false),
              )
              .toList();

    return Container(
      width: widget.width,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: widget.searchController,
              focusNode: widget.focusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildOption(
            null,
            widget.allLabel,
            isSelected: widget.selectedId == null || widget.selectedId!.isEmpty,
          ),
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return _buildOption(
                  item.id,
                  item.label,
                  subtitle: item.subtitle,
                  isSelected: item.id == widget.selectedId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    String? id,
    String label, {
    String? subtitle,
    bool isSelected = false,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      selected: isSelected,
      selectedTileColor: widget.accentColor.withValues(alpha: 0.08),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? widget.accentColor : const Color(0xFF334155),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_rounded, size: 16, color: widget.accentColor)
          : null,
      onTap: () => widget.onSelect(id, id == null ? null : label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

// ─── Multi-select dropdown ────────────────────────────────────────────────────

/// Like [SearchableDropdown] but allows checking multiple items at once.
class SearchableMultiDropdown extends StatefulWidget {
  final String fieldLabel;
  final String allLabel;
  final String searchHint;
  final IconData icon;
  final List<SearchableDropdownItem> items;
  final List<String> selectedIds;
  final void Function(List<String> ids, List<String> labels) onChanged;
  final Color accentColor;
  final double width;
  final double dropdownWidth;

  // When true (2026-07), the trigger renders each selected item as an
  // inline removable chip (avatar + name + ×) with an "add more" hint
  // trailing them, instead of the default single-line "fieldLabel /
  // N รายการ" summary box. Opt-in via a flag rather than changing the
  // default so the other pages already using SearchableMultiDropdown
  // (KPI, KPI Journal filter sections) keep their existing look.
  final bool chipStyle;

  const SearchableMultiDropdown({
    super.key,
    required this.fieldLabel,
    required this.allLabel,
    required this.searchHint,
    required this.icon,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    this.accentColor = const Color(0xFF3B82F6),
    this.width = 200,
    this.dropdownWidth = 280,
    this.chipStyle = false,
  });

  @override
  State<SearchableMultiDropdown> createState() =>
      _SearchableMultiDropdownState();
}

class _SearchableMultiDropdownState extends State<SearchableMultiDropdown> {
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isOpen = false;
  OverlayEntry? _overlay;
  late List<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List.from(widget.selectedIds);
  }

  @override
  void didUpdateWidget(SearchableMultiDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen) _localSelected = List.from(widget.selectedIds);
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _searchFocusNode.unfocus();
    final overlay = _overlay;
    if (overlay != null && overlay.mounted) {
      overlay.remove();
    }
    _overlay = null;
    _isOpen = false;
  }

  void _toggle() {
    if (_isOpen) {
      _removeOverlay();
      if (mounted) setState(() {});
    } else {
      _localSelected = List.from(widget.selectedIds);
      _searchController.clear();
      _overlay = _buildOverlay();
      final overlayState = Overlay.maybeOf(context);
      if (overlayState == null) return;
      overlayState.insert(_overlay!);
      _isOpen = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _handleToggle(String id) {
    if (_localSelected.contains(id)) {
      _localSelected.remove(id);
    } else {
      _localSelected.add(id);
    }
    _overlay?.markNeedsBuild();
    if (mounted) setState(() {});
    final labels = _localSelected
        .map((i) => widget.items.firstWhere((x) => x.id == i).label)
        .toList();
    widget.onChanged(List.from(_localSelected), labels);
  }

  void _clearAll() {
    _localSelected.clear();
    _overlay?.markNeedsBuild();
    if (mounted) setState(() {});
    widget.onChanged([], []);
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
          if (mounted) setState(() {});
        },
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 48),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: _MultiSelectPanel(
                    items: widget.items,
                    selectedIds: _localSelected,
                    searchHint: widget.searchHint,
                    searchController: _searchController,
                    focusNode: _searchFocusNode,
                    width: widget.dropdownWidth,
                    accentColor: widget.accentColor,
                    onToggle: _handleToggle,
                    onClearAll: _clearAll,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipTrigger() {
    final hasSelection = widget.selectedIds.isNotEmpty;
    final selectedLabels = widget.selectedIds
        .map(
          (id) =>
              widget.items.where((i) => i.id == id).firstOrNull?.label ?? id,
        )
        .toList();
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: widget.width,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (_isOpen || hasSelection)
                ? widget.accentColor.withValues(alpha: 0.04)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (_isOpen || hasSelection)
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: hasSelection
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final visibleCount = _visibleChipCount(
                            context,
                            selectedLabels,
                            constraints.maxWidth,
                          );
                          final hiddenCount =
                              selectedLabels.length - visibleCount;

                          return Row(
                            children: [
                              for (var i = 0; i < visibleCount; i++) ...[
                                Flexible(
                                  child: _buildChip(
                                    selectedLabels[i],
                                    onRemove: () =>
                                        _handleToggle(widget.selectedIds[i]),
                                  ),
                                ),
                                if (i != visibleCount - 1 || hiddenCount > 0)
                                  const SizedBox(width: 6),
                              ],
                              if (hiddenCount > 0) _buildCountChip(hiddenCount),
                            ],
                          );
                        },
                      )
                    : _buildChip(
                        widget.allLabel,
                        onRemove: _toggle,
                        placeholder: true,
                      ),
              ),
              if (hasSelection)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _clearAll,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _visibleChipCount(
    BuildContext context,
    List<String> labels,
    double maxWidth,
  ) {
    if (labels.isEmpty) return 0;
    var usedWidth = 0.0;
    var count = 0;

    for (var i = 0; i < labels.length; i++) {
      final chipWidth = _chipWidth(context, labels[i]);
      final hiddenAfterThis = labels.length - i - 1;
      final reserveWidth = hiddenAfterThis > 0
          ? 6 + _countChipWidth(context, hiddenAfterThis)
          : 0.0;
      final gap = count == 0 ? 0.0 : 6.0;

      if (usedWidth + gap + chipWidth + reserveWidth > maxWidth) break;
      usedWidth += gap + chipWidth;
      count++;
    }

    return count == 0 ? 1 : count;
  }

  double _chipWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: 170);
    return 4 + 16 + 5 + painter.width.clamp(0, 170) + 4 + 13 + 6;
  }

  double _countChipWidth(BuildContext context, int count) {
    final painter = TextPainter(
      text: TextSpan(
        text: '+$count',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return painter.width + 16;
  }

  Widget _buildChip(
    String label, {
    required VoidCallback onRemove,
    bool placeholder = false,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.only(left: 4, right: 6, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: placeholder ? Colors.transparent : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!placeholder) ...[
            UserAvatar(name: label, radius: 8),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: placeholder ? 13 : 12,
                fontWeight: placeholder ? FontWeight.w500 : FontWeight.w600,
                color: placeholder
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (!placeholder) ...[
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: widget.accentColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chipStyle) return _buildChipTrigger();

    final hasSelection = widget.selectedIds.isNotEmpty;
    final displayLabel = !hasSelection
        ? widget.allLabel
        : widget.selectedIds.length == 1
        ? (widget.items
                  .where((i) => i.id == widget.selectedIds.first)
                  .firstOrNull
                  ?.label ??
              widget.allLabel)
        : '${widget.selectedIds.length} รายการ';

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (_isOpen || hasSelection)
                ? widget.accentColor.withValues(alpha: 0.08)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (_isOpen || hasSelection)
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: (_isOpen || hasSelection)
                    ? widget.accentColor
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.fieldLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: (_isOpen || hasSelection)
                            ? widget.accentColor
                            : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      displayLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasSelection)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _clearAll,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: widget.accentColor,
                    ),
                  ),
                )
              else
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: (_isOpen || hasSelection)
                        ? widget.accentColor
                        : const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Multi-select panel ───────────────────────────────────────────────────────

class _MultiSelectPanel extends StatefulWidget {
  final List<SearchableDropdownItem> items;
  final List<String> selectedIds;
  final String searchHint;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final double width;
  final Color accentColor;
  final void Function(String id) onToggle;
  final VoidCallback onClearAll;

  const _MultiSelectPanel({
    required this.items,
    required this.selectedIds,
    required this.searchHint,
    required this.searchController,
    required this.focusNode,
    required this.width,
    required this.accentColor,
    required this.onToggle,
    required this.onClearAll,
  });

  @override
  State<_MultiSelectPanel> createState() => _MultiSelectPanelState();
}

class _MultiSelectPanelState extends State<_MultiSelectPanel> {
  String _query = '';
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) {
        setState(() => _query = widget.searchController.text.toLowerCase());
      }
    };
    widget.searchController.addListener(_listener);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
              .where(
                (i) =>
                    i.label.toLowerCase().contains(_query) ||
                    (i.subtitle?.toLowerCase().contains(_query) ?? false),
              )
              .toList();
    final selectedCount = widget.selectedIds.length;

    return Container(
      width: widget.width,
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'เลือก $selectedCount รายการ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClearAll,
                    child: Text(
                      'ล้างทั้งหมด',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: widget.searchController,
              focusNode: widget.focusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                final isSelected = widget.selectedIds.contains(item.id);
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  selected: isSelected,
                  selectedTileColor: widget.accentColor.withValues(alpha: 0.07),
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.accentColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? widget.accentColor
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? widget.accentColor
                          : const Color(0xFF334155),
                    ),
                  ),
                  subtitle: item.subtitle != null
                      ? Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        )
                      : null,
                  onTap: () => widget.onToggle(item.id),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
