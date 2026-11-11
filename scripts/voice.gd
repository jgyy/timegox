class_name Voice
extends RefCounted
## The story told of a woman (the New Fire release).  The hero can be a young man or a young woman
## (create.gd, Fashion.BODIES), and the story's ten thousand lines were written about a "he".  The data
## keeps the words it was written with (speakers, cues and tests read them); when the hero is a woman
## the words are changed on their way to the screen, like the name the player gave (UI.named).
##
## Most of the story speaks *to* the hero ("you"), and needs nothing.  The rest is told by rule:
##
## * a "he", "him", "his" or "himself" is the hero's when the last person named before it was the
##   hero ("Lin Feng", "Feng'er", "the sweeper"), and is left alone when a man has been named since
##   (the names of every man in the story: MEN below and the people of Data.AREAS; a woman's name
##   changes nothing, since "he" cannot be her);
## * what was said a line ago carries into the next line of the same conversation (`lines`), and a
##   line the hero speaks is never about the hero in the third person;
## * the hero's own words for a boy become a girl's ("the boy who swept the steps"), and the titles
##   people give change ("Senior Brother Lin", "young master", "our son");
## * and where the rule would be wrong, the line is written out by hand (FIX: the whole line as it is
##   in the data -> as it is told of her).
##
## tests/run_tests.gd reads every conversation of the story through this and checks that no line
## about another man changes and that the lines about the hero do.

const HE := {"he": "she", "him": "her", "his": "her", "himself": "herself"}
## said to or of the hero wherever they stand (whole phrases; capitals are kept)
const PHRASES := [
	["senior brother lin", "Senior Sister Lin"], ["junior brother lin", "Junior Sister Lin"], ["brother lin", "Sister Lin"],
	["big brother cultivator", "big sister cultivator"], ["lord lin", "Lady Lin"], ["his dao companion", "her Dao companion"], ["young master", "young mistress"], ["granny wen's boy", "Granny Wen's girl"],
	["sect boy", "sect girl"], ["sweeper boy", "sweeper girl"], ["the boy who swept", "the girl who swept"], ["the boy who held up the sky", "the girl who held up the sky"],
	["he is our son", "she is our daughter"], ["our son", "our daughter"], ["they had a son", "they had a daughter"], ["a son, looking for his parents", "a daughter, looking for her parents"],
	["waiting for a son to grow up", "waiting for a daughter to grow up"], ["their son to grow up", "their daughter to grow up"],
	[", young man", ", young woman"], ["it's him!", "it's her!"], ["good boy", "good girl"], ["a boy once swept", "a girl once swept"], ["it is their son", "it is their daughter"],
]
## the words that make whoever is named with them a woman (a name with one of these in it never takes
## a "he" away from the hero)
const HER_TITLES := ["Granny", "Auntie", "Madam", "Maiden", "Maid", "Sister", "Lady", "Mother", "Empress", "Queen", "Priestess", "Widow", "Fishwife", "Matron", "Matriarch", "Hag", "Witch",
	"Daughter", "Harbourmistress", "Headwoman", "Shrine-Maiden", "Feather-Mother", "Goddess", "Weaver-Girl", "Girl", "Grandmother", "Princess"]
## the women of the story who are named without such a word (art/characters: every model with "fem")
const WOMEN := ["Yue Ling", "Ah Mei", "Chang'e", "Ao Qing", "Dong Shuang", "Qing Lian", "Nuwa", "Egg-Warden Luan", "Farida", "Yu Hua", "Jiang Yao", "He Xiangu", "Xu Qian", "Houtu", "Hu Mei'er", "Hu Qingyi",
	"Innkeeper Bao", "Innkeeper Lou", "Jingwei", "Lan Jing", "Lan Caihe", "Ling Fei", "Little Bei", "Little Hua", "Little Lan", "Liu Ying", "Mazu", "Meng Po", "Ah Shui", "Ba Yin", "Xiao Qing", "Tao Yao", "Yu Lan", "Shui Lian",
	"Roll-Clerk Ning", "Can Niang", "Silk-Diver Yao", "Mo Gu", "A Lan", "Tala", "Tu Lan", "Weaver Liu", "Zhaya", "Xia", "Xiao Lan", "Xu Lan", "Zhi Nu", "Zhi", "Su Wan", "Sarnai", "Qing Nu", "Xihe", "Su Chun", "Xuanpin", "The Maiden of Yue",
	"Xiwangmu", "Chang Sheng", "Hai Ruo", "He Bo's Bride", "Cook Zhou", "Zhou the Cook"]
## men the story names who stand in no region's list of people (fathers, gods, the dead)
const MEN := ["Lin Shan", "Elder", "Qiu Ye", "Fang Hu", "Iron Fang", "Chiyou", "Yu", "Gun", "Kang", "Geng", "Wang", "Zao Jun", "Hundun", "Xu Fu", "Emperor", "King", "Lord", "Duke", "Patriarch",
	"General", "Marshal", "Judge", "Yama", "Taisui", "Gou Mang", "Lei Gong", "Uncle", "Grandpa", "Father", "Zhurong", "Huilu", "Suiren", "Batu", "Nie", "Shitou", "Temur", "Xuan Wu", "Xiu", "Feilian",
	"Shentu", "Yulei", "Yinglong", "Niu Lang", "Tiger", "He Bo", "Yu Qiang", "Li", "Saint", "Giant", "Admiral", "Dan", "Navid", "Pei", "Mo", "Tie"]
## words that begin a new clause (the one spoken of carries over, but its subject is still to come)
const JOINS := ["and", "but", "so", "then", "or", "yet"]
## words that begin a clause inside another ("He is gone before Lin Feng can answer, and the flowers
## close behind him"): who is spoken of inside it is forgotten again at its comma, unless the sentence
## began with it ("When Lin Feng draws the pearl out, ... in his palm")
const UNDER := ["while", "because", "until", "when", "where", "though", "although", "as", "before", "after", "since"]
## after one of these a name is somebody something is done to, not the one the clause is about
const TO := ["to", "at", "for", "from", "by", "of", "upon", "towards", "toward", "past", "beside", "behind", "with"]
## after these a "him" in the hero's own clause is still the hero ("Lin Feng holds heaven above him")
const AROUND := ["above", "below", "behind", "beside", "around", "round", "about", "through", "past", "before", "in", "on", "over", "under", "within", "towards", "toward", "beneath", "inside", "upon", "with", "at"]
## men spoken of without a name ("the giant", "the old man"): they take a "he" as a named man does
const COMMON_MEN := ["boy", "saint", "giant", "general", "god", "king", "emperor", "lord", "monk", "man", "sage", "hermit", "ferryman", "magician", "fisherman", "merchant", "father", "husband",
	"brother", "uncle", "son", "warden", "judge", "magistrate", "minister", "prince", "smith", "farmer", "hunter", "scholar", "soldier", "bandit", "immortal", "founder", "patriarch", "cowherd",
	"herdsman", "duke", "marshal", "captain", "priest", "abbot", "grandfather", "boatman", "ghost", "shade", "stranger", "tiger", "dragon", "elder", "master", "admiral", "marquis", "earl"]
## titles that are not a person by themselves
const STOP := ["The", "Of", "Who", "And", "His", "Her", "Last", "Old", "Little", "Big", "Echo", "Cave", "In", "At", "For", "From", "A", "An", "To", "That", "With", "On",
	# (words that are names in the story and words of the language as well: "Granny He", "He Bo")
	"He", "She", "Him", "It", "Its", "They", "You", "We", "I", "No", "So", "But", "One", "Two", "Three", "Everyone", "All", "Voice", "Villagers", "Children", "Crowd", "Both", "Fishermen",
	"Will", "Not", "Nobody", "Tree", "Month", "Temple", "Bell", "Paper", "Drum", "Pearl", "Fruit", "Gate", "Lantern", "Thousand", "Hands", "Storm", "Mirror", "Shadow", "Glass", "Ink", "Grand", "Twin", "Deer",
	"Mud", "Lean", "Tea", "Silk", "Cormorant", "Fisher", "Tofu", "Seller", "Scholar", "Farmer", "Innkeeper", "Teacher", "Carpenter", "Courier", "Envoy", "Hermit", "Warden", "Ferryman", "Magistrate", "Smith",
	# (what the hero is called as the realms go by, and what is no one person)
	"Ancestor", "Sovereign", "Immortal", "Dao", "Disciple", "Senior", "Junior", "Outer", "Inner", "Sect", "Azure", "Cloud", "Heaven", "Heavenly", "Golden", "Jade", "Star", "River", "Moon", "Sun",
	"Stone", "Iron", "Bronze", "Black", "White", "Red", "Green", "Nine", "Ten", "Great", "Young", "Mountain", "Sea", "Lotus", "Spring", "Autumn", "Winter", "Summer", "Night", "Dawn", "Year"]

## the whole line as the data has it -> as it is told of a woman, where the rule would be wrong
const FIX := {
	"...You have your mother's ears. Don't let anybody send a child down those steps, boy.": "...You have your mother's ears. Don't let anybody send a child down those steps, girl.",
	"They talk until the golden light dims. Afterwards Qiu Ye comes back through the lilies and says, to nobody in particular, that when Lin Feng goes down to the King he is going too.":
		"They talk until the golden light dims. Afterwards Qiu Ye comes back through the lilies and says, to nobody in particular, that when Lin Feng goes down to the King he is going too.",
	"They talk until the golden light dims. When it is done, Qiu Ye tells Lin Feng that he knows every court of this place from the queue, and that when Lin Feng goes down to the King, he is coming.":
		"They talk until the golden light dims. When it is done, Qiu Ye tells Lin Feng that he knows every court of this place from the queue, and that when Lin Feng goes down to the King, he is coming.",
	"At the foot of the bridge Lin Feng tells the old man the truth, in front of his son: that he dropped his guard on purpose among the barrows, and that Qiu Ye never knew.":
		"At the foot of the bridge Lin Feng tells the old man the truth, in front of his son: that she dropped her guard on purpose among the barrows, and that Qiu Ye never knew.",
	"Four pearls. Hold one to your ear, boy. Go on.": "Four pearls. Hold one to your ear, girl. Go on.",
	"Hah! A good new year, boy. Here: a pill for luck. It is mostly sugar. The best pills always are.": "Hah! A good new year, girl. Here: a pill for luck. It is mostly sugar. The best pills always are.",
	"White silk with an azure sash and the sect's cloud on the back, and a small jade crown for the topknot. The Elder had it made the night he broke through to Foundation.":
		"White silk with an azure sash and the sect's cloud on the back, and a small jade crown for the topknot. The Elder had it made the night she broke through to Foundation.",
	"Crimson and gold, with a mantle of ash-phoenix feathers that never quite stop smouldering at the tips. Sage Huo Rong says it suits him. Sage Huo Rong is a liar.":
		"Crimson and gold, with a mantle of ash-phoenix feathers that never quite stop smouldering at the tips. Sage Huo Rong says it suits her. Sage Huo Rong is a liar.",
	"Lin Feng banks the furnace's fire the way Alchemist Mo taught him in his first week, ash over the embers, and the furnace kneels on its three legs and goes quiet. Furnace-Boy Dan climbs inside to sleep, which, he says, is what furnaces are for.":
		"Lin Feng banks the furnace's fire the way Alchemist Mo taught her in her first week, ash over the embers, and the furnace kneels on its three legs and goes quiet. Furnace-Boy Dan climbs inside to sleep, which, he says, is what furnaces are for.",
	"The tea table on the terraces looks out over the whole valley: the new green of the paddies, the river at Longmen, the smoke of Qingshi's chimneys, and the mountain behind it all with cloud on its shoulders. Lin Feng heats the water to just below the boil, the way the tea master showed him, and pours it over the six buds.":
		"The tea table on the terraces looks out over the whole valley: the new green of the paddies, the river at Longmen, the smoke of Qingshi's chimneys, and the mountain behind it all with cloud on its shoulders. Lin Feng heats the water to just below the boil, the way the tea master showed her, and pours it over the six buds.",
	"He is our son. He swept the steps for three years without a single grain of qi, and he never once stopped being kind. That is the world he made. Let us go back to it.":
		"She is our daughter. She swept the steps for three years without a single grain of qi, and she never once stopped being kind. That is the world she made. Let us go back to it.",
	"You are the sweeper. The fishermen pray to me, and lately they pray about you: let him come and fix the sea. I am Lin Moniang. On the coast they call me Mazu, Grandmother, which I find very ageing. I bring the boats home.":
		"You are the sweeper. The fishermen pray to me, and lately they pray about you: let her come and fix the sea. I am Lin Moniang. On the coast they call me Mazu, Grandmother, which I find very ageing. I bring the boats home.",
	"A man steps out of the chaos wearing Lin Feng's face, a Dao Ancestor robed in stolen years, nineteen names stitched into his sleeves.":
		"A woman steps out of the chaos wearing Lin Feng's face, a Dao Ancestor robed in stolen years, nineteen names stitched into her sleeves.",
	"Before the broom there was Granny Wen's house in Qingshi Village, and a boy who carried the midwife's bag to every birth in the valley.":
		"Before the broom there was Granny Wen's house in Qingshi Village, and a girl who carried the midwife's bag to every birth in the valley.",
	"Before the broom there was Scholar Wang's schoolroom in Qingshi Village, and a boy who read every book in it twice by the light of one candle.":
		"Before the broom there was Scholar Wang's schoolroom in Qingshi Village, and a girl who read every book in it twice by the light of one candle.",
	"Wang's pupil. He wrote to me once, you know, to ask whether I would take a boy who reads too much. I said the steps would cure it. They did not, I see.":
		"Wang's pupil. He wrote to me once, you know, to ask whether I would take a girl who reads too much. I said the steps would cure it. They did not, I see.",
	"On the river below Qingshi the ferry still runs, and the fishermen say the current goes gentler where he used to pole.":
		"On the river below Qingshi the ferry still runs, and the fishermen say the current goes gentler where she used to pole.",
	"At the edge of the Whispering Bamboo an old hunter tells his grandchildren that the boy who held up the sky once carried his game.":
		"At the edge of the Whispering Bamboo an old hunter tells his grandchildren that the girl who held up the sky once carried his game.",
}

static var _men := {}
static var _women := {}
static var _seen := {}
static var _her_names := {}
static var _ready := false
static var _word: RegEx = null
static var _cache := {}

## The names of the story that are men's (they take a "he" away from the hero): the list above, the
## people of every region and everybody who speaks in the story, less the women (by a woman's title
## or by name) and the words that are not names.
static func _prepare() -> void:
	if _ready:
		return
	_ready = true
	_word = RegEx.new()
	_word.compile("[A-Za-z][A-Za-z'\\-]*")
	for n2 in MEN:
		for w2 in str(n2).split(" ", false):
			_men[w2] = true
	for a in Data.AREAS:
		for npc in Data.AREAS[a].get("npcs", []):
			_person(str(npc.n))
	# (everybody who speaks; a beast that speaks under its kind's name, "Thunder Roc", is not a name)
	var beasts := {}
	for id in Data.ENEMIES:
		beasts[str(Data.ENEMIES[id].n)] = true
	for key in Data.DIALOGUE:
		for ln in Data.DIALOGUE[key]:
			if ln is Array and (ln as Array).size() >= 2 and (not beasts.has(str(ln[0])) or str(ln[0]).contains(",")):
				_person(str(ln[0]))
	for stop in STOP:
		_men.erase(stop)
	for n3 in WOMEN:
		_her_names[str(n3)] = true
	# (the hero's family name is never somebody else; "Lin Shan" is known by "Shan")
	_men.erase("Lin")

## The words of a name that are the person: "Courier Ma of the Nine Roads" -> ["Courier", "Ma"].
static func _lead(full: String) -> PackedStringArray:
	var s := full
	for cut in [",", " the ", " of ", " Who ", " and ", " in "]:
		var k := s.find(cut)
		if k > 0:
			s = s.substr(0, k)
	return s.split(" ", false)

## Whether somebody called `full` is a woman: by a woman's title, or by name.
static func is_woman(full: String) -> bool:
	for w in full.replace(",", " ").split(" ", false):
		if HER_TITLES.has(w):
			return true
	var padded := " " + full.replace(",", " ,") + " "
	for n in WOMEN:
		if padded.contains(" " + str(n) + " "):
			return true
	return false

static func _person(full: String) -> void:
	if full in ["Narrator", "Lin Feng", "", "?"] or _seen.has(full):
		return
	_seen[full] = true
	if is_woman(full):
		for w in _lead(full):
			if not STOP.has(w):
				_women[w] = true
		return
	for w2 in _lead(full):
		if w2.length() >= 2 and not STOP.has(w2):
			_men[w2] = true

static func _cap(like: String, s: String) -> String:
	if like.length() > 0 and like.substr(0, 1) == like.substr(0, 1).to_upper() and like.substr(0, 1) != like.substr(0, 1).to_lower():
		return s.substr(0, 1).to_upper() + s.substr(1)
	return s

static func _phrases(s: String) -> String:
	var low := s.to_lower()
	for ph in PHRASES:
		var k := low.find(str(ph[0]))
		while k >= 0:
			# (whole words only: "our son" is not in "your son")
			var before := low.substr(k - 1, 1) if k > 0 else " "
			var first := str(ph[0]).substr(0, 1)
			if before >= "a" and before <= "z" and first >= "a" and first <= "z":
				k = low.find(str(ph[0]), k + 1)
				continue
			var from := s.substr(k, str(ph[0]).length())
			var to: String = str(ph[1])
			# (a phrase written small takes the capital the line had; a title keeps its own, and its last
			# word the capital the line's had: "Granny Wen's Boy", the name of a trade, is "...Girl")
			if to == to.to_lower():
				to = _cap(from, to)
			else:
				var cut := to.rfind(" ") + 1
				var cut0 := from.rfind(" ") + 1
				if cut > 0 and cut0 > 0:
					to = to.substr(0, cut) + _cap(from.substr(cut0), to.substr(cut))
				to = _cap(from, to)
			s = s.substr(0, k) + to + s.substr(k + from.length())
			low = s.to_lower()
			k = low.find(str(ph[0]), k + to.length())
	return s

## `s` told of a woman.  `about` is whether the hero was the one spoken of before it; returns [the
## line, whether the hero is the one spoken of after it].
##
## The line is read a clause at a time (a clause ends at a full stop, a colon, a semicolon or a joining
## word: and, but, while, because...).  The first person named in a clause is its subject, and the one
## spoken of from then on: the hero ("Lin Feng lifts his sword" -> her), or a man ("He Bo gives Lin
## Feng the tablet of his office": his own, though the hero is named before the "his").  A woman's
## name changes nothing; a name that only owns something ("Lin Feng's face") names nobody; and a "him"
## in the clause the hero is the subject of is somebody else ("Lin Feng takes it from him").
static func tell(s: String, about: bool = false) -> Array:
	_prepare()
	if FIX.has(s):
		return [str(FIX[s]), true]
	s = _phrases(s)
	var out := ""
	var at := 0
	var ms: Array = _word.search_all(s)
	var skip := false
	var topic_set := false
	var hero_subj := false
	var hero_sentence := false
	var her_title := false
	var obj_hero := false
	var under := false
	var saved_about := false
	var saved_topic := false
	var first_word := true
	var man_here := false
	var hero_met := false
	var prev_low := ""
	for i in ms.size():
		var m: RegExMatch = ms[i]
		var w := m.get_string()
		var a := m.get_start()
		var b := m.get_end()
		var gap := s.substr(at, a - at)
		out += gap
		at = b
		if under and (gap.contains(",") or gap.contains(".") or gap.contains("!") or gap.contains("?") or gap.contains(";") or gap.contains(":")):
			# the clause inside the clause is over: who the sentence was about is spoken of again
			under = false
			about = saved_about
			topic_set = saved_topic
			hero_subj = false
		for ch in [".", "!", "?", ";", ":"]:
			if gap.contains(ch):
				topic_set = false
				hero_subj = false
				if ch != ";" and ch != ":":
					# ("Yue Ling looks at Lin Feng. He smiles.": the hero was the only one a "he" could be)
					if hero_met and not man_here:
						about = true
					hero_sentence = false
					obj_hero = false
					first_word = true
					man_here = false
					hero_met = false
		var base := w
		var tail := ""
		var ap := w.find("'")
		if ap > 0:
			base = w.substr(0, ap)
			tail = w.substr(ap)
		var low := base.to_lower()
		var owns := tail == "'s"
		var nxt_w := (ms[i + 1] as RegExMatch).get_string() if i + 1 < ms.size() else ""
		# ("Yu Qiang's conch": the name that owns is two words long)
		if not owns and base != low and nxt_w.ends_with("'s") and nxt_w.substr(0, 1) != nxt_w.substr(0, 1).to_lower():
			owns = true
		var after_her_title := her_title
		her_title = base != low and HER_TITLES.has(base)
		if skip:
			skip = false
		elif base == "He" and nxt_w.trim_suffix("'s") in ["Bo", "Xiangu"]:
			# ("He Bo", the River Earl, and "He Xiangu" are names, not a "he")
			skip = true
			if nxt_w.begins_with("Bo") and not topic_set and not (nxt_w.ends_with("'s") and hero_sentence):
				about = false
				topic_set = true
		elif after_her_title and base != low:
			# a woman by her title ("Auntie Zhou", "Granny He"): she takes nothing away
			pass
		elif base == low and tail == "" and JOINS.has(low):
			topic_set = false
			hero_subj = false
		elif tail == "" and UNDER.has(low) and not first_word and not under and topic_set:
			under = true
			saved_about = about
			saved_topic = topic_set
			topic_set = false
			hero_subj = false
		elif (base == "Lin" and i + 1 < ms.size() and (ms[i + 1] as RegExMatch).get_string().begins_with("Feng")) or (base == "Feng" and tail == "'er") or (low == "sweeper" and base == low and prev_low in ["the", "a"]):
			if base == "Lin":
				skip = true
				owns = (ms[i + 1] as RegExMatch).get_string().ends_with("'s")
			hero_met = true
			if not owns and TO.has(prev_low):
				# ("bows once to Lin Feng", "stops a sword's length from Lin Feng and looks him up and
				# down": somebody something is done to; a "him" after it in the sentence is the hero)
				obj_hero = true
			elif not owns:
				if not topic_set:
					about = true
					topic_set = true
				else:
					obj_hero = true
				if about:
					hero_subj = true
					hero_sentence = true
			elif not topic_set:
				# ("the stamps on Lin Feng's sleeve... the grey at his temples": the hero is the one
				# spoken of, though not the one doing anything, so a "him" in the clause is somebody
				# else: "Lin Feng's last blow knocks him off the roof"; where a man was named first,
				# it is still him)
				about = true
				hero_subj = true
		elif base != low and ((i + 1 < ms.size() and _her_names.has(w + " " + (ms[i + 1] as RegExMatch).get_string().trim_suffix("'s"))) or (_her_names.has(base) and not _men.has(base))
				or (_women.has(base) and not _men.has(base))):
			# a woman, by both her names ("Yue Ling") or by one no man bears: she takes nothing away
			if i + 1 < ms.size() and _her_names.has(w + " " + (ms[i + 1] as RegExMatch).get_string().trim_suffix("'s")):
				skip = true
		elif (_men.has(base) and base != low) or (base == low and tail != "'ll" and COMMON_MEN.has(low)):
			# (a man who only owns something in a sentence about the hero, "Yu Qiang's conch at his belt",
			# takes nothing away)
			man_here = true
			if not topic_set and not (owns and hero_sentence):
				about = false
				topic_set = true
			if not owns:
				obj_hero = false
		elif not about and low == "him" and obj_hero and tail == "":
			out += _cap(base, "her")
			prev_low = low
			first_word = false
			continue
		elif not about and HE.has(low):
			# a "he" that is somebody else's: that somebody is the one this clause is about
			topic_set = true
			man_here = true
		elif about and HE.has(low) and (tail == "" or tail in ["'s", "'d", "'ll"]) and not (low == "him" and hero_subj and not AROUND.has(prev_low)):
			var to: String = HE[low]
			if low == "his" and tail == "":
				# "the choice was his." -> "hers."
				var nxt := s.substr(b, 1)
				if nxt == "" or nxt in [".", ",", ";", "!", "?", ":"]:
					to = "hers"
			out += _cap(base, to) + tail
			prev_low = low
			continue
		prev_low = low
		first_word = false
		out += w
	out += s.substr(at)
	return [out, about]

## One line by itself (a toast, an objective, a description), told of a woman.
static func she(s: String) -> String:
	if _cache.has(s):
		return _cache[s]
	if _cache.size() > 6000:
		_cache.clear()
	var r: String = str(tell(s, false)[0])
	_cache[s] = r
	return r

## A line that is about nobody but the hero (the creation screen, the wardrobe), told of a woman.
static func her(s: String) -> String:
	return str(tell(s, true)[0])

## A conversation ([[speaker, words, ...], ...]) told of a woman: who was spoken of last carries from
## line to line.  A line the hero speaks is not about the hero in the third person, and what the
## narrator says next most likely is; after a man has spoken, the next "he" is most likely him.
static func lines(ls: Array) -> Array:
	_prepare()
	var out: Array = []
	var about := false
	for ln in ls:
		if not (ln is Array) or (ln as Array).size() < 2:
			out.append(ln)
			continue
		var who := str(ln[0])
		var l2: Array = (ln as Array).duplicate()
		if who == "Narrator" or who == "":
			var r: Array = tell(str(ln[1]), about)
			l2[1] = r[0]
			about = bool(r[1])
		else:
			# somebody speaks: to the hero ("you"), so a "he" in it is somebody else; only what the hero
			# is called changes ("sect boy", "Senior Brother Lin"), or the line is written out (FIX)
			l2[1] = said(str(ln[1]))
			if who == "Lin Feng":
				about = true
			elif not is_woman(who):
				# (a man has spoken, or somebody who may be one: the narrator's next "he" is his)
				about = false
		out.append(l2)
	return out

## A line somebody speaks, told of a woman: what the hero is called in it, and nothing else.
static func said(s: String) -> String:
	if FIX.has(s):
		return str(FIX[s])
	return _phrases(s)
