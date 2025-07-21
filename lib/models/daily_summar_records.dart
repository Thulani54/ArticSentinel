import 'package:flutter/cupertino.dart';

class DailySummaryRecords {
  int itemCount;
  int itemRecordPercentage;
  String itemName;
  IconData itemIcon;
  Color cardColor;

  DailySummaryRecords(this.itemCount, this.itemRecordPercentage, this.itemName,
      this.itemIcon, this.cardColor);
}

class DailySummaryRecords2 {
  String itemName;
  bool condtion;
  IconData itemIcon;
  Color cardColor;

  DailySummaryRecords2(
      this.itemName, this.itemIcon, this.cardColor, this.condtion);
}
