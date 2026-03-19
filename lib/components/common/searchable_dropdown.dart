import 'package:flutter/material.dart';

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
    _overlay?.remove();
    _overlay = null;
    _isOpen = false;
  }

  void _toggle() {
    if (_isOpen) {
      _removeOverlay();
      setState(() {});
    } else {
      _searchController.clear();
      _overlay = _buildOverlay();
      Overlay.of(context).insert(_overlay!);
      _isOpen = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_searchFocusNode.canRequestFocus) _searchFocusNode.requestFocus();
      });
    }
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
          setState(() {});
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
                    setState(() {});
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

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() {
      if (mounted) {
        setState(() => _query = widget.searchController.text.toLowerCase());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where((i) =>
                i.label.toLowerCase().contains(_query) ||
                (i.subtitle?.toLowerCase().contains(_query) ?? false))
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
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
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
            isSelected:
                widget.selectedId == null || widget.selectedId!.isEmpty,
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
          color: isSelected
              ? widget.accentColor
              : const Color(0xFF334155),
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]))
          : null,
      trailing: isSelected
          ? Icon(Icons.check_rounded, size: 16, color: widget.accentColor)
          : null,
      onTap: () => widget.onSelect(id, id == null ? null : label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
