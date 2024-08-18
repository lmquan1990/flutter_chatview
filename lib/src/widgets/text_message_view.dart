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
import 'package:chatview/src/widgets/message_view.dart';
import 'package:flutter/material.dart';

import 'package:chatview/src/extensions/extensions.dart';
import 'package:chatview/src/models/models.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../utils/constants/constants.dart';
import 'link_preview.dart';
import 'reaction_widget.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum MenuItem { copy, share, export }

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

  TextStyle? get _textStyle => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.textStyle
      : widget.inComingChatBubbleConfig?.textStyle;

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

  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
    final isYesterday =
        dateTime.isBefore(now) && dateTime.difference(now).inDays == 1;

    return DateFormat(
            isToday ? 'HH:mm' : (isYesterday ? 'MMM/dd HH:mm' : 'MMM/dd HH:mm'))
        .format(dateTime);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textMessage = widget.message.message;
    FlutterTts flutterTts = FlutterTts();

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
                vertical: 10,
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
                  : Text(
                      textMessage,
                      style: _textStyle ??
                          textTheme.bodyMedium!.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                    ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.start,
                children: [
                  Text(
                    formatDateTime(widget.message.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 30,
                    child: IconButton(
                        onPressed: () async {
                          if (Provider.of<Speaking>(context, listen: false)
                              .speaking) {
                            context.read<Speaking>().changeSpeaking(false);
                            await flutterTts.stop();
                          } else {
                            context.read<Speaking>().changeSpeaking(true);
                            await flutterTts.speak(textMessage);
                            await flutterTts.awaitSpeakCompletion(true);
                            context.read<Speaking>().changeSpeaking(false);
                          }
                        },
                        icon: Icon(
                            context.watch<Speaking>().speaking
                                ? Ionicons.pause_circle_outline
                                : Ionicons.volume_high_outline,
                            size: 20,
                            color: Colors.white70)),
                  ),
                  SizedBox(
                    width: 30,
                    child: PopupMenuButton<MenuItem>(
                      icon: const Icon(
                        Ionicons.arrow_redo_outline,
                        size: 20,
                        color: Colors.white70,
                      ),
                      onSelected: (MenuItem item) {
                        if (item == MenuItem.copy) {
                          Clipboard.setData(ClipboardData(text: textMessage));
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<MenuItem>>[
                        const PopupMenuItem<MenuItem>(
                          value: MenuItem.copy,
                          child: ListTile(
                            leading: Icon(Ionicons.copy_outline),
                            title: Text('Copy'),
                          ),
                        ),
                        const PopupMenuItem<MenuItem>(
                          value: MenuItem.share,
                          child: ListTile(
                            leading: Icon(Ionicons.share_outline),
                            title: Text('Share'),
                          ),
                        ),
                        const PopupMenuItem<MenuItem>(
                          value: MenuItem.export,
                          child: ListTile(
                            leading: Icon(Ionicons.download_outline),
                            title: Text('Export'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
