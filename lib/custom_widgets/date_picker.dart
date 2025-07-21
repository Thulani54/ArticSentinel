import 'package:flutter/material.dart';

import '../constants/Constants.dart';

class CustomDatePicker extends StatefulWidget {
  const CustomDatePicker({super.key, this.restorationId});

  final String? restorationId;

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

/// RestorationProperty objects can be used because of RestorationMixin.
class _CustomDatePickerState extends State<CustomDatePicker>
    with RestorationMixin {
  // In this example, the restoration ID for the mixin is passed in through
  // the [StatefulWidget]'s constructor.
  @override
  String? get restorationId => widget.restorationId;

  final RestorableDateTime _selectedDate = RestorableDateTime(DateTime.now());
  late final RestorableRouteFuture<DateTime?> _restorableDatePickerRouteFuture =
      RestorableRouteFuture<DateTime?>(
    onComplete: _selectDate,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _datePickerRoute,
        arguments: _selectedDate.value.millisecondsSinceEpoch,
      );
    },
  );

  @pragma('vm:entry-point')
  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DatePickerDialog(
            restorationId: 'date_picker_dialog',
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
            firstDate: DateTime(1950),
            lastDate: DateTime.now());
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableDatePickerRouteFuture, 'date_picker_route_future');
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;
        Constants.datePickerValue = Constants.formatter.format(newSelectedDate);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Selected: Select Date'),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: Constants.ctaColorGreen, width: 1.0),
              minimumSize: Size(MediaQuery.of(context).size.width, 50)),
          onPressed: () {
            _restorableDatePickerRouteFuture.present();
          },
          child: Text(
            "${Constants.formatter.format(_selectedDate.value)}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Nonchalance',
            ),
          )),
    );
  }
}

class CustomDatePicker1 extends StatefulWidget {
  const CustomDatePicker1({super.key, this.restorationId});

  final String? restorationId;

  @override
  State<CustomDatePicker1> createState() => _CustomDatePicker1State();
}

/// RestorationProperty objects can be used because of RestorationMixin.
class _CustomDatePicker1State extends State<CustomDatePicker1>
    with RestorationMixin {
  // In this example, the restoration ID for the mixin is passed in through
  // the [StatefulWidget]'s constructor.
  @override
  String? get restorationId => widget.restorationId;

  final RestorableDateTime _selectedDate = RestorableDateTime(DateTime.now());
  late final RestorableRouteFuture<DateTime?> _restorableDatePickerRouteFuture =
      RestorableRouteFuture<DateTime?>(
    onComplete: _selectDate,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _datePickerRoute,
        arguments: _selectedDate.value.millisecondsSinceEpoch,
      );
    },
  );

  @pragma('vm:entry-point')
  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DatePickerDialog(
            restorationId: 'date_picker_dialog',
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
            firstDate: DateTime(1950),
            lastDate: DateTime.now());
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableDatePickerRouteFuture, 'date_picker_route_future');
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;
        Constants.datePickerValue1 =
            Constants.formatter.format(newSelectedDate);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Selected: Select Date'),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: Constants.ctaColorGreen, width: 1.0),
              minimumSize: Size(MediaQuery.of(context).size.width, 50)),
          onPressed: () {
            _restorableDatePickerRouteFuture.present();
          },
          child: Text(
            "${Constants.formatter.format(_selectedDate.value)}",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Nonchalance',
            ),
          )),
    );
  }
}
