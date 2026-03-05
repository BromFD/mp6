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
      appBar: AppBar(
        title: Center(child: Text("ChuniPlayer", style: TextStyle(color: textColor))),
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
          child: ListView(
            children: [
              //Тут просто кнопки для перехода между страницами

              SizedBox(
                height: 0.1 * screenHeight,
                child: MenuEntry(
                  onTap: () {
                    Navigator.pushNamed(context, "/mediateka");
                  },
                  text: Text('Медиатека', style: TextStyle(color: textColor, fontSize: screenHeight * 0.025),),
                  padding: Padding(padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05)),
                  child: Icon(Icons.folder, color: iconColor, size: screenHeight * 0.05,),
                ),
              ),

              SizedBox(
                height: 0.1 * screenHeight,
                child: MenuEntry(
                  onTap: () {
                    Navigator.pushNamed(context, "/playlist");
                  },
                  text: Text('Плейлисты', style: TextStyle(color: textColor, fontSize: screenHeight * 0.025),),
                  padding: Padding(padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05)),
                  child: Icon(Icons.playlist_play_sharp, color: iconColor, size: screenHeight * 0.05,),
                ),
              ),

              SizedBox(
                height: 0.1 * screenHeight,
                child: MenuEntry(
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  text: Text('Настройки', style: TextStyle(color: textColor, fontSize: screenHeight * 0.025),),
                  padding: Padding(padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05)),
                  child: Icon(Icons.settings, color: iconColor, size: screenHeight * 0.05,),
                ),
              )

            ],
          )
        ),
    );
  }
}
