import 'mobile_account_widgets.dart';
import '../../widgets/mobile_forms.dart';
import '../../gasmon/gas_theme.dart';
import '../../gasmon/gas_widgets.dart';
import 'package:flutter/material.dart';

class TermsOfUse extends StatefulWidget {
  const TermsOfUse({super.key});

  @override
  State<TermsOfUse> createState() => _TermsOfUseState();
}

class _TermsOfUseState extends State<TermsOfUse> {
  @override
  Widget build(BuildContext context) {
    if (isPhoneLayout(context)) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          GPanel(padding: const EdgeInsets.all(16), child: _termsContent())
        ],
      );
    }
    return AccountCard(
      elevation: isPhoneLayout(context) ? 0 : 5,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 12),
          side: isPhoneLayout(context)
              ? const BorderSide(color: GasPalette.border)
              : BorderSide.none),
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: _termsContent(),
        ),
      ),
    );
  }

  Widget _termsContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildTopic(context, "Terms and Conditions"),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildParagraph2(context,
              "These Terms and Conditions ('Agreement') constitute a legally binding agreement between you ('User,' 'you,' or 'your') and Silver Spectrum ('Company,' 'we,' 'us,' or 'our') governing your use of our platform ('Platform'). By accessing or using our services, you agree to be bound by this Agreement. If you do not agree to these terms, you must immediately cease using the Platform."),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildTitle1(context, "1. Definitions"),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildParagraph1(context,
              "'Platform' refers to the online application or website where users can upload images, powerlines, and towers for generating inspection reports, including all services provided by Silver Spectrum."),
          _buildParagraph1(context,
              "'Content' refers to any images, files, data, or other materials uploaded or generated on the Platform by the User."),
          _buildParagraph1(context,
              "'User' refers to any individual or entity accessing or using the Platform."),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildTitle1(context, "2. Acceptance of Terms"),
          _buildParagraph2(context,
              "By using the Platform, you confirm that you are at least 18 years of age or possess legal parental/guardian consent, and you are fully able and competent to enter into and comply with this Agreement. If you are using the Platform on behalf of an organization or entity, you represent and warrant that you are authorized to accept this Agreement on its behalf."),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildTitle1(context, "3. Modifications to Terms"),
          _buildParagraph2(context,
              "Silver Spectrum reserves the right to modify or update this Agreement at any time. Any changes will be posted on this page with an updated 'Last Updated' date. It is your responsibility to review this Agreement periodically. Your continued use of the Platform after any changes constitutes acceptance of the new terms."),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildTitle1(context, "4. Account Creation and Responsibilities"),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildParagraph1(context,
              "Users are required to create an account to access certain features of the Platform. You agree to provide accurate, current, and complete information during registration and update such information as necessary."),
          _buildParagraph1(context,
              "You are responsible for maintaining the confidentiality of your account and password. You agree to notify us immediately of any unauthorized use of your account or any other breach of security."),
          _buildParagraph1(context,
              "Silver Spectrum will not be liable for any losses or damages resulting from your failure to safeguard your account and password."),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
          _buildTitle1(context, "5. User Conduct and Obligations"),
          SizedBox(
            height: 8,
          ),
          _buildParagraph2(
              context, "By using the Platform, you agree that you will:"),
          SizedBox(
            height: 8,
          ),
          _buildParagraph1(context,
              "Use the Platform only for lawful purposes and in accordance with this Agreement."),
          _buildParagraph1(context,
              "Not upload, post, or transmit any content that is illegal, harmful, threatening, defamatory, obscene, infringing, or otherwise objectionable."),
          _buildParagraph1(context,
              "Not impersonate any person or entity or falsely state or misrepresent your affiliation with a person or entity."),
          _buildParagraph1(context,
              "Not engage in unauthorized access to or tampering with the Platform, including attempts to probe, scan, or test the vulnerability of any system or network."),
          _buildParagraph1(context,
              "Not distribute malware, spyware, or any other malicious software that may disrupt the functionality of the Platform."),
          SizedBox(
            height: isPhoneLayout(context) ? 8 : 16,
          ),
        ],
      );
}

Widget _buildTitle1(BuildContext context, String title) {
  if (isPhoneLayout(context)) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: GasPalette.border))),
      child: Text(title, style: gasTitle(context).copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
  return Text(
    title,
    style: accountInter(
      context,
      textStyle: TextStyle(
          fontSize: isPhoneLayout(context) ? 16 : 18,
          color: Color(0XFF282828),
          letterSpacing: 0,
          fontWeight:
              isPhoneLayout(context) ? FontWeight.w700 : FontWeight.w500),
    ),
  );
}

Widget _buildTopic(BuildContext context, String title) {
  return Text(
    title,
    style: accountInter(
      context,
      textStyle: TextStyle(
          fontSize: isPhoneLayout(context) ? 18 : 22,
          color: Color(0XFF282828),
          letterSpacing: 0,
          fontWeight: FontWeight.w600),
    ),
  );
}

Widget _buildParagraph1(BuildContext context, String title) {
  return Row(
    crossAxisAlignment: isPhoneLayout(context)
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Container(
        width: 5,
        height: 5,
        margin: EdgeInsets.only(top: isPhoneLayout(context) ? 12 : 0),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPhoneLayout(context) ? GasPalette.muted : Colors.black),
      ),
      SizedBox(
        width: 8,
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            title,
            style: accountInter(
              context,
              textStyle: TextStyle(
                  fontSize: 14,
                  color:
                      isPhoneLayout(context) ? GasPalette.ink2 : Colors.black,
                  letterSpacing: isPhoneLayout(context) ? 0 : 1.08,
                  height: 1.6,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildParagraph2(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      title,
      style: accountInter(
        context,
        textStyle: TextStyle(
            fontSize: 14,
            color: isPhoneLayout(context) ? GasPalette.ink2 : Colors.black,
            letterSpacing: isPhoneLayout(context) ? 0 : 1.08,
            height: 1.6,
            fontWeight: FontWeight.w400),
      ),
    ),
  );
}
