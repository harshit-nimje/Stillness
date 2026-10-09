import 'package:flutter/widgets.dart';

import '../sky/sky.dart';

/// Generated-scene definitions — a direct port of the `SC`, `LAY`, `G`, `CH`
/// tables and the `MAJ`/`MIN` scales from the original.
class Scene {
  final String key;
  final String name;
  final Color color;
  final double root; // r
  final int mode; // 0 major, 1 minor
  final List<int> scale;
  final double gap; // bell interval multiplier (g)
  final List<double> mix; // 7 layer levels, order = kLayers
  const Scene(this.key, this.name, this.color, this.root, this.mode, this.scale, this.gap, this.mix);
}

const List<String> kLayers = ['Pads', 'Bells', 'Rain', 'Sea', 'Wind', 'Wildlife', 'Hearth'];
const List<double> kLayerGain = [.22, .5, .5, .45, .3, .5, .6];
const List<int> kMajor = [0, 2, 4, 7, 9];
const List<int> kMinor = [0, 3, 5, 7, 10];

/// chord progressions: [major, minor]
final List<List<List<int>>> kChords = [
  [
    [0, 7, 12, 16],
    [-5, 2, 7, 11],
    [-3, 4, 9, 12],
    [-7, 0, 5, 9],
  ],
  [
    [0, 7, 12],
    [0, 7, 14],
    [-5, 2, 7],
  ],
];

final Map<String, Scene> kScenes = {
  'dawn': Scene('dawn', 'Dawn', hx('#f2b79c'), 146.8, 0, kMajor, 4, [.7, .45, 0, .1, .1, .5, 0]),
  'rain': Scene('rain', 'Rain', hx('#8da5bf'), 174.6, 0, kMajor, 6, [.3, .3, .75, 0, .1, .1, 0]),
  'sea': Scene('sea', 'Sea', hx('#76b8c6'), 130.8, 0, kMajor, 6, [.4, .2, 0, .8, .25, .25, 0]),
  'woods': Scene('woods', 'Woods', hx('#9cc58c'), 130.8, 0, kMajor, 9, [.3, .15, 0, .1, .55, .65, 0]),
  'hearth': Scene('hearth', 'Hearth', hx('#eba76d'), 98, 1, kMinor, 10, [.45, .12, 0, 0, 0, 0, .8]),
  'deep': Scene('deep', 'Deep', hx('#7f88dc'), 110, 1, kMinor, 7, [.85, .2, .1, 0, 0, .05, 0]),
};

/// The logo mark + tagline per scene (`LG` / `LT`).
const Map<String, String> kSceneTagline = {
  'dawn': 'first light',
  'rain': 'soft rain',
  'sea': 'slow tide',
  'woods': 'deep woods',
  'hearth': 'by the fire',
  'deep': 'night depth',
};

// ---------------------------------------------------------------------------
// Library — curated streamed tracks. Preserved verbatim (URLs, artists,
// licences) from the original so playback and attribution match.
// ---------------------------------------------------------------------------
class Track {
  final String categories; // "Ambient|Focus"
  final String title;
  final String artist;
  final String url;
  final String source; // page URL
  final String licence;
  final bool loop; // o
  const Track(this.categories, this.title, this.artist, this.url, this.source, this.licence, {this.loop = false});

  List<String> get catList => categories.split('|');
}

const List<String> kCategories = [
  'Ambient', 'Focus', 'Lo-fi', 'Classical', 'Piano', 'Rain', 'Nature', 'Birds', 'Yours'
];

final Map<String, Color> kCategoryColors = {
  'Ambient': hx('#7f88dc'),
  'Focus': hx('#9cc58c'),
  'Lo-fi': hx('#eba76d'),
  'Classical': hx('#e9b6c4'),
  'Piano': hx('#f2b79c'),
  'Rain': hx('#8da5bf'),
  'Nature': hx('#76b8c6'),
  'Birds': hx('#9cc58c'),
  'Yours': hx('#b5a8e0'),
};

const List<Track> kLibrary = [
  Track('Ambient|Focus', 'Starfish', 'Jack Hertz', 'https://archive.org/download/Complex_Silence_34/01_Starfish.mp3', 'https://archive.org/details/Complex_Silence_34', 'CC BY-NC-ND 3.0'),
  Track('Ambient|Focus', 'Blessings', 'The Lovely Moon', 'https://archive.org/download/TheLovelyMoon-MoonlightDrift/6-TheLovelyMoon-Blessings.mp3', 'https://archive.org/details/TheLovelyMoon-MoonlightDrift', 'CC BY-NC-SA 3.0'),
  Track('Ambient', 'Mountain Rain', 'The Lovely Moon', 'https://archive.org/download/TheLovelyMoon-MoonlightDrift/3-TheLovelyMoon-MountainRain.mp3', 'https://archive.org/details/TheLovelyMoon-MoonlightDrift', 'CC BY-NC-SA 3.0'),
  Track('Ambient', 'Mystery', 'The Lovely Moon', 'https://archive.org/download/TheLovelyMoon-MoonlightDrift/1-TheLovelyMoon-Mystery.mp3', 'https://archive.org/details/TheLovelyMoon-MoonlightDrift', 'CC BY-NC-SA 3.0'),
  Track('Ambient|Focus', 'Cold Moon Drift', 'Phillip Wilkerson', 'https://archive.org/download/Cold_Moon_Drift/Cold_Moon_Drift_vbr.mp3', 'https://archive.org/details/Cold_Moon_Drift', 'CC BY-ND 3.0'),
  Track('Focus', 'Somewhere Else', 'Candlegravity', 'https://archive.org/download/Vkrsnl037CandlegravityAMomentForMyself/Candlegravity-AMomentForMyself-01-SomewhereElse.mp3', 'https://archive.org/details/Vkrsnl037CandlegravityAMomentForMyself', 'CC BY-NC-ND 3.0'),
  Track('Focus', 'Love Breaks', 'Candlegravity', 'https://archive.org/download/Vkrsnl037CandlegravityAMomentForMyself/Candlegravity-AMomentForMyself-02-LoveBreaks.mp3', 'https://archive.org/details/Vkrsnl037CandlegravityAMomentForMyself', 'CC BY-NC-ND 3.0'),
  Track('Focus|Ambient', 'You Were In My Dream', 'Candlegravity', 'https://archive.org/download/Vkrsnl037CandlegravityAMomentForMyself/Candlegravity-AMomentForMyself-06-YouWereInMyDream.mp3', 'https://archive.org/details/Vkrsnl037CandlegravityAMomentForMyself', 'CC BY-NC-ND 3.0'),
  Track('Focus|Classical', 'Sketch No. 1', 'Emil Davydov', 'https://archive.org/download/pcr089EmilDavydov-Sketches/pcr089_01_emil_davydov_sketch_no1.mp3', 'https://archive.org/details/pcr089EmilDavydov-Sketches', 'CC BY-ND 3.0'),
  Track('Focus|Classical', 'Sketch No. 3', 'Emil Davydov', 'https://archive.org/download/pcr089EmilDavydov-Sketches/pcr089_03_emil_davydov_sketch_no3.mp3', 'https://archive.org/details/pcr089EmilDavydov-Sketches', 'CC BY-ND 3.0'),
  Track('Lo-fi', 'Shuttle', 'Slxt Sync', 'https://archive.org/download/jamendo-612992/01-2274653-Slxt%20Sync-Shuttle.mp3', 'https://archive.org/details/jamendo-612992', 'CC BY-NC-ND 3.0'),
  Track('Lo-fi', 'Green Background', 'Slxt Sync', 'https://archive.org/download/jamendo-612992/02-2274654-Slxt%20Sync-green%20background.mp3', 'https://archive.org/details/jamendo-612992', 'CC BY-NC-ND 3.0'),
  Track('Lo-fi', 'Full Moon', 'Slxt Sync', 'https://archive.org/download/jamendo-612992/03-2274652-Slxt%20Sync-full%20moon.mp3', 'https://archive.org/details/jamendo-612992', 'CC BY-NC-ND 3.0'),
  Track('Lo-fi', 'Elevation', 'Slxt Sync', 'https://archive.org/download/jamendo-612992/04-2274651-Slxt%20Sync-elevation.mp3', 'https://archive.org/details/jamendo-612992', 'CC BY-NC-ND 3.0'),
  Track('Lo-fi', 'Chill Carpet', 'Slxt Sync', 'https://archive.org/download/jamendo-612992/05-2274650-Slxt%20Sync-chill%20carpet.mp3', 'https://archive.org/details/jamendo-612992', 'CC BY-NC-ND 3.0'),
  Track('Lo-fi|Focus', 'Downtempo', 'Databend', 'https://archive.org/download/jamendo-632023/01-2315669-Databend-Lo%20Fi%20Hip%20Hop%20Downtempo%20Electronic.mp3', 'https://archive.org/details/jamendo-632023', 'CC BY-NC-ND 3.0'),
  Track('Lo-fi', 'Chillout', 'PeryCreep', 'https://archive.org/download/jamendo-445517/01-1864019-PeryCreep-Lofi%20Hip%20Hop%20Chillout.mp3', 'https://archive.org/details/jamendo-445517', 'CC BY-NC-ND 3.0'),
  Track('Lo-fi', 'Musical Immersion', 'Free Music Lab', 'https://archive.org/download/jamendo-609264/01-2265096-Free%20Music%20Lab-Musical%20Immersion%20-%20Lo-Fi%20Music%20I%20Free%20Background%20Music%20I%20Free%20Music%20Lab%20Release.mp3', 'https://archive.org/details/jamendo-609264', 'CC BY-NC-ND 3.0'),
  Track('Classical', 'Nocturne in B-flat minor, Op. 9 No. 1', 'Chopin \u00b7 Vadim Chaimovich', 'https://upload.wikimedia.org/wikipedia/commons/b/bf/Chopin%2C_Nocturne_No._1_in_B_Flat_Minor%2C_Op._9.ogg', 'https://commons.wikimedia.org/wiki/File:Chopin,_Nocturne_No._1_in_B_Flat_Minor,_Op._9.ogg', 'CC0'),
  Track('Classical', 'Nocturne in F minor, Op. 55 No. 1', 'Chopin', 'https://upload.wikimedia.org/wikipedia/commons/2/2f/Chopin_-_Nocturne-op-55-no-1.ogg', 'https://commons.wikimedia.org/wiki/File:Chopin_-_Nocturne-op-55-no-1.ogg', 'CC0'),
  Track('Classical', 'Nocturne in B major, Op. 32 No. 1', 'Chopin', 'https://upload.wikimedia.org/wikipedia/commons/a/a7/Chopin%2C_Nocturne_op_32_no_1.ogg', 'https://commons.wikimedia.org/wiki/File:Chopin,_Nocturne_op_32_no_1.ogg', 'CC BY-SA 4.0'),
  Track('Classical', 'Moonlight Sonata \u2014 I. Adagio', 'Beethoven', 'https://upload.wikimedia.org/wikipedia/commons/d/d0/Moonlight_Sonata.ogg', 'https://commons.wikimedia.org/wiki/File:Moonlight_Sonata.ogg', 'Public domain'),
  Track('Classical', 'Piano Sonata No. 1, Op. 2', 'Beethoven \u00b7 Paavali Jumppanen', 'https://upload.wikimedia.org/wikipedia/commons/f/f3/Beethoven_piano_sonata_1.ogg', 'https://commons.wikimedia.org/wiki/File:Beethoven_piano_sonata_1.ogg', 'CC BY-SA 3.0'),
  Track('Classical', 'Sonata No. 11 \u2014 Andante grazioso', 'Mozart \u00b7 Bernd Krueger', 'https://upload.wikimedia.org/wikipedia/commons/9/9b/Mozart_-_Piano_Sonata_No._11_in_A_major_-_I._Andante_grazioso.ogg', 'https://commons.wikimedia.org/wiki/File:Mozart_-_Piano_Sonata_No._11_in_A_major_-_I._Andante_grazioso.ogg', 'CC BY-SA 3.0'),
  Track('Classical', 'Clair de Lune', 'Debussy', 'https://upload.wikimedia.org/wikipedia/commons/b/be/Clair_de_lune_%28Claude_Debussy%29_Suite_bergamasque.ogg', 'https://commons.wikimedia.org/wiki/File:Clair_de_lune_(Claude_Debussy)_Suite_bergamasque.ogg', 'Public domain'),
  Track('Classical', 'Cello Suite No. 1 \u2014 Pr\u00e9lude', 'Bach', 'https://upload.wikimedia.org/wikipedia/commons/b/b8/Bach_-_Cello_Suite_no._1_in_G_major%2C_BWV_1007_-_I._Pr%C3%A9lude%2C_Lud_and_Schlatts_Musical_Emporium.ogg', 'https://commons.wikimedia.org/wiki/File:Bach_-_Cello_Suite_no._1_in_G_major,_BWV_1007_-_I._Pr%C3%A9lude,_Lud_and_Schlatts_Musical_Emporium.ogg', 'CC BY 3.0'),
  Track('Classical', 'Three Preludes \u2014 No. 1', 'Gershwin', 'https://upload.wikimedia.org/wikipedia/commons/a/af/3_Preludes_%28Gershwin%29%2C_No._1.ogg', 'https://commons.wikimedia.org/wiki/File:3_Preludes_(Gershwin),_No._1.ogg', 'Public domain'),
  Track('Piano', 'Gymnop\u00e9die No. 1', 'Erik Satie', 'https://upload.wikimedia.org/wikipedia/commons/b/b7/Gymnopedie_No._1..ogg', 'https://commons.wikimedia.org/wiki/File:Gymnopedie_No._1..ogg', 'CC0'),
  Track('Piano', 'Gymnop\u00e9die No. 3', 'Erik Satie', 'https://upload.wikimedia.org/wikipedia/commons/c/ce/Gymnop%C3%A9die_no.3.ogg', 'https://commons.wikimedia.org/wiki/File:Gymnop%C3%A9die_no.3.ogg', 'CC0'),
  Track('Piano', 'Gnossienne No. 1', 'Erik Satie', 'https://upload.wikimedia.org/wikipedia/commons/e/e5/Erik_Satie_-_Gnossienne_no_1.ogg', 'https://commons.wikimedia.org/wiki/File:Erik_Satie_-_Gnossienne_no_1.ogg', 'CC BY-SA 3.0'),
  Track('Piano', 'Gnossienne No. 2', 'Erik Satie', 'https://upload.wikimedia.org/wikipedia/commons/c/c8/Gnossienne_2_%28Satie%29.ogg', 'https://commons.wikimedia.org/wiki/File:Gnossienne_2_(Satie).ogg', 'Public domain'),
  Track('Rain', 'Steady rain', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/8/8a/Sound_of_rain.ogg', 'https://commons.wikimedia.org/wiki/File:Sound_of_rain.ogg', 'CC BY-SA 3.0', loop: true),
  Track('Rain', 'Rain against the window', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/4/41/Rain_against_the_window.ogg', 'https://commons.wikimedia.org/wiki/File:Rain_against_the_window.ogg', 'Public domain', loop: true),
  Track('Rain|Birds', 'Rain, thunder and birds', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/a/ab/Rain_thunder_and_birds.ogg', 'https://commons.wikimedia.org/wiki/File:Rain_thunder_and_birds.ogg', 'Public domain', loop: true),
  Track('Nature', 'Pond at dusk, frogs and crickets', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/f/fe/Nature_sounds_ambience_in_a_Dordogne_pond.ogg', 'https://commons.wikimedia.org/wiki/File:Nature_sounds_ambience_in_a_Dordogne_pond.ogg', 'CC BY 3.0', loop: true),
  Track('Nature|Birds', 'Forest ambience, crows and wind', 'nille (PDSounds)', 'https://upload.wikimedia.org/wikipedia/commons/0/0a/20090610_0_ambience.ogg', 'https://commons.wikimedia.org/wiki/File:20090610_0_ambience.ogg', 'Public domain', loop: true),
  Track('Nature', 'Beach, South Carolina', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/0/04/Beach_sounds_South_Carolina.ogg', 'https://commons.wikimedia.org/wiki/File:Beach_sounds_South_Carolina.ogg', 'Open licence', loop: true),
  Track('Nature', 'Campfire', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/b/b1/Campfire_sound_ambience.ogg', 'https://commons.wikimedia.org/wiki/File:Campfire_sound_ambience.ogg', 'Open licence', loop: true),
  Track('Nature', 'Caf\u00e9 ambiance', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/5/54/Cafe_ambiance.ogg', 'https://commons.wikimedia.org/wiki/File:Cafe_ambiance.ogg', 'Open licence'),
  Track('Nature|Birds', 'Lamington rainforest soundscape', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/a/a5/Short_nature_soundscape%2C_Lamington_National_Park%2C_Australia.ogg', 'https://commons.wikimedia.org/wiki/File:Short_nature_soundscape,_Lamington_National_Park,_Australia.ogg', 'Open licence'),
  Track('Birds', 'Birdsong, Bourne Woods', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/c/cb/Birdsong_Bourne_Woods_2020-04-27_0722.mp3', 'https://commons.wikimedia.org/wiki/File:Birdsong_Bourne_Woods_2020-04-27_0722.mp3', 'Open licence', loop: true),
  Track('Birds', 'Me and a magpie', 'Wikimedia Commons', 'https://upload.wikimedia.org/wikipedia/commons/2/25/01_-_Me_And_A_Magpie.ogg', 'https://commons.wikimedia.org/wiki/File:01_-_Me_And_A_Magpie.ogg', 'Open licence'),
];
