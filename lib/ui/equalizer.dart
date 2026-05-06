import 'package:mp6/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mp6/custom_widgets.dart';
import 'package:provider/provider.dart';

class Equalizer extends StatefulWidget {
  const Equalizer({super.key});

  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  late final savedProvider;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    savedProvider = Provider.of<PlayerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    savedProvider.setGainList();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    final backgroundColor = provider.themeData["equalizer"]!["background"];
    final iconColor = provider.themeData["equalizer"]!["icon"];
    final textColor = provider.themeData["equalizer"]!["text"];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Center(child: Text("Эквалайзер", style: TextStyle(color: textColor))),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(
          color: iconColor,
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: provider.themeData["equalizer"]?["backgroundImage"] == null ? null :
            DecorationImage(
                fit: BoxFit.cover,
                image: provider.themeData["equalizer"]!["backgroundImage"],
            )
        ),
        child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: screenHeight * 0.7,
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
                      shrinkWrap: true,
                      itemCount: provider.bands!.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        return BandSlider(
                            context: context,
                            band: provider.bands![index],
                            textColor: textColor!,
                            iconColor: iconColor!,
                       );
                     },
                     separatorBuilder: (BuildContext context, int index) {
                      return Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 0.01 * screenWidth));
                    }
                   ),
                  ),
                ],
              ),
          ),
      )
      );
  }
}
