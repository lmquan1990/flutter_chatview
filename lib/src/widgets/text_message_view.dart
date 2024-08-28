/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'dart:async';
import 'dart:io';

import 'package:chatview/src/widgets/message_view.dart';
import 'package:flutter/material.dart';

import 'package:chatview/src/extensions/extensions.dart';
import 'package:chatview/src/models/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../utils/constants/constants.dart';
import 'link_preview.dart';
import 'reaction_widget.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as html2pdf;

enum MenuItem { copy, share, pdf, txt }

class TextMessageView extends StatefulWidget {
  const TextMessageView({
    Key? key,
    required this.isMessageBySender,
    required this.message,
    this.chatBubbleMaxWidth,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.messageReactionConfig,
    this.highlightMessage = false,
    this.highlightColor,
  }) : super(key: key);

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides message instance of chat.
  final Message message;

  /// Allow users to give max width of chat bubble.
  final double? chatBubbleMaxWidth;

  /// Provides configuration of chat bubble appearance from other user of chat.
  final ChatBubble? inComingChatBubbleConfig;

  /// Provides configuration of chat bubble appearance from current user of chat.
  final ChatBubble? outgoingChatBubbleConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents message should highlight.
  final bool highlightMessage;

  /// Allow user to set color of highlighted message.
  final Color? highlightColor;

  @override
  State<TextMessageView> createState() => _TextMessageViewState();
}

class _TextMessageViewState extends State<TextMessageView> {
  EdgeInsetsGeometry? get _padding => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.padding
      : widget.inComingChatBubbleConfig?.padding;

  EdgeInsetsGeometry? get _margin => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.margin
      : widget.inComingChatBubbleConfig?.margin;

  LinkPreviewConfiguration? get _linkPreviewConfig => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.linkPreviewConfig
      : widget.inComingChatBubbleConfig?.linkPreviewConfig;

  BorderRadiusGeometry _borderRadius(String message) => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.borderRadius ??
          (message.length < 37
              ? BorderRadius.circular(replyBorderRadius1)
              : BorderRadius.circular(replyBorderRadius2))
      : widget.inComingChatBubbleConfig?.borderRadius ??
          (message.length < 29
              ? BorderRadius.circular(replyBorderRadius1)
              : BorderRadius.circular(replyBorderRadius2));

  Color get _color => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.color ?? Colors.purple
      : widget.inComingChatBubbleConfig?.color ?? Colors.grey.shade500;

  bool isDateTimeThisWeek(DateTime dateTime) {
    final now = DateUtils.dateOnly(DateTime.now());
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return dateTime.isAfter(startOfWeek) && dateTime.isBefore(endOfWeek);
  }

  String formatDateTime(DateTime dateTime) {
    if (DateUtils.isSameDay(dateTime, DateTime.now())) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (isDateTimeThisWeek(dateTime)) {
      return DateFormat('E HH:mm').format(dateTime);
    } else {
      return DateFormat('HH:mm dd MM, yyyy').format(dateTime);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textMessage = widget.message.message;
    FlutterTts flutterTts = FlutterTts();
    bool isSharePopupShown = false;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(
              minWidth: 100,
              maxWidth: widget.chatBubbleMaxWidth ??
                  MediaQuery.of(context).size.width * 0.75),
          padding: _padding ??
              const EdgeInsets.symmetric(
                horizontal: 12,
                // vertical: 10,
              ),
          margin: _margin ??
              EdgeInsets.fromLTRB(5, 0, 6,
                  widget.message.reaction.reactions.isNotEmpty ? 15 : 2),
          decoration: BoxDecoration(
            color: widget.highlightMessage ? widget.highlightColor : _color,
            borderRadius: _borderRadius(textMessage),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textMessage.isUrl
                  ? LinkPreview(
                      linkPreviewConfig: _linkPreviewConfig,
                      url: textMessage,
                    )
                  : Html(
                      data: md.markdownToHtml(textMessage),
                      style: {
                        'p': Style(
                          color: Colors.white,
                          fontSize: FontSize(16),
                        ),
                        'h2': Style(
                          color: Colors.white,
                          fontSize: FontSize(18),
                        ),
                        'ul': Style(
                          color: Colors.white,
                          fontSize: FontSize(16),
                          alignment: Alignment.topLeft,
                          padding: HtmlPaddings.only(left: 15),
                        ),
                        'ol': Style(
                          color: Colors.white,
                          fontSize: FontSize(16),
                          alignment: Alignment.topLeft,
                          padding: HtmlPaddings.only(left: 20),
                        ),
                        'li': Style(
                          color: Colors.white,
                          fontSize: FontSize(16),
                          alignment: Alignment.topLeft,
                          padding: HtmlPaddings.only(left: 5),
                        )
                      },
                    ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  children: [
                    Text(
                      formatDateTime(widget.message.createdAt),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: 30,
                      child: IconButton(
                          splashColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () async {
                            if (Provider.of<Speaking>(context, listen: false)
                                .speaking) {
                              context.read<Speaking>().changeSpeaking(false);
                              await flutterTts.stop();
                            } else {
                              context.read<Speaking>().changeSpeaking(true);
                              await flutterTts.awaitSpeakCompletion(true);
                              await flutterTts.speak(textMessage);
                              if (context.mounted) {
                                context.read<Speaking>().changeSpeaking(false);
                              }
                            }
                          },
                          icon: Icon(
                              context.watch<Speaking>().speaking
                                  ? IconsaxPlusLinear.pause
                                  : IconsaxPlusLinear.volume_high,
                              size: 20,
                              color: Colors.white70)),
                    ),
                    SizedBox(
                      width: 30,
                      child: PopupMenuButton<MenuItem>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(
                            width: 0,
                            color: Colors.transparent,
                          ),
                        ),
                        icon: const Icon(
                          IconsaxPlusLinear.more,
                          size: 20,
                          color: Colors.white70,
                        ),
                        onSelected: (MenuItem item) async {
                          if (item == MenuItem.copy) {
                            Clipboard.setData(ClipboardData(text: textMessage));
                          } else if (item == MenuItem.share) {
                            if (!isSharePopupShown) {
                              isSharePopupShown = true;
                              await Share.share(
                                textMessage,
                              ).whenComplete(() {
                                Timer(
                                    const Duration(
                                      milliseconds: 600,
                                    ), () {
                                  isSharePopupShown = false;
                                });
                              });
                            }
                          } else if (item == MenuItem.pdf) {
                            final newpdf = html2pdf.Document();
                            List<html2pdf.Widget> widgets =
                                await html2pdf.HTMLToPdf()
                                    .convert(md.markdownToHtml(textMessage));
                            newpdf.addPage(html2pdf.MultiPage(
                                maxPages: 200,
                                build: (context) {
                                  return widgets;
                                }));

                            if (await FileStorage.writePdf(await newpdf.save(),
                                "NakamaAI_${DateFormat('yyyyMMddmmhhss').format(DateTime.now())}.pdf")) {
                              toastification.show(
                                context: context.mounted ? context : null,
                                type: ToastificationType.success,
                                style: ToastificationStyle.fillColored,
                                primaryColor: Colors.green,
                                title: const Text(
                                  'Info',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                description: const Text(
                                  'File has been downloaded to the Download folder.',
                                  style: TextStyle(fontSize: 18),
                                ),
                                alignment: Alignment.bottomCenter,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            } else {
                              toastification.show(
                                context: context.mounted ? context : null,
                                type: ToastificationType.error,
                                style: ToastificationStyle.fillColored,
                                primaryColor: Colors.red,
                                title: const Text(
                                  'Error',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                description: const Text(
                                  'The app does not have permission to save files.',
                                  style: TextStyle(fontSize: 18),
                                ),
                                alignment: Alignment.bottomCenter,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            }

                            //Web
                            // var savedFile = await pdf.save();
                            // List<int> fileInts = List.from(savedFile);
                            // web.HTMLAnchorElement()
                            //   ..href = "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(fileInts)}"
                            //   ..setAttribute("download", "${DateTime.now().millisecondsSinceEpoch}.pdf")
                            //   ..click();
                          } else if (item == MenuItem.txt) {
                            if (await FileStorage.writeTxt(textMessage,
                                "NakamaAI_${DateFormat('yyyyMMddmmhhss').format(DateTime.now())}.txt")) {
                              toastification.show(
                                context: context.mounted ? context : null,
                                type: ToastificationType.success,
                                style: ToastificationStyle.fillColored,
                                primaryColor: Colors.green,
                                title: const Text(
                                  'Info',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                description: const Text(
                                  'File has been downloaded to the Download folder.',
                                  style: TextStyle(fontSize: 18),
                                ),
                                alignment: Alignment.bottomCenter,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            } else {
                              toastification.show(
                                context: context.mounted ? context : null,
                                type: ToastificationType.error,
                                style: ToastificationStyle.fillColored,
                                primaryColor: Colors.red,
                                title: const Text(
                                  'Error',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                description: const Text(
                                  'The app does not have permission to save files.',
                                  style: TextStyle(fontSize: 18),
                                ),
                                alignment: Alignment.bottomCenter,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<MenuItem>>[
                          const PopupMenuItem<MenuItem>(
                            value: MenuItem.copy,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: SizedBox(
                                // height: menuHeight,
                                child: ListTile(
                                  leading: Icon(IconsaxPlusLinear.copy),
                                  title: Text('Copy'),
                                ),
                              ),
                            ),
                          ),
                          const PopupMenuItem<MenuItem>(
                            value: MenuItem.share,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: SizedBox(
                                // height: menuHeight,
                                child: ListTile(
                                  leading: Icon(IconsaxPlusLinear.send_2),
                                  title: Text('Share'),
                                ),
                              ),
                            ),
                          ),
                          const PopupMenuItem<MenuItem>(
                            value: MenuItem.pdf,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: SizedBox(
                                // height: menuHeight,
                                child: ListTile(
                                  leading:
                                      Icon(IconsaxPlusLinear.document_text),
                                  title: Text('Export PDF'),
                                ),
                              ),
                            ),
                          ),
                          const PopupMenuItem<MenuItem>(
                            value: MenuItem.txt,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: SizedBox(
                                // height: menuHeight,
                                child: ListTile(
                                  leading: Icon(IconsaxPlusLinear.note_text),
                                  title: Text('Export Text'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.message.reaction.reactions.isNotEmpty)
          ReactionWidget(
            key: widget.key,
            isMessageBySender: widget.isMessageBySender,
            reaction: widget.message.reaction,
            messageReactionConfig: widget.messageReactionConfig,
          ),
      ],
    );
  }
}

Future<String> getPath() async {
  // Permission granted, proceed with storage operations
  Directory directory = Directory("");
  if (Platform.isAndroid) {
    // Redirects it to download folder in android
    directory = Directory("/storage/emulated/0/Download");
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  final exPath = directory.path;
  await Directory(exPath).create(recursive: true);
  return exPath;
}

// To save the file in the device
class FileStorage {
  static Future<String> getExternalDocumentPath() async {
    // To check whether permission is given for this app or not.
    var status = await Permission.storage.status;

    if (status.isGranted) {
      return getPath();
    } else if (status.isDenied) {
      // Permission denied, request it
      Map<Permission, PermissionStatus> statuses =
          await [Permission.storage].request();
      if (statuses[Permission.storage] == PermissionStatus.granted) {
        return getPath();
      } else {
        // Permission denied even after request, handle accordingly
      }
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, guide user to app settings
      openAppSettings();
    }
    return '';
  }

  static Future<String> get _localPath async {
    // final directory = await getApplicationDocumentsDirectory();
    // return directory.path;
    // To get the external path from device of download folder
    final String directory = await getExternalDocumentPath();
    return directory;
  }

  static Future<bool> writeTxt(String text, String name) async {
    final path = await _localPath;
    if (path != '') {
      File file = File('$path/$name');
      await file.writeAsString(text);
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> writePdf(List<int> bytes, String name) async {
    final path = await _localPath;
    // Create a file for the path of
    // device and file name with extension
    if (path != '') {
      File file = File('$path/$name');
      // Write the data in the file you have created
      await file.writeAsBytes(bytes);
      return true;
    } else {
      return false;
    }
  }
}
