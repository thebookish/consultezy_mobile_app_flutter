import 'package:consultezy/component/button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentForm extends StatefulWidget {
  final String consultancyId;
  const AppointmentForm({Key? key,  required this.consultancyId}) : super(key: key);

  @override
  _AppointmentFormState createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _ieltsScoreController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      await FirebaseFirestore.instance..collection('consultancies')
          .doc(widget.consultancyId)
          .collection('appointments').add({
        'country': _countryController.text,
        'ieltsScore': _ieltsScoreController.text,
        'program': _programController.text,
        'university': _universityController.text,
        'mobile': _mobileController.text,
        'email': _emailController.text,
        'name': _nameController.text,
        'approved': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment request submitted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // Adjust width as needed
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Book an Appointment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(labelText: 'Your chosen country',

                            focusedBorder:  UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
                ),
                        ),

                        validator: (value) => value!.isEmpty ? 'Please enter a country' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _ieltsScoreController,
                        decoration: const InputDecoration(labelText: 'IELTS Score', focusedBorder:  UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
                        ),),
                        validator: (value) => value!.isEmpty ? 'Please enter IELTS score' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _programController,
                        decoration: const InputDecoration(labelText: 'Program', focusedBorder:  UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
                        ),),
                        validator: (value) => value!.isEmpty ? 'Please enter a program' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _universityController,
                        decoration: const InputDecoration(labelText: 'University', focusedBorder:  UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
                        ),),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile', focusedBorder:  UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
                        ),),
                        validator: (value) => value!.isEmpty ? 'Please enter your mobile number' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', focusedBorder:  UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
                        ),),
                        validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name', focusedBorder:  UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff00adb5), width: 2.0),
                        ),),
                        validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xff00adb5)),),
                    style: TextButton.styleFrom(primary: const Color(0xff00adb5)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Submit',style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(primary: const Color(0xff00adb5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countryController.dispose();
    _ieltsScoreController.dispose();
    _programController.dispose();
    _universityController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class AppointmentBookingSection extends StatelessWidget {
  final String consultancyId;
  const AppointmentBookingSection({Key? key, required this.consultancyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Book an Appointment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Button(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return  AppointmentForm(consultancyId: consultancyId,);
              },
            );
          },
          text: 'Request Appointment',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}