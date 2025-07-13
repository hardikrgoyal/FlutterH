import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1565C0); // Deep Blue
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00ACC1); // Cyan
  static const Color secondaryLight = Color(0xFF5DDEF4);
  static const Color secondaryDark = Color(0xFF007C91);
  
  // Accent Colors
  static const Color accent = Color(0xFFFF7043); // Deep Orange
  static const Color accentLight = Color(0xFFFF9E80);
  static const Color accentDark = Color(0xFFBF360C);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Role Colors
  static const Color adminColor = Color(0xFF9C27B0); // Purple
  static const Color managerColor = Color(0xFF3F51B5); // Indigo
  static const Color supervisorColor = Color(0xFF009688); // Teal
  static const Color accountantColor = Color(0xFF795548); // Brown
  
  // Status Colors
  static const Color pendingColor = Color(0xFFFF9800); // Orange
  static const Color ongoingColor = Color(0xFF2196F3); // Blue
  static const Color completedColor = Color(0xFF4CAF50); // Green
  static const Color rejectedColor = Color(0xFFF44336); // Red
  static const Color approvedColor = Color(0xFF8BC34A); // Light Green
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF757575);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  
  // Helper Methods
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminColor;
      case 'manager':
        return managerColor;
      case 'supervisor':
        return supervisorColor;
      case 'accountant':
        return accountantColor;
      default:
        return grey500;
    }
  }
  
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingColor;
      case 'ongoing':
      case 'running':
        return ongoingColor;
      case 'completed':
      case 'finalized':
        return completedColor;
      case 'approved':
        return approvedColor;
      case 'rejected':
      case 'declined':
        return rejectedColor;
      case 'submitted':
        return info;
      default:
        return grey500;
    }
  }
  
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
} 