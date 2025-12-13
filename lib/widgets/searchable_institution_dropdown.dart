import 'package:flutter/material.dart';
import 'package:performax/models/institution.dart';

class SearchableInstitutionDropdown extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final Institution? selectedInstitution;
  final Function(Institution?) onChanged;
  final String? Function(Institution?)? validator;
  final bool enabled;
  final InstitutionType? filterByType;

  const SearchableInstitutionDropdown({
    super.key,
    this.labelText,
    this.hintText,
    this.selectedInstitution,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.filterByType,
  });

  @override
  State<SearchableInstitutionDropdown> createState() => _SearchableInstitutionDropdownState();
}

class _SearchableInstitutionDropdownState extends State<SearchableInstitutionDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Institution> _filteredInstitutions = [];
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _updateFilteredInstitutions();
    
    if (widget.selectedInstitution != null) {
      _searchController.text = widget.selectedInstitution!.name;
    }

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _updateFilteredInstitutions() async {
    _filteredInstitutions = await InstitutionData.searchInstitutions(_searchController.text);
    
    if (widget.filterByType != null) {
      _filteredInstitutions = _filteredInstitutions.where((inst) => inst.type == widget.filterByType).toList();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    setState(() {
      _isDropdownOpen = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _removeOverlay();
    setState(() {
      _isDropdownOpen = false;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _filteredInstitutions.isEmpty
                  ? _buildEmptyState()
                  : _buildDropdownList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Aradığınız kurum bulunamadı',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manuel giriş için aşağıdaki alana yazın',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      itemCount: _filteredInstitutions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final institution = _filteredInstitutions[index];
        return InkWell(
          onTap: () => _selectInstitution(institution),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: institution.type == InstitutionType.lise 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        institution.type.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: institution.type == InstitutionType.lise 
                              ? Colors.blue[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${institution.district}, ${institution.city}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectInstitution(Institution institution) {
    setState(() {
      _searchController.text = institution.name;
    });
    widget.onChanged(institution);
    _hideOverlay();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: TextFormField(
          controller: _searchController,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText ?? 'Okul veya dershane arayın...',
                                  prefixIcon: const Icon(Icons.school_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _updateFilteredInstitutions();
                      });
                      widget.onChanged(null);
                    },
                                            icon: const Icon(Icons.clear_outlined, size: 20),
                  ),
                Icon(
                                      _isDropdownOpen ? Icons.keyboard_arrow_up_outlined : Icons.keyboard_arrow_down_outlined,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
              ],
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
          onChanged: (value) {
            setState(() {
              _updateFilteredInstitutions();
            });
            
            // If the current text doesn't match any institution exactly, clear selection
            final exactMatch = _filteredInstitutions.any((inst) => inst.name == value);
            if (!exactMatch) {
              widget.onChanged(null);
            }
            
            if (_overlayEntry != null) {
              _overlayEntry!.markNeedsBuild();
            }
          },
          validator: widget.validator != null 
              ? (value) {
                  // Find the institution that matches the current text
                  Institution? matchedInstitution;
                  if (value != null && value.isNotEmpty) {
                    try {
                      matchedInstitution = _filteredInstitutions.firstWhere(
                        (inst) => inst.name == value,
                      );
                    } catch (e) {
                      matchedInstitution = null;
                    }
                  }
                  return widget.validator!(matchedInstitution);
                }
              : null,
        ),
      ),
    );
  }
} 