import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:chuni_player_revamped/provider/provider.dart';
import 'package:marquee/marquee.dart';

// Этот виджет отвечает за пункты меню на стартовом экране
class MenuEntry extends StatelessWidget {
  final Text? text;
  final GestureTapCallback? onTap;
  final Widget? child;
  final Padding? padding;
  final BoxDecoration? decoration;

  const MenuEntry({
    super.key,
    required this.text,
    required this.onTap,
    required this.child,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration ?? BoxDecoration(),
      child: InkWell(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                child ?? SizedBox.shrink(),
                padding ?? SizedBox.shrink(),
                text ?? SizedBox.shrink(),
              ],
            ),
          ),
    );
  }
}

// Этот виджет отвечает за отдельные пункты настроек
class SettingsEntry extends StatelessWidget {
  final Widget? text;
  final Icon? icon;
  final GestureTapCallback? onTap;

  const SettingsEntry({
    super.key,
    required this.text,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints){
          double width = constraints.maxWidth;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                child: text ?? SizedBox.shrink(),
              ),
              icon ?? SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

//Этот виджет объединяет отдельные пункты настроек воедино
class SettingSector extends StatelessWidget {
  final List<Widget> children;
  const SettingSector({
    super.key,
    required this.children
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Color(0xFF555555),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        )
    );
  }
}

// Этот виджет - всплывающее окно, вызывается когда пользователь нажимает на пункты настроек с выбором цвета
class ColorPickerAlertDialog extends StatefulWidget {
  final Text title;
  final String object;
  final BuildContext context;
  const ColorPickerAlertDialog({
    super.key,
    required this.title,
    required this.object,
    required this.context,
  });

  @override
  State<ColorPickerAlertDialog> createState() => _ColorPickerAlertDialogState();
}

class _ColorPickerAlertDialogState extends State<ColorPickerAlertDialog> {
  late final TextEditingController colorController;
  @override
  void initState() {
    super.initState();
    colorController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(widget.context).size.width;
    double screenHeight = MediaQuery.of(widget.context).size.width;
    final provider = widget.context.watch<PlayerProvider>();
    return AlertDialog(
      title: widget.title,
      backgroundColor: Colors.white,
      actions: <Widget>[
        SizedBox(
          width: screenWidth * 0.5,
          child: TextField(
            controller: colorController,
            decoration: InputDecoration(
              labelText: 'Введите цвет по hex кодировке',
            ),
          ),
        ),
        IconButton(
            onPressed: () async {
              int? normalizedHexCode = int.tryParse(colorController.text.replaceFirst('#', 'FF'), radix: 16);
              if (normalizedHexCode != null) {
                await provider.changeColorScheme(normalizedHexCode, widget.object);
              }
              else {
                showNotification(context, "Неправильный hex код");
              }
              colorController.clear();
              Navigator.pop(context);
            },
            icon: Icon(Icons.check)
        ),
      ],
    );
  }
}

// Этот виджет, визуализация каждого отдельного трека в медиатеке
class MediatekaListTile extends StatefulWidget {
  final int index;
  final BuildContext context;
  final Color textColor;
  final Color iconColor;
  final bool isUserMakingPlaylist;
  const MediatekaListTile({
    super.key,
    required this.index,
    required this.context,
    required this.textColor,
    required this.iconColor,
    required this.isUserMakingPlaylist,
  });

  @override
  State<MediatekaListTile> createState() => _MediatekaListTileState();
}

class _MediatekaListTileState extends State<MediatekaListTile> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    final int globalIndex = widget.isUserMakingPlaylist ? widget.index : int.parse((provider.audioSources[widget.index] as IndexedAudioSource).tag.id); // Положение трека в глобальном списке(Для исправления отображения UI)
    final Duration duration = Duration(milliseconds: provider.audioFiles[globalIndex]["duration"].toInt());
    final String minutes = duration.inMinutes.toString();
    final String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Container(
          decoration: isSelected ? BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
          ) : BoxDecoration(),
          child: ListTile(
            leading: SizedBox(
              width: width * 0.2,
              child: provider.audioFiles[globalIndex]["picture"] != null ?
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                        image: DecorationImage(image: MemoryImage(provider.audioFiles[globalIndex]["picture"].data)),
                ),
              ) :
              Icon(Icons.music_note, color: widget.iconColor,),),
            title: SizedBox(
              width: width * 0.625,
              child: Text(provider.audioFiles[globalIndex]["name"], style: TextStyle(color: widget.textColor),)),
            trailing: SizedBox(
              width: width * 0.175,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    child: Text("$minutes:$seconds", style: TextStyle(color: widget.textColor),)
                  ),
                  SizedBox(
                    width: width * 0.1,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: provider.isUserMakingPlaylist ? SizedBox.shrink() :
                      IconButton(
                        icon: Icon(Icons.more_vert, color: widget.iconColor,),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("Настройки аудио"),
                                  actions: [

                                    Column(
                                      children: [
                                        TextButton(
                                            onPressed: (){
                                              provider.addedAudio.add(globalIndex);
                                              provider.switchAddToExistingPlaylistFlag();
                                              Navigator.pushNamed(context, "/playlist");
                                            },
                                            child: Text("Добавить аудио в плейлист", style: TextStyle(color: Colors.black),)
                                        ),

                                        provider.currentPlaylist != "main" ? TextButton(
                                            onPressed: () async {
                                              await provider.removeFromExistingPlaylist(globalIndex);
                                              Navigator.pop(context);
                                            },
                                            child: Text("Удалить аудио из плейлиста", style: TextStyle(color: Colors.black),)
                                        ) : SizedBox.shrink(),
                                      ],
                                    ),
                                  ],
                                );
                              }
                          );
                        },
                      )
                    ),
                  ),
                ],
              ),
            ),
            onTap: () async {

              widget.isUserMakingPlaylist ? (isSelected ? provider.removeAudioFromPlaylist(widget.index) : provider.addAudioToPlaylist(widget.index))
                  : provider.isSearchMode ? null : provider.setAudioFile(widget.index);
              setState(() {
                widget.isUserMakingPlaylist ? (isSelected ? isSelected = false : isSelected = true) : null;
              });

              if (provider.isSearchMode) {
                await Future.delayed(Duration(milliseconds: 500));
                provider.isSearchMode = false;
                provider.audioSources = [for (var sourceIndex in provider.playlists[provider.currentPlaylist]!)
                  AudioSource.uri(Uri.parse(provider.audioFiles[sourceIndex]["url"]),
                    tag: MediaItem(
                      id: '$sourceIndex',
                      title: provider.audioFiles[sourceIndex]["name"],
                    ),
                  )
                ];
                provider.setAudioFile(provider.indexesOfSearchedAudios[globalIndex]!);
                provider.indexesOfSearchedAudios = {};
              }
            },
          ),
        );
      },
    );
  }
}

// Виджет представляющий собой мини плеер, будет всплывать снизу экрана
class MiniPlayer extends StatefulWidget {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final BuildContext context;
  const MiniPlayer({
    super.key,
    required this.backgroundColor,
    required this.iconColor,
    required this.context,
    required this.textColor,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final provider = context.watch<PlayerProvider>();
    final bool isPlaying = provider.player.playing;

    return Container(
      color: widget.backgroundColor,
      height: screenHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          SizedBox(
            height: screenHeight * 0.2,
            width: screenWidth * 0.8,
            child: Marquee(
              text: provider.currentAudioFile!["name"],
              style: TextStyle(color: widget.textColor, fontSize: screenHeight * 0.035),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: screenWidth * 0.8,
            ),
          ),

          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(Icons.music_note, color: widget.iconColor)),
          ),

          SizedBox(
            height: screenHeight * 0.1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: MiniPlayerSlider(
                context: context,
                iconColor: widget.iconColor,
                textColor: widget.textColor,
              ),
            ),
          ),

          SizedBox(
            height: screenHeight * 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [

                Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.235, right: screenWidth * 0.05),
                  child: IconButton(
                      onPressed: () {
                        provider.player.loopMode == LoopMode.off ? provider.setLoopMode(LoopMode.one) : provider.setLoopMode(LoopMode.off);
                        showNotification(widget.context, provider.player.loopMode == LoopMode.one ? 'Включён режим повтора' : "Режим повтора выключен");
                      },
                      icon: Icon(Icons.loop, color: widget.iconColor, size: screenHeight * 0.04)
                  ),
                ),

                IconButton(
                    onPressed: () {
                      provider.playPrevious();
                    },
                    icon: Icon(Icons.skip_previous, color: widget.iconColor, size: screenHeight * 0.04)
                ),

                IconButton(
                    onPressed: () {
                      if (isPlaying) {
                        provider.pause();
                      } else {
                        provider.play();
                      }
                    },
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: widget.iconColor, size: screenHeight * 0.04)
                ),

                IconButton(
                    onPressed: () {
                      provider.playNext();
                    },
                    icon: Icon(Icons.skip_next, color: widget.iconColor, size: screenHeight * 0.04)
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}

// Слайдер для перемотки аудио
class MiniPlayerSlider extends StatefulWidget {
  final BuildContext context;
  final Color iconColor;
  final Color textColor;
  const MiniPlayerSlider({
    super.key,
    required this.context,
    required this.iconColor,
    required this.textColor,
  });

  @override
  State<MiniPlayerSlider> createState() => _MiniPlayerSliderState();
}

class _MiniPlayerSliderState extends State<MiniPlayerSlider> {
  double dragValue = 0.0;
  bool isDragged = false;

  @override
  Widget build(BuildContext context) {
    final provider = widget.context.watch<PlayerProvider>();
    final Duration duration = provider.player.duration ?? Duration.zero;
    return StreamBuilder( // Обновляет слайдер каждый раз как меняется позиция
        stream: provider.player.positionStream,
        builder: (context, asyncSnapshot) {
          return Row(
            children: [

              Text(isDragged ? "${dragValue.toInt() ~/ 60}:${(dragValue.toInt() % 60).toString().padLeft(2, '0')}"
                  : "${provider.player.position.inMinutes}:${(provider.player.position.inSeconds % 60).toString().padLeft(2, '0')}",
                style: TextStyle(color: widget.textColor),
              ),

              Expanded(
                child: Slider(
                  value: isDragged ? dragValue : provider.player.position.inSeconds.toDouble(), // Текущее положение точки зависит от положения пальца при перемещении и от текущей позиции трека в состоянии поеоя
                  min: 0.0,
                  max: duration.inSeconds.toDouble(),
                  onChangeStart: (value) {
                    isDragged = true;
                    provider.pause();
                  },
                  onChangeEnd: (value) {
                    provider.player.seek(Duration(seconds: dragValue.toInt()));
                    provider.play();
                    isDragged = false;
                  },
                  onChanged: (value) {
                    setState(() {
                      dragValue = value;
                    });
                  },
                  activeColor: widget.iconColor,
                  thumbColor: widget.iconColor,
                ),
              ),

              Text("${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}",
                style: TextStyle(color: widget.textColor),
              ),

            ],
          );
        }
    );
  }
}

// Окно высплывающее при создании плейлиста
class PlaylistCreationAlertDialog extends StatefulWidget {
  final BuildContext context;
  const PlaylistCreationAlertDialog({
    super.key,
    required this.context,
  });

  @override
  State<PlaylistCreationAlertDialog> createState() => _PlaylistCreationAlertDialogState();
}

class _PlaylistCreationAlertDialogState extends State<PlaylistCreationAlertDialog> {
  late final TextEditingController nameController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    nameController = TextEditingController();
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(widget.context).size.width;
    double screenHeight = MediaQuery.of(widget.context).size.width;
    final provider = widget.context.watch<PlayerProvider>();
    return AlertDialog(
      title: Text("Создать новый плейлист"),
      backgroundColor: Colors.white,
      actions: <Widget>[
        SizedBox(
          width: screenWidth * 0.5,
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Введите название вашего плейлиста',
            ),
          ),
        ),
        IconButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.switchPlaylistCreationFlag();
              provider.createPlaylist(nameController.text);
              nameController.clear();
              Navigator.pushNamed(context, "/mediateka");
            },
            icon: Icon(Icons.check)
        ),
      ],
    );
  }
}

// Виджет отображающий созданный плейлист
class PlaylistTile extends StatefulWidget {
  final BuildContext context;
  final Color iconColor;
  final Color textColor;
  final int index;
  const PlaylistTile({
    super.key,
    required this.textColor,
    required this.iconColor,
    required this.context,
    required this.index,
  });

  @override
  State<PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<PlaylistTile> {
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.context.watch<PlayerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final String name = provider.playlists.keys.elementAt(widget.index);
    final isUserAddToExistingPlaylist = provider.isUserAddToExistingPlaylist;
    return ListTile(
      leading: Icon(Icons.playlist_play, color: widget.iconColor, size: screenHeight * 0.05,),
      title: Text(name, style: TextStyle(color: widget.textColor, fontSize: screenHeight * 0.025),),
      trailing: isUserAddToExistingPlaylist ? SizedBox.shrink() :
      IconButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Center(child: Text("Настройки плейлиста")),
                    actionsAlignment: MainAxisAlignment.start,
                    actions: [

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                              onPressed: () {

                                Navigator.pop(context);
                                showDialog(context: context,
                                    builder: (context){
                                      return AlertDialog(
                                        title: Center(child: Text("Вы действительно хотите удалить плейлист $name?")),
                                        actions: [

                                          TextButton(
                                              onPressed: () {
                                                provider.deletePlaylist(name);
                                                Navigator.pop(context);
                                              },
                                              child: Text("Да", style: TextStyle(color: Colors.black),)),

                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text("Нет", style: TextStyle(color: Colors.black),))

                                        ],
                                      );
                                    }
                                );

                              },
                            child: Text("Удалить плейлист", style: TextStyle(color: Colors.black),)
                          ),

                          TextButton(
                              onPressed: () {

                                Navigator.pop(context);
                                showDialog(context: context,
                                    builder: (context){
                                      return AlertDialog(
                                        title: Center(child: Text("Переименуйте ваш плейлист $name")),
                                        actions: [

                                          Column(
                                            children: [

                                              SizedBox(
                                                width: screenWidth * 0.5,
                                                child: TextField(
                                                  controller: nameController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Введите имя плейлиста',
                                                  ),
                                                ),
                                              ),

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [

                                                  TextButton(
                                                      onPressed: () async {
                                                        await provider.renamePlaylist(name, nameController.text);
                                                        nameController.clear();
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Подтвердить", style: TextStyle(color: Colors.black),)),

                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("Отмена", style: TextStyle(color: Colors.black),)),

                                                ],
                                              ),

                                            ],
                                          )

                                        ],
                                      );
                                    }
                                );
                              },
                              child: Text("Переименовать плейлист", style: TextStyle(color: Colors.black),)
                          ),
                        ],
                      ),

                    ],
                  );
                }
            );
          },
          icon: Icon(Icons.more_vert, color: widget.iconColor, size: screenHeight * 0.05,)
      ),
      onTap: () async {

        if (isUserAddToExistingPlaylist) {
          provider.addedAudio.add(name);
          provider.addToExistingPlaylist();
          Navigator.pushNamedAndRemoveUntil(widget.context, "/mediateka", (route) => false);
          provider.switchAddToExistingPlaylistFlag();
        } else {
          await provider.setCurrentPlaylist(name);
          Navigator.pushNamed(widget.context, "/mediateka");
        }
      },
    );
  }
}

// Вызывает уведомление с каким-то определённым сообщением
Future<void> showNotification(BuildContext context, String message) async {
  OverlayState? overlayState = Overlay.of(context);
  OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Positioned(
          top: screenHeight * 0.025,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300),
            tween: Tween(begin: -100.0, end: 0.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(screenHeight * 0.02),
                      child: Text(message, style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.02),),
                    )
                ),
              ),
            ),
          ),
        );
      }
  );
  overlayState.insert(overlayEntry);
  await Future.delayed(Duration(seconds: 2));
  overlayEntry.remove();
}

// Слайдер громкости
class VolumeSlider extends StatefulWidget {
  final BuildContext context;
  final Color iconColor;
  final Color textColor;
  const VolumeSlider({
    super.key,
    required this.context,
    required this.iconColor,
    required this.textColor,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  @override
  Widget build(BuildContext context) {
    final provider = widget.context.watch<PlayerProvider>();
    return StreamBuilder( // Обновляет слайдер каждый раз как меняется громкость
        stream: provider.player.volumeStream,
        builder: (context, asyncSnapshot) {
          return Row(
            children: [
              Icon(Icons.volume_down, color: widget.iconColor,),
              
              Expanded(
                child: Slider(
                  value: provider.player.volume, // Текущее положение точки зависит от положения пальца при перемещении и от текущей громкости трека
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      provider.player.setVolume(value);
                    });
                  },
                  activeColor: widget.iconColor,
                  thumbColor: widget.iconColor,
                ),
              ),
              
              Text("${(provider.player.volume * 100)~/1}", style: TextStyle(color: widget.textColor),)
              
            ],
          );
        }
    );
  }
}
