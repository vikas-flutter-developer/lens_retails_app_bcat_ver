import 'package:flutter/material.dart';

/// A widget that automatically switches between Row and Column layout
/// based on available width. This solves overflow issues systematically.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = 600,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < breakpoint;
        
        if (isNarrow) {
          // Use Column for narrow screens
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _addSpacing(children, isVertical: true),
          );
        }
        
        // Use Row for wide screens with Expanded wrappers
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: _addSpacing(
            children.map((child) => Expanded(child: child)).toList(),
            isVertical: false,
          ),
        );
      },
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets, {required bool isVertical}) {
    if (widgets.isEmpty) return widgets;
    
    final spacer = isVertical 
        ? SizedBox(height: spacing) 
        : SizedBox(width: spacing);
    
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(spacer);
      }
    }
    return result;
  }
}
