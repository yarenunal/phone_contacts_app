
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService extends ChangeNotifier {
  // Bilgileriniz
  final String _baseUrl = "http://146.59.52.68:11235/api/User";
  final String _apiKey = "3e81bbdf-4054-4e0e-8488-fca7e27e3b9c";

  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  
  // Header'lar
  Map<String, String> get _defaultHeaders => {
    "ApiKey": _apiKey,
    "Content-Type": "application/json",
  };

  UserService() {
    fetchUsers();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Helper: API yanıtını işleme (success kontrolü)
  bool _checkResponseSuccess(http.Response response, Map<String, dynamic> responseBody) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Swaggardaki alan 'success' olduğu için bunu kullanıyoruz
      return responseBody['success'] ?? false; 
    }
    return false;
  }

  /// 🔹 1. Tüm kullanıcıları API'den çek (GET)
  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/GetAll"),
        headers: _defaultHeaders,
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);
      
      if (_checkResponseSuccess(response, responseBody) && responseBody['data'] != null && responseBody['data']['users'] != null) {
        final List<dynamic> usersData = responseBody['data']['users'];
        _users = usersData.map((item) => User.fromJson(item)).toList();
        _users.sort((a, b) => a.firstName.compareTo(b.firstName)); 
      } else {
        debugPrint("Kişi listesi alınamadı: ${responseBody['message']}");
        _users = [];
      }
    } catch (e) {
      debugPrint('Kişi listesi yüklenirken hata oluştu: $e');
      _users = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 🔹 2. Yeni kullanıcı ekle (POST) - Performans için manuel liste güncelleme
  Future<bool> addUser(User user) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl), 
        headers: _defaultHeaders,
        body: json.encode(user.toJson()),
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);
      
      if (_checkResponseSuccess(response, responseBody) && responseBody['data'] != null) {
        final newUserJson = responseBody['data']; 
        final newUser = User.fromJson(newUserJson); 

        _users.add(newUser);
        _users.sort((a, b) => a.firstName.compareTo(b.firstName)); 
        notifyListeners();
        return true;
      } else {
        debugPrint("Ekleme Başarısız: ${responseBody['messages']}");
        return false;
      }
    } catch (e) {
      debugPrint('Ekleme hatası: $e');
      return false;
    }
  }

  /// 🔹 3. Kullanıcı güncelle (PUT) - Performans için manuel liste güncelleme
  Future<bool> updateUser(User user) async {
    try {
      // Swaggarda PUT: /api/User/{id}
      final response = await http.put(
        Uri.parse("$_baseUrl/${user.id}"), 
        headers: _defaultHeaders,
        body: json.encode(user.toJson()),
      );
      
      final Map<String, dynamic> responseBody = json.decode(response.body);
      
      if (_checkResponseSuccess(response, responseBody)) {
        // Listeyi manuel güncelleme
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = user; 
          // Sıralama zaten bozulmaz ama emin olmak için:
          _users.sort((a, b) => a.firstName.compareTo(b.firstName)); 
        }
        notifyListeners();
        return true;
      } else {
        debugPrint("Güncelleme Başarısız: ${responseBody['messages']}");
        return false;
      }
    } catch (e) {
      debugPrint('Güncelleme hatası: $e');
      return false;
    }
  }

  /// 🔹 4. Kullanıcı sil (DELETE)
  Future<bool> deleteUser(String id) async {
    try {
      // Swaggarda DELETE: /api/User/{id}
      final response = await http.delete(
        Uri.parse("$_baseUrl/$id"),
        headers: _defaultHeaders,
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (_checkResponseSuccess(response, responseBody)) {
        _users.removeWhere((u) => u.id == id);
        notifyListeners();
        return true;
      } else {
        debugPrint("Silme Başarısız: ${responseBody['messages']}");
        return false;
      }
    } catch (e) {
      debugPrint('Silme hatası: $e');
      return false;
    }
  }
}