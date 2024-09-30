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

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../utils/constants/constants.dart';
import '../values/enumeration.dart';
import '../values/typedefs.dart';

class ProfileImageWidget extends StatelessWidget {
  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.defaultAvatarImage = profileImage,
    this.circleRadius,
    this.assetImageErrorBuilder,
    this.networkImageErrorBuilder,
    this.imageType = ImageType.network,
    required this.networkImageProgressIndicatorBuilder,
  });

  /// Allow user to set radius of circle avatar.
  final double? circleRadius;

  /// Allow user to pass image url of user's profile picture.
  final String? imageUrl;

  /// Flag to check whether image is network or asset
  final ImageType? imageType;

  /// Field to set default avatar image if profile image link not provided
  final String defaultAvatarImage;

  /// Error builder to build error widget for asset image
  final AssetImageErrorBuilder? assetImageErrorBuilder;

  /// Error builder to build error widget for network image
  final NetworkImageErrorBuilder? networkImageErrorBuilder;

  /// Progress indicator builder for network image
  final NetworkImageProgressIndicatorBuilder?
      networkImageProgressIndicatorBuilder;

  @override
  Widget build(BuildContext context) {
    final radius = (circleRadius ?? 20) * 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(circleRadius ?? 20),
      child: switch (imageType) {
        ImageType.asset when (imageUrl?.isNotEmpty ?? false) => Image.asset(
            imageUrl!,
            height: radius,
            width: radius,
            fit: BoxFit.cover,
            errorBuilder: assetImageErrorBuilder ?? _errorWidget,
          ),
        ImageType.network when (imageUrl?.isNotEmpty ?? false) =>
          CachedNetworkImage(
            imageUrl: imageUrl ?? defaultAvatarImage,
            height: radius,
            width: radius,
            fit: BoxFit.cover,
            progressIndicatorBuilder: networkImageProgressIndicatorBuilder,
            errorWidget: networkImageErrorBuilder ?? _networkImageErrorWidget,
          ),
        ImageType.base64 when (imageUrl?.isNotEmpty ?? false) => Image.memory(
            base64Decode(imageUrl!),
            height: radius,
            width: radius,
            fit: BoxFit.cover,
            errorBuilder: assetImageErrorBuilder ?? _errorWidget,
          ),
        ImageType.icon => circleAvatar(imageUrl!),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget circleAvatar(String imageUrl) {
    return SizedBox(
      height: 50,
      width: 50,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Positioned(
            top: 0.0,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding:
                    const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 8),
                backgroundColor: imageUrl == '0'
                    ? Colors.deepPurpleAccent
                    : imageUrl == '1'
                        ? Colors.blueAccent
                        : imageUrl == '2'
                            ? Colors.green
                            : imageUrl == '3'
                                ? Colors.orange
                                : Colors.indigoAccent,
                foregroundColor: Colors.red,
              ),
              child: imageUrl == '0'
                  ? const Icon(
                      IconsaxPlusLinear.document_text,
                      color: Colors.white,
                      size: 25,
                    )
                  : imageUrl == '1'
                      ? const Icon(
                          IconsaxPlusLinear.global,
                          color: Colors.white,
                          size: 25,
                        )
                      : imageUrl == '2'
                          ? const Icon(
                              IconsaxPlusLinear.video_square,
                              color: Colors.white,
                              size: 25,
                            )
                          : imageUrl == '3'
                              ? const Icon(
                                  IconsaxPlusLinear.audio_square,
                                  color: Colors.white,
                                  size: 25,
                                )
                              : const Icon(
                                  IconsaxPlusLinear.image,
                                  color: Colors.white,
                                  size: 25,
                                ),
            ),
          ), //Icon
          const Positioned(
            top: 30,
            right: 2,
            child: CircleAvatar(
              radius: 6,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              // child: Text('24'),
            ), //CircularAvatar
          ), //Positioned
        ], //<Widget>[]
      ),
    );
  }

  Widget _networkImageErrorWidget(context, url, error) {
    return const Center(
      child: Icon(
        Icons.error_outline,
        size: 18,
      ),
    );
  }

  Widget _errorWidget(context, error, stackTrace) {
    return const Center(
      child: Icon(
        Icons.error_outline,
        size: 18,
      ),
    );
  }
}
