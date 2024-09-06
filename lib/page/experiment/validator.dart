import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/page/load_button.dart';

Text successText(String text,
    {TextStyle style = const TextStyle(color: Colors.green)}) {
  return Text("✅ $text", style: style, textAlign: TextAlign.center);
}

Text failureText(String text,
    {TextStyle style = const TextStyle(color: Colors.red)}) {
  return Text("❌ $text", style: style, textAlign: TextAlign.center);
}

// Returns true if the two videos overlap in timeline
//
bool areVideosInSameTimeline(Video video, Video other) {
  Duration diff = video.created.difference(other.created);
  return diff.inSeconds.abs() < video.duration.inSeconds;
}

Text areVideosInSameTimelineStatus(Video video, Video other) {
  return areVideosInSameTimeline(video, other)
    ? successText("Videos are in the same timeline")
    : failureText("Videos are not in the same timeline");
}

// Returns true if the two videos share the same duration
//
bool areVideosInSameDuration(Video video, Video other) {
  return video.duration == other.duration;
}

Widget areVideosInSameDurationStatus(Video video, Video other, Future<void> Function() failurePrompt) {
  return areVideosInSameDuration(video, other)
    ? successText("Videos share the same duration")
    : Column(children: [
        failureText("Videos do not share the same duration"),
        LoadButton(
            onPressed: failurePrompt,
            text: "Align",
            timer: false)
      ]);
}

// Returns true if the two videos share the same frame range
//
bool areVideosInSameFrameRange(Video video, Video other) {
  return video.startFrame == other.startFrame &&
      video.endFrame == other.endFrame;
}

Text areVideosInSameFrameRangeStatus(Video video, Video other) {
  return areVideosInSameFrameRange(video, other)
    ? successText("Videos share the same frame range")
    : failureText("Videos do not share the same frame range");
}

// Returns true if the two videos share the same frame count
//
bool areVideosInSameFrameCount(Video video, Video other) {
  return video.totalFrames == other.totalFrames;
}

Text areVideosInSameFrameCountStatus(Video video, Video other) {
  return areVideosInSameFrameCount(video, other)
    ? successText("Videos share the same frame count")
    : failureText("Videos do not share the same frame count");
}

// Returns true if the two videos share the same encoding
//
bool areVideosInSameEncoding(Video video, Video other) {
  return video.stats.codec == other.stats.codec;
}

Text areVideosInSameEncodingStatus(Video video, Video other) {
  return areVideosInSameEncoding(video, other)
    ? successText("Videos share the same encoding")
    : failureText("Videos do not share the same encoding");
}
