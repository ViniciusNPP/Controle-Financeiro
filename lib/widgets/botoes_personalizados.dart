import 'package:flutter/material.dart';

class BotoesPersonalizados extends StatelessWidget {
const BotoesPersonalizados({ super.key });

  @override
  Widget build(BuildContext context){
    return Container();
  }
}
enum Ground {
  foreground,
  background
}

ButtonStyle estiloBotao({
  Color corForeGround = const Color(0xFFece6f0),
  Color corBackGround = const Color(0xFFece6f0),
  bool isSide = false,
}) {
  return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(corForeGround),
      backgroundColor: WidgetStatePropertyAll(corBackGround),
      side: WidgetStatePropertyAll(
        BorderSide(color: isSide ? (corForeGround == Color(0xFFece6f0) ? corBackGround : corForeGround) : Color(0xFFece6f0))
      ),
      shadowColor: WidgetStatePropertyAll(Color(0xFFece6f0)),
      mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
      ),
    );
}