import 'package:flutter/material.dart';

class Md3Colors {
  static const background = Color(0xfff6f7fb);
  static const surface = Color(0xffffffff);
  static const surfaceMuted = Color(0xfff0f3f6);
  static const skeleton = Color(0xffedf1f5);
  static const skeletonHighlight = Color(0xfff8fafc);
  static const primary = Color(0xff4d55d9);
  static const primaryStrong = Color(0xff383faf);
  static const primarySoft = Color(0xffeff0fd);
  static const primarySoftStrong = Color(0xffe6e8fc);
  static const primaryDisabled = Color(0xffe5e7ef);
  static const accent = Color(0xfff4b84a);
  static const text = Color(0xff172033);
  static const secondaryText = Color(0xff748099);
  // The owner's secondary swatch is decorative. Small metadata needs a
  // darker foreground to maintain 4.5:1 on neutral and tonal surfaces.
  static const muted = Color(0xff59657a);
  static const border = Color(0xffe5e8f0);
  static const information = Color(0xff244f7d);
  static const informationSoft = Color(0xffe6eef7);
  static const success = Color(0xff287a50);
  static const warning = Color(0xffa96716);
  static const destructive = Color(0xffb93a46);
  static const error = destructive;

  // Opinion colors describe taste, not destructive actions or system errors.
  // Exact owner swatches are available for decorative accents; foreground
  // variants keep opinion labels/icons readable without changing their hue.
  static const likedAccent = Color(0xff22c55e);
  static const okayAccent = Color(0xfff2b84b);
  static const dislikedAccent = Color(0xffef4444);
  static const liked = Color(0xff16753b);
  static const okay = Color(0xff966010);
  static const disliked = Color(0xffbd2929);
  static const likedSoft = Color(0xffe9f7ef);
  static const okaySoft = Color(0xfffff4dc);
  static const dislikedSoft = Color(0xffffeded);
  static const watchlistSoft = primarySoftStrong;
  static const neutralSoft = Color(0xfff3f4f6);

  // Backward-compatible alias for older call sites. New code should choose the
  // explicit `error`, `destructive`, or `disliked` semantic role.
  static const danger = destructive;

  static const glassTint = Color(0xc7ffffff);
  static const glassBorder = Color(0xd9ffffff);
  static const navigationGlassBorder = Color(0xb8ffffff);
  static const navigationSelectionBorder = Color(0xd1ffffff);
  static const glassBorderSubtle = Color(0xffe9edf2);
  static const scrim = Color(0x7a000000);
}
