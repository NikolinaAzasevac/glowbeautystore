String formatOrderDate(
  DateTime date, {
  bool includeTime = true,
}) {
  final monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final formattedDate =
      '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  if (!includeTime) {
    return formattedDate;
  }

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$formattedDate, $hour:$minute';
}

bool isExpressDelivery(String deliveryMethod) {
  return deliveryMethod.toLowerCase().contains('express');
}
