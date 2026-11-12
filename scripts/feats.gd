class_name Feats
extends RefCounted
## Feats (the Thundering Pots release): what the journey is remembered for.  Nobody asks for a feat and
## no step of the story waits on one; each is a thing done (so many summits stood on, a field held, a
## dress worn, a lord passed without a blow) that is told the moment it is true and kept on a page of
## its own (Esc > Feats).  A few are not shown until they are done.  Some give something to wear
## (fashion.gd: `feat`).
##
## A feat is a comparison, `test`: [what, how much] (see `value`), so the page can show how far along
## it is, the bot's report can count them, and the tests can check that every one can be done.
## Nothing here keeps state but `Game.feats` (id -> the play time it was done at).

## the categories, in the order of the page
const KINDS := {
	"road": {"n": "The Road", "col": Color("f0c850")},
	"sword": {"n": "The Sword", "col": Color("e86a5a")},
	"people": {"n": "The People", "col": Color("7ad8a0")},
	"land": {"n": "The Land", "col": Color("8ac0e8")},
	"craft": {"n": "The Hand", "col": Color("d8a060")},
	"host": {"n": "The Host", "col": Color("c84a3a")},
	"song": {"n": "The Song", "col": Color("c8a0e8")},
	"dress": {"n": "The Wardrobe", "col": Color("ff9ac0")},
	"odd": {"n": "The Unasked", "col": Color("b0b8c8")},
}
const KIND_ORDER := ["road", "sword", "people", "land", "craft", "host", "song", "dress", "odd"]

## `pts`: what it is worth (5 for a thing most journeys do, 10 for one that takes meaning to, 20 for
## one few will); `hide`: not shown until done.
const FEATS := {
	# ---- the road: how far the story has been walked
	"first_steps": {"n": "The First Step Swept", "kind": "road", "pts": 5, "test": ["level", 3], "desc": "Reach Foundation Establishment."},
	"golden_core": {"n": "A Pill of One's Own", "kind": "road", "pts": 5, "test": ["level", 6], "desc": "Form a Golden Core."},
	"immortal": {"n": "No Dust on the Robe", "kind": "road", "pts": 10, "test": ["level", 24], "desc": "Ascend as a True Immortal."},
	"half_way": {"n": "Fourteen Realms Up", "kind": "road", "pts": 10, "test": ["level", 42], "desc": "Reach the fourteenth great realm."},
	"great_sound": {"n": "The Great Note", "kind": "road", "pts": 20, "test": ["level", 84], "desc": "Reach Great Sound, Rarely Heard."},
	# the Lost Horse release: the last realm, what was lost to, and what was left standing
	"soft_water": {"n": "Soft as Water", "kind": "road", "pts": 20, "test": ["level", 87], "desc": "Reach Soft as Water: the last realm there is."},
	"first_fall": {"n": "Set Down Somewhere Else", "kind": "road", "pts": 5, "test": ["fallen", 1], "desc": "Lose a battle that could not be won, and go on."},
	"three_dooms": {"n": "The Tide, the Ape and the Riders", "kind": "road", "pts": 10, "test": ["dooms", 3], "desc": "Stand in front of all three of the things that are not beaten."},
	"gave_way": {"n": "Who Put Up the Sword", "kind": "road", "pts": 10, "test": ["yielded", 1], "desc": "Give way to something that cannot be fought, standing."},
	"day_wage": {"n": "A Day's Wage", "kind": "people", "pts": 5, "test": ["shifts", 1], "desc": "Work a shift at a trade of a town."},
	"journeyman": {"n": "A Hook for Your Coat", "kind": "people", "pts": 10, "test": ["trade_rank", 2], "desc": "Be raised twice at a trade of the towns."},
	"trade_master": {"n": "A Sign with Your Name on It", "kind": "people", "pts": 20, "test": ["trade_rank", 4], "desc": "Reach the highest place there is at a trade."},
	"first_fare": {"n": "Room for One More", "kind": "people", "pts": 5, "test": ["fares", 1], "desc": "Carry somebody to another town in a carriage, for the fare."},
	"ten_fares": {"n": "The Regular Coach", "kind": "people", "pts": 10, "test": ["fares", 10], "desc": "Set down ten passengers where they were going."},
	"first_letter": {"n": "Somebody Wrote", "kind": "people", "pts": 5, "test": ["letters", 1], "desc": "Ask for your letters at a counter of the post, and open one."},
	"ten_letters": {"n": "A Full Satchel", "kind": "people", "pts": 10, "test": ["letters", 10], "desc": "Open ten letters."},
	"post_bags": {"n": "Neither Snow Nor Rain", "kind": "people", "pts": 10, "test": ["bags", 5], "desc": "Carry five bags of the post to the counters they were sealed for."},
	"first_coach": {"n": "Inside, If You Please", "kind": "people", "pts": 5, "test": ["coaches", 1], "desc": "Take the post-coach along the high road from one town to another."},
	"first_voyage": {"n": "Out of Sight of Land", "kind": "people", "pts": 5, "test": ["voyages", 1], "desc": "Take ship from one harbour to another."},
	"six_trades": {"n": "Jack of Six Trades", "kind": "people", "pts": 10, "test": ["trades", 6], "desc": "Work a shift at six different trades."},
	"marks_twelve": {"n": "Gone Back to Look", "kind": "road", "pts": 10, "test": ["marks", 12], "desc": "Look at twelve of the things your choices left standing in the land."},
	"companion": {"n": "Two on the Road", "kind": "road", "pts": 5, "test": ["step", "s_yue"], "desc": "Wake the girl by the lotus pond."},
	"sky_held": {"n": "The Sky Is Held", "kind": "road", "pts": 10, "test": ["step", "s_ch_hundun"], "desc": "End the Falling Sky."},
	"tribulations": {"n": "Struck Twenty Times", "kind": "road", "pts": 10, "test": ["realm", 20], "desc": "Come through twenty Heavenly Tribulations."},
	"far_traveller": {"n": "Thirty Countries", "kind": "road", "pts": 10, "test": ["seen", 30], "desc": "Set foot in thirty regions of the four realms."},
	"every_country": {"n": "The Whole Map", "kind": "road", "pts": 20, "test": ["seen", 48], "desc": "Set foot in forty-eight regions of the four realms."},
	"crossroads": {"n": "Asked and Answered", "kind": "road", "pts": 10, "test": ["picks", 10], "desc": "Answer ten crossroads of the road."},
	"calendar": {"n": "A Season on the Road", "kind": "road", "pts": 5, "test": ["day", 30], "desc": "See the thirtieth day of the journey."},
	# ---- the sword
	"hundred_foes": {"n": "A Hundred Felled", "kind": "sword", "pts": 5, "test": ["kills", 100], "desc": "Defeat a hundred foes."},
	"thousand_foes": {"n": "A Thousand Felled", "kind": "sword", "pts": 10, "test": ["kills", 1000], "desc": "Defeat a thousand foes."},
	"lords_ten": {"n": "Ten Lords", "kind": "sword", "pts": 5, "test": ["bosses", 10], "desc": "Bring down ten lords of the land."},
	"lords_hundred": {"n": "A Hundred Lords", "kind": "sword", "pts": 10, "test": ["bosses", 100], "desc": "Bring down a hundred lords of the land."},
	"lords_all": {"n": "Nobody Left to Fight", "kind": "sword", "pts": 20, "test": ["bosses", 240], "desc": "Bring down two hundred and forty lords."},
	"first_strike": {"n": "The Sword's Wake", "kind": "sword", "pts": 5, "test": ["ambushes", 25], "desc": "Strike first twenty-five times in the open land."},
	"tempered": {"n": "Folded a Tenth Time", "kind": "sword", "pts": 10, "test": ["temper", 10], "desc": "Temper the sword ten times at Smith Tie's forge."},
	"arms_three": {"n": "Three Daos of Arms", "kind": "sword", "pts": 10, "test": ["arms", 3], "desc": "Learn the Dao of three weapons to Adept."},
	"arms_eight": {"n": "The Eight Arms", "kind": "sword", "pts": 20, "test": ["arms", 8], "desc": "Learn the Dao of all eight weapons to Adept."},
	"many_ways": {"n": "Many Roads", "kind": "sword", "pts": 10, "test": ["trial_kinds", 6], "desc": "Pass trials in six different ways."},
	"trials_forty": {"n": "Forty Gates", "kind": "sword", "pts": 10, "test": ["trials", 40], "desc": "Pass forty trials."},
	"unbowed": {"n": "Never Carried Home", "kind": "sword", "pts": 20, "test": ["undefeated", 40], "desc": "Reach the fortieth level without once falling in battle.", "hide": true},
	# ---- the people
	"guest": {"n": "A Place at the Fire", "kind": "people", "pts": 5, "test": ["guests", 3], "desc": "Be called a guest, or kin, at three hearths of the land."},
	"kin_all": {"n": "Six Fires", "kind": "people", "pts": 20, "test": ["kin", 6], "desc": "Be called kin at all six hearths."},
	"friends": {"n": "The Peoples of the Realms", "kind": "people", "pts": 10, "test": ["races", 6], "desc": "Be a friend to six peoples of the realms."},
	"deeds_ten": {"n": "Ten Deeds", "kind": "people", "pts": 5, "test": ["deeds", 10], "desc": "Do ten deeds for the people of the towns."},
	"deeds_all": {"n": "Nobody Left Wanting", "kind": "people", "pts": 20, "test": ["deeds", 27], "desc": "Do every deed anybody asks."},
	"renowned": {"n": "Whom the World Respects", "kind": "people", "pts": 10, "test": ["renown", 280], "desc": "Become Famed in the eyes of the world."},
	"talker": {"n": "A Word with Everybody", "kind": "people", "pts": 5, "test": ["folk_talk", 40], "desc": "Speak with forty of the people of the towns and the road."},
	"heart": {"n": "Kindred Spirit", "kind": "people", "pts": 10, "test": ["bond", 45], "desc": "Grow as close to Yue Ling as two people on one road can."},
	"memories": {"n": "What She Was Happiest At", "kind": "people", "pts": 10, "test": ["memories", 5], "desc": "Give Yue Ling back five of her memories."},
	"jobs_five": {"n": "Five Notices Down", "kind": "people", "pts": 5, "test": ["jobs", 5], "desc": "Do five commissions of the notice board in Qingshi."},
	"jobs_all": {"n": "A Bare Board", "kind": "people", "pts": 20, "test": ["jobs", 18], "desc": "Do every commission of the notice board."},
	# ---- the land
	"summit_first": {"n": "One Stone on the Cairn", "kind": "land", "pts": 5, "test": ["summits", 1], "desc": "Stand on the very top of a peak."},
	"summits_nine": {"n": "Nine Cairns", "kind": "land", "pts": 10, "test": ["summits", 9], "desc": "Stand on nine summits."},
	"summits_forty": {"n": "The Forty Tops", "kind": "land", "pts": 20, "test": ["summits", 40], "desc": "Stand on forty summits."},
	"climber": {"n": "A Li of Rock", "kind": "land", "pts": 10, "test": ["climbed", 500], "desc": "Climb five hundred metres, hand over hand."},
	"glide_far": {"n": "Master Lie Nods", "kind": "land", "pts": 10, "test": ["glide_best", 50], "desc": "Fly a hundred metres in one flight under the cloud-kite."},
	"glide_thirty": {"n": "Two Under One Kite", "kind": "land", "pts": 10, "test": ["glides", 30], "desc": "Make thirty flights."},
	"delve_first": {"n": "Into the Dark", "kind": "land", "pts": 5, "test": ["delved", 1], "desc": "Go to the very back of a cave."},
	"delve_six": {"n": "The Ground Is Hollow", "kind": "land", "pts": 10, "test": ["delved", 6], "desc": "Go to the very back of six caves."},
	"abodes": {"n": "Her Nine Doors", "kind": "land", "pts": 10, "test": ["abodes", 9], "desc": "Open all nine of the Founder's caves."},
	"bestiary": {"n": "The Naturalist", "kind": "land", "pts": 10, "test": ["bestiary", 150], "desc": "Meet a hundred and fifty kinds of creature."},
	"clearer": {"n": "The Road Is Open", "kind": "land", "pts": 5, "test": ["cleared", 12], "desc": "Clear twelve things out of the way with the sword."},
	"woodsman": {"n": "Firewood for a Winter", "kind": "land", "pts": 5, "test": ["felled", 30], "desc": "Fell thirty trees."},
	"bull": {"n": "An Ox in the Pottery", "kind": "land", "pts": 5, "test": ["smashed", 40], "desc": "Break forty things that were somebody's.", "hide": true},
	# ---- the hand: making
	"works_three": {"n": "A Maker", "kind": "craft", "pts": 5, "test": ["works", 3], "desc": "Build three works."},
	"works_twelve": {"n": "A Master of Works", "kind": "craft", "pts": 20, "test": ["works", 12], "desc": "Build twelve works."},
	"rides": {"n": "A Full Stable", "kind": "craft", "pts": 10, "test": ["rides", 5], "desc": "Own five rides, to sit on or to stand on."},
	"rich": {"n": "The Open Hand", "kind": "craft", "pts": 10, "test": ["stones", 500000], "desc": "Hold half a million spirit stones at once."},
	"root": {"n": "Nine Heavens, Nine Branches", "kind": "craft", "pts": 10, "test": ["talents", 18], "desc": "Wake eighteen ranks of the branches of the root."},
	"sitter": {"n": "Sat Until It Came", "kind": "craft", "pts": 5, "test": ["meditated", 3600], "desc": "Meditate for an hour, all told."},
	"pastimes": {"n": "Things to Do", "kind": "craft", "pts": 10, "test": ["pastimes", 20], "desc": "Do twenty different things of the land: fish, play the qin, beat a drum, sit on a swing."},
	# ---- the host: war
	"host_raised": {"n": "The Levy Comes In", "kind": "host", "pts": 5, "test": ["host", 4], "desc": "Raise four companies for the host."},
	"host_full": {"n": "Six Hearths Under One Banner", "kind": "host", "pts": 10, "test": ["host", 8], "desc": "Raise eight companies."},
	"war_first": {"n": "A Field Held", "kind": "host", "pts": 5, "test": ["war_won", 1], "desc": "Win a field battle."},
	"war_three": {"n": "The Field Is Held", "kind": "host", "pts": 10, "test": ["war_won", 3], "desc": "Win three field battles."},
	"war_all": {"n": "Every Field", "kind": "host", "pts": 20, "test": ["war_won", 6], "desc": "Win every field battle there is to fight: the three of the story and the three of the drill ground."},
	"war_swift": {"n": "Before the Third Drum", "kind": "host", "pts": 20, "test": ["war_swift", 4], "desc": "Win a field battle in four drums or fewer."},
	"war_sound": {"n": "Songs on Four Sides", "kind": "host", "pts": 10, "test": ["war_order", "sound", 6], "desc": "Sound the airs of the land over a field six times."},
	"war_clean": {"n": "Who Never Lost a Field", "kind": "host", "pts": 10, "test": ["war_clean", 3], "desc": "Win three field battles without losing one.", "hide": true},
	# ---- the song: music
	"heard_ten": {"n": "An Ear", "kind": "song", "pts": 5, "test": ["heard", 10], "desc": "Hear ten tunes of the land."},
	"heard_all": {"n": "The Whole Songbook", "kind": "song", "pts": 20, "test": ["heard", 30], "desc": "Hear thirty tunes of the land."},
	"airs_three": {"n": "Three Airs", "kind": "song", "pts": 5, "test": ["airs", 3], "desc": "Learn the airs of three hearths."},
	"airs_six": {"n": "The Six Airs", "kind": "song", "pts": 10, "test": ["airs", 6], "desc": "Learn the air of every hearth of the land."},
	"player": {"n": "Play It Again", "kind": "song", "pts": 5, "test": ["songs_played", 5], "desc": "Ask for five tunes out of the songbook."},
	# ---- the wardrobe
	"dressed": {"n": "Something to Wear", "kind": "dress", "pts": 5, "test": ["outfits", 6], "desc": "Own six outfits."},
	"wardrobe": {"n": "A Cupboard of One's Own", "kind": "dress", "pts": 10, "test": ["outfits", 16], "desc": "Own sixteen outfits."},
	"every_thread": {"n": "Every Thread", "kind": "dress", "pts": 20, "test": ["outfits", 26], "desc": "Own every outfit there is."},
	"changeable": {"n": "Never Twice the Same", "kind": "dress", "pts": 5, "test": ["worn", 8], "desc": "Wear eight different outfits."},
	"her_dresses": {"n": "It Has Pockets", "kind": "dress", "pts": 10, "test": ["yue_outfits", 6], "desc": "Give Yue Ling six dresses to choose from."},
	# ---- the unasked
	"egg_one": {"n": "Nobody Told You To", "kind": "odd", "pts": 5, "test": ["eggs", 1], "desc": "Find something nobody told you to look for."},
	"egg_six": {"n": "A Habit of Looking", "kind": "odd", "pts": 10, "test": ["eggs", 6], "desc": "Find six such things."},
	"egg_all": {"n": "The Mapmaker's Friend", "kind": "odd", "pts": 20, "test": ["eggs", 12], "desc": "Find all twelve.", "hide": true},
	"body_week": {"n": "Seven Needs, Seven Days", "kind": "odd", "pts": 10, "test": ["survived", 7], "desc": "With survival on, see seven days go by and never once let the body have its own way."},
	"courting": {"n": "Said in a Voice", "kind": "people", "pts": 10, "test": ["romance", 1], "desc": "Say to Yue Ling what there is to say."},
	"promised": {"n": "In the Book", "kind": "people", "pts": 10, "test": ["romance", 2], "desc": "Exchange tokens with Yue Ling."},
	"wed": {"n": "Three Bows", "kind": "people", "pts": 20, "test": ["romance", 3], "desc": "One to heaven and earth, one to those who raised you, one to each other."},
	"gifts_six": {"n": "It Was a Lovely Thought", "kind": "people", "pts": 5, "test": ["gifts", 6], "desc": "Give Yue Ling six things, whether or not she knows what to do with them."},
	"hours_all": {"n": "Ten Hours", "kind": "people", "pts": 20, "test": ["outings", 10], "desc": "Spend all ten hours with Yue Ling: each has its own place, and its own time of day."},
	"gamble_first": {"n": "Nine of Ten", "kind": "odd", "pts": 5, "test": ["gamble_rounds", 1], "desc": "Sit down at Old Du's mat in Qingshi, and stake something."},
	"gamble_ten": {"n": "The Tenth", "kind": "odd", "pts": 10, "test": ["gamble_wins", 10], "desc": "Win ten rounds at Old Du's mat."},
	"gamble_streak": {"n": "Luck Unpacks", "kind": "odd", "pts": 10, "test": ["gamble_streak", 4], "desc": "Win four rounds running at Old Du's mat."},
	"gamble_triple": {"n": "Three of a Kind", "kind": "odd", "pts": 20, "test": ["gamble_best", 30000], "desc": "Win thirty thousand spirit stones on a single throw.", "hide": true},
	"feats_forty": {"n": "A Life Worth Telling", "kind": "odd", "pts": 10, "test": ["feats", 40], "desc": "Do forty of the feats on this page."},
}

## what a journey is called by the feats it has done: [points, title]
const TITLES := [[0, "Unsung"], [40, "Spoken Of"], [120, "Sung in the Teahouses"], [240, "Told to Children"], [400, "Carved on a Stele"], [600, "A Legend in the Making"], [780, "The Tale Itself"]]

static func order() -> Array:
	var out: Array = []
	for k in KIND_ORDER:
		for id in FEATS:
			if str(FEATS[id].kind) == k:
				out.append(id)
	return out

## How far along the thing a feat measures is now.
static func value(g, t: Array) -> float:
	match str(t[0]):
		"level":
			return float(g.level)
		"realm":
			return float(g.realm())
		"step":
			return 1.0 if g.done(str(t[1])) else 0.0
		"seen":
			return float(g.seen.size())
		"picks":
			var n := 0
			for cid in Echoes.ORDER:
				if g.picks.has(cid):
					n += 1
			return float(n)
		"day":
			return float(g.day)
		"kills":
			return float(g.kills)
		"bosses":
			return float(g.boss_done.size())
		"ambushes":
			return float(g.ambushes)
		"temper":
			return float(g.temper)
		"arms":
			return float(Arms.adept(g))
		"trials":
			return float(g.trials.size())
		"trial_kinds":
			var kinds := {}
			for tid in g.trials:
				var p := Trials.path(str(tid), str(g.trials[tid]))
				if not p.is_empty():
					kinds[str(p.kind)] = true
			return float(kinds.size())
		"undefeated":
			return float(g.level) if g.deaths == 0 else 0.0
		"guests":
			return float(Cultures.guests(g))
		"kin":
			var kn := 0
			for hid in Cultures.ORDER:
				if Cultures.tier(g, hid) >= 2:
					kn += 1
			return float(kn)
		"races":
			var rn := 0
			for race in g.standing:
				if g.race_tier(str(race)) >= 1:
					rn += 1
			return float(rn)
		"deeds":
			return float(g.deeds.size())
		"renown":
			return float(g.renown)
		"folk_talk":
			return float(g.folk_talk.size())
		"bond":
			return float(g.bond)
		"memories":
			return float(g.memories.size())
		"jobs":
			return float(Jobs.done_count(g))
		"summits":
			return float(g.summits.size())
		"climbed":
			return float(g.climbed)
		"glide_best":
			return float(g.glide_best)
		"glides":
			return float(g.glides)
		"delved":
			return float(g.delved.size())
		"abodes":
			return float(g.abodes.size())
		"bestiary":
			return float(g.bestiary.size())
		"cleared":
			return float(g.cleared.size())
		"felled":
			return float(g.felled_n)
		"smashed":
			return float(g.smashed)
		"works":
			return float(Works.count(g))
		"rides":
			return float(g.rides.size())
		"stones":
			return float(g.stones)
		"talents":
			return float(g.talent_ranks())
		"meditated":
			return float(g.meditated)
		"pastimes":
			return float(g.pastimes.size())
		"host":
			return float(War.companies(g).size())
		"war_won":
			return float(g.war_won.size())
		"war_swift":
			# (the fewer drums the better: the feat asks for a battle won in `n` or fewer)
			var best := 99
			for b in g.war_won:
				best = mini(best, int(g.war_won[b]))
			return float(int(t[1])) if best <= int(t[1]) else 0.0
		"war_order":
			return float(g.war_orders.get(str(t[1]), 0))
		"war_clean":
			return float(g.war_won.size()) if g.war_lost == 0 else 0.0
		"heard":
			return float(g.heard.size())
		"airs":
			return float(g.airs.size())
		"shifts":
			return float(Offices.worked(g)[0])
		"fares":
			return float(g.fares)
		"letters":
			return float(g.mail_read.size())
		"coaches":
			return float(g.coaches)
		"voyages":
			return float(g.voyages)
		"bags":
			return float(g.bags_done)
		"trade_rank":
			return float(maxi(0, Offices.best_rank(g)))
		"trades":
			return float(Offices.worked(g)[1])
		"fallen":
			return float(g.fallen)
		"yielded":
			return float(g.yielded)
		"dooms":
			# (dooms.gd: the tide, in any of its three shapes, is one of them)
			return float((1 if g.falls.has("tide_horse") or g.falls.has("tide_mare") or g.falls.has("spring_colt") else 0) + (1 if g.falls.has("wuzhiqi") else 0) + (1 if g.falls.has("the_riders") else 0))
		"marks":
			return float(g.marks_seen.size())
		"songs_played":
			return float(g.songs_played)
		"outfits":
			return float(g.outfits.size())
		"worn":
			return float(g.worn.size())
		"yue_outfits":
			return float(g.yue_outfits.size())
		"eggs":
			return float(g.eggs.size())
		"survived":
			# (days seen with survival on and nothing given way: nothing once the body has had its way)
			return float(g.day - int(g.needs.get("since", g.day))) if g.survival and g.needs_fell.is_empty() else 0.0
		"romance":
			return float(Romance.stage(g))
		"gifts":
			return float(Romance.gifts_given(g))
		"outings":
			return float(Romance.outings_had(g))
		"gamble_rounds":
			return float(g.gamble_rounds)
		"gamble_wins":
			return float(g.gamble_wins)
		"gamble_streak":
			return float(g.gamble_streak)
		"gamble_best":
			return float(g.gamble_best)
		"feats":
			return float(g.feats.size())
	return 0.0

static func need(t: Array) -> float:
	return 1.0 if str(t[0]) == "step" else float(t[t.size() - 1])

static func met(g, id: String) -> bool:
	var t: Array = FEATS[id].test
	return value(g, t) >= need(t)

## "7 of 9"
static func progress(g, id: String) -> String:
	var t: Array = FEATS[id].test
	if str(t[0]) in ["step", "war_swift"]:
		return "done" if g.feats.has(id) else "not yet"
	return "%d of %d" % [int(minf(value(g, t), need(t))), int(need(t))]

static func points(g) -> int:
	var n := 0
	for id in g.feats:
		if FEATS.has(id):
			n += int(FEATS[id].pts)
	return n

static func total() -> int:
	var n := 0
	for id in FEATS:
		n += int(FEATS[id].pts)
	return n

static func title(g) -> String:
	var out := str(TITLES[0][1])
	var p := points(g)
	for tl in TITLES:
		if p >= int(tl[0]):
			out = str(tl[1])
	return out

## Look for feats done since the last look: each is told once, kept, and may give something to wear.
static func poll(g) -> void:
	if g.prologue != "":
		return
	Eggs.poll(g)
	for id in FEATS:
		if g.feats.has(id) or not met(g, id):
			continue
		g.feats[id] = g.playtime
		g.toast("Feat: %s" % str(FEATS[id].n))
		g.note("Feat: %s (%s)" % [str(FEATS[id].n), str(FEATS[id].desc)])
		g.grant_earned("feat", id)

## The page's text for a feat.
static func text(g, id: String) -> String:
	var f: Dictionary = FEATS[id]
	var has: bool = g.feats.has(id)
	if bool(f.get("hide", false)) and not has:
		return "Not shown until it is done.\n\n%d points." % int(f.pts)
	var out := str(f.desc) + "\n\n" + ("Done at %s of the journey." % Fmt.clock(float(g.feats[id])) if has else "So far: %s." % progress(g, id))
	out += "\n%d points." % int(f.pts)
	for rw in Fashion.earned_by("feat", id):
		var nm: String = str(Fashion.OUTFITS[rw[1]].n) if str(rw[0]) == "outfit" else str(Fashion.YUE_OUTFITS[rw[1]].n) + ", for Yue Ling"
		out += "\nIt gives something to wear: the %s." % nm
	return out
