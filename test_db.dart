import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://pqjxjzqmsedhetejofxu.supabase.co';
  final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxanhqenFtc2VkaGV0ZWpvZnh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMTE3ODQsImV4cCI6MjA5MDY4Nzc4NH0.6V1JE2ONk61cOpAopgsT4FRHf9he-4j3-yrLu1oKY6Y';

  final res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/products?select=*'),
    headers: {
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey'
    }
  );
  print('HTTP Status: ${res.statusCode}');
  print('Response Body: ${res.body}');
}
