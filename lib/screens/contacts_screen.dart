
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contacts_service/contacts_service.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; 

import '../models/user.dart';
import '../services/api_service.dart';
import 'add_edit_user_screen.dart';


// =======================================================
// CONTACT ITEM WIDGET'I BURAYA TAŞINDI
// =======================================================

class ContactItem extends StatelessWidget {
  final String name;
  final String number;
  final String avatarUrl;
  final VoidCallback onTap;

  const ContactItem({
    super.key,
    required this.name,
    required this.number,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: avatarUrl.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                  placeholder: (context, url) => const Icon(Icons.person, color: Colors.grey),
                  errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
                ),
              )
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(number),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}

// =======================================================
// CONTACTS SCREEN BAŞLANGICI
// =======================================================

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  List<Contact> _localContacts = [];
  bool _isImporting = false;


  Future<void> _handleLocalContactImport() async {
    if (!mounted) return; 

    setState(() {
      _isImporting = true;
    });

    List<Contact>? importedContacts;
    
    try {
        Iterable<Contact> contacts = await ContactsService.getContacts(
            withThumbnails: false,
        );
        importedContacts = contacts.toList();
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Rehber erişimi reddedildi veya okunamadı.")),
            );
        }
    }


    if (!mounted) return;

    setState(() {
      _isImporting = false;
      if (importedContacts != null) {
        _localContacts = importedContacts;
      }
    });

    if (_localContacts.isNotEmpty && mounted) {
      _showLocalContactsDialog(context);
    }
  }

  
  void _showLocalContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yerel Rehberden Okunan Kişiler'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _localContacts.length,
              itemBuilder: (context, index) {
                final contact = _localContacts[index];
                final name = contact.displayName ?? 'İsimsiz';
                final number = contact.phones?.isNotEmpty == true ? contact.phones!.first.value : 'Numara Yok';
                
                return ListTile(
                  title: Text(name),
                  subtitle: Text(number ?? ''),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  
  Map<String, List<User>> _groupUsersByFirstLetter(List<User> users) {
    List<User> filteredUsers = users.where((user) {
      if (_searchQuery.isEmpty) return true;
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();
    
    filteredUsers.sort((a, b) => a.firstName.compareTo(b.firstName));
    Map<String, List<User>> grouped = {};
    for (var user in filteredUsers) {
      final firstLetter = user.firstName.isNotEmpty
          ? user.firstName[0].toUpperCase()
          : '#';
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(user);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final List<User> users = userService.users;
        final bool isLoading = userService.isLoading;
        final groupedUsers = _groupUsersByFirstLetter(users);

        return Scaffold(
          appBar: AppBar(title: const Text('Kişilerim')),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Kişi Ara...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                if (isLoading && users.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (users.isEmpty && !isLoading && _searchQuery.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Henüz kişi eklenmemiş.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                // Arama Sonuçsuzluğu Bildirimi (AYNI)
                else if (groupedUsers.isEmpty && _searchQuery.isNotEmpty && !isLoading)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Aradığınız kişi bulunamadı.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Lütfen arama terimini kontrol edin.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                // -------------------------------------------------------------
                else
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        
                        ListTile(
                          leading: _isImporting 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : Icon(Icons.perm_contact_calendar, color: Theme.of(context).colorScheme.primary),
                          title: const Text('Telefon Rehberini Görüntüle', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isImporting ? null : _handleLocalContactImport,
                        ),
                        const Divider(height: 1),
                        // Listelenen kişiler
                        ...groupedUsers.entries.map((entry) {
                          final letter = entry.key;
                          final usersUnderLetter = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 4),
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...usersUnderLetter.map(
                                (user) => Dismissible(
                                  key: ValueKey(user.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  
                                  // Silme Onayını Sor 
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Kişiyi Sil"),
                                          content: Text("${user.firstName} ${user.lastName} adlı kişiyi silmek istediğinizden emin misiniz?"),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false), 
                                              child: const Text("Hayır"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(true), 
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text("Evet, Sil", style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  // ------------------------------------

                                  onDismissed: (direction) async {
                                    final userName = '${user.firstName} ${user.lastName}'; // Kişinin adını al
                                    final success = await userService.deleteUser(user.id);
                                    
                                    if (mounted) {
                                      if (success) {
                                        // ✅ BAŞARI SNACKBAR'I 
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$userName başarıyla silindi.'), 
                                            backgroundColor: Colors.green.shade700,
                                            duration: const Duration(milliseconds: 1000), 
                                          ),
                                        );
                                      } else {
                                        // Başarısızlık Snackbar'ı
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Silme işlemi başarısız oldu.'),
                                              backgroundColor: Colors.red,
                                            ));
                                      }
                                    }
                                  },
                                  child: ContactItem(
                                    name: '${user.firstName} ${user.lastName}',
                                    number: user.phoneNumber,
                                    avatarUrl: user.profileImageUrl ?? '',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddEditUserScreen(userToEdit: user),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditUserScreen(),
                ),
              );
            },
            tooltip: 'Yeni Kullanıcı Ekle',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}