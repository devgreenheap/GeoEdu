import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';

import '../../edit_profile_screen/edit_profile_screen_controller.dart';

class Step3 extends StatelessWidget {
  final EditProfileScreenController controller;

  const Step3({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDynamicField(
          label: "Email",
          hint: "Enter Email",
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          readOnly: true,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Phone",
          hint: "Enter Phone Number",
          controller: controller.phoneNumberController,
          keyboardType: TextInputType.phone,
          isRequired: true,
          readOnly: true,
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Address 1",
          hint: "Enter Address Line 1",
          controller: controller.address1Controller,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Address 2",
          hint: "Enter Address Line 2",
          controller: controller.address2Controller,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "City",
          hint: "Enter City",
          controller: controller.cityController,
          icon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 20),
        GetBuilder<EditProfileScreenController>(
          builder: (c) {
            return Column(
              children: [
                CustomDynamicDropdown(
                  label: "Country",
                  hint: "Select Country",
                  value: c.selectedCountry,
                  items: c.countryList,
                  isRequired: true,
                  onChanged: c.selectCountry,
                ),
                const SizedBox(height: 20),
                CustomDynamicDropdown(
                  label: "State",
                  hint: "Select State",
                  value: c.selectedState,
                  items: c.stateList,
                  onChanged: c.selectState,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Zipcode",
          hint: "Enter Zipcode",
          controller: controller.zipcodeController,
          keyboardType: TextInputType.number,
          icon: Icons.pin_drop_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Bank Name",
          hint: "Enter Bank Name",
          controller: controller.bankNameController,
          keyboardType: TextInputType.name,
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Account Number",
          hint: "Enter Account Number",
          controller: controller.accountNumberController,
          keyboardType: TextInputType.number,
          icon: Icons.credit_card_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "IFSC Code",
          hint: "Enter IFSC Code",
          controller: controller.ifscCodeController,
          keyboardType: TextInputType.text,
          icon: Icons.tag_outlined,
        ),
        const SizedBox(height: 20),
        CustomDynamicField(
          label: "Branch Name",
          hint: "Enter Branch Name",
          controller: controller.branchNameController,
          keyboardType: TextInputType.name,
          icon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 20),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: CustomButton(
                text: "Previous",
                isPrimary: false,
                onTap: controller.previous,
              ),
            ),
            Expanded(
              child: CustomButton(
                text: "Update",
                onTap: controller.saveMoreDetails,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
