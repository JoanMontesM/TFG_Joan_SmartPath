import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        
        children: [
          Stack( 
            children: [
              Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.white,
              ),
              Align(
                alignment: Alignment.center,
                child: Image.asset('images/smartpath_logo.png',
                width: 350,
                ),
              ),
              Align(
                alignment: Alignment(0, -0.51),
                child: Image.asset('images/smartpath_brand.png',
                width: 250,
                height: 250,),
              ),
              Align(
                alignment: Alignment(0, 0.5),
                child: GestureDetector(
                  onTap: (){
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: 200,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: opacPrimaryColor,
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0,5),
                        )
                      ]
                    ),
                    child: 
                    Text(
                      "Iniciar",
                      style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, 
                      fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}