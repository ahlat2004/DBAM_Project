// Shared design helpers used across wizard steps
import 'package:flutter/material.dart';

const kBg = Color(0xFF0F172A);
const kSurface = Color(0xFF1E293B);
const kBorder = Color(0xFF334155);
const kPrimary = Color(0xFF2563EB);
const kMuted = Color(0xFF64748B);
const kText = Color(0xFFCBD5E1);
const kTextBright = Colors.white;

Widget appCard({required Widget child, double padding = 24}) => Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );

Widget sectionTitle(String t) => Text(
      t,
      style: const TextStyle(
          color: kTextBright, fontSize: 18, fontWeight: FontWeight.bold),
    );

Widget fieldLabel(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        t,
        style: const TextStyle(
            color: kMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
      ),
    );

Widget appTextField(TextEditingController ctrl, String hint,
        {bool isObscure = false, Function(String)? onChanged}) =>
    TextField(
      controller: ctrl,
      obscureText: isObscure,
      onChanged: onChanged,
      style: const TextStyle(color: kTextBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kMuted),
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

Widget primaryBtn(String label, VoidCallback? onTap) => SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: kTextBright,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );

Widget secondaryBtn(String label, VoidCallback? onTap) => SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: kText,
          side: const BorderSide(color: kBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );

Widget appCheckbox(bool value, String label, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: value ? kPrimary : Colors.transparent,
            border: Border.all(color: value ? kPrimary : kMuted, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: value
              ? const Icon(Icons.check, size: 12, color: kTextBright)
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label,
              style: const TextStyle(color: kText, fontSize: 13)),
        ),
      ]),
    );
