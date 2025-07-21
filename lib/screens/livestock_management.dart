import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';

import '../constants/Constants.dart';
import '../constants/models/device.dart';
import '../custom_widgets/customCard.dart';
import '../custom_widgets/customInput.dart';
import '../custom_widgets/date_picker.dart';
import '../models/animal_breed.dart';
import '../models/livestock_model.dart';
import '../services/authentication.dart';
import 'device_management.dart';
import 'edit_livestock_info.dart';
import 'livestock_view.dart';
import '../widgets/compact_header.dart';

class LivestockManagement extends StatefulWidget {
  const LivestockManagement({super.key});

  @override
  State<LivestockManagement> createState() => _LivestockManagementState();
}

class _LivestockManagementState extends State<LivestockManagement> {
  List<String> livestockTypeList = [];

  TextEditingController _searchMemorialController = TextEditingController();
  List<AnimalBreed> animalBreedList = [
    AnimalBreed(01, "Cow", 78, 21),
    AnimalBreed(02, "Goat", 31, 45),
    AnimalBreed(03, "Sheep", 19, 51),
    AnimalBreed(04, "Ostrich", 39, 67),
  ];

  List<LivestockModel> recentAddedLivestock = [];
  int tableColorIndex = -1;
  int tableColorIndex1 = -1;
  int tableColorIndex2 = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
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
                                    top: 0.0, bottom: 0.0, right: 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Constants.ctaColorGreen,
                                      borderRadius: BorderRadius.circular(360)),
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
                          contentPadding: EdgeInsets.only(left: 16),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.35)),
                            borderRadius: BorderRadius.circular(360),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Constants.ctaColorGreen),
                            borderRadius: BorderRadius.circular(360),
                          ),
                        ),
                        controller: _searchMemorialController,
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(),
              InkWell(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                child: Container(
                  height: 40,
                  padding: EdgeInsets.only(left: 12, right: 12),
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(360),
                    color: Constants.ctaColorGreen,
                  ),
                  child: Center(
                    child: Text(
                      "Add Livestock",
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      // set to false if you want to force a rating
                      builder: (context) => AddLivestockDialog(
                            livestockTypeList: livestockTypeList,
                          ));
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const CompactHeader(
          title: "Livestock Management",
          description: "Manage livestock inventory and tracking",
          icon: Icons.pets_rounded,
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
          child: CustomCard(
            elevation: 5,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              height: 300,
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [BarChartSample2()],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Text(
            "Animal By Breed",
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ),
        SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: CustomCard(
            elevation: 5,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              //height: 130,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 50,
                    padding: EdgeInsets.only(left: 8, right: 8),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(360),
                      color: Color(0XFF2F4852),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          child: Text(
                            "#",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Expanded(
                          child: Text(
                            "Name",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Expanded(
                          child: Text(
                            "Popularity",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Container(
                          width: 80,
                          child: Text(
                            "Sales",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  ListView.builder(
                      itemCount: animalBreedList.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      physics: ScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    child: Text(
                                      animalBreedList[index].id.toString(),
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 22,
                                  ),
                                  Expanded(
                                    child: Text(
                                      animalBreedList[index].breedName,
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 22,
                                  ),
                                  Expanded(
                                      child: SizedBox(
                                          height: 15,
                                          child: Stack(
                                            fit: StackFit.loose,
                                            children: [
                                              LinearProgressIndicator(
                                                  minHeight: 15,
                                                  semanticsValue:
                                                      "${(animalBreedList[index].popularity) / 100}%",
                                                  value: (animalBreedList[index]
                                                          .popularity) /
                                                      100,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          360),
                                                  color:
                                                      Constants.ctaColorGreen,
                                                  backgroundColor:
                                                      Colors.grey.shade300),
                                              Center(
                                                child: Text(
                                                  "${(animalBreedList[index].popularity)}",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ))),
                                  SizedBox(
                                    width: 22,
                                  ),
                                  Container(
                                    width: 80,
                                    height: 35,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            width: 1.0,
                                            color: Color(0XFF0036B7))),
                                    child: Center(
                                      child: Text(
                                        "${animalBreedList[index].sales}%",
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            index < animalBreedList.length - 1
                                ? Padding(
                                    padding: EdgeInsets.only(left: 8, right: 8),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Divider(
                                          thickness: 0.5,
                                          color: Colors.black54,
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox.shrink()
                          ],
                        );
                      }),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Text(
            "Recent Added",
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ),
        SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: CustomCard(
            elevation: 5,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              //height: 130,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    padding: EdgeInsets.only(left: 8, right: 8),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(360),
                      color: Color(0XFF2F4852),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          child: Text(
                            "#",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Expanded(
                          child: Text(
                            "Device",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Expanded(
                          child: Text(
                            "Type",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Expanded(
                          child: Text(
                            "Allocated To",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 22,
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            child: Text(
                              "Action",
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  recentAddedLivestock.isEmpty
                      ? Center(
                          child: SizedBox(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(
                                color: Constants.ctaColorLight,
                       strokeWidth: 1.5,
                              )),
                        )
                      : ListView.builder(
                          itemCount: recentAddedLivestock.length,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          physics: ScrollPhysics(),
                          itemBuilder: (context, index) {
                            var live = recentAddedLivestock[index];
                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 8, right: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        child: Text(
                                          recentAddedLivestock[index]
                                              .id
                                              .toString(),
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 22,
                                      ),
                                      Expanded(
                                        child: Text(
                                          recentAddedLivestock[index]
                                              .device
                                              .deviceId,
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 22,
                                      ),
                                      Expanded(
                                        child: Text(
                                          recentAddedLivestock[index]
                                              .device
                                              .iccid,
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 22,
                                      ),
                                      Expanded(
                                        child: Text(
                                          recentAddedLivestock[index].name,
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 22,
                                      ),
                                      Expanded(
                                        child: Text(
                                          recentAddedLivestock[index]
                                              .device
                                              .currentStatus,
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 22,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                    minimumSize: Size(60, 30),
                                                    backgroundColor:
                                                        tableColorIndex == index
                                                            ? Constants
                                                                .ctaColorGreen
                                                            : Colors
                                                                .transparent,
                                                    side: BorderSide(
                                                        width: 1.0,
                                                        color: Constants
                                                            .ctaColorGreen)),
                                                onPressed: () {
                                                  tableColorIndex = index;
                                                  showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      // set to false if you want to force a rating
                                                      builder: (context) =>
                                                          StatefulBuilder(
                                                              builder: (context,
                                                                      setState) =>
                                                                  LivestockViewDialog(
                                                                    livestockModel:
                                                                        live,
                                                                  )));
                                                  setState(() {});
                                                },
                                                child: Center(
                                                  child: Text(
                                                    "View",
                                                    style: GoogleFonts.inter(
                                                      textStyle: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              tableColorIndex ==
                                                                      index
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                    minimumSize: Size(60, 30),
                                                    backgroundColor:
                                                        tableColorIndex1 ==
                                                                index
                                                            ? Constants
                                                                .ctaColorGreen
                                                            : Colors
                                                                .transparent,
                                                    side: BorderSide(
                                                        width: 1.0,
                                                        color: Constants
                                                            .ctaColorGreen)),
                                                onPressed: () {
                                                  tableColorIndex1 =
                                                      index; //EditInfoDialog
                                                  /*Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                       ),
                                              );*/

                                                  showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      // set to false if you want to force a rating
                                                      builder: (context) =>
                                                          StatefulBuilder(
                                                              builder: (context,
                                                                      setState) =>
                                                                  EditInfoDialog(
                                                                    livestockModel:
                                                                        live,
                                                                    livestockTypeList:
                                                                        livestockTypeList,
                                                                  )));

                                                  setState(() {});
                                                },
                                                child: Center(
                                                  child: Text(
                                                    "Edit",
                                                    style: GoogleFonts.inter(
                                                      textStyle: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              tableColorIndex1 ==
                                                                      index
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                    minimumSize: Size(60, 30),
                                                    backgroundColor:
                                                        tableColorIndex2 ==
                                                                index
                                                            ? Constants
                                                                .ctaColorGreen
                                                            : Colors
                                                                .transparent,
                                                    side: BorderSide(
                                                        width: 1.0,
                                                        color: Constants
                                                            .ctaColorGreen)),
                                                onPressed: () {
                                                  tableColorIndex2 = index;
                                                  showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      // set to false if you want to force a rating
                                                      builder: (context) =>
                                                          StatefulBuilder(
                                                              builder: (context,
                                                                      setState) =>
                                                                  Dialog(
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              24),
                                                                    ),
                                                                    elevation:
                                                                        0.0,
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent,
                                                                    child: Container(
                                                                        width: MediaQuery.of(context).size.width,
                                                                        //height: 380,
                                                                        padding: EdgeInsets.all(16),
                                                                        constraints: BoxConstraints(
                                                                          minHeight:
                                                                              100,
                                                                          maxWidth:
                                                                              600,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color:
                                                                              Colors.white,
                                                                          shape:
                                                                              BoxShape.rectangle,
                                                                          borderRadius:
                                                                              BorderRadius.circular(24),
                                                                          boxShadow: const [
                                                                            BoxShadow(
                                                                              color: Colors.black26,
                                                                              blurRadius: 10.0,
                                                                              offset: Offset(0.0, 10.0),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        child: SingleChildScrollView(
                                                                            child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(left: 24, right: 24),
                                                                              child: Row(
                                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  Icon(
                                                                                    CupertinoIcons.exclamationmark_circle,
                                                                                    size: 32,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: 12,
                                                                                  ),
                                                                                  Text.rich(
                                                                                    TextSpan(
                                                                                      children: [
                                                                                        TextSpan(
                                                                                          text: "Are sure you want to delete",
                                                                                          style: GoogleFonts.inter(
                                                                                            textStyle: const TextStyle(fontSize: 16, color: Colors.black54, letterSpacing: 0, fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                        TextSpan(
                                                                                          text: "\t${live.name}?",
                                                                                          style: GoogleFonts.inter(
                                                                                            textStyle: const TextStyle(fontSize: 18, color: Colors.black, letterSpacing: 0, fontWeight: FontWeight.bold),
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            SizedBox(height: 16),
                                                                            Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    Navigator.pop(context);

                                                                                    setState(() {});
                                                                                  },
                                                                                  style: TextButton.styleFrom(
                                                                                      minimumSize: Size(200, 50),
                                                                                      side: BorderSide(
                                                                                        width: 1.0,
                                                                                        color: Constants.ctaColorGreen,
                                                                                      ),
                                                                                      backgroundColor: Constants.ctaColorGreen // Background color
                                                                                      ),
                                                                                  child: Text(
                                                                                    'Cancel',
                                                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                                                  ),
                                                                                ),
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    recentAddedLivestock.removeAt(index);
                                                                                    Navigator.pop(context);
                                                                                    setState(() {});
                                                                                  },
                                                                                  style: TextButton.styleFrom(
                                                                                      minimumSize: Size(200, 50),
                                                                                      side: BorderSide(
                                                                                        width: 1.0,
                                                                                        color: Constants.ctaColorGreen,
                                                                                      ),
                                                                                      backgroundColor: Colors.transparent // Background color
                                                                                      ),
                                                                                  child: Text(
                                                                                    'Confrim',
                                                                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ))),
                                                                  )));

                                                  setState(() {});
                                                },
                                                child: Center(
                                                  child: Text(
                                                    "Delete",
                                                    style: GoogleFonts.inter(
                                                      textStyle: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              tableColorIndex2 ==
                                                                      index
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                index < recentAddedLivestock.length - 1
                                    ? Padding(
                                        padding:
                                            EdgeInsets.only(left: 8, right: 8),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: 16,
                                            ),
                                            Divider(
                                              thickness: 0.5,
                                              color: Colors.black54,
                                            ),
                                            SizedBox(
                                              height: 16,
                                            ),
                                          ],
                                        ),
                                      )
                                    : SizedBox.shrink()
                              ],
                            );
                          }),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 16,
        ),
      ],
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLivestock(Constants.business_uid);
  }

  Future<void> getLivestock(int business_uid) async {
    //isLoading = true;
    final response = await http.get(
      Uri.parse(
          '${Constants.articBaseUrl2}get_livestock_by_client/$business_uid/'),
      headers: {'Content-Type': 'application/json'},
    );
    print("dfggh ${response.body}");
    try {
      if (response.statusCode == 200) {
        var responsedata = jsonDecode(response.body);
        Set<String> list1 = {};
        for (var device in responsedata) {
          print("top____exercise.... ${device}");
          LivestockModel livestockModel = LivestockModel.fromJson(device);
          recentAddedLivestock.add(livestockModel);

          list1.add(livestockModel.species);
          list1.toSet();
          livestockTypeList = list1.toList();
          print("dfdghghdfgf ${recentAddedLivestock.length}");
          setState(() {});
        }

        setState(() {});
      } else {
        //isLoading = false;
        setState(() {});
        print(response.reasonPhrase);
      }
    } catch (e) {
      //isLoading = false;
      setState(() {});
      print("An error occurred: $e");
    }
  }
}

class BarChartSample2 extends StatefulWidget {
  BarChartSample2({super.key});
  final Color leftBarColor = Color(0XFF2F4852);
  final Color rightBarColor = Color(0XFFB1EBC0);
  final Color avgColor = Color(0XFFB1EBC0);
  @override
  State<StatefulWidget> createState() => BarChartSample2State();
}

class BarChartSample2State extends State<BarChartSample2> {
  final double width = 15;

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

    final items = [
      barGroup1,
      barGroup2,
      barGroup3,
      barGroup4,
      barGroup5,
      barGroup6,
      barGroup7,
    ];

    rawBarGroups = items;

    showingBarGroups = rawBarGroups;
  }

  String? selectedPeriod;
  List<String> periodList = ["Daily", "Weekly", "Monthly"];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Active Animal",
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Container(
                width: 120,
                height: 35,
                decoration: BoxDecoration(
                    border:
                        Border.all(color: Constants.ctaColorGreen, width: 1.0),
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
                    items: periodList.map<DropdownMenuItem<String>>((value) {
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
                      reservedSize: 28,
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
            height: 12,
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
                  color: Color(0XFF2F4852),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "Within Range",
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400),
                ),
              ),
              SizedBox(
                width: 32,
              ),
              Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(360),
                    color: Color(0XFFB1EBC0)),
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "Product",
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
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '1K';
    } else if (value == 4) {
      text = '5K';
    } else if (value == 8) {
      text = '10K';
    } else if (value == 12) {
      text = '15K';
    } else if (value == 16) {
      text = '20K';
    } else if (value == 20) {
      text = '25K';
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
    final titles = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final Widget text = Text(
      titles[value.toInt()],
      style: const TextStyle(
        color: Color(0xffAAAAAA),
        fontWeight: FontWeight.w500,
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

class AddLivestockDialog extends StatefulWidget {
  final List<String> livestockTypeList;
  const AddLivestockDialog({super.key, required this.livestockTypeList});

  @override
  State<AddLivestockDialog> createState() => _AddLivestockDialogState();
}

class _AddLivestockDialogState extends State<AddLivestockDialog> {
  //List<DeviceTypeModel> deviceTypeList = [];
  DeviceModel? selectedDeviceType;

  String? selectedLivestockType;

  String? selectedDeviceNumber;
  List<String> deviceNumberList = [];

  bool sex = false;
  bool sex1 = false;

  bool isPoisinous = false;
  bool isAlive = false;

  TextEditingController _livestockTypeNumberController =
      TextEditingController();
  FocusNode livestockTypeNumberFocusNode = FocusNode();
  TextEditingController _colorVariant1Controller = TextEditingController();
  FocusNode colorVariant1FocusNode = FocusNode();
  TextEditingController _colorVariant2Controller = TextEditingController();
  FocusNode colorVariant2FocusNode = FocusNode();
  TextEditingController _colorVariant3Controller = TextEditingController();
  FocusNode colorVariant3FocusNode = FocusNode();

  TextEditingController _nameController = TextEditingController();
  FocusNode nameFocusNode = FocusNode();
  TextEditingController _speciesController = TextEditingController();
  FocusNode speciesFocusNode = FocusNode();
  TextEditingController _breedController = TextEditingController();
  FocusNode breedFocusNode = FocusNode();
  TextEditingController _ageController = TextEditingController();
  FocusNode ageFocusNode = FocusNode();
  TextEditingController _weightController = TextEditingController();
  FocusNode weightFocusNode = FocusNode();
  TextEditingController _healthStatusController = TextEditingController();
  FocusNode healthStatusFocusNode = FocusNode();
  TextEditingController _vaccinationStatusController = TextEditingController();
  FocusNode vaccinationStatusFocusNode = FocusNode();
  TextEditingController _medicalHistoryController = TextEditingController();
  FocusNode medicalHistoryFocusNode = FocusNode();
  //TextEditingController _colorVariant3Controller = TextEditingController();
  //FocusNode colorVariant3FocusNode = FocusNode();

  Color colorVariant1 = Colors.white;
  Color colorVariant2 = Colors.white;
  Color colorVariant3 = Colors.white;

  Color getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'grey':
        return Colors.grey;
      case 'blue':
        return Colors.blue;
      case 'brown':
        return Colors.brown;
      // Add more colors as needed
      default:
        return Colors.white; // Default color if not found
    }
  }

  @override
  Widget build(BuildContext context) {
    // var device = deviceTypeList;
    return MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: StatefulBuilder(
            builder: (context1, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0.0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      //height: 380,
                      constraints: BoxConstraints(
                        minHeight: 200,
                        maxWidth: 900,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10.0,
                            offset: Offset(0.0, 10.0),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            height: 60,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Constants.ctaColorGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 8,
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {});
                                      },
                                      icon: Icon(Icons.arrow_back_sharp)),
                                  Spacer(),
                                  Text(
                                    "Add Livestock",
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          letterSpacing: 0,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 24, right: 24),
                            child: CustomCard(
                              elevation: 5,
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Livestock Type",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black),
                                              ),
                                              SizedBox(
                                                height: 4,
                                              ),
                                              Text(
                                                "Code will be generated automatically",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        Constants.ctaTextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                        width: 120,
                                                        height: 45,
                                                        decoration: BoxDecoration(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32)),
                                                        child: Center(
                                                          child: DropdownButton<
                                                              String>(
                                                            dropdownColor:
                                                                Colors.white,
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 12,
                                                                    right: 12),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            value:
                                                                selectedLivestockType,
                                                            isExpanded: true,
                                                            hint: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          8.0),
                                                              child: Text(
                                                                "Select Livestock Type ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontSize:
                                                                        14),
                                                              ),
                                                            ),
                                                            onChanged:
                                                                (newValue) {
                                                              setState(() {
                                                                selectedLivestockType =
                                                                    newValue;
                                                                _livestockTypeNumberController
                                                                    .text = (Random()
                                                                            .nextInt(899999999) +
                                                                        100000)
                                                                    .toString();
                                                              });
                                                            },
                                                            selectedItemBuilder:
                                                                (BuildContext
                                                                    context) {
                                                              return widget
                                                                  .livestockTypeList
                                                                  .map<Widget>(
                                                                      (item) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: item,
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsets
                                                                        .only(
                                                                            left:
                                                                                8.0),
                                                                    child: Text(
                                                                      item,
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                  ),
                                                                );
                                                              }).toList();
                                                            },
                                                            items: widget
                                                                .livestockTypeList
                                                                .map<
                                                                        DropdownMenuItem<
                                                                            String>>(
                                                                    (value) {
                                                              return DropdownMenuItem<
                                                                  String>(
                                                                value: value,
                                                                child:
                                                                    Text(value),
                                                              );
                                                            }).toList(),
                                                            underline:
                                                                Container(),
                                                            // Uncomment if you want to add validation
                                                            // validator: (value) => value == null ? 'Device Type is required' : null,
                                                          ),
                                                        )),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: CustomInputTransparent1(
                                                        controller:
                                                            _livestockTypeNumberController,
                                                        hintText:
                                                            "Livestock Number",
                                                        onChanged: (val) {},
                                                        onSubmitted: (val) {},
                                                        focusNode:
                                                            livestockTypeNumberFocusNode,
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        isPasswordField: false),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Divider(
                                      thickness: 0.5,
                                      color: Colors.black54,
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Device Information",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black),
                                              ),
                                              SizedBox(
                                                height: 4,
                                              ),
                                              Text(
                                                "Unique device information",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        Constants.ctaTextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                             /*     Expanded(
                                                    child: Container(
                                                        width: 120,
                                                        height: 45,
                                                        decoration: BoxDecoration(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32)),
                                                        child: Center(
                                                          child: DropdownButton<
                                                              DeviceModel>(
                                                            dropdownColor:
                                                                Colors.white,
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 12,
                                                                    right: 12),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            value:
                                                                selectedDeviceType,
                                                            isExpanded: true,
                                                            hint: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          8.0),
                                                              child: Text(
                                                                "Select Device Type ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontSize:
                                                                        14),
                                                              ),
                                                            ),
                                                            onChanged:
                                                                (newValue) {
                                                              deviceNumberList =
                                                                  [];
                                                              setState(() {
                                                                selectedDeviceType =
                                                                    newValue;

                                                                deviceNumberList.add(
                                                                    selectedDeviceType!
                                                                        .iccid);
                                                              });
                                                            },
                                                            selectedItemBuilder:
                                                                (BuildContext
                                                                    context) {
                                                              return deviceAvailable
                                                                  .map<Widget>(
                                                                      (item) {
                                                                return DropdownMenuItem<
                                                                    DeviceModel>(
                                                                  value: item,
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsets
                                                                        .only(
                                                                            left:
                                                                                8.0),
                                                                    child: Text(
                                                                      item.deviceId,
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                  ),
                                                                );
                                                              }).toList();
                                                            },
                                                            items: deviceAvailable.map<
                                                                    DropdownMenuItem<
                                                                        DeviceModel>>(
                                                                (DeviceModel
                                                                    value) {
                                                              return DropdownMenuItem<
                                                                  DeviceModel>(
                                                                value: value,
                                                                child: Text(value
                                                                    .deviceId),
                                                              );
                                                            }).toList(),
                                                            underline:
                                                                Container(),
                                                            // Uncomment if you want to add validation
                                                            // validator: (value) => value == null ? 'Device Type is required' : null,
                                                          ),
                                                        )),
                                                  ),*/
                                                ],
                                              ),
                                              SizedBox(
                                                height: 24,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                        width: 120,
                                                        height: 45,
                                                        decoration: BoxDecoration(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32)),
                                                        child: Center(
                                                          child: DropdownButton<
                                                              String>(
                                                            dropdownColor:
                                                                Colors.white,
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 12,
                                                                    right: 12),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            value:
                                                                selectedDeviceNumber,
                                                            isExpanded: true,
                                                            hint: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          8.0),
                                                              child: Text(
                                                                "Select Device iccid ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontSize:
                                                                        14),
                                                              ),
                                                            ),
                                                            onChanged:
                                                                (newValue) {
                                                              setState(() {
                                                                selectedDeviceNumber =
                                                                    newValue;
                                                              });
                                                            },
                                                            selectedItemBuilder:
                                                                (BuildContext
                                                                    context) {
                                                              return deviceNumberList
                                                                  .map<Widget>(
                                                                      (item) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: item,
                                                                  child:
                                                                      Padding(
                                                                    padding: EdgeInsets
                                                                        .only(
                                                                            left:
                                                                                8.0),
                                                                    child: Text(
                                                                      item.toString(),
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                  ),
                                                                );
                                                              }).toList();
                                                            },
                                                            items: deviceNumberList.map<
                                                                    DropdownMenuItem<
                                                                        String>>(
                                                                (value) {
                                                              return DropdownMenuItem<
                                                                  String>(
                                                                value: value,
                                                                child: Text(value
                                                                    .toString()),
                                                              );
                                                            }).toList(),
                                                            underline:
                                                                Container(),
                                                            // Uncomment if you want to add validation
                                                            // validator: (value) => value == null ? 'Device Type is required' : null,
                                                          ),
                                                        )),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Divider(
                                      thickness: 0.5,
                                      color: Colors.black54,
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          "sex",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black),
                                        ),
                                        Expanded(child: Container()),
                                        Transform.scale(
                                          scaleX: 1.7,
                                          scaleY: 1.7,
                                          child: Checkbox(
                                              value: sex1,
                                              side: BorderSide(
                                                  width: 1.2,
                                                  color:
                                                      Constants.ctaColorGreen),
                                              activeColor: Colors.blue,
                                              checkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          360)),
                                              onChanged: (bool? newValue) {
                                                setState(() {
                                                  sex1 = newValue!;
                                                });
                                              }),
                                        ),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          "Female",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black),
                                        ),
                                        SizedBox(
                                          width: 40,
                                        ),
                                        Transform.scale(
                                          scaleX: 1.7,
                                          scaleY: 1.7,
                                          child: Checkbox(
                                              value: sex,
                                              side: BorderSide(
                                                  width: 1.2,
                                                  color:
                                                      Constants.ctaColorGreen),
                                              activeColor: Colors.blue,
                                              checkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          360)),
                                              onChanged: (bool? newValue) {
                                                setState(() {
                                                  sex = newValue!;
                                                });
                                              }),
                                        ),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          "Male",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Divider(
                                      thickness: 0.5,
                                      color: Colors.black54,
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Color Variants",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black),
                                              ),
                                              SizedBox(
                                                height: 4,
                                              ),
                                              Text(
                                                "Colours for the animal",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        Constants.ctaTextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: colorVariant1,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ),
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _colorVariant1Controller,
                                                            hintText:
                                                                "Color Variant 1",
                                                            onChanged: (val) {
                                                              colorVariant1 =
                                                                  getColorFromString(
                                                                      _colorVariant1Controller
                                                                          .text
                                                                          .toLowerCase());
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              colorVariant1 =
                                                                  getColorFromString(
                                                                      _colorVariant1Controller
                                                                          .text
                                                                          .toLowerCase());
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                colorVariant1FocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: colorVariant2,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ),
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _colorVariant2Controller,
                                                            hintText:
                                                                "Color Variant 2",
                                                            onChanged: (val) {
                                                              colorVariant2 =
                                                                  getColorFromString(
                                                                      _colorVariant2Controller
                                                                          .text
                                                                          .toLowerCase());
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              colorVariant1 =
                                                                  getColorFromString(
                                                                      _colorVariant2Controller
                                                                          .text
                                                                          .toLowerCase());
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                colorVariant2FocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: colorVariant3,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ),
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _colorVariant3Controller,
                                                            hintText:
                                                                "Color Variant 3",
                                                            onChanged: (val) {
                                                              colorVariant3 =
                                                                  getColorFromString(
                                                                      _colorVariant3Controller
                                                                          .text
                                                                          .toLowerCase());
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              colorVariant1 =
                                                                  getColorFromString(
                                                                      _colorVariant3Controller
                                                                          .text
                                                                          .toLowerCase());
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                colorVariant3FocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Name",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _nameController,
                                                            hintText: "Name",
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                nameFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Species",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _speciesController,
                                                            hintText: "Species",
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                speciesFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Breed",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _breedController,
                                                            hintText: "Breed",
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                breedFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Age",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _ageController,
                                                            hintText: "Age",
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                ageFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Weight",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _weightController,
                                                            hintText: "Weight",
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                speciesFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Health Status",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _healthStatusController,
                                                            hintText:
                                                                "Health Status",
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                healthStatusFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 10),
                                                child: Text(
                                                  "Birth Date",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: CustomDatePicker(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 10),
                                                child: Text(
                                                  "Last Vet Visit",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                      child:
                                                          CustomDatePicker1()),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Vaccination Status",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _vaccinationStatusController,
                                                            hintText:
                                                                "Vaccination Status",
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                vaccinationStatusFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8, bottom: 4),
                                                child: Text(
                                                  "Medication History",
                                                  style: GoogleFonts.inter(
                                                    textStyle: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child:
                                                        CustomInputTransparent1(
                                                            controller:
                                                                _medicalHistoryController,
                                                            hintText:
                                                                "Medication History",
                                                            maxLines: 4,
                                                            onChanged: (val) {
                                                              setState(() {});
                                                            },
                                                            onSubmitted: (val) {
                                                              setState(() {});
                                                            },
                                                            focusNode:
                                                                medicalHistoryFocusNode,
                                                            textInputAction:
                                                                TextInputAction
                                                                    .next,
                                                            isPasswordField:
                                                                false),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Transform.scale(
                                          scaleX: 1.7,
                                          scaleY: 1.7,
                                          child: Checkbox(
                                              value: isPoisinous,
                                              side: BorderSide(
                                                  width: 1.2,
                                                  color:
                                                      Constants.ctaColorGreen),
                                              activeColor: Colors.blue,
                                              checkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          360)),
                                              onChanged: (bool? newValue) {
                                                setState(() {
                                                  isPoisinous = newValue!;
                                                });
                                              }),
                                        ),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          "Is Poisonous",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black),
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Transform.scale(
                                          scaleX: 1.7,
                                          scaleY: 1.7,
                                          child: Checkbox(
                                              value: isAlive,
                                              side: BorderSide(
                                                  width: 1.2,
                                                  color:
                                                      Constants.ctaColorGreen),
                                              activeColor: Colors.blue,
                                              checkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          360)),
                                              onChanged: (bool? newValue) {
                                                setState(() {
                                                  isAlive = newValue!;
                                                });
                                              }),
                                        ),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          "Is Alive",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 24, right: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  style: TextButton.styleFrom(
                                      minimumSize: Size(110, 50),
                                      side: BorderSide(
                                          width: 1.2,
                                          color: Constants.ctaColorGreen)),
                                  child: Text(
                                    "Go Back",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    createLivestock(context);
                                    setState(() {});
                                  },
                                  style: TextButton.styleFrom(
                                      minimumSize: Size(110, 50),
                                      backgroundColor: Constants.ctaColorGreen,
                                      side: BorderSide(
                                          width: 1.2,
                                          color: Constants.ctaColorGreen)),
                                  child: Text(
                                    "Submit Details",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ))),
                )),
      ),
    );
  }

  @override
  void initState() {
    //getLivestockType();
    //getDeviceType();
    super.initState();
  }

  Future<void> createLivestock(BuildContext context) async {
    if (selectedDeviceType?.deviceId == "") {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("Select device type or device ID"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else if (_colorVariant1Controller.text.isEmpty) {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("Please enter the color"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else if (_nameController.text.isEmpty) {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("Please enter the name"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else if (_speciesController.text.isEmpty) {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("Please enter the species"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else if (_breedController.text.isEmpty) {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("Please the breed type"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else if (_ageController.text.isEmpty) {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("Please enter the age"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else if (_healthStatusController.text.isEmpty) {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("please enter the health status"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else if (isPoisinous == false && isAlive == false) {
      MotionToast.error(
        //title: Text("Success"),
        description: const Text("is animal poisonous or alive"),
        layoutOrientation: TextDirection.rtl,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(
          milliseconds: 2500,
        ),
      ).show(context);
    } else {
      print("Adding livestock...");

      // Prepare the data for the API call
      var live_data = {
        "device_id": selectedDeviceType?.deviceId,
        "business_uid": Constants.business_uid,
        "user_uid": Constants.user_uid,
        "name": _nameController.text,
        "color": _colorVariant1Controller.text,
        "species": _speciesController.text,
        "breed": _breedController.text,
        "birth_date": Constants.datePickerValue,
        "is_poisonous": isPoisinous,
        "is_alive": isAlive,
        "age": _ageController.text,
        "weight": _weightController.text,
        "health_status": _healthStatusController.text,
        "vaccination_status": _vaccinationStatusController.text,
        "medical_history": _medicalHistoryController.text,
        "last_vet_visit": Constants.datePickerValue1
      };
      print(live_data);

      // Initialize the WorkoutService and make the API call
      AuthenticationApiService service =
          AuthenticationApiService(baseUrl: Constants.articBaseUrl2);
      var response = await service.AddNewLivestock(live_data);

      if (response.statusCode == 201) {
        MotionToast.success(
          //title: Text("Success"),
          description: const Text("Livestock added Successfully"),
          layoutOrientation: TextDirection.rtl,
          animationType: AnimationType.fromTop,
          width: 400,
          height: 55,
          animationDuration: const Duration(
            milliseconds: 2500,
          ),
        ).show(context);
        setState(() {});
        Navigator.pop(context);
        print("livestock submitted!");
      } else {
        print("Failed to submit livestock: ${response.body}");
      }

      // Optionally update UI here with setState
      setState(() {});
    }

    //Constants.showAddButton = false;
    setState(() {});
  }
}
