import 'package:flutter/material.dart';
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
  
  // Dragging connection state
  String? _draggingFromNodeId;
  Offset? _dragCurrentPos;
  
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
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    
    // Sort pages based on nextId to determine the final order
    Set<String> targetIds = _pages.where((p) => p.nextId != null).map((p) => p.nextId!).toSet();
    List<RecipePage> startNodes = _pages.where((p) => !targetIds.contains(p.id)).toList();
    
    List<RecipePage> orderedPages = [];
    Set<String> visited = {};
    
    for (var node in startNodes) {
      var current = node;
      while (!visited.contains(current.id)) {
        orderedPages.add(current);
        visited.add(current.id);
        if (current.nextId != null) {
          // Find the next node
          var matches = _pages.where((p) => p.id == current.nextId);
          if (matches.isEmpty) break;
          current = matches.first;
        } else {
          break;
        }
      }
    }
    
    // Add any unvisited nodes (e.g. standalone nodes or cycles)
    for (var page in _pages) {
      if (!visited.contains(page.id)) {
        orderedPages.add(page);
      }
    }

    final updatedRecipe = widget.recipe.copyWith(pages: orderedPages);
    recipeProvider.updateRecipe(updatedRecipe);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: updatedRecipe.id),
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
                painter: _GridAndConnectionPainter(_pages, _draggingFromNodeId, _dragCurrentPos, nodeWidth, nodeHeight),
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
            color: context.colors.surfaceElevated,
            border: Border.all(color: context.colors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
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
              // Port for outgoing connection
              Positioned(
                right: -16,
                top: nodeHeight / 2 - 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () {
                    setState(() {
                      page.nextId = null;
                    });
                  },
                  onPanStart: (details) {
                    setState(() {
                      _draggingFromNodeId = page.id;
                      _dragCurrentPos = _getLocalPos(details.globalPosition);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _dragCurrentPos = _getLocalPos(details.globalPosition);
                    });
                  },
                  onPanEnd: (details) {
                    _handleConnectionDrop(page.id, details.globalPosition);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Input area visualization
              Positioned(
                left: -6,
                top: nodeHeight / 2 - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.colors.textHint,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Offset _getLocalPos(Offset globalPos) {
    RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPos);
  }

  void _handleConnectionDrop(String sourceId, Offset globalPos) {
    final localPos = _getLocalPos(globalPos);
    String? targetId;
    
    for (final page in _pages) {
      if (page.id == sourceId) continue;
      if (localPos.dx >= page.uiX! - 20 && localPos.dx <= page.uiX! + nodeWidth + 20 &&
          localPos.dy >= page.uiY! - 20 && localPos.dy <= page.uiY! + nodeHeight + 20) {
        targetId = page.id;
        break;
      }
    }

    setState(() {
      _draggingFromNodeId = null;
      _dragCurrentPos = null;
      
      if (targetId != null) {
        final sourcePage = _pages.firstWhere((p) => p.id == sourceId);
        sourcePage.nextId = targetId;
      } else {
        final sourcePage = _pages.firstWhere((p) => p.id == sourceId);
        sourcePage.nextId = null;
      }
    });
  }
}

class _GridAndConnectionPainter extends CustomPainter {
  final List<RecipePage> pages;
  final String? draggingNodeId;
  final Offset? dragPos;
  final double nodeWidth;
  final double nodeHeight;

  _GridAndConnectionPainter(this.pages, this.draggingNodeId, this.dragPos, this.nodeWidth, this.nodeHeight);

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

        final start = Offset(page.uiX! + nodeWidth, page.uiY! + nodeHeight / 2);
        final end = Offset(targetPage.uiX!, targetPage.uiY! + nodeHeight / 2);
        
        _drawOrthogonalLine(canvas, start, end, linePaint, arrowPaint);
      }
    }

    // 3. Draw Dragging Line
    if (draggingNodeId != null && dragPos != null) {
      final sourcePage = pages.firstWhere((p) => p.id == draggingNodeId);
      final start = Offset(sourcePage.uiX! + nodeWidth, sourcePage.uiY! + nodeHeight / 2);
      
      _drawOrthogonalLine(canvas, start, dragPos!, linePaint..color = Colors.green, arrowPaint..color = Colors.green);
    }
  }

  void _drawOrthogonalLine(Canvas canvas, Offset start, Offset end, Paint linePaint, Paint arrowPaint) {
    final Path path = Path();
    path.moveTo(start.dx, start.dy);
    
    double midX = start.dx + (end.dx - start.dx) / 2;
    
    if (end.dx < start.dx + 40) {
      midX = start.dx + 30;
      path.lineTo(midX, start.dy);
      path.lineTo(midX, start.dy + nodeHeight + 20); // Go down around
      double backX = end.dx - 30;
      path.lineTo(backX, start.dy + nodeHeight + 20);
      path.lineTo(backX, end.dy);
      path.lineTo(end.dx, end.dy);
    } else {
      path.lineTo(midX, start.dy);
      path.lineTo(midX, end.dy);
      path.lineTo(end.dx, end.dy);
    }
    
    canvas.drawPath(path, linePaint);
    
    final Path arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(end.dx - 10, end.dy - 6);
    arrowPath.lineTo(end.dx - 10, end.dy + 6);
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _GridAndConnectionPainter oldDelegate) => true;
}
