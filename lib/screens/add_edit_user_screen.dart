// lib/screens/add_edit_user_screen.dart (SON VE KUSURSUZ VERSİYON)

import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:palette_generator/palette_generator.dart'; 
import 'package:contacts_service/contacts_service.dart'; 
import 'package:flutter/services.dart'; // Input formatters için
import '../models/user.dart';
import '../services/api_service.dart';

class AddEditUserScreen extends StatefulWidget {
  final User? userToEdit;

  const AddEditUserScreen({super.key, this.userToEdit});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

  Color _dominantColor = const Color(0xFF3B0764); 
  File? _pickedImageFile; 

  bool get isEditing => widget.userToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final user = widget.userToEdit!;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phoneNumber;
      _avatarController.text = user.profileImageUrl ?? '';
      
      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        _extractColorFromUrl(user.profileImageUrl!);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  // URL'den renk çekme
  Future<void> _extractColorFromUrl(String url) async {
    try {
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        NetworkImage(url),
        size: const Size(100, 100),
      );
      if (mounted) {
        setState(() {
          _dominantColor = generator.dominantColor?.color ?? const Color(0xFF3B0764); 
        });
      }
    } catch (e) {
      debugPrint("Renk çıkarma hatası: $e");
    }
  }

  // Resim seçme ve renk çıkarma
  Future<void> _pickImageAndExtractColor() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File image = File(pickedFile.path);
      
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        FileImage(image),
        size: const Size(100, 100),
      );

      if (mounted) {
        setState(() {
          _pickedImageFile = image;
          _dominantColor = generator.dominantColor?.color ?? const Color(0xFF3B0764);
          _avatarController.text = 'LOCAL_FILE_SELECTED'; 
        });
      }
    }
  }

  // Lottie Animasyonu
  void _showLottieAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Lottie.asset(
          'assets/lottie/success_check.json', 
          width: 150,
          height: 150,
          repeat: false,
          onLoaded: (composition) {
            Future.delayed(composition.duration * 1.5, () {
              if (mounted) {
                Navigator.of(context).pop(); 
                Navigator.of(context).pop(); 
              }
            });
          },
        ),
      ),
    );
  }

  // API'ye kaydetme/güncelleme metodu (Aynı)
  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final userService = Provider.of<UserService>(context, listen: false);

      final String finalImageUrl = _avatarController.text.trim().isNotEmpty && _avatarController.text.trim() != 'LOCAL_FILE_SELECTED'
          ? _avatarController.text.trim()
          : widget.userToEdit?.profileImageUrl ?? ''; 

      final newUser = User(
        id: isEditing ? widget.userToEdit!.id : const Uuid().v4(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: finalImageUrl.isNotEmpty ? finalImageUrl : null,
      );

      bool success;
      if (isEditing) {
        success = await userService.updateUser(newUser);
      } else {
        success = await userService.addUser(newUser);
      }

      if (success) {
        _showLottieAnimation();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEditing ? 'Güncelleme başarısız.' : 'Kişi eklenemedi.')),
          );
        }
      }
    }
  }

  // Kişiyi Cihaz Rehberine Kaydetme (Sadece Ekleme Modunda mantıklı)
  Future<void> _saveToLocalContacts() async {
    if (isEditing || widget.userToEdit != null) {
      // Bu buton sadece yeni kayıtlarda mantıklıdır. Düzenlemede bu metot çağrılmamalı.
      return; 
    }
    
    final newUser = User(
        id: const Uuid().v4(), // Geçici ID
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
    );

    final Contact newContact = Contact(
      givenName: newUser.firstName,
      familyName: newUser.lastName,
      phones: [
        Item(label: 'mobile', value: newUser.phoneNumber),
      ],
    );

    try {
      await ContactsService.addContact(newContact);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newUser.firstName} ${newUser.lastName} rehbere başarıyla kaydedildi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rehbere kaydetme işlemi başarısız oldu. İzinleri kontrol edin.')),
        );
      }
      debugPrint("Rehbere kaydetme hatası: $e");
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text('${widget.userToEdit!.firstName} ${widget.userToEdit!.lastName} adlı kullanıcıyı silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(child: const Text('Vazgeç'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await Provider.of<UserService>(context, listen: false).deleteUser(widget.userToEdit!.id);
              Navigator.of(ctx).pop(); 
              if (mounted) Navigator.of(context).pop(); 
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Kullanıcıyı Düzenle' : 'Yeni Kullanıcı Ekle'),
        backgroundColor: _dominantColor, 
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveUser, tooltip: 'Kaydet'),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white), 
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'Sil',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              // Avatar Alanı (Aynı)
              InkWell(
                onTap: _pickImageAndExtractColor,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _dominantColor.withOpacity(0.5), 
                      child: _pickedImageFile != null
                          ? ClipOval(child: Image.file(_pickedImageFile!, width: 100, height: 100, fit: BoxFit.cover))
                          : (isEditing && widget.userToEdit!.profileImageUrl != null && widget.userToEdit!.profileImageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    widget.userToEdit!.profileImageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person, size: 50, color: Colors.white),
                                  ),
                                )
                              : const Icon(Icons.person, size: 50, color: Colors.white)), 
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, size: 14, color: Colors.grey),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Text Alanları (Aynı)
              _buildTextField(controller: _firstNameController, labelText: 'Ad', icon: Icons.person, validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Ad alanı boş bırakılamaz.';
                return null;
              }),
              const SizedBox(height: 16),
              _buildTextField(controller: _lastNameController, labelText: 'Soyad', icon: Icons.person, validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Soyad alanı boş bırakılamaz.';
                return null;
              }),
              const SizedBox(height: 16),
              // Telefon Numarası Alanı (11 Hane Kısıtlaması entegre edildi)
              _buildTextField(
                controller: _phoneController,
                labelText: 'Telefon Numarası',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [ // ⬅️ Formatters EKLENDİ
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11), 
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Telefon numarası boş bırakılamaz.';
                  // Validator sadece 11 haneyi kontrol eder
                  if (value.trim().length != 11) return 'Telefon numarası 11 hane olmalıdır.'; 
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _avatarController, labelText: 'Profil Resmi URL (İsteğe Bağlı)', icon: Icons.image, keyboardType: TextInputType.url),

              const SizedBox(height: 30),

              // REHBERE KAYDET Butonu (Sadece Yeni Ekleme Modunda Görünür)
              if (!isEditing) 
                ElevatedButton.icon(
                  onPressed: _saveToLocalContacts,
                  icon: const Icon(Icons.bookmark_add, color: Colors.white),
                  label: const Text('Rehbere Kaydet', style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: _dominantColor.withOpacity(0.8), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              // ANA KAYDET BUTONU (Aynı)
              ElevatedButton.icon(
                onPressed: _saveUser,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(isEditing ? 'Güncellemeleri Kaydet' : 'Kişiyi Ekle', style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: _dominantColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TextField Yardımcı Metodu (InputFormatters eklentisi için güncellendi)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters, // ⬅️ YENİ PARAMETRE
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters, // ⬅️ KULLANIM
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: _dominantColor), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _dominantColor, width: 2), 
        ),
      ),
    );
  }
}