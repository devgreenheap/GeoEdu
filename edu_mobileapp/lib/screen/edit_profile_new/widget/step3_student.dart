import 'package:flutter/material.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';

import '../../edit_profile_screen/edit_profile_screen_controller.dart';


class Step3Student extends StatefulWidget {
  final EditProfileScreenController controller;

  const Step3Student({super.key,required this.controller});

  @override
  State<Step3Student> createState() => _Step3StudentState();
}

class _Step3StudentState extends State<Step3Student> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomDynamicDropdown(label: "Parent / Guardian", items: ["Parent","Guardian"],isRequired: true,onChanged: (value) => widget.controller.selectedParentType = value, value: widget.controller.selectedParentType),
        SizedBox(height: 20,),
        CustomDynamicField(label: "Father Name", hint: "Enter Father Name", controller: TextEditingController(),isRequired: true,),
        SizedBox(height: 20,),
        CustomDynamicField(label: "Father Role", hint: "Enter Father Role", controller: TextEditingController(),isRequired: true,),
        SizedBox(height: 20,),
        CustomDynamicField(label: "Mother Name", hint: "Enter Mother Name", controller: TextEditingController(),isRequired: true,),
        SizedBox(height: 20,),
        CustomDynamicField(label: "Mother Role", hint: "Enter Mother Role", controller: TextEditingController(),isRequired: true,),
        SizedBox(height: 30,),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: CustomButton(text: "<<< Previous", onTap: (){
                widget.controller.previous();
              }),
            ),
            Expanded(
              child: CustomButton(text: "Register", onTap: (){
                widget.controller.previous();

              }),
            ),
          ],
        )
      ]
    );
  }
}
