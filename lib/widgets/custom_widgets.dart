import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message) =>
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

InputDecoration appInputDecoration({
  required String labelText,
  IconData? icon,
  String? hintText,
}) => InputDecoration(
  labelText: labelText,
  hintText: hintText,
  prefixIcon: icon == null ? null : Icon(icon),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  filled: true,
  fillColor: Colors.white,
);

Widget authHeader(String title) => Column(
  children: [
    const Icon(Icons.apartment, size: 100, color: Colors.blue),
    const SizedBox(height: 20),
    Text(
      title,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    ),
  ],
);

Widget sectionTitle(String title) => Text(
  title,
  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
);

Widget appTextField({
  required TextEditingController controller,
  required String labelText,
  required IconData icon,
  TextInputType? keyboardType,
  bool obscureText = false,
  int maxLines = 1,
  String? hintText,
  ValueChanged<String>? onChanged,
}) => TextField(
  controller: controller,
  keyboardType: keyboardType,
  obscureText: obscureText,
  maxLines: maxLines,
  onChanged: onChanged,
  decoration: appInputDecoration(
    labelText: labelText,
    icon: icon,
    hintText: hintText,
  ),
);

Widget appDropdownField<T>({
  required T? value,
  required String labelText,
  required IconData icon,
  required List<T> values,
  required ValueChanged<T?> onChanged,
}) => DropdownButtonFormField<T>(
  initialValue: value,
  decoration: appInputDecoration(labelText: labelText, icon: icon),
  items: values
      .map((item) => DropdownMenuItem(value: item, child: Text('$item')))
      .toList(),
  onChanged: onChanged,
);

Widget appPrimaryButton({
  required String label,
  required VoidCallback? onPressed,
  bool isLoading = false,
  Color color = Colors.blue,
}) => ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: onPressed,
  child: isLoading
      ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
      : Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
);
