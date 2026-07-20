import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/recipe.dart';
import '../models/recipe_page.dart';
import '../providers/recipe_provider.dart';
import '../widgets/app_theme.dart';
import 'package:provider/provider.dart';
import 'recipe_detail_screen.dart';

class RecipeFlowScreen extends StatefulWidget {
  final Recipe recipe;
  final List<RecipePage> pages;

  const RecipeFlowScreen({super.key, required this.recipe, required this.pages});

  @override
  State<RecipeFlowScreen> createState() => _RecipeFlowScreenState();
}

class _RecipeFlowScreenState extends State<RecipeFlowScreen> {
  late List<RecipePage> _pages;
  final GlobalKey _canvasKey = GlobalKey();
  
  // Connection state
  String? _selectedSourceNodeId;
  
  // Viewport
  final TransformationController _transformController = TransformationController();

  static const double nodeWidth = 150;
  static const double nodeHeight = 60;

  @override
  void initState() {
    super.initState();
    // Deep copy to not affect original until saved
    _pages = widget.pages.map((p) => p.copyWith()).toList();
    
    // Auto-layout if no coordinates
    double startX = 100.0;
    double startY = 100.0;
    for (int i = 0; i < _pages.length; i++) {
      if (_pages[i].uiX == null || _pages[i].uiY == null) {
        _pages[i].uiX = startX + (i * 200.0);
        _pages[i].uiY = startY + (i % 2 == 0 ? 0 : 50.0);
      }
    }
  }

  void _saveFlow() {
    if (_pages.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Validation 1: Check for multiple incoming connections
    Map<String, int> incomingCounts = {};
    for (var page in _pages) {
      if (page.nextId != null) {
        incomingCounts[page.nextId!] = (incomingCounts[page.nextId!] ?? 0) + 1;
      }
    }
    
    for (var entry in incomingCounts.entries) {
      if (entry.value > 1) {
        final duplicatePage = _pages.firstWhere((p) => p.id == entry.key);
        _showError('Giai đoạn "${duplicatePage.name}" đang được nối tới 2 lần! Mỗi giai đoạn chỉ được nhận 1 đường nối.');
        return;
      }
    }

    // Validation 2: Find start node and check for disconnected components
    final startNodes = _pages.where((p) => !incomingCounts.containsKey(p.id)).toList();
    if (startNodes.isEmpty) {
      _showError('Quy trình không hợp lệ (bị vòng lặp khép kín, không có điểm bắt đầu).');
      return;
    }
    if (startNodes.length > 1 && _pages.length > 1) {
      _showError('Có giai đoạn chưa được kết nối! Vui lòng nối tất cả thành một luồng duy nhất.');
      return;
    }

    // Validation 3: Traverse to ensure all nodes are reachable in a single path
    List<RecipePage> orderedPages = [];
    Set<String> visited = {};
    var current = startNodes.first;
    
    while (true) {
      orderedPages.add(current);
      visited.add(current.id);
      
      if (current.nextId == null) break;
      
      final nextNodes = _pages.where((p) => p.id == current.nextId);
      if (nextNodes.isEmpty) break;
      
      current = nextNodes.first;
      if (visited.contains(current.id)) {
        _showError('Quy trình bị vòng lặp tại giai đoạn "${current.name}".');
        return;
      }
    }

    if (visited.length < _pages.length) {
      _showError('Có giai đoạn chưa được nối vào luồng chính. Vui lòng kiểm tra lại.');
      return;
    }

    // All validations passed. Save.
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final updatedRecipe = widget.recipe.copyWith(pages: orderedPages);
    recipeProvider.updateRecipe(updatedRecipe);
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: updatedRecipe.id),
      ),
      (route) => route.isFirst,
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: context.colors.warning),
            const SizedBox(width: 8),
            Text('Lỗi kết nối', style: context.textTheme.titleLarge),
          ],
        ),
        content: Text(message, style: context.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background like draw.io
      appBar: AppBar(
        title: const Text('Sắp xếp bước'),
        backgroundColor: context.colors.surface,
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(5000),
            minScale: 0.1,
            maxScale: 2.0,
            child: Container(
              key: _canvasKey,
              width: 5000,
              height: 5000,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
              ),
              child: CustomPaint(
                painter: _GridAndConnectionPainter(_pages, nodeWidth, nodeHeight),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ..._pages.map((page) => _buildNode(page)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  elevation: 6,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 24),
                label: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _saveFlow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(RecipePage page) {
    return Positioned(
      left: page.uiX!,
      top: page.uiY!,
      child: GestureDetector(
        onTap: () => _handleNodeTap(page.id),
        onDoubleTap: () {
          setState(() {
            page.nextId = null;
            if (_selectedSourceNodeId == page.id) _selectedSourceNodeId = null;
          });
        },
        onLongPress: () {
          setState(() {
            page.nextId = null;
            if (_selectedSourceNodeId == page.id) _selectedSourceNodeId = null;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            // Apply scale factor for smooth dragging
            final scale = _transformController.value.getMaxScaleOnAxis();
            page.uiX = page.uiX! + details.delta.dx / scale;
            page.uiY = page.uiY! + details.delta.dy / scale;
          });
        },
        child: Container(
          width: nodeWidth,
          height: nodeHeight,
          decoration: BoxDecoration(
            color: _selectedSourceNodeId == page.id 
                ? context.colors.primary.withValues(alpha: 0.2) 
                : context.colors.surfaceElevated,
            border: Border.all(
              color: _selectedSourceNodeId == page.id ? context.colors.primary : context.colors.primary.withValues(alpha: 0.5), 
              width: 2
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _selectedSourceNodeId == page.id 
                ? [BoxShadow(color: context.colors.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)]
                : const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    page.name,
                    style: context.textTheme.labelLarge!.copyWith(color: context.colors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Type icon
              if (page.type == 'timer')
                Positioned(
                  top: 4,
                  left: 4,
                  child: Icon(Icons.timer, size: 12, color: context.colors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNodeTap(String tappedId) {
    setState(() {
      if (_selectedSourceNodeId == null) {
        _selectedSourceNodeId = tappedId;
      } else if (_selectedSourceNodeId == tappedId) {
        _selectedSourceNodeId = null; // deselect
      } else {
        final sourcePage = _pages.firstWhere((p) => p.id == _selectedSourceNodeId);
        if (sourcePage.nextId == tappedId) {
          // Đã kết nối với nhau rồi thì xoá liên kết (Toggle)
          sourcePage.nextId = null;
        } else {
          sourcePage.nextId = tappedId;
        }
        _selectedSourceNodeId = null;
      }
    });
  }
}

class _GridAndConnectionPainter extends CustomPainter {
  final List<RecipePage> pages;
  final double nodeWidth;
  final double nodeHeight;

  _GridAndConnectionPainter(this.pages, this.nodeWidth, this.nodeHeight);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid (Dots)
    final Paint dotPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;
    
    // Just draw a small area of dots to avoid performance hit, or draw lines.
    // For simplicity, we skip grid drawing to maintain 60fps on web, Draw.io often uses a background image.

    // 2. Draw Connections
    final Paint linePaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final Paint arrowPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.fill;

    for (final page in pages) {
      if (page.nextId != null) {
        final targetPage = pages.firstWhere((p) => p.id == page.nextId, orElse: () => page);
        if (targetPage.id == page.id) continue;

        final centerA = Offset(page.uiX! + nodeWidth / 2, page.uiY! + nodeHeight / 2);
        final centerB = Offset(targetPage.uiX! + nodeWidth / 2, targetPage.uiY! + nodeHeight / 2);

        final start = _getPerimeterPoint(centerA, centerB, nodeWidth, nodeHeight);
        final end = _getPerimeterPoint(centerB, centerA, nodeWidth, nodeHeight);
        
        _drawStraightLine(canvas, start, end, linePaint, arrowPaint);
      }
    }
  }

  Offset _getPerimeterPoint(Offset center, Offset target, double width, double height) {
    final double dx = target.dx - center.dx;
    final double dy = target.dy - center.dy;
    if (dx == 0 && dy == 0) return center;
    
    final double hw = width / 2;
    final double hh = height / 2;
    
    final double scaleX = dx.abs() > 0 ? hw / dx.abs() : double.infinity;
    final double scaleY = dy.abs() > 0 ? hh / dy.abs() : double.infinity;
    
    final double scale = math.min(scaleX, scaleY);
    
    return Offset(center.dx + dx * scale, center.dy + dy * scale);
  }

  void _drawStraightLine(Canvas canvas, Offset start, Offset end, Paint linePaint, Paint arrowPaint) {
    final Path path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, linePaint);
    
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double angle = math.atan2(dy, dx);
    
    final Path arrowPath = Path();
    // Arrow tip
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - 14 * math.cos(angle - math.pi / 7),
      end.dy - 14 * math.sin(angle - math.pi / 7),
    );
    arrowPath.lineTo(
      end.dx - 14 * math.cos(angle + math.pi / 7),
      end.dy - 14 * math.sin(angle + math.pi / 7),
    );
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _GridAndConnectionPainter oldDelegate) => true;
}
