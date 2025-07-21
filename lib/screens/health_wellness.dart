import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../models/appointment.dart';
import '../models/average_temperature.dart';
import '../models/specialist_appointment.dart';
import '../widgets/compact_header.dart';

class HealthWellness extends StatefulWidget {
  const HealthWellness({super.key});

  @override
  State<HealthWellness> createState() => _HealthWellnessState();
}

class _HealthWellnessState extends State<HealthWellness> {
  List<Appointment> appointList = [
    Appointment(
        3534542,
        "Khathaza ",
        "Shabalala",
        "The Livestock Schedule ",
        "The Livestock Schedule allows you to calculate your gross profit from trading and average cost per head for your operation.",
        DateTime.now()),
    Appointment(
        657437,
        "Andze",
        "Mudau",
        "Populated from death records",
        "The killed for rations section is populated from death records recorded with rations in the description.",
        DateTime.now()),
    Appointment(
        3534542,
        "Khathaza ",
        "Shabalala",
        "The Livestock Schedule ",
        "The Livestock Schedule allows you to calculate your gross profit from trading and average cost per head for your operation.",
        DateTime.now()),
  ];
  TextEditingController _appointmentSearchController = TextEditingController();
  TextEditingController _appointmentByController = TextEditingController();
  List<Appointment> appointHistoryList = [
    Appointment(
        3534542,
        "Khathaza ",
        "Shabalala",
        "The Livestock Schedule ",
        "The Livestock Schedule allows you to calculate your gross profit from trading and average cost per head for your operation.",
        DateTime.now()),
    Appointment(
        657437,
        "Andze",
        "Mudau",
        "Populated from death records",
        "The killed for rations section is populated from death records recorded with rations in the description.",
        DateTime.now()),
  ];
  bool isLoading = false;
  List<SpecialistAppointment> specialistAppointList = [];

  List<AverageTemperature> aveTemperatureList = [
    AverageTemperature("Mon", 23, 11),
    AverageTemperature("Tue", 19, 5),
    AverageTemperature("Wed", 17, 6),
    AverageTemperature("Thu", 14, 1),
    AverageTemperature("Fri", 27, 10),
    AverageTemperature("Sat", 21, 7),
    AverageTemperature("Sun", 18, 9),
  ];
  String errorText = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const CompactHeader(
          title: "Health & Wellness",
          description: "Monitor livestock health status",
          icon: Icons.health_and_safety_rounded,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Divider(
            thickness: 0.5,
            color: Colors.black54,
          ),
        ),
        SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomCard(
                  elevation: 5,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    height: 340,
                    width: MediaQuery.of(context).size.width,
                    //padding: EdgeInsets.only(right: 24),
                    child: HeartBeat(),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
              ),
              Expanded(
                flex: 2,
                child: CustomCard(
                  elevation: 5,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    height: 340,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Recent Appointment",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                                fontSize: 14,
                                color: Constants.ctaTextColor,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        ListView.builder(
                          itemCount: appointList.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            var appointment = appointList[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      index < appointList.length - 1 ? 16 : 0),
                              child: InkWell(
                                hoverColor: Colors.white,
                                splashColor: Colors.white,
                                focusColor: Colors.white,
                                child: Container(
                                  //height: 60,
                                  padding: EdgeInsets.only(
                                      left: 8, top: 8, bottom: 8, right: 12),
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(360),
                                      color: Color(0XFFF4F4F4)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Card(
                                        elevation: 10,
                                        color: Colors.white,
                                        shadowColor: Colors.black,
                                        surfaceTintColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(360)),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Icon(
                                              CupertinoIcons.mail,
                                              size: 32,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Appointment By: ${appointment.firstName} ${appointment.lastName} ",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  appointment.topic,
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  CupertinoIcons.time,
                                                  color: Colors.black54,
                                                  size: 18,
                                                ),
                                                SizedBox(
                                                  width: 12,
                                                ),
                                                Text(
                                                  Constants.dateTimeformatter
                                                      .format(appointment
                                                          .appointDate),
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      // set to false if you want to force a rating
                                      builder: (context) => StatefulBuilder(
                                          builder: (context, setState) =>
                                              Dialog(
                                                insetAnimationDuration:
                                                    Duration(milliseconds: 800),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(64),
                                                ),
                                                elevation: 0.0,
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    constraints: BoxConstraints(
                                                        maxWidth: 800,
                                                        maxHeight: 350),
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 16,
                                                      bottom: 16,
                                                      left: 16,
                                                      right: 16,
                                                    ),
                                                    //margin: EdgeInsets.only(top: 16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.rectangle,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 10.0,
                                                          offset:
                                                              Offset(0.0, 10.0),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width,
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12),
                                                          decoration: BoxDecoration(
                                                              color: Color(
                                                                  0XFFF4F4F4),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16)),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    appointment
                                                                        .topic,
                                                                    style: GoogleFonts
                                                                        .inter(
                                                                      textStyle: const TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: Colors
                                                                              .black,
                                                                          letterSpacing:
                                                                              0,
                                                                          fontWeight:
                                                                              FontWeight.normal),
                                                                    ),
                                                                  ),
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .end,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            10,
                                                                        width:
                                                                            10,
                                                                        decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color: Constants.ctaColorGreen),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                      Text(
                                                                        Constants
                                                                            .dateTimeformatter
                                                                            .format(appointment.appointDate),
                                                                        style: GoogleFonts
                                                                            .inter(
                                                                          textStyle: const TextStyle(
                                                                              fontSize: 13,
                                                                              color: Colors.black,
                                                                              letterSpacing: 0,
                                                                              fontWeight: FontWeight.w400),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                              Text(
                                                                "Appointment by:${appointment.firstName} ${appointment.lastName}",
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  textStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .black54,
                                                                      letterSpacing:
                                                                          0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                              Text(
                                                                appointment
                                                                    .description,
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  textStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .black,
                                                                      letterSpacing:
                                                                          0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 16,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            TextButton(
                                                              style: TextButton.styleFrom(
                                                                  backgroundColor:
                                                                      Constants
                                                                          .ctaColorGreen,
                                                                  minimumSize:
                                                                      Size(140,
                                                                          45)),
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                setState(() {});
                                                              },
                                                              child: Text(
                                                                "Close",
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  textStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .white,
                                                                      letterSpacing:
                                                                          0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    )),
                                              )));
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CustomCard(
                  elevation: 5,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    height: 350,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                height: 120,
                                width: MediaQuery.of(context).size.width,
                                //padding: EdgeInsets.all(12),
                                child: ListView.builder(
                                    itemCount: aveTemperatureList.length,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            right: index <
                                                    aveTemperatureList.length -
                                                        1
                                                ? 16
                                                : 0),
                                        child: Container(
                                          //height: 180,
                                          width: 70,
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: Color(0XFFD9D9D9),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                aveTemperatureList[index].day,
                                                style: GoogleFonts.inter(
                                                  textStyle: TextStyle(
                                                      fontSize: 16,
                                                      color: Constants
                                                          .ctaTextColor,
                                                      letterSpacing: 0,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 12,
                                              ),
                                              Text(
                                                "${aveTemperatureList[index].highTemperature}/${aveTemperatureList[index].lowTemperature}",
                                                style: GoogleFonts.inter(
                                                  textStyle: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                      letterSpacing: 0,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 12,
                                              ),
                                              Container(
                                                height: 5,
                                                width: 5,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0XFF2F4852),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Average Temperature",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(child: Container()),
                            IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.arrow_circle_left_outlined,
                                  color: Constants.ctaColorGreen,
                                )),
                            SizedBox(
                              width: 12,
                            ),
                            IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.arrow_circle_right_outlined,
                                  color: Constants.ctaColorGreen,
                                )),
                          ],
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Expanded(
                          child: LivestockActivity(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
              ),
              Expanded(
                flex: 2,
                child: CustomCard(
                  elevation: 5,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    height: 350,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Appointment History",
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  "Recap on this month",
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                        fontSize: 13,
                                        color: Constants.ctaTextColor,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Constants.ctaColorGreen,
                                side: BorderSide(
                                    color: Constants.ctaColorGreen, width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(360),
                                ),
                                // minimumSize: Size(120, 50),
                              ),
                              child: Center(
                                child: Text(
                                  "View All",
                                  style: GoogleFonts.inter(
                                    textStyle: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 45,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(360),
                                  child: Material(
                                    elevation: 10,
                                    child: TextFormField(
                                      autofocus: false,
                                      decoration: InputDecoration(
                                        suffixIcon: InkWell(
                                          onTap: () {},
                                          child: Container(
                                            height: 48,
                                            width: 48,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 0.0,
                                                  bottom: 0.0,
                                                  right: 0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color:
                                                        Constants.ctaColorGreen,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            360)),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.search,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        hintText: 'Search appointment',
                                        hintStyle: GoogleFonts.inter(
                                          textStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.normal),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            EdgeInsets.only(left: 16),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey
                                                  .withOpacity(0.35)),
                                          borderRadius:
                                              BorderRadius.circular(360),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Constants.ctaColorGreen),
                                          borderRadius:
                                              BorderRadius.circular(360),
                                        ),
                                      ),
                                      controller: _appointmentSearchController,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        ListView.builder(
                          itemCount: appointHistoryList.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            var appointment = appointHistoryList[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      index < appointList.length - 1 ? 16 : 0),
                              child: InkWell(
                                hoverColor: Colors.white,
                                splashColor: Colors.white,
                                focusColor: Colors.white,
                                child: Container(
                                  //height: 60,
                                  padding: EdgeInsets.only(
                                      left: 8, top: 8, bottom: 8, right: 12),
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(360),
                                      color: Color(0XFFF4F4F4)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Card(
                                        elevation: 10,
                                        color: Colors.white,
                                        shadowColor: Colors.black,
                                        surfaceTintColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(360)),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          child: Center(
                                            child: Icon(
                                              CupertinoIcons.mail,
                                              size: 32,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  appointment.topic,
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  Constants.dateTimeformatter
                                                      .format(appointment
                                                          .appointDate),
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      // set to false if you want to force a rating
                                      builder: (context) => StatefulBuilder(
                                          builder: (context, setState) =>
                                              Dialog(
                                                insetAnimationDuration:
                                                    Duration(milliseconds: 800),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(64),
                                                ),
                                                elevation: 0.0,
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    constraints: BoxConstraints(
                                                        maxWidth: 800,
                                                        maxHeight: 350),
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 16,
                                                      bottom: 16,
                                                      left: 16,
                                                      right: 16,
                                                    ),
                                                    //margin: EdgeInsets.only(top: 16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.rectangle,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 10.0,
                                                          offset:
                                                              Offset(0.0, 10.0),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width,
                                                          padding:
                                                              EdgeInsets.all(
                                                                  12),
                                                          decoration: BoxDecoration(
                                                              color: Color(
                                                                  0XFFF4F4F4),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16)),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    appointment
                                                                        .topic,
                                                                    style: GoogleFonts
                                                                        .inter(
                                                                      textStyle: const TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color: Colors
                                                                              .black,
                                                                          letterSpacing:
                                                                              0,
                                                                          fontWeight:
                                                                              FontWeight.normal),
                                                                    ),
                                                                  ),
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .end,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            10,
                                                                        width:
                                                                            10,
                                                                        decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color: Constants.ctaColorGreen),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                      Text(
                                                                        Constants
                                                                            .dateTimeformatter
                                                                            .format(appointment.appointDate),
                                                                        style: GoogleFonts
                                                                            .inter(
                                                                          textStyle: const TextStyle(
                                                                              fontSize: 13,
                                                                              color: Colors.black,
                                                                              letterSpacing: 0,
                                                                              fontWeight: FontWeight.w400),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                              Text(
                                                                "Appointment by:${appointment.firstName} ${appointment.lastName}",
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  textStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .black54,
                                                                      letterSpacing:
                                                                          0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                              Text(
                                                                appointment
                                                                    .description,
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  textStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .black,
                                                                      letterSpacing:
                                                                          0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 16,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            TextButton(
                                                              style: TextButton.styleFrom(
                                                                  backgroundColor:
                                                                      Constants
                                                                          .ctaColorGreen,
                                                                  minimumSize:
                                                                      Size(140,
                                                                          45)),
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                setState(() {});
                                                              },
                                                              child: Text(
                                                                "Close",
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  textStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Colors
                                                                          .white,
                                                                      letterSpacing:
                                                                          0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    )),
                                              )));
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: CustomCard(
                  elevation: 5,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    height: 350,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 45,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(360),
                                  child: Material(
                                    elevation: 10,
                                    child: TextFormField(
                                      autofocus: false,
                                      decoration: InputDecoration(
                                        errorStyle:
                                            TextStyle(color: Colors.red),
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            getSpecialDoctor(
                                                _appointmentSearchController
                                                    .text);
                                            setState(() {});
                                          },
                                          child: Container(
                                            height: 48,
                                            width: 48,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 0.0,
                                                  bottom: 0.0,
                                                  right: 0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color:
                                                        Constants.ctaColorGreen,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            360)),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.search,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        hintText: 'Last Appointment By',
                                        hintStyle: GoogleFonts.inter(
                                          textStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.normal),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            EdgeInsets.only(left: 16),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey
                                                  .withOpacity(0.35)),
                                          borderRadius:
                                              BorderRadius.circular(360),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Constants.ctaColorGreen),
                                          borderRadius:
                                              BorderRadius.circular(360),
                                        ),
                                      ),
                                      controller: _appointmentByController,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        specialistAppointList.isEmpty
                            ? CircularProgressIndicator()
                            : ListView.builder(
                                itemCount: 1, //specialistAppointList.length,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: 16,
                                      ),
                                      specialistAppointList.isEmpty
                                          ? CircleAvatar(
                                              backgroundColor:
                                                  Constants.ctaColorGreen,
                                              radius: 38,
                                              child: Icon(
                                                CupertinoIcons.person,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(360),
                                              child: Image.network(
                                                specialistAppointList[index]
                                                    .doctorImage,
                                                width: 95,
                                                height: 95,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                      SizedBox(
                                        height: 12,
                                      ),
                                      Text(
                                        "${specialistAppointList[index].doctorName}",
                                        style: GoogleFonts.inter(
                                          textStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 16,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 120,
                                            height: 105,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Constants.ctaColorGreen),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "${specialistAppointList[index].overallRating}",
                                                  style: GoogleFonts.inter(
                                                    textStyle: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                Icon(
                                                  CupertinoIcons.star,
                                                  color: Color(0XFF2F4852),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                Text(
                                                  "Overall Ratings",
                                                  style: GoogleFonts.inter(
                                                    textStyle: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(child: Container()),
                                          Container(
                                            width: 120,
                                            height: 105,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Constants.ctaColorGreen),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "${specialistAppointList[index].averagePatients}",
                                                  style: GoogleFonts.inter(
                                                    textStyle: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                Icon(
                                                  CupertinoIcons.person,
                                                  color: Color(0XFF2F4852),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                Text(
                                                  "Average Patient",
                                                  style: GoogleFonts.inter(
                                                    textStyle: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }),
                        SizedBox(
                          height: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
              ),
              Expanded(
                flex: 2,
                child: Container(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
        ),
      ],
    );
  }

  @override
  void initState() {
    isLoading = true;
    getSpecialDoctor("Dr. John Doe");

    super.initState();
  }

  Future<void> getSpecialDoctor(String docName) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST',
        Uri.parse(
            "https://qa.miinsightsapps.net/parlour_config/parlour-config/"));
    request.body = json.encode({"identityNumber": ""});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      print("users.....above.....");
      if (response.statusCode != 200) {
        String jsonString = '''
[
  {
    "id": 1,
    "patientName": "Alice Smith",
    "patientImage": "https://example.com/images/alice.jpg",
    "doctorName": "Dr. John Doe",
    "doctorImage": "https://plus.unsplash.com/premium_photo-1681494086824-7200170f1353?q=80&w=1374&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "appointmentDate": "2024-11-01T10:00:00Z",
    "status": "confirmed",
    "notes": "Follow-up visit for blood test results.",
    "overallRating": 3.9,
    "averagePatients": 116
  },
  {
    "id": 2,
    "patientName": "Bob Johnson",
    "patientImage": "https://example.com/images/bob.jpg",
    "doctorName": "Dr. Jane Smith",
    "doctorImage": "https://plus.unsplash.com/premium_photo-1693258698597-1b2b1bf943cc?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MjV8fHByb2ZpbGUlMjBwaWN0dXJlfGVufDB8fDB8fHww",
    "appointmentDate": "2024-11-02T11:30:00Z",
    "appointmentTime": "11:30 AM",
    "status": "confirmed",
    "notes": "Initial consultation for skin issue.",
    "overallRating": 4.1,
    "averagePatients": 189
  },
  {
    "id": 3,
    "patientName": "Charlie Brown",
    "patientImage": "https://example.com/images/charlie.jpg",
    "doctorName": "Dr. Emily White",
    "doctorImage": "https://plus.unsplash.com/premium_photo-1689568126014-06fea9d5d341?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "appointmentDate": "2024-11-03T09:15:00Z",
    "status": "canceled",
    "notes": "Patient rescheduled for next week.",
    "overallRating": 3.8,
    "averagePatients": 129
  }
]


''';
        isLoading = true;
        List<dynamic> specList = jsonDecode(jsonString);
        specialistAppointList = specList
            .map((spec) => SpecialistAppointment.fromMap(spec))
            .toList();
        specialistAppointList = specialistAppointList
            .where((spec) => docName.contains(spec.doctorName))
            .toList();

        /*for (var spec in specList) {
          SpecialistAppointment specialistAppointment =
              SpecialistAppointment.fromMap(spec);

          specialistAppointList.add(specialistAppointment);
        }*/
        setState(() {});
        print("hghfhfd ${specialistAppointList.length}");

        print("yjyuoihhjk $specList");
      } else {
        print(response.reasonPhrase);
      }
    } catch (e) {
      print("An error occurred: $e");
    }
  }
}

class HeartBeat extends StatefulWidget {
  HeartBeat({super.key});
  final Color leftBarColor = Constants.ctaColorGreen;
  final Color rightBarColor = Color(0XFFAAAAAA);
  final Color avgColor = Color(0XFFB1EBC0);
  @override
  State<StatefulWidget> createState() => HeartBeatState();
}

class HeartBeatState extends State<HeartBeat> {
  final double width = 8;

  late List<BarChartGroupData> rawBarGroups;
  late List<BarChartGroupData> showingBarGroups;

  int touchedGroupIndex = -1;

  @override
  void initState() {
    super.initState();
    final barGroup1 = makeGroupData(0, 5, 12);
    final barGroup2 = makeGroupData(1, 16, 12);
    final barGroup3 = makeGroupData(2, 18, 5);
    final barGroup4 = makeGroupData(3, 20, 16);
    final barGroup5 = makeGroupData(4, 17, 6);
    final barGroup6 = makeGroupData(5, 19, 1.5);
    final barGroup7 = makeGroupData(6, 10, 1.5);
    final barGroup8 = makeGroupData(7, 19, 12);
    final barGroup9 = makeGroupData(8, 21, 19);
    final barGroup10 = makeGroupData(9, 11, 24);
    final barGroup11 = makeGroupData(4, 14, 4.5);
    final barGroup12 = makeGroupData(11, 23, 21.5);

    final items = [
      barGroup1,
      barGroup2,
      barGroup3,
      barGroup4,
      barGroup5,
      barGroup6,
      barGroup7,
      barGroup8,
      barGroup9,
      barGroup10,
      barGroup11,
      barGroup12,
    ];

    rawBarGroups = items;

    showingBarGroups = rawBarGroups;
  }

  String? selectedPeriod;
  List<String> periodList = [
    "today",
    "Yesterday",
    "3 days ",
    "5 days",
    "7 days ",
    "10 days ",
    " 14 days ",
    "21 days",
    "28 days ",
    "Month",
    "2 Month",
    "3 Month",
    "6 Month",
    "Year"
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Average Heart beat",
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Column(
                children: [
                  Text(
                    "Select Day(s)",
                    style: GoogleFonts.inter(
                      textStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Container(
                    width: 120,
                    height: 35,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Constants.ctaColorGreen, width: 1.0),
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32)),
                    child: Center(
                      child: DropdownButton<String>(
                        value: selectedPeriod,
                        isExpanded: true,
                        hint: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "Select Period",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPeriod = newValue;
                          });
                        },
                        selectedItemBuilder: (BuildContext ctxt) {
                          return periodList.map<Widget>((item) {
                            return DropdownMenuItem(
                                child: Container(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text("${item}",
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                ),
                                value: item);
                          }).toList();
                        },
                        items:
                            periodList.map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        underline: Container(),
                        /* validator: (value) =>
                                                        value == null ? 'Relationship is required' : null,*/
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            "Livestock average heart beat per minute is 23bpm.",
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                  fontSize: 13,
                  color: Constants.ctaTextColor,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 20,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: ((group) {
                      return Colors.grey;
                    }),
                    getTooltipItem: (a, b, c, d) => null,
                  ),
                  touchCallback: (FlTouchEvent event, response) {
                    if (response == null || response.spot == null) {
                      setState(() {
                        touchedGroupIndex = -1;
                        showingBarGroups = List.of(rawBarGroups);
                      });
                      return;
                    }

                    touchedGroupIndex = response.spot!.touchedBarGroupIndex;

                    setState(() {
                      if (!event.isInterestedForInteractions) {
                        touchedGroupIndex = -1;
                        showingBarGroups = List.of(rawBarGroups);
                        return;
                      }
                      showingBarGroups = List.of(rawBarGroups);
                      if (touchedGroupIndex != -1) {
                        var sum = 0.0;
                        for (final rod
                            in showingBarGroups[touchedGroupIndex].barRods) {
                          sum += rod.toY;
                        }
                        final avg = sum /
                            showingBarGroups[touchedGroupIndex].barRods.length;

                        showingBarGroups[touchedGroupIndex] =
                            showingBarGroups[touchedGroupIndex].copyWith(
                          barRods: showingBarGroups[touchedGroupIndex]
                              .barRods
                              .map((rod) {
                            return rod.copyWith(
                                toY: avg, color: widget.avgColor);
                          }).toList(),
                        );
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: bottomTitles,
                      reservedSize: 42,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: leftTitles,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: showingBarGroups,
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(360),
                    color: Constants.ctaColorGreen),
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "Average Heart Beat(23bpm)",
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400),
                ),
              ),
              SizedBox(
                width: 40,
              ),
              Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(360),
                    color: Color(0XFFAAAAAA)),
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "Actual Heart Beat Per Minute",
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
        ],
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xffAAAAAA),
      fontWeight: FontWeight.w400,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '5';
    } else if (value == 5) {
      text = '10';
    } else if (value == 10) {
      text = '15';
    } else if (value == 15) {
      text = '20';
    } else if (value == 20) {
      text = '25';
    } else if (value == 24) {
      text = '30';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 0,
      child: Text(text, style: style),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final titles = <String>[
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
      'Jan',
    ];

    final Widget text = Text(
      titles[value.toInt()],
      style: const TextStyle(
        color: Color(0xffAAAAAA),
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16, //margin top
      child: text,
    );
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: widget.leftBarColor,
          width: width,
        ),
        BarChartRodData(
          toY: y2,
          color: widget.rightBarColor,
          width: width,
        ),
      ],
    );
  }

  Widget makeTransactionsIcon() {
    const width = 4.5;
    const space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color: Colors.white.withOpacity(1),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
      ],
    );
  }
}

class LivestockActivity extends StatefulWidget {
  const LivestockActivity({super.key});

  @override
  State<LivestockActivity> createState() => _LivestockActivityState();
}

class _LivestockActivityState extends State<LivestockActivity> {
  List<Color> gradientColors = [
    Constants.ctaColorGreen,
    Constants.ctaColorGreen,
  ];

  bool showAvg = false;
  int maxY = 11;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          height: 300,
          //width: 270,
          padding: EdgeInsets.all(20),
          //color: Color(0xFF20263A),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade50),
          child: LineChart(
            showAvg ? avgData() : mainData(),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Text(
            "Livestock Activity",
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Text(
            "+7.45%",
            style: GoogleFonts.inter(
              textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500),
            ),
          ),
        )
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
        fontWeight: FontWeight.normal, fontSize: 12, color: Color(0XFF737791));
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Jan', style: style);
        break;
      case 1:
        text = const Text('Feb', style: style);
        break;
      case 2:
        text = const Text('Mar', style: style);
        break;
      case 3:
        text = const Text('Apr', style: style);
        break;
      case 4:
        text = const Text('May', style: style);
        break;
      case 5:
        text = const Text('Jun', style: style);
        break;
      case 6:
        text = const Text('Jul', style: style);
        break;
      case 7:
        text = const Text('Aug', style: style);
        break;
      case 8:
        text = const Text('Sep', style: style);
        break;
      case 9:
        text = const Text('Oct', style: style);
        break;
      case 10:
        text = const Text('Nov', style: style);
        break;
      case 11:
        text = const Text('Dec', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
        fontWeight: FontWeight.normal, fontSize: 12, color: Color(0XFF737791));
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0';
        break;
      case 1:
        text = '100';
        break;
      case 2:
        text = '200';
        break;
      case 3:
        text = '300';
        break;
      case 4:
        text = '400';
        break;
      case 5:
        text = '500';
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  LineChartData mainData() {
    return LineChartData(
      //backgroundColor:  Color(0xFF20263A),
      gridData: FlGridData(
          show: false,
          drawHorizontalLine: false,
          drawVerticalLine: false,
          //drawVerticalLine: true,
          horizontalInterval: 1,
          //verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.black54,
              strokeWidth: 0.5,
            );
          }),
      titlesData: FlTitlesData(
        show: false,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: 2,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
        //border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          color: Constants.ctaColorGreen,
          curveSmoothness: 0.5,
          show: true,
          spots: const [
            FlSpot(0, 3),
            FlSpot(2.6, 2),
            FlSpot(4.9, 5),
            FlSpot(6.8, 3.1),
            FlSpot(8, 4),
            FlSpot(9.5, 3),
            FlSpot(11, 4),
          ],
          isCurved: true,
          /*gradient: LinearGradient(
            colors: gradientColors,
          ),*/
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: false,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        //verticalInterval: 1,
        horizontalInterval: 1,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Constants.ctaColorGreen,
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Constants.ctaColorGreen,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 2,
            getTitlesWidget: bottomTitleWidgets,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 2,
            interval: 1,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Constants.ctaColorGreen,
        ),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          show: true,
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(2.6, 3.44),
            FlSpot(4.9, 3.44),
            FlSpot(6.8, 3.44),
            FlSpot(8, 3.44),
            FlSpot(9.5, 3.44),
            FlSpot(11, 3.44),
          ],
          isCurved: true,
          color: Constants.ctaColorGreen,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
