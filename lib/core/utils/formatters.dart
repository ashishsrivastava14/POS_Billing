import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final compactCurrency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final dateFormat = DateFormat('dd MMM yyyy');
final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
final timeFormat = DateFormat('hh:mm a');

String formatCurrency(double amount) => currencyFormat.format(amount);
String formatCompactCurrency(double amount) => compactCurrency.format(amount);
String formatDate(DateTime date) => dateFormat.format(date);
String formatDateTime(DateTime date) => dateTimeFormat.format(date);
