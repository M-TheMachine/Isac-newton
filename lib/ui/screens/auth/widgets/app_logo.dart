import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../utils/ui_utils.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(context) => SizedBox(
        height: 130,
        child: 
          Image.asset(
          UiUtils.getImagePath("isac_newton_logo.png")
        ),
        
        // child: SvgPicture.asset(
        //   UiUtils.getImagePath("isac_newton_logo.png"),
        //   color: Theme.of(context).primaryColor,
        // ),
      );
}
