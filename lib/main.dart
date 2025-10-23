// main.dart (Kusursuz Son Hali)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'screens/contacts_screen.dart';
import 'services/api_service.dart'; // UserService

void main() {
  // Uygulamamızı ChangeNotifierProvider ile sarmalıyoruz.
  runApp(
    ChangeNotifierProvider(
      // UserService, başlangıçta fetchUsers() çağıracak.
      create: (context) => UserService(),
      child: const PhoneContactsApp(),
    ),
  );
}

class PhoneContactsApp extends StatelessWidget {
  const PhoneContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Phone Contacts App',
      // ContactsScreen artık veriyi kendi içinde Provider ile dinlediği için,
      // burada Consumer kullanmaya ve users listesini geçmeye gerek kalmadı.
      home: const ContactsScreen(), 
    );
  }
}