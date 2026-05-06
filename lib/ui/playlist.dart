import 'package:mp6/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mp6/custom_widgets.dart';
import 'package:provider/provider.dart';

class Playlist extends StatelessWidget {
  const Playlist({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    final isUserAddToExistingPlaylist = provider.isUserAddToExistingPlaylist;
    final backgroundColor = provider.themeData["playlist"]!["background"];
    final iconColor = provider.themeData["playlist"]!["icon"];
    final textColor = provider.themeData["playlist"]!["text"];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Center(child: Text("Плейлисты", style: TextStyle(color: textColor))),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(
          color: iconColor,
        ),
        leading: isUserAddToExistingPlaylist ? SizedBox.shrink() :
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, "/");
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: provider.themeData["playlist"]?["backgroundImage"] == null ? null :
            DecorationImage(
                fit: BoxFit.cover,
                image: provider.themeData["playlist"]!["backgroundImage"],
            )
        ),
        child: SafeArea(
          child: ListView.separated(
              itemBuilder: (BuildContext context, int index) {
                return PlaylistTile(
                    textColor: textColor!,
                    iconColor: iconColor!,
                    context: context,
                    index: index
                );
              },
              itemCount: provider.playlists.isEmpty ? 0 : provider.playlists.length,
            separatorBuilder: (BuildContext context, int index) {
                return Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 0.015 * screenHeight));
            },
          )
        ),
      ),
      floatingActionButton: isUserAddToExistingPlaylist ? SizedBox.shrink() :
      FloatingActionButton.large(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return PlaylistCreationAlertDialog(context: context);
              }
          );
        },
        child: Icon(Icons.add, color: iconColor,),

      )
    );
  }
}
