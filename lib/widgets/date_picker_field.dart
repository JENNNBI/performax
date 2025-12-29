import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final DateTime? selectedDate;
  final Function(DateTime?) onChanged;
  final String? Function(DateTime?)? validator;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    this.labelText,
    this.hintText,
    this.selectedDate,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  final TextEditingController _controller = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _updateController();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _updateController();
    }
  }

  void _updateController() {
    if (widget.selectedDate != null) {
      _controller.text = _dateFormat.format(widget.selectedDate!);
    } else {
      // Don't clear if user is typing
      if (!_focusNode.hasFocus) {
        _controller.clear();
      }
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // When focus is lost, try to parse the date
      _parseAndValidateDate();
    }
  }

  void _parseAndValidateDate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _notifyDateChange(null);
      return;
    }

    try {
      // Try to parse the date
      final date = _dateFormat.parseStrict(text);
      
      // Check if date is within valid range
      final now = DateTime.now();
      final firstDate = widget.firstDate ?? DateTime(now.year - 100);
      final lastDate = widget.lastDate ?? now;
      
      if (date.isBefore(firstDate) || date.isAfter(lastDate)) {
        // Invalid date range, reset to previous valid date or clear
        _updateController();
        return;
      }
      
      // Valid date, notify change
      _notifyDateChange(date);
    } catch (e) {
      // Invalid format, reset to previous valid date or clear
      _updateController();
    }
  }

  void _notifyDateChange(DateTime? date) {
    if (date != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(date);
        }
      });
    }
  }

  void _onTextChanged(String value) {
    // Auto-format the date as user types
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    String formattedValue = '';
    
    for (int i = 0; i < cleanValue.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        formattedValue += '/';
      }
      formattedValue += cleanValue[i];
    }
    
    if (formattedValue != value) {
      _controller.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
    
    // If complete date format, try to parse it
    if (formattedValue.length == 10) {
      try {
        final date = _dateFormat.parseStrict(formattedValue);
        final now = DateTime.now();
        final firstDate = widget.firstDate ?? DateTime(now.year - 100);
        final lastDate = widget.lastDate ?? now;
        
        if (!date.isBefore(firstDate) && !date.isAfter(lastDate)) {
          _notifyDateChange(date);
        }
      } catch (e) {
        // Invalid date, will be handled on focus loss
      }
    }
  }

  Future<void> _selectDate() async {
    if (!widget.enabled) return;

    try {
      final DateTime now = DateTime.now();
      final DateTime firstDate = widget.firstDate ?? DateTime(now.year - 100);
      final DateTime lastDate = widget.lastDate ?? now;
      
      // Calculate initial date
      DateTime initialDate;
      if (widget.selectedDate != null) {
        initialDate = widget.selectedDate!;
      } else {
        final defaultDate = DateTime(now.year - 16, now.month, now.day);
        if (defaultDate.isBefore(firstDate)) {
          initialDate = firstDate;
        } else if (defaultDate.isAfter(lastDate)) {
          initialDate = lastDate;
        } else {
          initialDate = defaultDate;
        }
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'Doğum Tarihi Seçin',
        cancelText: 'İptal',
        confirmText: 'Tamam',
        fieldLabelText: 'Tarih girin',
        fieldHintText: 'gg/aa/yyyy',
        errorFormatText: 'Geçerli tarih formatı: gg/aa/yyyy',
        errorInvalidText: 'Geçerli bir tarih girin',
      );

      if (picked != null) {
        _controller.text = _dateFormat.format(picked);
        _notifyDateChange(picked);
      }
    } catch (e) {
      debugPrint('Error showing date picker: $e');
    }
  }

  String? _validateDate(String? value) {
    if (widget.validator != null) {
      return widget.validator!(widget.selectedDate);
    }
    
    // Basic validation
    if (value == null || value.trim().isEmpty) {
      return 'Doğum tarihi gereklidir';
    }
    
    try {
      final date = _dateFormat.parseStrict(value);
      final now = DateTime.now();
      final firstDate = widget.firstDate ?? DateTime(now.year - 100);
      final lastDate = widget.lastDate ?? now;
      
      if (date.isAfter(lastDate)) {
        return 'Geçerli bir doğum tarihi girin';
      }
      if (date.isBefore(firstDate)) {
        return 'Çok eski bir tarih';
      }
    } catch (e) {
      return 'Geçerli format: gg/aa/yyyy (örn: 15/03/2005)';
    }
    
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
          LengthLimitingTextInputFormatter(10), // dd/MM/yyyy = 10 characters
        ],
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText ?? 'gg/aa/yyyy (örn: 15/03/2005)',
          helperText: 'Format: Gün/Ay/Yıl',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  onPressed: widget.enabled
                      ? () {
                          _controller.clear();
                          _notifyDateChange(null);
                        }
                      : null,
                                      icon: const Icon(Icons.clear_outlined, size: 20),
                ),
              IconButton(
                onPressed: widget.enabled ? _selectDate : null,
                                  icon: const Icon(Icons.date_range_outlined, size: 20),
                tooltip: 'Takvimden seç',
              ),
            ],
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onChanged: _onTextChanged,
        validator: _validateDate,
      ),
    );
  }
} 