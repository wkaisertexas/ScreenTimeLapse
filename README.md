<img alt="TimeLapse, easily screen screen and camera recordings" src="https://github.com/wkaisertexas/tiktok-uploader/assets/27795014/3b390663-1416-42bb-81eb-5f297ed04e26">
<h1 align="center">Screen Time Lapse</h1>

<p align="center">
  A open-source menu bar application for creating screen and camera timelapses without excessive file sizes.
</p>

<p align="center">
  <a href="#introduction"><strong>Introduction</strong></a> ·
  <a href="#features"><strong>Features</strong></a> ·
  <a href="#installation"><strong>Installation</strong></a> ·
  <a href="#local-development"><strong>Local Development</strong></a> ·
  <a href="#tech-stack"><strong>Tech Stack</strong></a> ·
  <a href="#contributing"><strong>Contributing</strong></a>
</p>
<br/>

## Introduction
<p align="center">
<img width="553" alt="Application demonstration photo in menu bar" src="https://github.com/wkaisertexas/ScreenTimeLapse/assets/27795014/785ee2b6-1ef5-4302-83da-c3d81a069074">
</p>

<p align="center">
    A <i>TimeLapse</i> is open-source menu bar application for creating screen and camera timelapses without excessive file sizes.
</p>

## Features

- **Minimalist Design**: a fully featured web recorder in your menu bar
- **Hardware Accelerated**: fully utilized hardware accelerated encoding for a lightweight recording experience
- **Space Saving**: Avoid the excessive file sizes of high quality video (can be as high as 7 GB / hour).
- **Camera Recording**: Record your webcam or phone with the same frame rate and camera speed
- **Secure**: Use the fully features of `ScreenCaptureKit` to only record certain windows, applications and more. Never leak your bank information in recordings again!
- **Customizability**: Change everything from the frame rate, quality and speed multiple

## Installation

The recommended way to install **TimeLapse** is through [Homebrew](https://brew.sh/) cask.

```console
brew install --cask timelapse
```

## Local Development

To develop Dub locally, you will need to clone and open this repository in XCode.

Once that's done, you can use the following commands to run the app locally:

```console
git clone https://github.com/wkaisertexas/ScreenTimeLapse
cd ScreenTimeLapse
open ScreenTimeLapse.xcodeproj
```

Following this, you need to allow the app to be built for local signining. 

## Tech Stack

- [SwiftUI](https://developer.apple.com/documentation/swiftui/)
- [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit/)
- [AVFoundation](https://developer.apple.com/av-foundation/)
- [CoreMedia](https://developer.apple.com/documentation/coremedia)

## Contributing

We love our contributors! Here's how you can contribute:

- [Open an issue](https://github.com/wkaisertexas/ScreenTimeLapse/issues) if you believe you've encountered a bug.
- Make a [pull request](https://github.com/wkaisertexas/ScreenTimeLapse/pull) to add new features/make quality-of-life improvements/fix bugs.

<a href="https://github.com/wkaisertexas/ScreenTimeLapse/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=wkaisertexas/ScreenTimeLapse" />
</a>

## Repo Activity

![Screen Time Lapse Repo Activity](https://repobeats.axiom.co/api/embed/3c10f8fa2ca2324639b9986cb38043750550c993.svg "Repobeats analytics image")

## License

Inspired by [ScreenTimeLapez](https://apps.apple.com/us/app/screen-timelapsez/id1440244990) and [Amethyst](https://github.com/ianyh/Amethyst), ScreenTimeLapse is open-source under the MIT Liscense. You can [find it here](https://github.com/wkaisertexas/ScreenTimeLapse/LICENSE.md)
