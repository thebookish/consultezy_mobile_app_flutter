import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppointmentBookingSection extends StatefulWidget {
  const AppointmentBookingSection({Key? key}) : super(key: key);

  @override
  _AppointmentBookingSectionState createState() => _AppointmentBookingSectionState();
}

class _AppointmentBookingSectionState extends State<AppointmentBookingSection> {
  bool _showAppointments = false;

  Future<List<QueryDocumentSnapshot>> _fetchAppointments(String consultancyId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('consultancies')
        .doc(consultancyId)
        .collection('appointments')
        .get();

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showAppointments = !_showAppointments;
                });
              },
              child: Text(
                _showAppointments ? 'Hide Appointments' : 'Manage Appointments',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: const Color(0xff00adb5), // Button color
              ),
            ),

            if (_showAppointments)
              user != null
                  ? FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _fetchAppointments(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Text('Error loading appointments');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No appointments found');
                  }

                  final appointments = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index].data() as Map<String, dynamic>;
                      final appointmentId = appointments[index].id;

                      return AppointmentCard(
                        appointment: appointment,
                        appointmentId: appointmentId,
                      );
                    },
                  );
                },
              )
                  : const Text('Please log in to manage appointments'),
          ],
        ),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String appointmentId;

  const AppointmentCard({required this.appointment, required this.appointmentId, Key? key}) : super(key: key);

  Future<void> _approveAppointment() async {
    await FirebaseFirestore.instance
        .collection('consultancies')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('appointments')
        .doc(appointmentId)
        .update({'approved': true});
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailScreen(
          appointment: appointment,
          appointmentId: appointmentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToDetails(context),
      child: Card(
        surfaceTintColor: Color(0xff00adb5),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name: ${appointment['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Program: ${appointment['program']}'),
              Text('University: ${appointment['university']}'),
              Text('Approved: ${appointment['approved'] ? "Yes" : "No"}'),
              const SizedBox(height: 8),
              Text(
                'Appointment Time: ${appointment['timestamp'].toDate()}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String appointmentId;

  const AppointmentDetailScreen({required this.appointment, required this.appointmentId, Key? key}) : super(key: key);

  Future<void> _approveAppointment() async {
    await FirebaseFirestore.instance
        .collection('consultancies')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('appointments')
        .doc(appointmentId)
        .update({'approved': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xff00adb5), // AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${appointment['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text('Program: ${appointment['program']}'),
            Text('University: ${appointment['university']}'),
            Text('Country: ${appointment['country']}'),
            Text('IELTS Score: ${appointment['ieltsScore']}'),
            Text('Mobile: ${appointment['mobile']}'),
            Text('Email: ${appointment['email']}'),
            const SizedBox(height: 10),
            Text(
              'Appointment Time: ${appointment['timestamp'].toDate()}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Text('Approved: ${appointment['approved'] ? "Yes" : "No"}'),
            const SizedBox(height: 20),
            if (!appointment['approved'])
              ElevatedButton(
                onPressed: _approveAppointment,
                child: const Text('Approve Appointment', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xff00adb5), // Button color
                ),
              ),
          ],
        ),
      ),
    );
  }
}
