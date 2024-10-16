// ignore_for_file: cast_nullable_to_non_nullable

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:string_extensions/string_extensions.dart';
import 'package:substring_highlight/substring_highlight.dart';
import 'package:comment_scope/constants.dart';
import 'package:comment_scope/models/comments_response.dart';
import 'package:comment_scope/models/video_information.dart';
import 'package:comment_scope/services/youtube_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _videoFieldController = TextEditingController();
  final TextEditingController _filterTextController = TextEditingController();

  VideoInformation? videoInfo;

  List<Comment?> allComments = [];
  List<Comment?> filteredComments = [];
  List<Comment?> randomFilteredComments = [];

  bool isSearching = false;

  final List<double> values = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 10.0, 15.0];
  int selectedCommentsCount = 1;

  YoutubePlayerController? _controller;

  NumberFormat formatter = NumberFormat('#,###,000');

  Future<void> prepareComments(String video) async {
    allComments = [];
    filteredComments = [];
    String videoId = '';

    if (video.length > 11) {
      videoId = video.after('?v=').before('&ab_channel')!;
    } else {
      videoId = video;
    }
    final res = await Future.wait([
      getComments(video, context),
      getVideoInformation(video),
    ]);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
      ),
    );

    if (res[0] != null && res[1] != null) {
      allComments.addAll(res[0] as List<Comment?>);
      filteredComments.addAll(res[0] as List<Comment?>);
      videoInfo = res[1] as VideoInformation?;

      allComments
          .sort((a, b) => Comparable.compare(b!.likeCount!, a!.likeCount!));
      filteredComments
          .sort((a, b) => Comparable.compare(b!.likeCount!, a!.likeCount!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        title: const Text(
          'Mahmoud Azab',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          if (allComments.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  allComments = [];
                  filteredComments = [];
                  randomFilteredComments = [];
                  videoInfo = null;
                  _videoFieldController.clear();
                  _filterTextController.clear();
                });
              },
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
            )
        ],
      ),
      body: Column(
        children: <Widget>[
          if (allComments.isEmpty) ...[
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextField(
                controller: _videoFieldController,
                style: const TextStyle(
                  color: Colors.black,
                ),
                decoration:
                    kInputDecoration(labeText: 'Enter a video URL or ID')
                        .copyWith(
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Bounceable(
              scaleFactor: 0.7,
              onTap: () async {
                if (_videoFieldController.text.isNotEmpty) {
                  isSearching = true;
                  setState(() {});
                  await prepareComments(_videoFieldController.text);
                  isSearching = false;
                  setState(() {});
                }
              },
              child: Container(
                height: 50,
                width: 100,
                decoration: BoxDecoration(
                  color: kColorRedYtb,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ] else
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 250,
              child: YoutubePlayer(
                controller: _controller!,
              ),
            ),
          const SizedBox(
            height: 20,
          ),
          if (isSearching)
            LottieBuilder.asset(
              'assets/loading.json',
              height: 100,
            )
          else if (videoInfo != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoInfo!.title!,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Text(
                        '${formatter.format(videoInfo?.viewCount.toInt())} views',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '   ${DateFormat('MMM d, yyyy').format(videoInfo!.publishedAt!)}',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            if (allComments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _filterTextController,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                      decoration: kInputDecoration(labeText: 'Search comments')
                          .copyWith(
                        labelStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      onChanged: (value) {
                        log.f(value.length);

                        setState(() {
                          if (value.isNotEmpty) {
                            filteredComments = allComments
                                .where(
                                  (c) => c!.text!
                                      .toLowerCase()
                                      .contains(value.toLowerCase()),
                                )
                                .toList();
                          } else {
                            log.f('Value is empty');
                            filteredComments = allComments;
                          }
                        });

                        // else {
                        //   if (filteredComments.isNotEmpty) {
                        //     log.wtf('Resetting filters');
                        //     filteredComments = [];
                        //     filteredComments.addAll(allComments);
                        //     log.wtf('Filters are ${filteredComments.length}');
                        //     setState(() {});
                        //   }
                        // }
                      },
                    ),
                  ],
                ),
              )
            else
              const Text(
                'No comments found',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (filteredComments.isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (filteredComments.isNotEmpty) ...[
                      SliverAppBar(
                        backgroundColor: kColorRedYtb,
                        elevation: 12,
                        primary: false,
                        pinned: true,
                        shadowColor: kColorRedYtb,
                        title: Text(
                          '${filteredComments.length} comments found',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                color: const Color(0xff20262E),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    key: ValueKey(
                                      filteredComments[index]!
                                          .authorProfileImageUrl!,
                                    ),
                                    leading: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          kLaunchUrl(
                                            filteredComments[index]!
                                                    .authorChannel ??
                                                '',
                                          );
                                        },
                                        child: ExtendedImage.network(
                                          filteredComments[index]!
                                              .authorProfileImageUrl!,
                                          height: 50,
                                          width: 50,
                                          fit: BoxFit.fill,
                                          shape: BoxShape.circle,
                                          loadStateChanged: (state) {
                                            if (state.extendedImageLoadState ==
                                                LoadState.failed) {
                                              return Image.network(
                                                'https://i.imgur.com/qV26MhU.png',
                                              );
                                            }
                                            if (state.extendedImageLoadState ==
                                                LoadState.loading) {
                                              return LottieBuilder.asset(
                                                'assets/loading.json',
                                                height: 100,
                                              );
                                            }
                                          },
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(30.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                    subtitle: Column(
                                      children: [
                                        SubstringHighlight(
                                          text: filteredComments[index]!.text!,
                                          term: _filterTextController.text,
                                          textStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textStyleHighlight: TextStyle(
                                            color: kColorRedYtb,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.thumb_up,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              filteredComments[index]!
                                                  .likeCount!
                                                  .toString(),
                                              style: TextStyle(
                                                color: kColorRedYtb,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    title: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        filteredComments[index]!.authorName!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: filteredComments.length,
                        ),
                      )
                    ],
                  ],
                ),
              )
            ]
          ]
        ],
      ),
// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
