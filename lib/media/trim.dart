import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';

void trimVideos(Video videoA, Video videoB) {
  // Determine which video is longer
  final Video longerVideo = videoA.duration > videoB.duration ? videoA : videoB;
  final Video shorterVideo =
      videoA.duration > videoB.duration ? videoB : videoA;

  // Assuming they are always on the same timeline
  // areOnDifferentTimelines(videoA, videoB)
  //  ? handleDifferentTimelines(longerVideo, shorterVideo)
  //  : handleSameTimeline(longerVideo, shorterVideo);
  handleSameTimeline(longerVideo, shorterVideo);
}

bool areOnDifferentTimelines(Video videoA, Video videoB) {
  Duration aBeforeB = videoA.created.difference(videoB.created);
  Duration bBeforeA = videoB.created.difference(videoA.created);
  return aBeforeB.inSeconds.abs() > videoA.duration.inSeconds &&
      bBeforeA.inSeconds.abs() > videoB.duration.inSeconds;
}

void handleDifferentTimelines(Video longerVideo, Video shorterVideo) {
  if (longerVideo.duration > shorterVideo.duration) {
    trimEnd(longerVideo, shorterVideo);
  } else {
    trimStart(shorterVideo, longerVideo);
  }
}

void handleSameTimeline(Video longerVideo, Video shorterVideo) {
  if (longerVideo.created.isBefore(shorterVideo.created)) {
    if (longerVideo.duration > shorterVideo.duration) {
      trimEnd(longerVideo, shorterVideo);
    } else {
      trimStart(shorterVideo, longerVideo);
    }
  } else {
    if (longerVideo.duration > shorterVideo.duration) {
      trimStart(longerVideo, shorterVideo);
    } else {
      trimEnd(shorterVideo, longerVideo);
    }
  }
}

void trimStart(Video video, Video other) {
  // Logic to trim the start of the video
  Duration trimDuration = (video.duration - other.duration).abs();
  Logging().debug("Trimming $trimDuration from the start");
  video.trim(trimDuration, Duration.zero);
}

void trimEnd(Video video, Video other) {
  // Logic to trim the end of the video
  Duration trimDuration = (video.duration - other.duration).abs();
  Logging().debug("Trimming $trimDuration from the end");
  video.trim(Duration.zero, trimDuration);
}
