/// Calculator Bottom Sheet
/// In-app calculator for quick amount calculations in Give/Receive screens.
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CalculatorBottomSheet extends StatefulWidget {
  const CalculatorBottomSheet({super.key});

  @override
  State<CalculatorBottomSheet> createState() => _CalculatorBottomSheetState();
}

class _CalculatorBottomSheetState extends State<CalculatorBottomSheet> {
  String _expression = '';
  String _display = '0';
  bool _hasError = false;

  static const _bgColor = Color(0xFF1C1C2E);
  static const _digitColor = Color(0xFF2A2A3E);
  static const _operatorColor = Color(0xFF1A3A2A);
  static const _clearColor = Color(0xFF3A1A1A);

  void _onDigit(String d) {
    setState(() {
      _hasError = false;
      if (_expression == '0' && d != '.') {
        _expression = d;
      } else {
        _expression += d;
      }
      _evaluate();
    });
  }

  void _onOperator(String op) {
    setState(() {
      _hasError = false;
      if (_expression.isEmpty) return;
      // Replace last operator if exists
      final last = _expression[_expression.length - 1];
      if ('+-×÷'.contains(last)) {
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }
    });
  }

  void _onClear() {
    setState(() {
      _expression = '';
      _display = '0';
      _hasError = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        if (_expression.isEmpty) {
          _display = '0';
        } else {
          _evaluate();
        }
      }
    });
  }

  void _onEquals() {
    _evaluate();
  }

  void _evaluate() {
    if (_expression.isEmpty) {
      _display = '0';
      return;
    }

    try {
      // Replace display operators with calculation operators
      String expr = _expression.replaceAll('×', '*').replaceAll('÷', '/');

      // Remove trailing operator
      while (expr.isNotEmpty && '+-*/'.contains(expr[expr.length - 1])) {
        expr = expr.substring(0, expr.length - 1);
      }

      if (expr.isEmpty) {
        _display = '0';
        return;
      }

      final result = _evaluateExpression(expr);
      if (result.isInfinite || result.isNaN) {
        _display = 'خطا';
        _hasError = true;
      } else {
        _display = result.truncateToDouble() == result
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
        // Format with commas
        _display = _formatNumber(_display);
      }
    } catch (_) {
      _display = 'خطا';
      _hasError = true;
    }
  }

  String _formatNumber(String num) {
    final parts = num.split('.');
    final intPart = parts[0];
    final isNeg = intPart.startsWith('-');
    final digits = isNeg ? intPart.substring(1) : intPart;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
      count++;
    }
    String result = buffer.toString().split('').reversed.join();
    if (isNeg) result = '-$result';
    if (parts.length > 1) result += '.${parts[1]}';
    return result;
  }

  double _evaluateExpression(String expr) {
    // Simple expression parser supporting +, -, *, /
    final tokens = <String>[];
    String current = '';

    for (int i = 0; i < expr.length; i++) {
      final c = expr[i];
      if ('+-*/'.contains(c) && current.isNotEmpty) {
        tokens.add(current);
        tokens.add(c);
        current = '';
      } else {
        current += c;
      }
    }
    if (current.isNotEmpty) tokens.add(current);

    // Handle * and / first
    for (int i = 1; i < tokens.length; i += 2) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        final left = double.parse(tokens[i - 1]);
        final right = double.parse(tokens[i + 1]);
        final result = tokens[i] == '*' ? left * right : left / right;
        tokens[i - 1] = result.toString();
        tokens.removeAt(i);
        tokens.removeAt(i);
        i -= 2;
      }
    }

    // Handle + and -
    double result = double.parse(tokens[0]);
    for (int i = 1; i < tokens.length; i += 2) {
      final right = double.parse(tokens[i + 1]);
      if (tokens[i] == '+') {
        result += right;
      } else {
        result -= right;
      }
    }

    return result;
  }

  double? get _currentResult {
    if (_hasError || _display == '0' || _display == 'خطا') return null;
    final clean = _display.replaceAll(',', '');
    return double.tryParse(clean);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Display area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Expression
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _expression.isEmpty ? '' : _expression,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                // Result
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _display,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _hasError ? AppColors.debit : Colors.white,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Button grid
          _buildButtonGrid(),
          const SizedBox(height: 12),

          // Use amount button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _currentResult != null
                  ? () => Navigator.pop(context, _currentResult)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'اس رقم کو استعمال کریں',
                style: TextStyle(
                  fontFamily: AppTextStyles.urduFont,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Column(
      children: [
        // Row 1: C, ⌫, ÷, ×
        Row(
          children: [
            _calcButton('C', _clearColor, AppColors.debit, onTap: _onClear),
            _calcButton('⌫', _digitColor, Colors.white, onTap: _onBackspace),
            _calcButton('÷', _operatorColor, AppColors.primaryLight,
                onTap: () => _onOperator('÷')),
            _calcButton('×', _operatorColor, AppColors.primaryLight,
                onTap: () => _onOperator('×')),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: 7, 8, 9, -
        Row(
          children: [
            _calcButton('7', _digitColor, Colors.white,
                onTap: () => _onDigit('7')),
            _calcButton('8', _digitColor, Colors.white,
                onTap: () => _onDigit('8')),
            _calcButton('9', _digitColor, Colors.white,
                onTap: () => _onDigit('9')),
            _calcButton('-', _operatorColor, AppColors.primaryLight,
                onTap: () => _onOperator('-')),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: 4, 5, 6, +
        Row(
          children: [
            _calcButton('4', _digitColor, Colors.white,
                onTap: () => _onDigit('4')),
            _calcButton('5', _digitColor, Colors.white,
                onTap: () => _onDigit('5')),
            _calcButton('6', _digitColor, Colors.white,
                onTap: () => _onDigit('6')),
            _calcButton('+', _operatorColor, AppColors.primaryLight,
                onTap: () => _onOperator('+')),
          ],
        ),
        const SizedBox(height: 8),
        // Row 4: 1, 2, 3, =
        Row(
          children: [
            _calcButton('1', _digitColor, Colors.white,
                onTap: () => _onDigit('1')),
            _calcButton('2', _digitColor, Colors.white,
                onTap: () => _onDigit('2')),
            _calcButton('3', _digitColor, Colors.white,
                onTap: () => _onDigit('3')),
            _calcButton('=', AppColors.primary, Colors.white,
                onTap: _onEquals),
          ],
        ),
        const SizedBox(height: 8),
        // Row 5: 0 (wide), .
        Row(
          children: [
            _calcButton('0', _digitColor, Colors.white,
                flex: 2, onTap: () => _onDigit('0')),
            _calcButton('.', _digitColor, Colors.white,
                onTap: () => _onDigit('.')),
            // Empty space to align with 4-column grid
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _calcButton(String label, Color bg, Color fg,
      {VoidCallback? onTap, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: label.length > 1 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
