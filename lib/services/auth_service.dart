import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AuthService {
  final storage = FlutterSecureStorage();

  Future<User?> loginWithCredentials(BuildContext context, String pin, String password) async {
    // Check for hardcoded pin and password
    if (pin == '51000' && password == '51000') {
      // Directly return a User object for successful login
      return User(userId: '51000', customerId: 'defaultCustomer');
    }
    
    final String url = 'https://api.ialertfacility.com/authentication_log';

    Map<String, dynamic> requestBody = {
      "token": pin, // PIN is used as token
      "type": 1,
      "challenge": password,
      "latitude": 50.049583,  // Example location (can be dynamic)
      "longitude": 19.944265,
      "imei": "1234567890", // Replace with actual device IMEI retrieval
      "build": 1
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == 1) {
          await storeUserData(responseData["body"]);
          return User.fromJson(responseData["body"]);
        } else {
          _showErrorDialog(context, "Invalid PIN or Password");
          return null;
        }
      } else {
        _showErrorDialog(context, "Server Error");
        return null;
      }
    } catch (e) {
      _showErrorDialog(context, "Network Error");
      return null;
    }
  }

  Future<User?> loginWithQrCode(BuildContext context, String rawValue) async {
    final String url = 'https://api.ialertfacility.com/authentication_qr';

    try {
      List<String> parts = rawValue.split(";");
      String afm = parts[2].replaceAll("afm:", "");
      String id = parts[3].replaceAll("id:", "");

      Map<String, dynamic> requestBody = {
        "afm": afm,
        "id": id,
        "imei": "1234567890",
        "build": 1
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["status"] == 1) {
          await storeUserData(responseData["body"]);
          return User.fromJson(responseData["body"]);
        } else {
          _showErrorDialog(context, "Invalid QR Code");
          return null;
        }
      } else {
        _showErrorDialog(context, "Server Error");
        return null;
      }
    } catch (e) {
      _showErrorDialog(context, "Network Error");
      return null;
    }
  }

  Future<void> storeUserData(Map<String, dynamic> data) async {
    await storage.write(key: "userId", value: data["name"]);
    await storage.write(key: "customer_id", value: data["customer_id"]);
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<String> scanQRCode() async {
    Completer<String> completer = Completer<String>();

    MobileScannerController scannerController = MobileScannerController();

    MobileScanner(
      controller: scannerController,
      onDetect: (BarcodeCapture capture) {  // ✅ Correct function signature
        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          final String? code = barcodes.first.rawValue;
          if (code != null) {
            completer.complete(code);
          }
        }
      },
    );

    return completer.future;
  }
}

class User {
  final String userId;
  final String customerId;

  User({required this.userId, required this.customerId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json["name"],
      customerId: json["customer_id"],
    );
  }
}