import 'package:chuni_player_revamped/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:chuni_player_revamped/custom_widgets.dart';
import 'package:provider/provider.dart';


class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    final backgroundColor = provider.colorScheme["background"];
    final iconColor = provider.colorScheme["icon"];
    final textColor = provider.colorScheme["text"];
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.15),
            child: ListView(
              children: [

                Center(
                  child: Container(
                    width: screenWidth * 0.25,
                    height: screenHeight * 0.075,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: iconColor,
                    ),
                    child: Center(child: Text("mp6", style: TextStyle(fontSize: screenHeight * 0.035, color: backgroundColor, fontWeight: FontWeight(1000)),),),
                  ),
                ),

                Padding(padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: screenWidth * 0.1,
                  children: [

                    MenuEntry(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: textColor,
                      ),
                        action: () => provider.loaded ? Navigator.pushNamed(context, "/mediateka") : null,
                        child: Padding(
                          padding: EdgeInsets.all(screenHeight * 0.025),
                          child: Icon(Icons.folder_outlined, color: backgroundColor, size: screenHeight * 0.075,),
                        ),
                    ),

                    MenuEntry(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: textColor,
                      ),
                      action: () => provider.loaded ? Navigator.pushNamed(context, "/playlist") : null,
                      child: Padding(
                        padding: EdgeInsets.all(screenHeight * 0.025),
                        child: Icon(Icons.playlist_play_outlined, color: backgroundColor, size: screenHeight * 0.075,),
                      ),
                    ),

                  ],
                ),

                Padding(padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: screenWidth * 0.1,
                  children: [

                    MenuEntry(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: textColor,
                      ),
                      action: () => provider.loaded ? Navigator.pushNamed(context, "/search&load") : null,
                      child: Padding(
                        padding: EdgeInsets.all(screenHeight * 0.025),
                        child: Icon(Icons.search_outlined, color: backgroundColor, size: screenHeight * 0.075,),
                      ),
                    ),

                    MenuEntry(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: textColor,
                      ),
                      action: () => provider.loaded ? Navigator.pushNamed(context, "/equalizer") : null,
                      child: Padding(
                        padding: EdgeInsets.all(screenHeight * 0.025),
                        child: Icon(Icons.tune_outlined, color: backgroundColor, size: screenHeight * 0.075,),
                      ),
                    ),

                  ],
                ),

                Padding(padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: screenWidth * 0.1,
                  children: [

                    MenuEntry(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: textColor,
                      ),
                      action: () => provider.loaded ? Navigator.pushNamed(context, "/settings") : null,
                      child: Padding(
                        padding: EdgeInsets.all(screenHeight * 0.025),
                        child: Icon(Icons.settings_outlined, color: backgroundColor, size: screenHeight * 0.075,),
                      ),
                    ),

                  ],
                ),

              ],
            ),
          )
        ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: iconColor,
        onPressed: () async {
          try {
            await provider.shareLogFile();
          } catch(e) {
            showNotification("Ошибка библиотеки SharePlus: ${e.toString()}");
          }
        },
        child: Icon(Icons.error, color: backgroundColor,),
      ),
    );
  }
}
