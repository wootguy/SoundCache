# SoundCache
This plugin loads the soundcache into memory, so that other plugins can get sound/sentence indexes without having to parse the soundcache again. Parsing files is slow in AS so it's best that this only happens once.

`StartSoundMsg.as` includes an example usage for sound indexes - the `StartSound` user message. Unlike the `g_SoundSystem` APIs, the StartSound message can play sounds at an offset. Include this file in your own plugin to use it.
