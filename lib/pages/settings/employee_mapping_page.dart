import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../../services/employee_mapping_service.dart';
import '../../utils/app_logger.dart';

class EmployeeMappingPage extends StatefulWidget {
  const EmployeeMappingPage({super.key});

  @override
  State<EmployeeMappingPage> createState() => _EmployeeMappingPageState();
}

class _EmployeeMappingPageState extends State<EmployeeMappingPage> {
  Map<String, String> _mappings = {};
  List<String> _knownNames = [];
  bool _isLoading = true;
  int _titleTapCount = 0;
  bool _showDebugInfo = false;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _activeTab = 0; // 0=all, 1=configured, 2=unconfigured

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    dLog('🔄 Loading data for mapping page...');
    final mappings = await EmployeeMappingService.getAllMappings();
    final known = await EmployeeMappingService.getKnownEmployees();

    known.sort();
    final filteredKnown = known.where((name) => !mappings.containsKey(name)).toList();

    if (mounted) {
      setState(() {
        _mappings = mappings;
        _knownNames = filteredKnown;
        _isLoading = false;
      });
    }
  }

  Map<String, String> get _filteredMappings {
    if (_searchQuery.isEmpty) return _mappings;
    final q = _searchQuery.toLowerCase();
    return Map.fromEntries(
      _mappings.entries.where(
        (e) => e.key.toLowerCase().contains(q) || e.value.toLowerCase().contains(q),
      ),
    );
  }

  List<String> get _filteredKnownNames {
    if (_searchQuery.isEmpty) return _knownNames;
    final q = _searchQuery.toLowerCase();
    return _knownNames.where((n) => n.toLowerCase().contains(q)).toList();
  }

  void _showMappingDialog([String? username, String? displayName]) {
    final displayController = TextEditingController(text: displayName);
    final isEditing = displayName != null && displayName.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_rounded, color: Color(0xFF6366F1), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'แก้ไขชื่อแสดงผล' : 'ระบุชื่อที่ต้องการแสดง',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ชื่อจากระบบ (API)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                username ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ชื่อแสดงผลใหม่',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: displayController,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'เช่น นายสมหมาย ใจดี',
                hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
                filled: true,
                fillColor: const Color(0xFFEFF6FF),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (username != null && displayController.text.isNotEmpty) {
                await EmployeeMappingService.saveMapping(
                  username.trim(),
                  displayController.text.trim(),
                );
                Navigator.pop(context);
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).whenComplete(displayController.dispose);
  }

  Future<void> _deleteMapping(String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ลบการตั้งค่า'),
        content: Text('คุณต้องการกลับไปใช้ชื่อเดิมของ "$username" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ยืนยันการลบ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await EmployeeMappingService.removeMapping(username);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMappings = _filteredMappings;
    final filteredKnownNames = _filteredKnownNames;
    final showConfigured = _activeTab == 0 || _activeTab == 1;
    final showUnconfigured = _activeTab == 0 || _activeTab == 2;

    final hasResults =
        (showConfigured && filteredMappings.isNotEmpty) ||
        (showUnconfigured && filteredKnownNames.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            if (!kDebugMode) return;
            _titleTapCount++;
            if (_titleTapCount >= 5) {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
                _titleTapCount = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_showDebugInfo ? 'เปิดโหมดวิเคราะห์' : 'ปิดโหมดวิเคราะห์')),
              );
            }
          },
          child: const Text(
            'จัดการชื่อพนักงาน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _loadData,
            tooltip: 'โหลดใหม่',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (_showDebugInfo)
                        SliverToBoxAdapter(child: _buildDebugPanel()),
                      if (_activeTab == 0 && _searchQuery.isEmpty)
                        SliverToBoxAdapter(child: _buildInfoBanner()),
                      if (showConfigured && filteredMappings.isNotEmpty) ...[
                        _buildSectionHeader(
                          'ตั้งค่าชื่อแล้ว',
                          filteredMappings.length,
                          const Color(0xFF10B981),
                          Icons.check_circle_rounded,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final username = filteredMappings.keys.elementAt(index);
                                final displayName = filteredMappings[username]!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildMappingCard(username, displayName),
                                );
                              },
                              childCount: filteredMappings.length,
                            ),
                          ),
                        ),
                      ],
                      if (showUnconfigured && filteredKnownNames.isNotEmpty) ...[
                        _buildSectionHeader(
                          'ยังไม่ได้ตั้งชื่อ',
                          filteredKnownNames.length,
                          const Color(0xFFF59E0B),
                          Icons.pending_rounded,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final username = filteredKnownNames[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildApiNameCard(username),
                                );
                              },
                              childCount: filteredKnownNames.length,
                            ),
                          ),
                        ),
                      ],
                      if (!hasResults)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _searchQuery.isNotEmpty
                              ? _buildNoSearchResults()
                              : _buildEmptyState(),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndTabs() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหรือ ID ระบบ...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab(0, 'ทั้งหมด', _mappings.length + _knownNames.length, const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                _buildTab(1, 'ตั้งค่าแล้ว', _mappings.length, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildTab(2, 'ยังไม่ตั้งค่า', _knownNames.length, const Color(0xFFF59E0B)),
              ],
            ),
          ),
          const SizedBox(height: 1),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count, Color color) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? color : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? color : const Color(0xFF94A3B8),
                ),
                child: Text(label),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isActive ? color : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'รายชื่อพนักงานจะขึ้นแสดงเองเมื่อมีการบันทึกบัญชี\nแตะรายชื่อเพื่อตั้งชื่อที่ต้องการแสดงผล',
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    String origin = 'Unknown';
    if (kIsWeb) {
      try {
        origin = Uri.base.toString();
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🛠 โหมดวิเคราะห์', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          const Divider(color: Colors.white24),
          _debugItem('Origin URL', origin),
          _debugItem('Mappings Count', _mappings.length.toString()),
          _debugItem('Known Count', _knownNames.length.toString()),
          const SizedBox(height: 8),
          const Text('Raw Storage Keys:', style: TextStyle(color: Colors.white54, fontSize: 10)),
          Text(_mappings.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _debugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color accentColor, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                '$count คน',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(Icons.badge_outlined, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text(
            'ไม่พบข้อมูลรายชื่อพนักงาน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          const Text(
            'รายชื่อจะแสดงขึ้นมาโดยอัตโนมัติ\nเมื่อมีการโหลดข้อมูลในหน้า KPI Journal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          const Text(
            'ไม่พบผลลัพธ์',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            'ไม่พบชื่อหรือ ID ที่ตรงกับ "$_searchQuery"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingCard(String username, String displayName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMappingDialog(username, displayName),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0] : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            username,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconButton(
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: () => _showMappingDialog(username, displayName),
                  ),
                  const SizedBox(width: 6),
                  _IconButton(
                    icon: Icons.delete_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => _deleteMapping(username),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiNameCard(String username) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: () => _showMappingDialog(username),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
        ),
        title: Text(
          username,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
        subtitle: const Text(
          'ยังไม่ได้ตั้งชื่อแสดงผล',
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ตั้งชื่อ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
              ),
              SizedBox(width: 3),
              Icon(Icons.add_rounded, size: 13, color: Color(0xFF6366F1)),
            ],
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
