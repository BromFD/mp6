import 'package:chuni_player_revamped/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:chuni_player_revamped/custom_widgets.dart';
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
    final backgroundColor = provider.colorScheme["background"];
    final iconColor = provider.colorScheme["icon"];
    final textColor = provider.colorScheme["text"];

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
      body: SafeArea(

            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: screenHeight * 0.7,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
                    shrinkWrap: true,
                    itemCount: provider.bands.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      return BandSlider(
                          context: context,
                          band: provider.bands[index],
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
        )
      );
  }
}
