import 'package:flutter/material.dart';
import 'package:geoedu/screen/edit_profile_new/widget/textfieldwidget.dart';

import '../../edit_profile_screen/edit_profile_screen_controller.dart';


class Step3Professor extends StatefulWidget {
  final EditProfileScreenController controller;

  const Step3Professor({super.key,required this.controller});

  @override
  State<Step3Professor> createState() => _Step3ProfessorState();
}

class _Step3ProfessorState extends State<Step3Professor> {
  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          CustomDynamicField(label: "Designation", hint: "Enter Your Designation", controller: TextEditingController(),isRequired: true,),
          SizedBox(height: 20,),
          CustomDynamicField(label: "Years of Experience", hint: "Enter Your Experience In Number eg: “2“", controller: TextEditingController(),isRequired: true,),
          SizedBox(height: 20,),
          CustomDynamicField(label: "Area of Expertise", hint: "Enter Your Area of Expertise", controller: TextEditingController(),isRequired: true,),
          SizedBox(height: 20,),
          CustomDynamicField(label: "Short Bio", hint: "Enter Short Bio", controller: TextEditingController(),isRequired: true,),
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
