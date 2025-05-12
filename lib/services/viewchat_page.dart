import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:hosp_test/components/appointment_card.dart';
import 'package:hosp_test/utils/config.dart';

class ViewchatPage extends StatefulWidget {
  const ViewchatPage({super.key});

  @override
  State<ViewchatPage> createState() => _ViewchatPage();
}

enum FilterStatus { upcoming, complete, cancel }

class _ViewchatPage extends State<ViewchatPage> {
  FilterStatus status = FilterStatus.upcoming;
  Alignment _alignment = Alignment.centerLeft;
  List<dynamic> schedules = [
    {
      "doctor_name": "Dr Ramesh Babu",
      "doctor_profile": "assets/doctor1.jpeg",
      "category": "Cardiology",
      "status": FilterStatus.upcoming,
    },
    {
      "doctor_name": "Dr Ramesh Babu",
      "doctor_profile": "assets/doctor1.jpeg",
      "category": "Cardiology",
      "status": FilterStatus.complete,
    },
    {
      "doctor_name": "Dr Ramesh Babu",
      "doctor_profile": "assets/doctor1.jpeg",
      "category": "Cardiology",
      "status": FilterStatus.complete,
    },
    {
      "doctor_name": "Dr Ramesh Babu",
      "doctor_profile": "assets/doctor1.jpeg",
      "category": "Cardiology",
      "status": FilterStatus.cancel,
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredSchedules = schedules.where((var schedule) {
      // switch (schedule['status']) {
      //   case 'upcoming':
      //     schedule['status'] = FilterStatus.upcoming;
      //     break;
      //   case 'complete':
      //     schedule['status'] = FilterStatus.complete;
      //     break;
      //   case 'cancel':
      //     schedule['status'] = FilterStatus.cancel;
      //     break;
      // }
      return schedule['status'] == status;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          top: 20,
          right: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Chats',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
            ),

            Center(
                child: const Text(
              'Coming Soon...',
              style: TextStyle(fontSize: 21),
            )),
            // Stack(
            //   children: [
            //     Container(
            //       width: double.infinity,
            //       height: 40,
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         borderRadius: BorderRadius.circular(20),
            //       ),
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           for (FilterStatus filterStatus in FilterStatus.values)
            //             Expanded(
            //               child: GestureDetector(
            //                 onTap: () {
            //                   setState(
            //                     () {
            //                       if (filterStatus == FilterStatus.upcoming) {
            //                         status = FilterStatus.upcoming;
            //                         _alignment = Alignment.centerLeft;
            //                       } else if (filterStatus ==
            //                           FilterStatus.complete) {
            //                         status = FilterStatus.complete;
            //                         _alignment = Alignment.center;
            //                       } else if (filterStatus ==
            //                           FilterStatus.cancel) {
            //                         status = FilterStatus.cancel;
            //                         _alignment = Alignment.centerRight;
            //                       }
            //                     },
            //                   );
            //                 },
            //                 child: Center(child: Text(filterStatus.name)),
            //               ),
            //             ),
            //         ],
            //       ),
            //     ),
            //     AnimatedAlign(
            //       alignment: _alignment,
            //       duration: const Duration(
            //         milliseconds: 200,
            //       ),
            //       child: Container(
            //         width: 100,
            //         height: 40,
            //         decoration: BoxDecoration(
            //           color: Config.primaryColor,
            //           borderRadius: BorderRadius.circular(20),
            //         ),
            //         child: Center(
            //           child: Text(
            //             status.name,
            //             style: const TextStyle(
            //                 color: Colors.white, fontWeight: FontWeight.bold),
            //           ),
            //         ),
            //       ),
            //     )
            //   ],
            // ),
            Config.spaceSmall,
            // Expanded(
            //   child: ListView.builder(
            //     itemCount: filteredSchedules.length,
            //     itemBuilder: ((context, index) {
            //       var schedule = filteredSchedules[index];
            //       bool isLastElement = filteredSchedules.length + 1 == index;
            //       return Card(
            //         shape: RoundedRectangleBorder(
            //             side: const BorderSide(
            //               color: Colors.grey,
            //             ),
            //             borderRadius: BorderRadius.circular(20)),
            //         margin: !isLastElement
            //             ? const EdgeInsets.only(bottom: 20)
            //             : EdgeInsets.zero,
            //         child: Padding(
            //           padding: const EdgeInsets.all(15),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.stretch,
            //             children: [
            //               Row(
            //                 children: [
            //                   CircleAvatar(
            //                     backgroundImage:
            //                         AssetImage(schedule['doctor_profile']),
            //                   ),
            //                   const SizedBox(
            //                     width: 10,
            //                   ),
            //                   Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     children: [
            //                       Text(
            //                         schedule['doctor_name'],
            //                         style: const TextStyle(
            //                             color: Colors.black,
            //                             fontWeight: FontWeight.w700),
            //                       ),
            //                       const SizedBox(
            //                         height: 5,
            //                       ),
            //                       Text(
            //                         schedule['category'],
            //                         style: const TextStyle(
            //                             color: Colors.grey,
            //                             fontWeight: FontWeight.w600),
            //                       ),
            //                     ],
            //                   ),
            //                 ],
            //               ),
            //               const SizedBox(
            //                 height: 15,
            //               ),
            //               const ScheduleCard(),
            //               const SizedBox(
            //                 height: 15,
            //               ),
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   Expanded(
            //                     child: OutlinedButton(
            //                       onPressed: () {},
            //                       child: const Text(
            //                         'cancel',
            //                         style:
            //                             TextStyle(color: Config.primaryColor),
            //                       ),
            //                     ),
            //                   ),
            //                   const SizedBox(
            //                     width: 20,
            //                   ),
            //                   Expanded(
            //                     child: OutlinedButton(
            //                       style: OutlinedButton.styleFrom(
            //                         backgroundColor: Config.primaryColor,
            //                       ),
            //                       onPressed: () {},
            //                       child: const Text(
            //                         'Reschedule',
            //                         style: TextStyle(color: Colors.white),
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ],
            //           ),
            //         ),
            //       );
            //     }),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.calendar_today,
            color: Config.primaryColor,
            size: 15,
          ),
          SizedBox(
            width: 5,
          ),
          Text(
            'Monday , 04/08/2023',
            style: TextStyle(color: Config.primaryColor),
          ),
          SizedBox(
            width: 20,
          ),
          Icon(
            Icons.access_alarm,
            color: Config.primaryColor,
            size: 17,
          ),
          SizedBox(
            width: 5,
          ),
          Flexible(
            child: Text(
              '10:20 AM',
              style: TextStyle(color: Config.primaryColor),
            ),
          )
        ],
      ),
    );
  }
}
