class_name Music
extends RefCounted
## The music of the land (the Thundering Pots release).  **Every note is written here and every sound
## is made here**: there is no audio file in the repository.  A tune is a few lines of numbered
## notation (jianpu, the way the tunes of the land have been written down since the brush: 1 2 3 5 6
## are the five tones, a dash holds a note, an underline halves it), a key, a tempo and the
## instruments that play it; `render` turns it into sound with instruments built from arithmetic:
##
##   qin, zheng, pipa   plucked strings: a burst of noise going round a delay line (Karplus-Strong)
##   dizi, xiao, erhu   a wave of a few harmonics with breath, a slow vibrato and a soft attack
##   bell, chime        a struck bronze: partials that are not quite harmonics, each dying at its own rate
##   drum, pot, gong    a falling sine and a burst of noise; a clay pot is the same with less of both
##
## Thirty-four tunes: one for the title, the sect, the mountain, each of the six hearths (their
## **airs**, which are learned in the story and sounded over a field of war), ten kinds of wild
## country, the night, a cave, the cloud-kite, battles, lords, war, the clay host, sitting still,
## the ending, and one that nobody wrote down.  `tick` plays what the place, the hour and the screen
## call for and cross-fades between them; the songbook (Esc > Songs) keeps every tune heard, shows it
## as a roll of notes, and plays it when asked.
##
## A tune is synthesised the first time it is wanted, on a worker thread (a second or two), and kept
## for the rest of the session.  With no window (the bot in CI, the tests) nothing is synthesised and
## nothing plays: what would be playing is still worked out, so the songbook fills as it would.

const RATE := 22050
const TAB := 1024
## how loud music is (dB), how long a cross-fade takes (s), how long a tune must be the one wanted
## before it counts as heard (s)
const VOL_DB := -9.0
const FADE := 1.4
const HEARD_AFTER := 3.0
## the average level every tune is brought to
const LEVEL := 0.16

const DEGREE := {"1": 0, "2": 2, "3": 4, "4": 5, "5": 7, "6": 9, "7": 11}

## `key`: the MIDI note of degree 1; `bpm`; `voices`: [instrument, volume, octaves up, notes, loops?]
## (a voice that loops is a pattern repeated under the first voice, which sets the tune's length).
## `where`: when it is heard, for the songbook.
const TUNES := {
	"title": {"n": "Azure Cloud", "key": 62, "bpm": 60, "where": "Before the journey begins.",
		"desc": "A xiao over a qin's slow broken chords, in the yu mode: the mountain above the sea of clouds, before anybody is up.",
		"voices": [["xiao", 0.9, 0, "6, - 1 2 | 3 - - 2_ 1_ | 6, - 1 3 | 2 - - - | 3 - 5 6 | 5 - 3 2_ 1_ | 2 - 3 1 | 6, - - - | 6 - 5 3 | 5 - - 6_ 5_ | 3 - 2 1 | 2 - - - | 1 - 2 3 | 5 - 3 2 | 1 - 6, 1 | 6, - - -"],
			["qin", 0.7, -1, "6, 3 6 3 | 1 5 1' 5 | 6, 3 6 3 | 2 6 2' 6 | 1 5 1' 5 | 3 1' 3' 1' | 2 6 2' 6 | 6, 3 6 -", true]]},
	"sect": {"n": "Nine Hundred and Ninety-Nine Steps", "key": 67, "bpm": 84, "where": "In the courtyards of the Azure Cloud Sect.",
		"desc": "A bamboo flute in the bright gong mode over a qin, with a wood-block keeping the count: a broom's rhythm, if a broom had one.",
		"voices": [["dizi", 0.8, 0, "5 6 1' 6 | 5 3 5 - | 6 5 3 2 | 1 - - - | 2 3 5 3 | 2 1 6, 1 | 2 3 2 1 | 5, - - - | 5 6 1' 2' | 1' 6 5 - | 3 5 6 5 | 3 2 1 - | 6, 1 2 3 | 5 3 2 1 | 6, 5, 6, 1 | 1 - - -"],
			["qin", 0.65, -1, "1 - 5 - | 1 - 3 - | 6, - 3 - | 1 - 5, - | 2 - 6 - | 2 - 6, - | 5, - 2 - | 5, - 5 -", true],
			["drum", 0.25, 0, "0 5 0 5", true]]},
	"mountain": {"n": "Sun-Viewing", "key": 60, "bpm": 66, "where": "On Azure Cloud Mountain, and in the sea of clouds.",
		"desc": "Wide leaps on the xiao, a fifth and then an octave, the way the eye goes up a peak; the qin answers a bar behind.",
		"voices": [["xiao", 0.9, 0, "1 - 5 - | 6 5 3 - | 2 - 3 5 | 1' - - - | 6 - 1' 6 | 5 3 2 - | 3 5 2 1 | 1 - - - | 5 - 6 1' | 2' - 1' 6 | 5 - 6 5 | 3 - - - | 2 3 5 6 | 5 3 2 1 | 6, - 1 2 | 1 - - -"],
			["qin", 0.7, -1, "1 - - 5 | 1' - 5 - | 6, - - 3 | 6 - 3 -", true]]},
	"valley": {"n": "Green Stone, Green Rice", "key": 65, "bpm": 96, "air": "valley", "where": "In Qingshi and Cloudfoot, the towns of the Rice Hearth.",
		"desc": "The air of the Rice Hearth: a planting song, quick, on the flute, with a pipa picking out every second beat and the count kept on wood. It is sung bent double, so the phrases are short.",
		"voices": [["dizi", 0.8, 0, "3_ 5_ 6 5 3_ 2_ | 1 2 3 - | 5_ 6_ 1' 6 5_ 3_ | 2 - - - | 3_ 2_ 1 6, 1 | 2_ 3_ 5 3 2 | 1_ 2_ 3 2 1_ 6,_ | 5, - - - | 5,_ 6,_ 1 2 3 | 5 6_ 5_ 3 - | 2_ 3_ 5 6_ 5_ 3_ 2_ | 1 - - 2 | 3 5_ 3_ 2 1 | 6, 1_ 2_ 3 - | 2_ 1_ 6, 5, 6, | 1 - - -"],
			["pipa", 0.6, -1, "1 5 3 5 | 1 5 3 5 | 6, 3 1 3 | 5, 2 7, 2", true],
			["drum", 0.22, 0, "5 0 5_ 5_ 0", true]]},
	"steppe": {"n": "Long Song of the Felt Tents", "key": 62, "bpm": 56, "air": "steppe", "where": "Among the tents of the Felt Hearth, below Thunder Valley.",
		"desc": "The air of the Felt Hearth: a long song, one fiddle over a drone, every note held until the breath or the horizon runs out. The horse-folk say a short song is for people with walls.",
		"voices": [["erhu", 0.85, 0, "6, - - 3 | 3 - 5_ 6_ 1' | 6 - - 5_ 3_ | 5 - - - | 6 - 1' 2' | 3' - 2'_ 1'_ 6 | 5 - 6 3 | 3 - - - | 2 - 3 5 | 6 - - 1' | 6 5 3 2 | 3 - - - | 6, - 1 2 | 3 - 5 3 | 2 - 1 6, | 6, - - -"],
			["xiao", 0.35, -1, "6, - - - | 3 - - -", true],
			["qin", 0.5, -2, "6 - - - | 0 - 3' -", true]]},
	"sand": {"n": "Bells of Shazhou", "key": 64, "bpm": 100, "air": "sand", "where": "Round the well of Shazhou, the town of the Sweet-Well Hearth.",
		"desc": "The air of the Sweet-Well Hearth: a caravan tune with a half-step in it that the valley does not have, on the pipa, over a hand-drum and a camel's bell. It came down the road from somewhere west of the maps.",
		"voices": [["pipa", 0.85, 0, "3 4_ 3_ 6 - | 7 1'_ 7_ 6 4 | 3 - 4 6 | 3 - - - | 6 7_ 6_ 1' - | 2' 1'_ 7_ 6 4 | 6 4 3 4 | 3 - - - | 3' 2'_ 1'_ 7 6 | 7 - 6 4 | 3 4 6 7 | 6 - - - | 1' 7_ 6_ 4 3 | 4 6_ 4_ 3 - | 4 3 7, 1 | 3 - - -"],
			["drum", 0.4, 0, "1 0 5_ 5_ 0 | 1 0 5 0", true],
			["bell", 0.25, 1, "0 - - 3 | 0 - - -", true]]},
	"river": {"n": "The Haulers' Call", "key": 57, "bpm": 72, "air": "river", "where": "At Longmen Ferry, the town of the Boat Hearth.",
		"desc": "The air of the Boat Hearth: the call the haulers sing on the tow-path below the Dragon Gate, one voice and then all of them, with a drum for the pull. The second half of every phrase is the rope coming in.",
		"voices": [["dizi", 0.8, 0, "5 - 6 5 | 3 - 2 - | 5 - 6 1' | 5 - - - | 1' - 6 5 | 6 - 5 3 | 2 3 5 3 | 2 - - - | 5, - 6, 1 | 2 - 3 - | 5 3 2 1 | 6, - - - | 1 - 2 3 | 5 - 6 5 | 3 2 1 6, | 5, - - -"],
			["erhu", 0.4, -1, "0 - - - | 0 - 5 3 | 0 - - - | 0 - 2 5", true],
			["drum", 0.45, 0, "1 - 0 - | 1 - 5 5", true]]},
	"forge": {"n": "Hammer Song of Tushan", "key": 60, "bpm": 108, "air": "forge", "where": "In Tushan, the town of the Casting Hearth.",
		"desc": "The air of the Casting Hearth: two hammers and a song to keep them out of each other's way. Every phrase starts with the same note struck twice, because that is where the hammers fall.",
		"voices": [["pipa", 0.85, 0, "1 1 5 5 | 6_ 5_ 3 5 - | 1 1 5 5 | 3_ 2_ 1 2 - | 3 3 6 6 | 5_ 3_ 2 3 - | 5 3 2 1 | 1 - 0 - | 5 5 1' 1' | 6_ 5_ 3 5 - | 6 6 2' 2' | 1'_ 6_ 5 6 - | 5 6 1' 6 | 5 3 2 3 | 5 2 3 1 | 1 - 0 -"],
			["bell", 0.3, 1, "0 5 0 5", true],
			["drum", 0.5, 0, "1 0 1 0", true]]},
	"dawn": {"n": "Lanterns of the Dawn Market", "key": 67, "bpm": 112, "air": "dawn", "where": "In Yanggu, the town of the Lantern Hearth.",
		"desc": "The air of the Lantern Hearth: the tune the Lantern Dragon is danced to down the main street on the fifteenth night, flute and pipa and a small gong, quick enough that the dragon's tail has to run.",
		"voices": [["dizi", 0.8, 0, "5_ 5_ 6 5_ 3_ 2 | 3_ 5_ 6 1' - | 6_ 6_ 1' 6_ 5_ 3 | 5 - - - | 3_ 3_ 5 3_ 2_ 1 | 2_ 3_ 5 6 - | 5_ 6_ 5_ 3_ 2 3 | 1 - - - | 1'_ 1'_ 2' 1'_ 6_ 5 | 6_ 1'_ 2' 3' - | 2'_ 1'_ 6 5 6 | 5 - - - | 3_ 5_ 6_ 5_ 3 2 | 1_ 2_ 3 5 - | 6_ 5_ 3_ 2_ 1 2 | 1 - - -"],
			["pipa", 0.55, -1, "1_ 5_ 3_ 5_ 1_ 5_ 3_ 5_ | 6,_ 3_ 1_ 3_ 5,_ 2_ 7,_ 2_", true],
			["gong", 0.3, 0, "5 0 0 0 | 0 0 5 0", true],
			["drum", 0.3, 0, "1 5_ 5_ 1 5", true]]},
	"bamboo": {"n": "Whispering Bamboo", "key": 64, "bpm": 70, "where": "In the green country: bamboo, tea, mulberry, maple and garden.",
		"desc": "A flute with a great deal of breath in it, over a qin: the sound of a wood that is mostly air.",
		"voices": [["dizi", 0.75, 0, "3 - 5 6 | 5 - 3 - | 2 3 5 3 | 2 - - - | 1 2 3 5 | 6 - 5 - | 3 5 2 3 | 1 - - - | 6 - 1' 6 | 5 - 6 5 | 3 2 3 5 | 6 - - - | 5 6 5 3 | 2 - 3 2 | 1 6, 1 2 | 1 - - -"],
			["qin", 0.7, -1, "1 - 5 - | 3 - 5 - | 6, - 3 - | 2 - 6, -", true]]},
	"marsh": {"n": "Crimson Marsh", "key": 61, "bpm": 58, "where": "In the wet country: marsh, fungus, lilies and the drowned land.",
		"desc": "A low xiao in the yu mode with the leading tone left in, which the old books call a sound of grief, and one stone chime a long way off.",
		"voices": [["xiao", 0.9, 0, "6, - 7, 1 | 3 - 2 - | 1 - 7, 6, | 6, - - - | 3 - 5 3 | 2 - 1 - | 7, 1 2 7, | 6, - - - | 1 - 3 5 | 6 - 5 - | 3 5 2 3 | 1 - - - | 2 - 1 7, | 6, - 3, - | 5, 6, 7, 5, | 6, - - -"],
			["chime", 0.3, 1, "0 - - - | 0 - 6 - | 0 - - - | 3 - - -", true],
			["qin", 0.55, -2, "6 - - - | 3 - - -", true]]},
	"frost": {"n": "Frostpeak", "key": 69, "bpm": 54, "where": "In the cold country: the snow peaks, the aurora and the Palace of the Moon.",
		"desc": "Stone chimes, high and far apart, and a xiao that waits for each to finish. Cold air carries a note a long way and gives none of it back.",
		"voices": [["xiao", 0.8, 0, "6 - - 3' | 2' - - - | 1' - 6 - | 5 - - - | 6 - 1' 2' | 3' - - 2' | 1' - 6 5 | 6 - - -"],
			["chime", 0.45, 1, "0 - 6 - | 0 - 3 - | 0 - 1' - | 0 - 5 -", true],
			["qin", 0.5, -2, "6 - - - | 0 - - - | 3 - - - | 0 - - -", true]]},
	"thunder": {"n": "Thunder Valley", "key": 62, "bpm": 120, "where": "In the loud country: thunder, the volcano, the forges of heaven and Buzhou.",
		"desc": "A fiddle driven hard over two drums, in the yu mode. The drum figure is the one Lei Gong practises: one, and then three that hurry.",
		"voices": [["erhu", 0.8, 0, "6 - 6_ 5_ 3 | 5 - 6 - | 1' - 1'_ 6_ 5 | 6 - - - | 3 3_ 5_ 6 5 | 3 2 3 - | 5 5_ 6_ 1' 6 | 5 - - - | 2' - 2'_ 1'_ 6 | 1' - 6 - | 5 6 1' 2' | 3' - - - | 2' 1' 6 5 | 6 5 3 2 | 3 5 6 5 | 6 - - -"],
			["pipa", 0.5, -1, "6,_ 6_ 3_ 6_ 6,_ 6_ 3_ 6_ | 5,_ 5_ 2_ 5_ 5,_ 5_ 2_ 5_", true],
			["drum", 0.6, 0, "1 0 1_ 1_ 5 | 1 5_ 5_ 1 5", true]]},
	"desert": {"n": "Fallen Stars", "key": 59, "bpm": 63, "where": "In the dry country: the desert, the millet plain and the stone forest.",
		"desc": "A xiao alone for most of it, with a pipa that plays one note and thinks about the next. There is a great deal of room in it.",
		"voices": [["xiao", 0.9, 0, "3 - - 6 | 5 - 3 - | 2 - 3 5 | 3 - - - | 6 - - 1' | 7 - 6 - | 5 - 6 3 | 3 - - - | 3' - 2' 1' | 6 - 5 - | 3 5 6 1' | 6 - - - | 5 - 3 2 | 3 - 6, - | 1 2 3 2 | 3 - - -"],
			["pipa", 0.5, -1, "3 - - - | 0 - 6 - | 3 - - - | 0 - 7, -", true]]},
	"heaven": {"n": "The Nine Heavens", "key": 65, "bpm": 60, "where": "In the realm above: the Celestial Court, the Silver River, the Jasper Pool.",
		"desc": "A rack of bronze bells under a xiao, in the gong mode, the mode of the ruler. It is exactly as grand as it means to be, and one of the bells is very slightly flat.",
		"voices": [["xiao", 0.85, 0, "5 - 1' - | 2' - 1' 6 | 5 - 6 1' | 5 - - - | 3 - 5 6 | 1' - 6 5 | 3 5 2 3 | 1 - - - | 1' - 2' 3' | 5' - 3' 2' | 1' - 2' 1' | 6 - - - | 5 6 1' 2' | 1' 6 5 3 | 2 3 5 6 | 5 - - -"],
			["bell", 0.5, -1, "1 - - - | 5, - - - | 6, - - - | 3, - - -", true],
			["zheng", 0.4, 0, "1_ 3_ 5_ 1'_ 5_ 3_ 1_ 5,_ | 6,_ 1_ 3_ 6_ 3_ 1_ 6,_ 3,_", true]]},
	"under": {"n": "The Nine Springs", "key": 60, "bpm": 50, "where": "In the realm below: the Yellow Springs, Youdu, the abyss and the graveyards.",
		"desc": "The lowest xiao there is, a great gong struck once every four bars, and a drum like a door a long way down. It is not unkind. It is only in no hurry.",
		"voices": [["xiao", 0.95, -1, "6 - - - | 1' - 7 - | 6 - 3 - | 3 - - - | 2' - - 1' | 7 - 6 - | 5 - 6 7 | 6 - - - | 3' - - 2' | 1' - 7 - | 6 7 1' 2' | 3' - - - | 2' 1' 7 6 | 5 - 3 - | 5 6 7 5 | 6 - - -"],
			["gong", 0.4, 0, "1 - - - | 0 - - - | 0 - - - | 0 - - -", true],
			["drum", 0.4, 0, "1 - - - | 0 - 1 -", true]]},
	"sea": {"n": "The Isles", "key": 67, "bpm": 76, "where": "By the sea: Penglai and the Isles of the Immortals, Fusang, the Returning Ruins.",
		"desc": "A flute over a zheng that never stops rising and falling, eight notes to the bar: the swell under a boat.",
		"voices": [["dizi", 0.75, 0, "1 - 2 3 | 5 - - 6 | 5 3 2 3 | 1 - - - | 6, - 1 2 | 3 - - 5 | 3 2 1 6, | 5, - - - | 5 - 6 1' | 2' - - 1' | 6 5 6 1' | 5 - - - | 3 - 5 6 | 5 3 2 1 | 2 3 2 6, | 1 - - -"],
			["zheng", 0.6, -1, "1_ 5_ 1'_ 3'_ 5'_ 3'_ 1'_ 5_ | 6,_ 3_ 6_ 1'_ 3'_ 1'_ 6_ 3_", true]]},
	"strange": {"n": "The Unwritten", "key": 66, "bpm": 48, "where": "Where the world is not finished: time, the origin, chaos and the mirror.",
		"desc": "A scale with no home note, on bells and a qin, each note a whole step from the last so that nothing leads anywhere. Ling Lun says it is what the pipes sounded like before he cut them.",
		"voices": [["bell", 0.6, 0, "1 - 3 - | 4# - 2 - | 6#, - 1 - | 4# - - - | 6# - 5# - | 4# - 3 - | 2 - 1 - | 6#, - - -"],
			["qin", 0.6, -1, "1 - - 4# | 0 - 2 - | 6#, - - 3 | 0 - 5# -", true]]},
	"night": {"n": "The Third Watch", "key": 62, "bpm": 52, "where": "Out in the land after dark.",
		"desc": "A xiao alone, and a qin string touched now and then. It leaves out more notes than it plays.",
		"voices": [["xiao", 0.85, 0, "3 - - 5 | 6 - - - | 5 - 3 2 | 3 - - - | 1 - - 2 | 3 - 5 - | 2 - 1 6, | 6, - - -"],
			["qin", 0.6, -2, "6 - - - | 0 - 3' - | 1' - - - | 0 - 6 -", true]]},
	"watch": {"n": "The Watchman's Round", "key": 57, "bpm": 60, "where": "In a town after dark.",
		"desc": "A qin, slowly, and the watchman's gong: once for the watch, and twice at the end of the round to say that all is well, whether or not it is.",
		"voices": [["qin", 0.85, 0, "6, - 1 - | 2 - 3 - | 2 - 1 - | 6, - - - | 5, - 6, - | 1 - 2 - | 1 - 6, - | 6, - - -"],
			["gong", 0.3, 0, "5 - - - | 0 - - - | 0 - - - | 0 - 5 5", true]]},
	"cave": {"n": "Stone Chimes", "key": 60, "bpm": 46, "where": "Under the ground.",
		"desc": "Stone on stone, far apart, with the long echo a cave gives, and under it one low string. The first music, they say: somebody knocked on a cave to see if it was hollow, and it sang.",
		"voices": [["chime", 0.7, 0, "6 - - - | 3' - - 1' | 2' - - - | 6 - - - | 5 - - 1' | 6 - - - | 3 - 5 - | 6 - - -"],
			["qin", 0.5, -2, "6 - - - | 0 - - - | 3 - - - | 0 - - -", true],
			["drum", 0.12, 0, "0 - 5 - | 0 - - - | 0 - - 5 | 0 - - -", true]]},
	"kite": {"n": "Leaning on Nothing", "key": 69, "bpm": 88, "where": "Under the cloud-kite, and on a summit.",
		"desc": "A flute that goes up and stays up, over a zheng running in sixteenths like air over paper. Master Lie hums it and denies that he does.",
		"voices": [["dizi", 0.8, 0, "5 - 1' 2' | 3' - - 2' | 1' - 6 1' | 5 - - - | 6 - 1' 2' | 5' - - 3' | 2' - 1' 2' | 1' - - - | 3' - 5' 3' | 2' - 1' 6 | 1' - 2' 3' | 2' - - - | 1' 6 5 6 | 1' - 2' 3' | 2' 1' 6 1' | 1' - - -"],
			["zheng", 0.5, 0, "1_ 5_ 1'_ 5_ 3_ 5_ 1'_ 5_ | 6,_ 3_ 6_ 3_ 1_ 3_ 6_ 3_", true]]},
	"battle": {"n": "Crossed Blades", "key": 64, "bpm": 132, "where": "In battle.",
		"desc": "A pipa in running eighths, a fiddle doubling it and a drum on every beat: quick, in the yu mode, and over before anybody has decided how they feel.",
		"voices": [["pipa", 0.85, 0, "6_ 6_ 3'_ 6_ 5_ 6_ 3_ 5_ | 6_ 6_ 1'_ 6_ 5_ 3_ 5 | 6_ 6_ 3'_ 6_ 5_ 6_ 1'_ 2'_ | 3' - 2' - | 2'_ 2'_ 6_ 2'_ 1'_ 2'_ 6_ 1'_ | 2'_ 2'_ 3'_ 2'_ 1'_ 6_ 5 | 3_ 5_ 6_ 1'_ 6_ 5_ 3_ 5_ | 6 - 6 0"],
			["erhu", 0.45, 0, "6 - 3' - | 6 - 5 - | 6 - 3' - | 3' - 2' - | 2' - 6 - | 2' - 1' - | 3 - 6 - | 6 - - 0"],
			["drum", 0.55, 0, "1 5_ 5_ 1 5 | 1 5_ 5_ 1_ 1_ 5", true]]},
	"boss": {"n": "The Lord of the Place", "key": 60, "bpm": 100, "where": "Before a lord of the land.",
		"desc": "A low fiddle, heavy drums and a great gong on the first beat of every fourth bar. The tune is the same four notes going down, a step lower each time, like somebody coming down a stair towards you.",
		"voices": [["erhu", 0.85, -1, "6 - 6_ 7_ 1' | 3' - 2' 1' | 7 - 7_ 1'_ 2' | 6 - - - | 3' - 3'_ 5'_ 6' | 5' - 3' 2' | 1' 2' 3' 1' | 7 - - - | 6' - 6'_ 5'_ 3' | 5' - 6' 1'' | 7' - 6' 5' | 6' - - - | 3' 5' 6' 5' | 3' 2' 1' 7 | 6 7 1' 7 | 6 - - -"],
			["bell", 0.35, -1, "6, - - - | 0 - - - | 5, - - - | 0 - - -", true],
			["gong", 0.4, 0, "1 - - - | 0 - - - | 0 - - - | 0 - - -", true],
			["drum", 0.6, 0, "1 0 0 1_ 1_ | 1 0 5 0", true]]},
	"tribulation": {"n": "Tribulation", "key": 62, "bpm": 144, "where": "At a breakthrough, and against the last of a chapter's lords.",
		"desc": "A pipa in tremolo, every note struck twice, and drums that do not leave room for breath. It is the one piece in the book that is meant to be uncomfortable.",
		"voices": [["pipa", 0.9, 0, "3'_ 3'_ 3'_ 3'_ 2'_ 2'_ 1'_ 1'_ | 6_ 6_ 1'_ 1'_ 2'_ 2'_ 3' | 5'_ 5'_ 5'_ 5'_ 3'_ 3'_ 2'_ 2'_ | 1'_ 1'_ 2'_ 2'_ 3' - | 6 1' 2' 3' | 5' - 3' - | 2'_ 3'_ 2'_ 1'_ 6 1' | 6 - 6 0"],
			["erhu", 0.5, 0, "3' - 2' 1' | 6 - 2' 3' | 5' - 3' 2' | 1' - 3' - | 6 - 2' - | 5' - 3' - | 2' - 6 - | 6 - - 0"],
			["gong", 0.35, 0, "1 - - - | 0 - - - | 0 - - - | 0 - 5 -", true],
			["drum", 0.65, 0, "1_ 1_ 5 1_ 1_ 5 | 1 5_ 5_ 1_ 5_ 1_ 5_", true]]},
	"war": {"n": "Ambush on Every Side", "key": 62, "bpm": 126, "where": "Over a field of war.",
		"desc": "A pipa played as the old war pieces are: one note struck again and again, faster, until it is a roll, then the tune let go all at once. War drums, a gong for the orders, and a reed horn over the top that can be heard by the hindmost rank.",
		"voices": [["pipa", 0.85, 0, "5 5 5 5 | 5_ 5_ 5_ 5_ 5_ 5_ 5_ 5_ | 6 - 5 - | 3 - 2 - | 5_ 6_ 5_ 3_ 2_ 3_ 5 | 6_ 1'_ 6_ 5_ 3_ 5_ 6 | 1' - 6 5 | 6 - - - | 2' 2' 2' 2' | 2'_ 2'_ 2'_ 2'_ 1'_ 1'_ 6_ 6_ | 5 - 6 - | 1' - 2' - | 3'_ 2'_ 1'_ 6_ 5_ 6_ 1' | 2'_ 1'_ 6_ 5_ 3_ 5_ 6 | 5 3 2 3 | 5 - 5 0"],
			["suona", 0.4, 0, "0 - - - | 0 - - - | 6 - 5 - | 3 - 2 - | 0 - - - | 0 - - - | 1' - 6 5 | 6 - - - | 0 - - - | 0 - - - | 5 - 6 - | 1' - 2' - | 0 - - - | 0 - - - | 5 3 2 3 | 5 - - 0"],
			["gong", 0.35, 0, "1 - - - | 0 - - - | 0 - - - | 0 - - - | 5 - - - | 0 - - - | 0 - - - | 0 - - -", true],
			["drum", 0.65, 0, "1 1 1_ 1_ 1 | 1_ 5_ 1_ 5_ 1 1", true]]},
	"clay": {"n": "Clay Pots Thunder", "key": 45, "bpm": 92, "where": "Where the clay host marches.",
		"desc": "\"The Yellow Bell is broken and thrown away, and the clay pots thunder.\" Three notes, chanted flat by eight thousand who were fired without ears, and the pots: struck with whatever was to hand, exactly in time, with no tune in them at all.",
		"voices": [["erhu", 0.7, 0, "1 1 3 1 | 1 1 5, - | 1 1 3 1 | 2 1 6, - | 3 3 5 3 | 3 2 1 - | 1 1 3 1 | 1 - 0 -"],
			["pot", 0.75, 0, "5 1 5_ 5_ 1 | 5 1 1 5", true],
			["drum", 0.5, 0, "1 - 1 - | 1 - 1 1", true]]},
	"chu": {"n": "The Songs of Chu", "key": 62, "bpm": 60, "where": "When the airs of the land are sounded over a field of war.",
		"desc": "A song of home, in the zhi mode, a fiddle and a xiao in unison as two people sing who learned it from the same mother. At Gaixia it was sung on four sides in the night, and by morning eight thousand had gone home. Nobody has ever said who started it.",
		"voices": [["erhu", 0.75, 0, "5 - 3 5 | 6 - - 5 | 3 - 2 3 | 5 - - - | 1' - 6 5 | 6 - 5 3 | 2 - 3 2 | 1 - - - | 2 - 3 5 | 6 - 1' - | 6 5 3 5 | 2 - - - | 3 - 5 6 | 5 - 3 2 | 1 2 3 2 | 1 - - -"],
			["xiao", 0.6, 0, "5 - 3 5 | 6 - - 5 | 3 - 2 3 | 5 - - - | 1' - 6 5 | 6 - 5 3 | 2 - 3 2 | 1 - - - | 2 - 3 5 | 6 - 1' - | 6 5 3 5 | 2 - - - | 3 - 5 6 | 5 - 3 2 | 1 2 3 2 | 1 - - -"],
			["qin", 0.55, -1, "1 - 5 - | 6, - 3 - | 1 - 5 - | 5, - 2 -", true]]},
	"still": {"n": "Sitting and Forgetting", "key": 53, "bpm": 40, "where": "In meditation.",
		"desc": "A qin, alone, with long silences. The player is said to have asked how many notes it should have, and been told: fewer.",
		"voices": [["qin", 0.9, 0, "1 - - - | 5 - - - | 6 - 1' - | 5 - - - | 3 - 5 - | 6 - - - | 2' - 1' - | 1 - - -"],
			["chime", 0.25, 2, "0 - - 5 | 0 - - - | 0 - 3 - | 0 - - -", true]]},
	"lotus": {"n": "The Lotus Pond", "key": 67, "bpm": 66, "where": "When Yue Ling has something to say.",
		"desc": "A zheng and a xiao, in the gong mode, a tune that keeps starting to go somewhere and coming back to the same three notes. She says it is not hers. It is.",
		"voices": [["xiao", 0.8, 0, "3 - 5 3 | 2 - 1 - | 6, - 1 2 | 3 - - - | 5 - 6 5 | 3 - 2 - | 1 2 3 5 | 2 - - - | 3 - 5 6 | 1' - 6 - | 5 6 5 3 | 5 - - - | 6 - 5 3 | 2 - 3 5 | 2 1 6, 2 | 1 - - -"],
			["zheng", 0.6, -1, "1_ 5_ 3'_ 5_ 1'_ 5_ 3'_ 5_ | 6,_ 3_ 1'_ 3_ 6_ 3_ 1'_ 3_", true]]},
	"ending": {"n": "The Great Note", "key": 60, "bpm": 63, "where": "At the end.",
		"desc": "Everything in the book at once: bells, xiao, fiddle, qin and zheng, in the gong mode, going up by steps to a note it holds. \"The great note is rarely sounded,\" says the Old Master. This is not it. This is what there is instead.",
		"voices": [["xiao", 0.8, 0, "1 - 2 3 | 5 - - 6 | 1' - 6 5 | 6 - - - | 5 - 6 1' | 2' - - 3' | 2' 1' 6 1' | 5 - - - | 3 - 5 6 | 1' - 2' 3' | 5' - 3' 2' | 1' - - - | 6 - 1' 6 | 5 - 3 5 | 2 - 3 2 | 1 - - -"],
			["erhu", 0.45, 0, "0 - - - | 0 - - - | 1' - 6 5 | 6 - - - | 0 - - - | 0 - - - | 2' 1' 6 1' | 5 - - - | 3 - 5 6 | 1' - 2' 3' | 5' - 3' 2' | 1' - - - | 6 - 1' 6 | 5 - 3 5 | 2 - 3 2 | 1 - - -"],
			["bell", 0.45, -1, "1 - - - | 5, - - - | 6, - - - | 3, - - - | 4, - - - | 5, - - - | 6, - - - | 5, - - -", true],
			["zheng", 0.45, 0, "1_ 3_ 5_ 1'_ 5_ 3_ 1_ 5,_ | 5,_ 7,_ 2_ 5_ 2_ 7,_ 5,_ 2,_ | 6,_ 1_ 3_ 6_ 3_ 1_ 6,_ 3,_ | 3,_ 5,_ 7,_ 3_ 7,_ 5,_ 3,_ 7,,_", true],
			["qin", 0.5, -2, "1' - - - | 5 - - - | 6 - - - | 3 - - -", true]]},
	"indoors": {"n": "Tea Going Cold", "key": 64, "bpm": 72, "where": "Indoors, upstairs and in cellars.",
		"desc": "A pipa by itself in somebody else's room, played quietly so as not to be asked to stop.",
		"voices": [["pipa", 0.8, 0, "3_ 5_ 6 5 3 | 2 - 1 - | 2_ 3_ 5 3 2 | 6, - - - | 1_ 2_ 3 2 1 | 6, - 5, - | 6,_ 1_ 2 3 2 | 1 - - -"],
			["qin", 0.4, -1, "1 - - - | 6, - - - | 2 - - - | 5, - - -", true]]},
	"bell": {"n": "The Yellow Bell", "key": 60, "bpm": 50, "where": "When the Yellow Bell is hung again.",
		"desc": "Not a tune. The twelve pipes in order, as Ling Lun cut them to the phoenix's song, each a third part shorter or longer than the one before; and then the note they are all measured from, struck once, on the bell that is called yellow because it is the colour of the middle of things.",
		"voices": [["bell", 0.8, 0, "1 1# 2 2# | 3 4 4# 5 | 5# 6 6# 7 | 1' - - - | 0 - - - | 1 - - - | 0 - - - | 1, - - -"],
			["xiao", 0.35, 0, "0 - - - | 0 - - - | 0 - - - | 1' - - - | 5 - - - | 1 - - - | 1 - - - | 1 - - -"]]},
	"ditty": {"n": "The Sweeper's Ditty", "key": 79, "bpm": 100, "hidden": true, "where": "On the steps, on a cold morning, when nobody is listening.",
		"desc": "Whistled through the teeth, with a broom for the beat. It is in no mode. It has never been played to anybody.",
		"voices": [["whistle", 0.7, 0, "5 3 5 6 | 5 - 3 - | 2 3 5 3 | 2 - 1 - | 6, 1 2 3 | 2 1 6, - | 5, 6, 1 2 | 1 - - -"],
			["drum", 0.18, 0, "5__ 0__ 0_ 5__ 0__ 0_ 5_ 0_ 0", true]]},
	# ---- three stings: a step of the story done, a feat, a breakthrough (played once, over the tune)
	"sting_step": {"n": "", "key": 72, "bpm": 132, "sting": true, "voices": [["chime", 0.6, 0, "5_ 1'_ 2' -"]]},
	"sting_feat": {"n": "", "key": 72, "bpm": 132, "sting": true, "voices": [["bell", 0.6, 0, "1_ 3_ 5_ 1'_ 1' -"], ["gong", 0.25, 0, "0 0 5 -"]]},
	"sting_break": {"n": "", "key": 60, "bpm": 120, "sting": true, "voices": [["zheng", 0.7, 0, "1__ 2__ 3__ 5__ 6__ 1'__ 2'__ 3'__ 5' - - -"], ["gong", 0.5, 0, "0 0 1 - - -"], ["bell", 0.5, 0, "0 0 1 - - -"]]},
}
## the songbook's order
const ORDER := ["title", "sect", "mountain", "valley", "steppe", "sand", "river", "forge", "dawn", "bamboo", "marsh", "frost", "thunder", "desert", "heaven", "under",
	"sea", "strange", "night", "watch", "cave", "indoors", "kite", "still", "lotus", "battle", "boss", "tribulation", "war", "clay", "chu", "bell", "ending", "ditty"]
## who still sings each hearth's air (asked in Part XXIII, and of any of them afterwards)
const TEACHERS := {"tofu_sun": "valley", "batu": "steppe", "well_keeper_zhaya": "sand", "boatwright_gao": "river", "bell_tuner_gong": "forge", "tea_seller_pan": "dawn"}
## the airs of the six hearths (cultures.gd): hearth -> tune
const AIRS := {"valley": "valley", "steppe": "steppe", "sand": "sand", "river": "river", "forge": "forge", "dawn": "dawn"}

## the tune of each kind of country (a region's theme): everything not named is "bamboo"
const OF_THEME := {"sect": "sect", "cloudsea": "mountain", "village": "bamboo", "tea": "bamboo", "silk": "bamboo", "maple": "bamboo", "garden": "bamboo", "bamboo": "bamboo",
	"marsh": "marsh", "fungal": "marsh", "lilies": "marsh", "drowned": "marsh",
	"frost": "frost", "aurora": "frost", "guanghan": "frost",
	"thunder": "thunder", "volcano": "thunder", "forge": "thunder", "buzhou": "thunder", "tushan": "thunder",
	"dunes": "desert", "millet": "desert", "karst": "desert", "yanggu": "desert",
	"celestial": "heaven", "court": "heaven", "palace": "heaven", "starpalace": "heaven", "starferry": "heaven", "magpie": "heaven", "jasper": "heaven", "loom": "heaven",
	"juntian": "heaven", "changhe": "heaven",
	"diyu": "under", "ninesprings": "under", "youdu": "under", "abyss": "under", "grave": "under", "void": "under",
	"penglai": "sea", "fangzhang": "sea", "yingzhou": "sea", "guixu": "sea", "fusang": "sea", "longmen": "sea",
	"time": "strange", "origin": "strange", "chaos": "strange", "mirror": "strange"}

# ---------------------------------------------------------------- reading a tune
## The notes of one voice: [[start (beats), length (beats), semitones above the key or -99 for a
## rest, the digit as written], ...] and the voice's length in beats.
static func parse(notes: String) -> Array:
	var out: Array = []
	var at := 0.0
	for tok in notes.split(" ", false):
		if tok == "|":
			continue
		if tok == "-":
			# a held beat: the note before it goes on
			if not out.is_empty():
				out[out.size() - 1][1] += 1.0
			at += 1.0
			continue
		var d := tok.substr(0, 1)
		var semi := -99
		if DEGREE.has(d):
			semi = int(DEGREE[d])
		var dur := 1.0
		for i in range(1, tok.length()):
			match tok[i]:
				"#":
					semi += 1
				"b":
					semi -= 1
				"'":
					semi += 12
				",":
					semi -= 12
				"_":
					dur *= 0.5
				".":
					dur *= 1.5
				"-":
					dur += 1.0
		out.append([at, dur, semi, int(d) if d.is_valid_int() else 0])
		at += dur
	return [out, at]

## How long a tune is, in beats (its first voice) and in seconds.
static func beats(id: String) -> float:
	return float(parse(str(TUNES[id].voices[0][3]))[1])

static func seconds(id: String) -> float:
	return beats(id) * 60.0 / float(TUNES[id].bpm)

static func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

## The notes of a tune's first voice as the songbook draws them: [[start, length, midi], ...].
static func roll(id: String) -> Array:
	var tn: Dictionary = TUNES[id]
	var out: Array = []
	for vi in tn.voices.size():
		var v: Array = tn.voices[vi]
		if str(v[0]) in ["drum", "pot", "gong"]:
			continue
		var pr: Array = parse(str(v[3]))
		var total := beats(id)
		var reps := 1 if v.size() < 5 or not bool(v[4]) else int(ceil(total / maxf(0.25, float(pr[1]))))
		for r in reps:
			for n in pr[0]:
				if int(n[2]) > -90 and float(n[0]) + r * float(pr[1]) < total:
					out.append([float(n[0]) + r * float(pr[1]), float(n[1]), int(tn.key) + int(n[2]) + 12 * int(v[2]), vi])
	return out

# ---------------------------------------------------------------- the instruments
static var _tabs := {}
static var _sin := PackedFloat32Array()

## One cycle of an instrument's wave: its harmonics added up.
static func _table(inst: String) -> PackedFloat32Array:
	if _tabs.has(inst):
		return _tabs[inst]
	var hs: Array = {"dizi": [1.0, 0.5, 0.26, 0.12, 0.05], "xiao": [1.0, 0.2, 0.08], "erhu": [1.0, 0.7, 0.5, 0.36, 0.25, 0.18, 0.1, 0.06],
		"suona": [0.6, 1.0, 0.8, 0.6, 0.45, 0.3, 0.2], "whistle": [1.0, 0.04]}.get(inst, [1.0])
	var tb := PackedFloat32Array()
	tb.resize(TAB)
	var peak := 0.0
	for i in TAB:
		var v := 0.0
		for h in hs.size():
			v += float(hs[h]) * sin(TAU * (h + 1) * i / float(TAB))
		tb[i] = v
		peak = maxf(peak, absf(v))
	for i in TAB:
		tb[i] /= peak
	_tabs[inst] = tb
	return tb

static func _sine() -> PackedFloat32Array:
	if _sin.is_empty():
		_sin = _table("sine")
	return _sin

## A blown or bowed note: a wave table with a soft attack, a release, a vibrato that comes in late
## and a little breath.
static func _tone(buf: PackedFloat32Array, L: int, s0: int, n: int, f: float, vol: float, inst: String, seed_: int) -> void:
	var tb := _table(inst)
	var sn := _sine()
	var att := int(RATE * (0.07 if inst == "xiao" else (0.1 if inst == "erhu" else 0.035)))
	var rel := int(RATE * 0.09)
	var vib := 0.0045 if inst != "erhu" else 0.008
	var vinc := (5.2 if inst != "erhu" else 5.9) * TAB / float(RATE)
	var vd := int(RATE * 0.22)
	var breath := 0.07 if inst == "dizi" else (0.12 if inst == "xiao" else (0.05 if inst == "whistle" else 0.0))
	var bl := 0.0
	var inc := f * TAB / float(RATE)
	var ph := 0.0
	var vph := 0.0
	var rnd := seed_ * 2654435761 % 2147483647
	var total := n + rel
	for k in total:
		var env := 1.0
		if k < att:
			env = float(k) / att
		elif k > n:
			env = 1.0 - float(k - n) / rel
		var v := 0.0
		if k > vd:
			v = vib * sn[int(vph) & 1023] * minf(1.0, float(k - vd) / 4000.0)
			vph += vinc
		ph += inc * (1.0 + v)
		var s := tb[int(ph) & 1023]
		if breath > 0.0:
			rnd = (rnd * 1103515245 + 12345) & 0x7fffffff
			# (breath is not hiss: the noise is dulled before it is added)
			bl += ((float(rnd) / 1073741824.0 - 1.0) - bl) * 0.12
			s += bl * breath * (1.0 + 2.5 * maxf(0.0, 1.0 - float(k) / (att * 3.0)))
		var at := (s0 + k) % L
		buf[at] += s * env * vol

## A plucked string: noise round a delay line, averaged each time round so that the high part dies
## first (Karplus and Strong).  `dark`: how many times the first burst is smoothed (a silk string is
## darker than a wire one); `tau`: seconds to die away.
static func _pluck(buf: PackedFloat32Array, L: int, s0: int, f: float, vol: float, dark: int, tau: float, ring: float, seed_: int) -> void:
	var N := maxi(2, int(round(RATE / f)))
	var line := PackedFloat32Array()
	line.resize(N)
	var rnd := (seed_ * 7919 + 13) % 2147483647
	for i in N:
		rnd = (rnd * 1103515245 + 12345) & 0x7fffffff
		line[i] = float(rnd) / 1073741824.0 - 1.0
	for p in dark:
		var prev := line[N - 1]
		for i in N:
			var cur := line[i]
			line[i] = (cur + prev) * 0.5
			prev = cur
	var decay := exp(-1.0 / (tau * f))
	var total := int(RATE * ring)
	var i2 := 0
	var fade := int(RATE * 0.04)
	for k in total:
		var j := i2 + 1
		if j >= N:
			j = 0
		var v := line[i2]
		line[i2] = (v + line[j]) * 0.5 * decay
		i2 = j
		var env := 1.0 if k < total - fade else float(total - k) / fade
		var at := (s0 + k) % L
		buf[at] += v * vol * env

## Struck bronze or stone: a few partials that are not harmonics, each dying at its own rate.
static func _struck(buf: PackedFloat32Array, L: int, s0: int, f: float, vol: float, stone: bool) -> void:
	var sn := _sine()
	var parts: Array = [[1.0, 1.0, 1.7], [2.0, 0.45, 1.1], [2.99, 0.28, 0.7], [4.16, 0.14, 0.4]] if not stone else [[1.0, 1.0, 0.9], [2.76, 0.4, 0.45], [5.4, 0.18, 0.2]]
	var total := int(RATE * (2.2 if not stone else 1.4))
	for p in parts:
		var inc := f * float(p[0]) * TAB / float(RATE)
		if f * float(p[0]) > RATE * 0.45:
			continue
		var ph := 0.0
		var amp := vol * float(p[1])
		var dec := exp(-1.0 / (float(p[2]) * RATE))
		for k in total:
			ph += inc
			var at := (s0 + k) % L
			buf[at] += sn[int(ph) & 1023] * amp
			amp *= dec
			if amp < 0.0005:
				break

## A drum, a wood-block, a clay pot or a gong: `what` 1 the low one, 5 the high one.
static func _hit(buf: PackedFloat32Array, L: int, s0: int, inst: String, what: int, vol: float, seed_: int) -> void:
	var sn := _sine()
	var rnd := (seed_ * 31337 + 7) % 2147483647
	var low := what < 4
	var f0 := 105.0
	var f1 := 58.0
	var tone_tau := 0.2
	var noise := 0.5
	var noise_tau := 0.025
	var total := 0.55
	match inst:
		"drum":
			if not low:
				# the rim, or a wood-block: short, high, dry
				f0 = 1150.0
				f1 = 1050.0
				tone_tau = 0.035
				noise = 0.35
				noise_tau = 0.008
				total = 0.16
		"pot":
			f0 = 190.0 if low else 310.0
			f1 = f0 * 0.93
			tone_tau = 0.07
			noise = 0.9
			noise_tau = 0.03
			total = 0.3
		"gong":
			f0 = 150.0 if low else 520.0
			f1 = f0 * (1.0 if low else 1.18)
			tone_tau = 1.6 if low else 0.5
			noise = 0.6
			noise_tau = 0.5 if low else 0.12
			total = 3.2 if low else 1.0
	var n := int(RATE * total)
	var ph := 0.0
	var ph2 := 0.0
	var ph3 := 0.0
	var amp := 1.0
	var namp := noise
	var dec := exp(-1.0 / (tone_tau * RATE))
	var ndec := exp(-1.0 / (noise_tau * RATE))
	var glide := 1.0 / (RATE * (0.08 if inst != "gong" else 0.25))
	var lp := 0.0
	var is_gong := inst == "gong"
	for k in n:
		var g := minf(1.0, k * glide)
		var f := f0 + (f1 - f0) * g
		ph += f * TAB / float(RATE)
		var s := sn[int(ph) & 1023] * amp
		if is_gong:
			# a gong is a crowd of partials, and it blooms: the high ones come in after the stroke
			ph2 += f * 1.52 * TAB / float(RATE)
			ph3 += f * 2.47 * TAB / float(RATE)
			s += (sn[int(ph2) & 1023] * 0.6 + sn[int(ph3) & 1023] * 0.45 * g) * amp
			s *= 0.55
		rnd = (rnd * 1103515245 + 12345) & 0x7fffffff
		var w := float(rnd) / 1073741824.0 - 1.0
		# (the noise of a skin is duller than the noise of a rim)
		lp += (w - lp) * (0.25 if low and not is_gong else 0.7)
		s += lp * namp
		amp *= dec
		namp *= ndec
		var at := (s0 + k) % L
		buf[at] += s * vol

# ---------------------------------------------------------------- a tune into sound
## The whole tune as samples in -1..1, exactly one loop long (what rings past the end is folded back
## into the beginning, so the loop has no seam).
static func render(id: String) -> PackedFloat32Array:
	var tn: Dictionary = TUNES[id]
	var spb := 60.0 / float(tn.bpm)
	var total_beats := beats(id)
	var sting: bool = tn.get("sting", false)
	var L := int(total_beats * spb * RATE) + (int(RATE * 2.5) if sting else 0)
	var buf := PackedFloat32Array()
	buf.resize(L)
	var note_i := 0
	for v in tn.voices:
		var inst := str(v[0])
		var vol := float(v[1])
		var pr: Array = parse(str(v[3]))
		var vlen := float(pr[1])
		var loops: bool = v.size() > 4 and bool(v[4])
		var reps := int(ceil(total_beats / maxf(0.25, vlen))) if loops else 1
		for r in reps:
			for nt in pr[0]:
				var start := float(nt[0]) + r * vlen
				if int(nt[2]) < -90 or start >= total_beats:
					continue
				note_i += 1
				var s0 := int(start * spb * RATE)
				var dur := float(nt[1]) * spb
				var f := hz(float(int(tn.key) + int(nt[2]) + 12 * int(v[2])))
				match inst:
					"dizi", "xiao", "erhu", "suona", "whistle":
						_tone(buf, L, s0, int(dur * RATE * 0.94), f, vol * 0.5, inst, note_i)
					"qin":
						_pluck(buf, L, s0, f, vol * 0.9, 4, 1.9, minf(2.4, dur + 1.4), note_i)
					"zheng":
						_pluck(buf, L, s0, f, vol * 0.75, 2, 1.2, minf(1.6, dur + 0.9), note_i)
					"pipa":
						_pluck(buf, L, s0, f, vol * 0.75, 1, 0.5, minf(0.8, dur + 0.35), note_i)
					"bell":
						_struck(buf, L, s0, f, vol * 0.4, false)
					"chime":
						_struck(buf, L, s0, f, vol * 0.45, true)
					"drum", "pot", "gong":
						_hit(buf, L, s0, inst, int(nt[3]), vol * 0.8, note_i)
	if not sting:
		# a room: two soft echoes, taken round the loop
		for d in [[0.19, 0.2], [0.31, 0.12]]:
			var off := int(float(d[0]) * RATE)
			var gain := float(d[1])
			var src := buf.duplicate()
			for i in L:
				buf[(i + off) % L] += src[i] * gain
	# every tune as loud as every other (by its average, not its loudest moment: a qin alone is all
	# moments), with whatever then stands too tall bent over rather than cut off
	var peak := 0.001
	var sq := 0.0
	for i in L:
		peak = maxf(peak, absf(buf[i]))
		sq += buf[i] * buf[i]
	var rms := sqrt(sq / L)
	var k := minf(LEVEL / maxf(0.0005, rms), 2.2 / peak)
	for i in L:
		var x := buf[i] * k
		var ax := absf(x)
		if ax > 0.6:
			x = signf(x) * (0.6 + (ax - 0.6) / (1.0 + (ax - 0.6) / 0.3))
		buf[i] = x
	return buf

static func pcm(buf: PackedFloat32Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(buf.size() * 2)
	for i in buf.size():
		out.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	return out

## A tune as a RIFF/WAVE file (for looking at it with other tools: tests, the tour).
static func wav_file(id: String) -> PackedByteArray:
	var data := pcm(render(id))
	var out := PackedByteArray()
	out.resize(44)
	out.encode_u32(0, 0x46464952)
	out.encode_u32(4, 36 + data.size())
	out.encode_u32(8, 0x45564157)
	out.encode_u32(12, 0x20746d66)
	out.encode_u32(16, 16)
	out.encode_u16(20, 1)
	out.encode_u16(22, 1)
	out.encode_u32(24, RATE)
	out.encode_u32(28, RATE * 2)
	out.encode_u16(32, 2)
	out.encode_u16(34, 16)
	out.encode_u32(36, 0x61746164)
	out.encode_u32(40, data.size())
	out.append_array(data)
	return out

# ---------------------------------------------------------------- playing
static var _on := -1
static var _players: Array = []
static var _sting_player: AudioStreamPlayer = null
static var _streams := {}
static var _pending := {}
static var _ready := {}
static var _lock := Mutex.new()
static var _cur := ""
static var _cur_slot := 0
static var _want := ""
static var _want_t := 0.0
static var _asked := ""
static var _poll_t := 0.0
static var _watch := {"step": -1, "level": -1, "feats": -1}
## what would be playing now (for the HUD, the songbook, the bot's report and the tests)
static var now := ""

## Whether sound is made at all: not without a window, not for the bot, the tour or the bench unless
## asked (--music), and never with --no-music.
static func enabled(main) -> bool:
	if _on < 0:
		var a: Dictionary = main.args
		_on = 1
		if DisplayServer.get_name() == "headless" or a.has("no-music") or ((a.has("bot") or a.has("tour") or a.has("bench")) and not a.has("music")):
			_on = 0
	return _on == 1

static func _job(id: String) -> void:
	var data := pcm(render(id))
	_lock.lock()
	_ready[id] = data
	_lock.unlock()

## The stream of a tune, or null while it is still being made (it is asked for again next frame).
static func _stream(id: String) -> AudioStreamWAV:
	if _streams.has(id):
		return _streams[id]
	_lock.lock()
	var data = _ready.get(id)
	_lock.unlock()
	if data == null:
		if not _pending.has(id):
			_pending[id] = true
			WorkerThreadPool.add_task(_job.bind(id))
		return null
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = data
	if not TUNES[id].get("sting", false):
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(data.size() / 2.0)
	_streams[id] = st
	return st

## The tune the screen, the place and the hour call for.
static func wanted(main) -> String:
	var Game = main.get_node("/root/Game")
	if _asked != "":
		return _asked
	var base := ""
	for i in range(main.stack.size() - 1, -1, -1):
		if str(main.stack[i]) in ["title", "create", "world", "battle", "field", "meditate", "ending"]:
			base = str(main.stack[i])
			break
	match base:
		"title", "create":
			return "title"
		"ending":
			return "ending"
		"meditate":
			return "still"
		"field":
			return main.field.tune()
		"battle":
			var boss := false
			var last := false
			for f in main.battle.foes:
				boss = boss or bool(f.get("boss", false))
				last = last or (bool(f.get("boss", false)) and str(Game.cur_step().get("kind", "")) == "kill" and Data.STEPS[mini(Game.step + 3, Data.STEPS.size() - 1)].kind == "breakthrough")
			return "tribulation" if last else ("boss" if boss else "battle")
		"world":
			return of_world(main.world, Game)
	return ""

## The tune of where the hero stands in the world.
static func of_world(world, Game) -> String:
	if Game.prologue == "" and not Game.started:
		return "title"
	if world.gliding():
		return "kite"
	if world.is_cave():
		return "cave"
	if str(world.layer).begins_with("f:"):
		return "indoors"
	var night := Clock.is_night(Clock.hour(Game))
	# a town of one of the six hearths plays its hearth's air
	var tid := town_at(Game.area, world.ptile)
	if tid != "":
		if night:
			return "watch"
		var hid := Cultures.of_town(tid)
		if AIRS.has(hid):
			return str(AIRS[hid])
	if not Peaks.summit_at(world.wd, world.ptile).is_empty():
		return "kite"
	if night:
		return "night"
	if Game.area == "mountain":
		return "mountain"
	# (the clay host is abroad in the regions of Part XXIII while its chapter is being played)
	if War.abroad(Game, Game.area):
		return "clay"
	return str(OF_THEME.get(str(world.theme_name), "bamboo"))

## The town (folk.gd) the tile is in the middle of, "" if none.
static func town_at(area: String, tile: Vector2i) -> String:
	for tid in Folk.TOWNS:
		var tw: Dictionary = Folk.TOWNS[tid]
		if str(tw.area) != area or tid == "sect":
			continue
		var c: Vector2i = Atlas.to_world(area, tw.at)
		if absi(tile.x - c.x) + absi(tile.y - c.y) <= Folk.RADIUS:
			return tid
	return ""

## The songbook asks for a tune (it plays until the menu is left or another is asked for).
static func ask(id: String) -> void:
	_asked = id

static func asked() -> String:
	return _asked

## Every frame (main.gd): work out what should be playing; mark it heard; and, where there is sound,
## fade to it.
static func tick(main, d: float) -> void:
	var Game = main.get_node("/root/Game")
	if _asked != "" and main.top_name() != "menu":
		_asked = ""
	# (what is wanted is worked out four times a second, not sixty)
	_poll_t -= d
	var w := _want
	if _poll_t <= 0.0 or _asked != "":
		_poll_t = 0.25
		w = wanted(main)
	if w != _want:
		_want = w
		_want_t = 0.0
	_want_t += d
	now = _want
	if Game.started and _want != "" and _want_t >= HEARD_AFTER and not Game.heard.has(_want):
		Game.heard[_want] = true
	if not enabled(main):
		return
	if _players.is_empty():
		for i in 2:
			var p := AudioStreamPlayer.new()
			p.volume_db = -60.0
			main.add_child(p)
			_players.append(p)
		_sting_player = AudioStreamPlayer.new()
		_sting_player.volume_db = VOL_DB + 2.0
		main.add_child(_sting_player)
	# the stings: a step done, a feat, a breakthrough
	if Game.started:
		var st := ""
		if _watch.level >= 0 and Game.level > int(_watch.level):
			st = "sting_break"
		elif _watch.feats >= 0 and Game.feats.size() > int(_watch.feats):
			st = "sting_feat"
		elif _watch.step >= 0 and Game.step > int(_watch.step):
			st = "sting_step"
		_watch = {"step": Game.step, "level": Game.level, "feats": Game.feats.size()}
		if st != "":
			var ss := _stream(st)
			if ss != null:
				_sting_player.stream = ss
				_sting_player.play()
	if _want != _cur and _want != "":
		var s := _stream(_want)
		if s != null:
			_cur = _want
			_cur_slot = 1 - _cur_slot
			var p2: AudioStreamPlayer = _players[_cur_slot]
			p2.stream = s
			p2.volume_db = -50.0
			p2.play()
	var loud := VOL_DB + float(main.args.get("music-vol", "0"))
	for i in 2:
		var p3: AudioStreamPlayer = _players[i]
		var target := loud if (i == _cur_slot and _cur == _want) or (i == _cur_slot and _want == "") else -60.0
		if i == _cur_slot and _want == "":
			target = -60.0
		p3.volume_db = move_toward(p3.volume_db, target, d * 50.0 / FADE)
		if p3.volume_db <= -59.0 and p3.playing and i != _cur_slot:
			p3.stop()

# ---------------------------------------------------------------- the songbook
## The tunes the songbook lists: every tune but the stings; one that is hidden only once it is heard
## or found.
static func book(g) -> Array:
	var out: Array = []
	for id in ORDER:
		if TUNES[id].get("hidden", false) and not g.heard.has(id):
			continue
		out.append(id)
	return out

static func count() -> int:
	var n := 0
	for id in ORDER:
		if not TUNES[id].get("hidden", false):
			n += 1
	return n

static func label(g, id: String) -> String:
	return str(TUNES[id].n) if g.heard.has(id) else "?  not yet heard"

static func instruments(id: String) -> String:
	var names := {"dizi": "bamboo flute", "xiao": "xiao", "erhu": "fiddle", "suona": "reed horn", "whistle": "a whistle", "qin": "qin", "zheng": "zheng", "pipa": "pipa",
		"bell": "bronze bells", "chime": "stone chimes", "drum": "drum", "pot": "clay pots", "gong": "gong"}
	var out: Array = []
	for v in TUNES[id].voices:
		var nm: String = str(names.get(str(v[0]), str(v[0])))
		if not out.has(nm):
			out.append(nm)
	return ", ".join(out)

## A tune asked for out of the songbook: it plays, it is counted, and when every tune in the book has
## been asked for there is one more leaf (eggs.gd).
static func play_from_book(g, id: String) -> void:
	if not g.heard.has(id):
		return
	ask(id)
	g.songs_played += 1
	g.songs_asked[id] = true
	var all := true
	for t in ORDER:
		if not TUNES[t].get("hidden", false) and not g.songs_asked.has(t):
			all = false
	if all and Eggs.find(g, "all_songs"):
		g.heard["ditty"] = true
