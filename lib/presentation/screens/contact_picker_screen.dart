import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../data/models/contact_model.dart';
import '../../data/repositories/contact_repository.dart';
import '../widgets/empty_state_widget.dart';
import 'contact_edit_screen.dart';

class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  List<Contact> _phoneContacts = [];
  List<Contact> _filteredContacts = [];
  Set<String> _existingPhones = {}; // Track existing contact phone numbers
  bool _isLoading = true;
  bool _isLoadingExisting = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadExistingContacts();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load existing contacts from database to check duplicates
  Future<void> _loadExistingContacts() async {
    setState(() => _isLoadingExisting = true);

    try {
      final contactRepo = context.read<ContactRepository>();
      final existingContacts = await contactRepo.getAllContacts();

      // Extract all phone numbers from existing contacts
      final phones = <String>{};
      for (var contactSummary in existingContacts) {
        final phone = contactSummary.contact.phone;
        if (phone != null && phone.isNotEmpty) {
          // Normalize phone number (remove spaces, dashes, etc.)
          final normalized = _normalizePhone(phone);
          phones.add(normalized);
        }
      }

      setState(() {
        _existingPhones = phones;
        _isLoadingExisting = false;
      });
    } catch (e) {
      setState(() => _isLoadingExisting = false);
    }
  }

  /// Normalize phone number for comparison
  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Check if contact already exists in database
  bool _isContactExisting(Contact contact) {
    for (var phone in contact.phones) {
      final normalized = _normalizePhone(phone.number);
      if (_existingPhones.contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        if (mounted) {
          final tr = AppLocalizations.of(context);
          showFailureSnackbar(context, tr?.contactsPermissionRequired ?? '-');
          Navigator.pop(context);
        }
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      setState(() {
        _phoneContacts =
            contacts
                .where((c) => c.displayName.isNotEmpty && c.phones.isNotEmpty)
                .toList()
              ..sort((a, b) => a.displayName.compareTo(b.displayName));
        _filteredContacts = _phoneContacts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final tr = AppLocalizations.of(context);
        showFailureSnackbar(context, '${tr?.failedToLoad}: $e');
        Navigator.pop(context);
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _phoneContacts;
      } else {
        _filteredContacts = _phoneContacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final searchLower = query.toLowerCase();
          final phoneMatch = contact.phones.any(
            (phone) => phone.number.contains(searchLower),
          );
          return name.contains(searchLower) || phoneMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(title: Text(tr.selectContact), elevation: 0),
      body: Column(
        children: [
          // Search bar - synced with borrow/lend screen style
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr.searchContacts,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _filterContacts('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterContacts,
            ),
          ),

          // Info banner
          if (_isLoadingExisting)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tr.checkingExistingContacts,
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.blue.shade100,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.contactsAlreadyAddedMarked,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Contact list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.person_search_rounded,
                    title: _searchQuery.isEmpty
                        ? tr.noContactsFound
                        : tr.noMatchingContacts,
                    message: _searchQuery.isEmpty
                        ? tr.noContactsAvailableInPhone
                        : tr.tryDifferentSearchTerm,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final isExisting = _isContactExisting(contact);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildContactCard(contact, isExisting, isDark),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact, bool isExisting, bool isDark) {
    final name = contact.displayName;
    final phones = contact.phones;
    final hasMultiplePhones = phones.length > 1;
    final tr = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExisting
              ? Colors.green.shade200.withValues(alpha: 0.5)
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          width: isExisting ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: contact.photo != null
                    ? MemoryImage(contact.photo!)
                    : null,
                backgroundColor: isExisting
                    ? Colors.green.shade100
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                child: contact.photo == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isExisting
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              if (isExisting)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[850]! : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            hasMultiplePhones
                ? '${phones.length} ${tr.phoneNumbersSmall}'
                : phones.first.number,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          children: phones.map((phone) {
            final phoneNormalized = _normalizePhone(phone.number);
            final isPhoneExisting = _existingPhones.contains(phoneNormalized);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPhoneExisting
                      ? Colors.green.shade200
                      : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Icon(
                  Icons.phone_rounded,
                  size: 18,
                  color: isPhoneExisting
                      ? Colors.green.shade600
                      : (isDark ? Colors.grey[500] : Colors.grey[600]),
                ),
                title: Text(
                  phone.number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                trailing: isPhoneExisting
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tr.added,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      )
                    : null,

                onTap: () =>
                    _selectContact(contact, phone.number, isPhoneExisting),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectContact(
    Contact contact,
    String selectedPhone,
    bool isExisting,
  ) async {
    // Navigate to edit screen before saving
    final result = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactEditScreen(
          name: contact.displayName,
          phone: selectedPhone,
          email: contact.emails.isNotEmpty
              ? contact.emails.first.address
              : null,
          photo: contact.photo,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
}
