import 'dart:math' as math;

import 'package:borrow_ledger/core/constants/app_functions.dart';
import 'package:borrow_ledger/core/utils/app_loading_delay.dart';
import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../data/models/contact_model.dart';
import '../../data/repositories/contact_repository.dart';
import '../widgets/app_loading_state.dart';
import '../widgets/app_search_field.dart';
import '../widgets/empty_state_widget.dart';
import 'contact_edit_screen.dart';

class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  static const int _displayPageSize = 40;

  List<Contact> _phoneContacts = [];
  List<Contact> _filteredContacts = [];
  Set<String> _existingPhones = {}; // Track existing contact phone numbers
  Map<String, ContactModel> _existingContactsByPhone = {};
  bool _isLoading = true;
  bool _isLoadingExisting = true;
  bool _isLoadingMore = false;
  int _visibleContactCount = _displayPageSize;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadExistingContacts();
    _loadContacts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Contact> get _visibleContacts =>
      _filteredContacts.take(_visibleContactCount).toList();

  bool get _hasMoreVisibleContacts =>
      _visibleContactCount < _filteredContacts.length;

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMoreVisibleContacts) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreVisibleContacts();
    }
  }

  Future<void> _loadMoreVisibleContacts() async {
    if (_isLoadingMore || !_hasMoreVisibleContacts) return;

    setState(() => _isLoadingMore = true);
    await AppLoadingDelay.loadMore();
    if (!mounted) return;

    setState(() {
      _visibleContactCount = math.min(
        _visibleContactCount + _displayPageSize,
        _filteredContacts.length,
      );
      _isLoadingMore = false;
    });
  }

  /// Load existing contacts from database to check duplicates
  Future<void> _loadExistingContacts() async {
    setState(() => _isLoadingExisting = true);

    try {
      final contactRepo = context.read<ContactRepository>();
      final existingContacts = await contactRepo.getAllContacts();

      // Extract all phone numbers from existing contacts
      final phones = <String>{};
      final contactsByPhone = <String, ContactModel>{};
      for (var contactSummary in existingContacts) {
        final contact = contactSummary.contact;
        final phone = contact.phone;
        if (phone != null && phone.isNotEmpty) {
          // Normalize phone number (remove spaces, dashes, etc.)
          final normalized = _normalizePhone(phone);
          phones.add(normalized);
          contactsByPhone[normalized] = contact;
        }
      }

      setState(() {
        _existingPhones = phones;
        _existingContactsByPhone = contactsByPhone;
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
      final permissionStatus = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      final hasPermission =
          permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.limited;

      if (!hasPermission) {
        if (mounted) {
          final tr = AppLocalizations.of(context);
          showFailureSnackbar(context, tr?.contactsPermissionRequired ?? '-');
          Navigator.pop(context);
        }
        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.phone,
          ContactProperty.email,
          ContactProperty.photoThumbnail,
          ContactProperty.photoFullRes,
        },
      );

      setState(() {
        _phoneContacts =
            contacts
                .where(
                  (c) =>
                      (c.displayName?.isNotEmpty ?? false) &&
                      c.phones.isNotEmpty,
                )
                .toList()
              ..sort(
                (a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''),
              );
        _filteredContacts = _phoneContacts;
        _visibleContactCount = math.min(
          _displayPageSize,
          _filteredContacts.length,
        );
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
          final name = (contact.displayName ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          final phoneMatch = contact.phones.any(
            (phone) => phone.number.contains(searchLower),
          );
          return name.contains(searchLower) || phoneMatch;
        }).toList();
      }
      _visibleContactCount = math.min(
        _displayPageSize,
        _filteredContacts.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(tr.selectContact), elevation: 0),
      body: Column(
        children: [
          // Search bar - synced with borrow/lend screen style
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: AppSearchField(
              controller: _searchController,
              hintText: tr.searchContacts,
              onClear: () {
                _searchController.clear();
                _filterContacts('');
              },
              onChanged: _filterContacts,
            ),
          ),

          // Info banner
          if (_isLoadingExisting)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              color: Colors.transparent,
              child: Row(
                children: [
                  AppInlineLoadingState(
                    message: tr.checkingExistingContacts,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.contactsAlreadyAddedMarked,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Contact list
          Expanded(
            child: _isLoading
                ? const AppPageLoadingState(compact: true)
                : _filteredContacts.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.person_search_rounded,
                    title: _searchQuery.isEmpty
                        ? tr.noContactsFound
                        : tr.noMatchingContacts,
                    message: _searchQuery.isEmpty
                        ? tr.noContactsAvailableInPhone
                        : tr.tryDifferentSearchTerm,
                    compact: true,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: _visibleContacts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _visibleContacts.length) {
                        return AppLoadMoreFooter(
                          isLoading: _isLoadingMore,
                          hasMoreData: _hasMoreVisibleContacts,
                          hasItems: _visibleContacts.isNotEmpty,
                          itemCount: _visibleContacts.length,
                        );
                      }

                      final contact = _visibleContacts[index];
                      final isExisting = _isContactExisting(contact);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
    final theme = Theme.of(context);
    final name = contact.displayName ?? '';
    final phones = contact.phones;
    final hasMultiplePhones = phones.length > 1;
    final tr = AppLocalizations.of(context)!;
    final photoBytes = contact.photo?.fullSize ?? contact.photo?.thumbnail;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExisting
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07)),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundImage: photoBytes != null
                    ? MemoryImage(photoBytes)
                    : null,
                backgroundColor: isExisting
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : (isDark ? Colors.grey[700] : Colors.grey[200]),
                child: photoBytes == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isExisting
                              ? theme.colorScheme.primary
                              : (isDark ? Colors.grey[100] : Colors.grey[700]),
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
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[850]! : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
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
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            hasMultiplePhones
                ? '${phones.length} ${tr.phoneNumbersSmall}'
                : phones.first.number,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          children: phones.map((phone) {
            final phoneNormalized = _normalizePhone(phone.number);
            final isPhoneExisting = _existingPhones.contains(phoneNormalized);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Material(
                color: theme.colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isPhoneExisting
                        ? theme.colorScheme.primary.withValues(alpha: 0.35)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.07)),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  minLeadingWidth: 24,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  leading: Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: isPhoneExisting
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                  ),
                  title: Text(
                    phone.number,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  trailing: isPhoneExisting
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.18 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tr.added,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : null,

                  onTap: () =>
                      _selectContact(contact, phone.number, isPhoneExisting),
                ),
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
    final existingContact =
        _existingContactsByPhone[_normalizePhone(selectedPhone)];

    if (isExisting && existingContact != null) {
      Navigator.pop(context, existingContact);
      return;
    }

    // Navigate to edit screen before saving
    final result = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactEditScreen(
          name: contact.displayName ?? '',
          phone: selectedPhone,
          email: contact.emails.isNotEmpty
              ? contact.emails.first.address
              : null,
          photo: contact.photo?.fullSize ?? contact.photo?.thumbnail,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
}
