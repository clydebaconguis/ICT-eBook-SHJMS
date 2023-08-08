import 'dart:math';

import 'package:flutter/material.dart';

import 'custom_clipper.dart';

class BezierContainer extends StatelessWidget {
  const BezierContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -pi / 3.6,
      child: ClipPath(
        clipper: ClipPainter(),
        child: Container(
          height: MediaQuery.of(context).size.height * .5,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(141, 31, 31, 1),
                Color.fromRGBO(141, 31, 31, 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class BezierContainer2 extends StatelessWidget {
//   const BezierContainer2({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Transform.rotate(
//       angle: -4,
//       child: ClipPath(
//         clipper: ClipPainter(),
//         child: Container(
//           height: MediaQuery.of(context).size.height * .5,
//           width: MediaQuery.of(context).size.width,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Color.fromARGB(200, 245, 179, 216),
//                 Color.fromARGB(255, 228, 23, 146)
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
