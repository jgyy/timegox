extends Node
## Global game state (autoload "Game"): party, progression, quest chain and the play clock.

signal quest_changed
signal level_changed

var started := false
var finished := false
var playtime := 0.0          # seconds of game time since "New Game"
var level := 0
var exp := 0.0
var stones := 60
var inv := {"hp_pill": 3, "qi_pill": 1}
var step := 0
var area := "sect"
var tile := Vector2i(-1, -1)  # world tile (see atlas.gd), in the tiles of `layer`
## the realm Lin Feng is in: "surface" (the Unbroken Land), "heaven", "under", or the floor of a
## building ("f:...", see Atlas.floor_id)
var layer := "surface"
var companion := false
var temper := 0
var hp := [80.0, 0.0]
var qi := [40.0, 0.0]
var boss_done := {}
var taken := {}
var defeated := {}
var kills := 0
var battles := 0
var deaths := 0
var meditated := 0.0
var hunt := 0
## the Hollow Hills release (caves.gd): the caves Lin Feng has been to the very back of (the id of the
## cave's floor -> true), and the things of a cave done during the step that asks for them (their kind)
var delved := {}
var step_uses := {}
## the High Roads release (peaks.gd): the summits stood on (the peak's id -> true), the metres of rock
## climbed, the flights under the kite (how many, the tiles flown in all, the longest, and the
## greatest height come down in one) and the wayfarers met on the road (wayfarers of folk.gd)
var summits := {}
var climbed := 0.0
var glides := 0
var glided := 0
var glide_best := 0
var glide_drop := 0.0
## the longest flight since the step of the story that asks for one began (tiles)
var step_glide := 0
var timeline: Array = []
var toasts: Array = []
## regions Lin Feng has set foot in (their histories go into the Annals)
var seen := {}
## Part XI: the Dao Lin Feng walks ("" until the Jianmu grows back), the mastery points he has in
## each, how often he has changed roads; his standing with each people of the realms and the peoples
## he has met
var dao := ""
var dao_xp := {}
var dao_switches := 0
## the Two Roads release (braid.gd): the roads he holds besides the one he leads with, the hundredths of a point
## each has towards its next (a battle's point is shared out when he holds several), and the most he ever held
var braid: Array = []
var dao_part := {}
var braid_most := 0
var standing := {}
var met := {}
## Part XII: the branches of the Nine Heavens root Lin Feng has woken (talent id -> rank 1..3), the
## awakenings he has not yet spent, the Founder's sealed caves he has opened, and how many packs have
## scattered before his aura
var talents := {}
var talent_pts := 0
var awakenings := 0
var abodes := {}
var scattered := 0
## Many roads (Part XIII's release, see trials.gd): Lin Feng's renown (the respect of the world), the
## trials he has passed and the path he took through each, the paths he has already paid for (a lost
## battle does not charge twice), the deeds he has done for townsfolk and the Eight Gates he has opened
var renown := 0
var trials := {}
var paid := {}
var deeds := {}
var gates_open := {}
## the leaders Lin Feng has carried the Conclave's invitations to (Part XIII)
var visited := {}
## things done in the world (props.gd): the kinds of thing he has done at least once (his pastimes),
## how often he has used each thing, the things that gave up a find, and when each last gave
## something that comes back with time (herbs, training)
var pastimes := {}
var prop_uses := {}
var prop_found := {}
var prop_t := {}
## Fates and Faces (fashion.gd, fate.gd, lore.gd): who the player made Lin Feng (name, look, colours,
## origin), the outfits he owns and wears, the rides he owns, the one he summons and whether he is in
## the saddle; the fated encounters (thread -> its state, and the choices made in it, in order); the
## small choices of the road (a choice id -> the option taken); the foes he has met (species -> how
## many battles) and the bosses whose story has been told
var hero := {}
var outfits := {}
var outfit := "sweeper"
var rides := {}
var ride := ""
var riding := false
var fates := {}
var fate_log := {}
var picks := {}
var bestiary := {}
var told := {}
## the grudges that stayed (grudges.gd, Part XIV): grudge boss id -> the option taken once it was spent
var grudges := {}
## Yue Ling (bonds.gd, the Lotus release): how close the two of them are, which way her heart leans
## (future -> weight), the heart-to-hearts had (talk -> the reply given), her wishes granted, when each
## kind of thing was last done together, the memories given back to her in Part XV (memory -> what Lin
## Feng said), the people who tied a thread for her (Part XV) and the future she chose for herself
var bond := 0
var heart := {}
var talks := {}
var wishes := {}
var shared := {}
var memories := {}
var threads := {}
var future := ""
## the Living Land release (clock.gd): the minute of the day (0..1440) and the day it is
var clock := Clock.START
var day := 1
## the people of the towns (folk.gd): how often Lin Feng has talked with each
var folk_talk := {}
## things broken (havoc.gd): thing id -> the minute of the game it broke (mended by the next dawn),
## and how many things he has broken in all
var broken := {}
var smashed := 0
## Part XVI: the towns Lin Feng reminded of the old ways (npc id -> true), and the people of the towns
## he has done what a step asked of with (step id -> {townsperson id -> true}): the merchants he bought
## red paper from, the children he gave a red envelope to
var rallied := {}
var folk_done := {}
## the Sword's Wake (impact.gd, the Spring Thunder release): things of the land felled or shattered on
## screen (key -> the minute of the game; they grow back by the next dawn) and how many in all; the
## obstacles of the story cleared (id -> "kind|region") and the blows landed on those not yet cleared;
## and how often Lin Feng struck a pack first, threw the sword qi and swung at the world at all
var felled := {}
var felled_n := 0
var cleared := {}
var obstacle_hits := {}
var ambushes := 0
var waves := 0
var strikes := 0
## the Heavy Road release (load.gd, toil.gd): what is left in the storehouse (item -> how many), the
## jin carried a league on the hero's own back, the work of the hands done (work -> times; every time;
## tile -> the day it last gave), what a step asking for work or for a load has had since it began,
## and the goods sold to the pedlars of the road
var stash := {}
var hauled := 0.0
var toil := {}
var toil_n := 0
var toiled := {}
var step_toil := 0
var step_haul := 0
var sold := 0
## the Small Fish release (sunder.gd, cooking.gd): what lies broken in the land by his blows (layer|x|y ->
## [what, the day]), how many of each he has broken in all, the blows that broke something, what a step
## that asks for breaking has had since it began, and how hard he means to strike (-1: all he has; else no
## harder than that rank); the meals he has cooked (dish -> times), how many, how many came out right, and
## what a step that asks for a meal has had since it began; and whether he looks out of his own eyes
var scars := {}
var sundered := {}
var sunder_n := 0
var step_sunder := 0
var sunder_light := 0
var hand := -1
var cooked := {}
var cooked_n := 0
var cooked_good := 0
var step_cook := 0
var first_person := false
## the Five Hands release (phases.gd): the phase his hand is turned to ("" the plain blade), what lies on
## the land by it (layer|x|y -> [what, the day]), how many of each he has left, the blows that came to
## something, how many of each phase, how often one phase overcame another or was fed by it, and what a
## step that asks for it has had since it began
var phase := ""
var touched := {}
var phased := {}
var phase_n := 0
var phases_used := {}
var reacts := {}
var step_phase := 0
## steps just finished that have words to say about it, waiting for the world ("done:<step>")
var done_pending: Array = []
## the Six Hearths (cultures.gd, the New Fire release): standing with each hearth of the land; the
## named people of the hearths the hero has sat down with; the hearth whose farewell is still to be
## said (the beginning of the game: "" once the story proper has begun); and the end chosen
var hearth := {}
var sat := {}
var prologue := ""
## the Hundred Works release: the works built (works.gd: id -> the day it was built), the crossroads
## of the road and what was chosen at each (echoes.gd; `picks` keeps the choices themselves), and the
## three scales those choices tip (echoes.gd SCALES: scale -> points)
var works := {}
var scales := {}
var echoed := {}
## crossroads reached in play and not yet answered (asked by Main once nothing else is going on)
var cross_pending: Array = []
var ending := ""
## the Hundred Arms release (arms.gd): the weapons he owns, the one in his hand, the battles each has
## won (its Dao's mastery), and how often he has changed from one to another
var arms := {"sword": true, "staff": true}
var arm := "sword"
var arm_xp := {}
var arm_switches := 0

## ---- the Thundering Pots release
## Yue Ling's dresses and the one she wears (fashion.gd YUE_OUTFITS); every outfit the hero has had on
var yue_outfits := {"lotus": true}
var yue_outfit := "lotus"
var worn := {"sweeper": true}
## the Underclothes release: down to what is worn under any robe (Esc > Wardrobe; Models.undress), and
## not an outfit of its own: it is under all of them
var underclothes := false
## feats (feats.gd: id -> the play time it was done at) and what was found that nobody was told to
## look for (eggs.gd)
var feats := {}
var eggs := {}
## the tunes heard (music.gd) and the airs of the land learned (id -> true), and how many times a
## tune was asked for in the songbook
var heard := {}
var airs := {}
var songs_played := 0
## the host (war.gd): the companies raised, the field battles won (id -> drums it took) and lost, the
## orders given (order -> times) and how many drums running the host has given ground
var host := {}
var war_won := {}
var war_lost := 0
var war_orders := {}
var war_feints := 0
var war_tries := {}
var songs_asked := {}
## survival (needs.gd): whether the body is asked after at all, the seven needs, the water gourd, the
## clock they were last reckoned at, and how often each has had its way
var survival := false
var needs := {}
var gourd := 0
var needs_clock := 0.0
var needs_fell := {}
## courtship (romance.gd): the stage, the gifts given, the hours had together, and the tone taken
var romance := {}
## Old Du's mat (gamble.gd): the throws so far (every throw is drawn from this count), and how it has gone
## the Lost Horse release: what the choices left standing that has been looked at (marks.gd); and the
## things that could not be beaten (dooms.gd): how each was lost, how often, how often by giving way
var marks_seen := {}
## (the Underclothes release: how many had been looked at when a step asking for more began, `"new": true`)
var marks_from := 0
## the Three Burrows release (hold.gd): the town that is the hero's own: `built` (plots), `settlers`
## (who was asked and came), `day0` (the day it was founded), `taken` (the day the chest was last emptied)
var hold := {}
## (offices.gd: shifts worked at the trades of the towns, and the day the last one was worked in each town)
## (reckon.gd: the last lords of the story that were faced)
var reckoned := {}
## (carriages: who is being carried for a fare, offices.gd: {id, n, asset, to, pay}; and how many have been)
var passengers: Array = []
var fares := 0
## (the post, mail.gd: letters opened, answers written, bags carried {from, to, pay, day}, the day a
## counter last gave one, bags handed over, and how many waiting letters he has been told of)
var mail_read := {}
var mail_replies := {}
var mail_bags: Array = []
var bag_day := {}
var bags_done := 0
var mail_told := 0
## (roads.gd: how many times the post-coach has been taken)
var coaches := 0
## (ships.gd: how many passages by sea have been taken)
var voyages := 0
## passages taken by spirit ark (arks.gd)
var ark_voyages := 0
## (fame.gd: the standing he has been told of, the day each town last gave him something, and how often)
var fame_told := 0
var fan_day := {}
var fan_gifts := 0
var shifts := {}
var shift_day := {}
## (careers: the day the last shift was worked at each trade in each town, for the salary; all wages earned)
var salary_day := {}
var wages := 0
var falls := {}
## the Answering Land release (weal.gd): what was done in each town's own streets ("<town>|<act>" -> times;
## "kills|<region>" -> what fell there; "<town>|thanked"), a counter that moves whenever it changes, and the
## state each town was last told to be in
var weal := {}
var weal_n := 0
var weal_state := {}
var weal_from := {}
var weal_force := {}
var fallen := 0
var yielded := 0
var gamble_n := 0
var gamble_rounds := 0
var gamble_wins := 0
var gamble_won := 0
var gamble_lost := 0
var gamble_best := 0
var gamble_streak := 0
var gamble_triples := 0
## the commissions of the notice board (jobs.gd): id -> "taken" or "done", and what each was at when
## it was taken (to count from)
var jobs := {}
var job_base := {}
## how many times each named person has been spoken to (eggs.gd), and the foes felled by kind
var npc_talks := {}
var felled_kind := {}
## what was said when something was found (eggs.gd), waiting to be shown
var egg_pending: Array = []
var _feat_t := 0.0
## the Ordered House release (almanac.gd): days the story has moved the calendar on by, the month the last
## stipend came for, when each pack's clock began (pack -> day), what was last told of each of the roll,
## and stipends drawn
var cal := 0
var cal_month := -1
var pack_day := {}
var roll_told := {}
var stipends := 0
var _poll_day := 0
## (creed.gd): what was done that the Way he walks is weighed by ("<deed>" -> times)
var creed := {}
var creed_told := ""
## (repute.gd, the Turned Face release): the stage of what the land thinks of him last told, and every stage ever reached
var repute_told := 0
var repute_seen := {}
## (fitting.gd): what has been set down where ("<spot>" -> thing), which houses have been put to rights
## (house -> day), and how many since the step in hand began
var placed := {}
var fitted := {}
var misplaced := 0
var step_fit := 0
## the Open Net release (crime.gd): who is dead by his hand (id -> {n, day, area, town, seen, might}), the
## price on his head (town -> spirit stones), the last of what is charged, the day the watch of each town
## last came for him and the bounty-takers last found him, how often he has beaten them, days served in the
## circle, and what he has paid
var slain := {}
var slain_n := 0
var thrown := 0
var bounty := {}
var crimes: Array = []
var watch_day := {}
var hunter_day := -1
var hunted := 0
var served := 0
var bounty_paid := 0
var watch_slain := 0
## (taboo.gd): how deep he has sat to each forbidden Dao ("marked" -> the day he was found out)
var taboo := {}
## (wilds.gd): the strain on each region (region -> [packs put down, the day it was counted]), the state last
## told of it, the worst it was ever brought to, and the nets opened (region -> day)
var cull := {}
var cull_told := {}
var cull_worst := {}
var nets := {}
var nets_opened := 0
## the Unpicked Road release (trifles.gd): the small things taken up (id -> the day), what is in his
## sleeve, how many were picked up, pocketed though somebody's, brought home, given to a child; and
## (world.gd) how many times he has jumped, leapt two tiles, come down beside somebody, been walked into
var trifles := {}
var pocket: Array = []
var picked := 0
var pilfered := 0
var restored := 0
var treats := 0
var jumps := 0
var leaps := 0
var bumps := 0
var step_restore := 0
var step_leap := 0
## the Uncarved Block release (rites.gd): the rites of the Daos he has performed (id -> times), those waiting to
## be played, how many he has performed in all, and how many since the step began
var rites := {}
var rite_due: Array = []
var rite_n := 0
var step_rite := 0
## the Higher Sky release (betters.gd): those above him: how each bout went and what it took (better -> {first, last,
## base, took, wound, bouts}), how often each has been watched and on which day, and the tallies
var bested := {}
var watched := {}
var watch_on := {}
var bettered := 0
var overmatched := 0
var bowed := 0
## and (memoir.gd) the pages written in their own words (page -> the day), and the ones not yet read out
var pages := {}
var page_due: Array = []
## the Red Seal release: the papers of his Daos (seals.gd: rite id -> {grade, day}); the meets (lists.gd: meet ->
## {round, day, place, crowd, best, times, said}), what he said to whom across a ring, and the tallies; the
## auction rooms (auction.gd: lots sold to him, where today's bidding stands, sealed bids in the post); and what
## else the post now carries (mail.gd: who he wrote to, parcels waiting for him)
var seals := {}
var seals_sat := 0
var meets := {}
var said_to := {}
var bouts := 0
var bouts_won := 0
var words_said := 0
var purses := 0
var lots := {}
var lot_at := {}
var lots_won := 0
var lot_spent := 0
var lot_saved := 0
var step_bid := 0
## the Two Roads release (yezi.gd): hands of leaves dealt so far (every deal is drawn from this count), how it has
## gone, who was sat with (id -> {won, lost, beat_day}), the painted leaves won and the one he brings to a table
var card_n := 0
var card_hands := 0
var card_wins := 0
var card_streak := 0
var card_best := 0
var card_tea := 0
var cards := {}
var leaves := {}
var leaf := ""
var step_cards := 0
## the Rivers and Lakes release (sects.gd, raids.gd, sides.gd): the tasks of the sects (task -> "taken" or "done") and
## what was so when each was taken; raids broken (in all, by his coming alone, this watch's by key, since the step
## began); the day a cutpurse last tried him and the day he was last mended for nothing, by town; and how often
## the Sea Floor release (mills.gd, deeps.gd, terra.gd): what each works' store held when it was last counted
## (works -> {n, at}), the crates in his hands, the day each pair of works last had one of him, what he has
## bought and been paid and brought; the places of the sea floor found (sight -> day); and the ground he has
## shaped (realm -> tile -> {h, w}), how often, of which kinds, and since the step began
var mills := {}
var mill_crates: Array = []
var mill_runs := {}
var mill_bought := 0
var mill_paid := 0
var crates_done := 0
var step_supply := 0
var sights := {}
var shaped := {}
var shaped_n := 0
var shaped_kinds := {}
var step_terra := 0
## the Unblunted Knife release (channels.gd, crafts.gd, pets.gd, retreats.gd): the points of the chart he has
## opened (point -> ranks), how often, and the insight that came of sitting and making; what each craft has
## learned, the best thing kept of each (craft -> {id, q}), the best each thing has come out, the first
## masterworks, and how many things were made; the beasts he keeps (each {k, foe, shape, n, bond, day, fed,
## wins, loads, out}), which is at his heel, how many he has ever kept and what they have brought back; the
## places of peace he has sat in (place -> sittings), the day he last sat in each, sittings and nights slept
## out; and what the step of the day has seen done (kind -> n: "train", "craft", "tame", "fetch", "retreat")
var channels := {}
var channels_n := 0
var insight := 0
var craft_xp := {}
var kept := {}
var crafted := {}
var crafted_n := 0
var masterworks := {}
var pets: Array = []
var pet := -1
var pets_n := 0
var fetched := 0
var retreats := {}
var sat_day := {}
var sittings := 0
var slept := 0
var step_did := {}
var sect_q := {}
var sect_base := {}
var raids_broken := 0
var raids_fled := 0
var raid_done := {}
var step_raids := 0
var purse_day := {}
var alms_day := {}
var purses_cut := 0
var alms_taken := 0
## the Two Roads release (plights.gd): good deeds and bad ones done in the street (plight:what -> how often), who
## was met in one and on which day, and what the wrong ones put in his purse
var deeds_done := {}
var plights_met := {}
var deeds_good := 0
var deeds_bad := 0
var deeds_took := 0
var sealed_bids: Array = []
var parcels: Array = []
var wrote := {}
var letters_sent := 0
var parcels_sent := 0
var remitted := 0

func _process(d: float) -> void:
	if started and not finished:
		playtime += d
		Clock.advance(self, d)
		# feats, finds and the dresses the journey has earned are looked for now and then (cheap: a
		# few dozen comparisons)
		_feat_t -= d
		if _feat_t <= 0.0:
			_feat_t = 1.5
			poll_wardrobe()
			Feats.poll(self)
			# (the Underclothes release: the town that is his own grows overnight, and a step waiting on it
			# hears of it without anything else having to happen first, hold.gd)
			Hold.tick(self)
			# (the Ordered House release, almanac.gd: what a new day has brought: the month's stipend, word of
			# the roll; and creed.gd: the Way he walks, told when it changes)
			if day != _poll_day:
				_poll_day = day
				Almanac.poll(self)
				# (the Open Net release, wilds.gd: what the days have mended in the countries he hunted)
				Wilds.poll_all(self)
			Creed.poll(self)
			# (the Turned Face release, repute.gd: what the land thinks of him, told when it changes)
			Repute.poll(self)
			# (needs.gd: the body follows the land's clock; the night wears comfort faster)
			if survival and prologue == "":
				Needs.tick(self, 1.6 if Clock.is_night(Clock.hour(self)) else 1.0)

func reset() -> void:
	started = true
	finished = false
	playtime = 0.0
	level = 0
	exp = 0.0
	stones = 60
	inv = {"hp_pill": 3, "qi_pill": 1}
	step = 0
	area = "sect"
	# a world tile: the sect's courtyard in front of the hall (Vector2i(20, 8) is the sect's own
	# tile, which used to be stored here as if it were a world tile)
	tile = Atlas.to_world("sect", Vector2i(20, 8))
	layer = "surface"
	companion = false
	temper = 0
	boss_done = {}
	taken = {}
	defeated = {}
	kills = 0
	battles = 0
	deaths = 0
	meditated = 0.0
	hunt = 0
	delved = {}
	step_uses = {}
	summits = {}
	climbed = 0.0
	glides = 0
	glided = 0
	glide_best = 0
	glide_drop = 0.0
	step_glide = 0
	timeline = []
	toasts = []
	seen = {"sect": true}
	dao = ""
	dao_xp = {}
	dao_switches = 0
	standing = {}
	met = {}
	talents = {}
	talent_pts = 0
	awakenings = 0
	abodes = {}
	scattered = 0
	renown = 0
	trials = {}
	paid = {}
	deeds = {}
	gates_open = {}
	visited = {}
	pastimes = {}
	prop_uses = {}
	prop_found = {}
	prop_t = {}
	hero = Fashion.default_hero()
	outfits = {"sweeper": true}
	outfit = "sweeper"
	rides = {}
	ride = ""
	riding = false
	fates = {}
	fate_log = {}
	picks = {}
	works = {}
	scales = {}
	echoed = {}
	cross_pending = []
	bestiary = {}
	told = {}
	grudges = {}
	bond = 0
	heart = {}
	talks = {}
	wishes = {}
	shared = {}
	memories = {}
	threads = {}
	future = ""
	clock = Clock.START
	day = 1
	folk_talk = {}
	broken = {}
	smashed = 0
	rallied = {}
	folk_done = {}
	felled = {}
	felled_n = 0
	cleared = {}
	obstacle_hits = {}
	ambushes = 0
	waves = 0
	strikes = 0
	done_pending = []
	hearth = {"valley": Cultures.KIN}
	sat = {}
	prologue = ""
	ending = ""
	arms = {}
	for aid in Arms.FIRST:
		arms[aid] = true
	arm = "sword"
	arm_xp = {}
	arm_switches = 0
	yue_outfits = {"lotus": true}
	yue_outfit = "lotus"
	worn = {"sweeper": true}
	underclothes = false
	stash = {}
	hauled = 0.0
	toil = {}
	toil_n = 0
	toiled = {}
	step_toil = 0
	step_haul = 0
	scars = {}
	sundered = {}
	sunder_n = 0
	step_sunder = 0
	sunder_light = 0
	hand = -1
	cooked = {}
	cooked_n = 0
	cooked_good = 0
	step_cook = 0
	first_person = false
	phase = ""
	touched = {}
	phased = {}
	phase_n = 0
	phases_used = {}
	reacts = {}
	step_phase = 0
	sold = 0
	feats = {}
	eggs = {}
	heard = {}
	airs = {}
	songs_played = 0
	host = {}
	war_won = {}
	war_lost = 0
	war_orders = {}
	war_feints = 0
	war_tries = {}
	songs_asked = {}
	survival = false
	needs = {}
	gourd = 0
	needs_clock = 0.0
	needs_fell = {}
	romance = {}
	marks_seen = {}
	marks_from = 0
	hold = {}
	reckoned = {}
	passengers = []
	fares = 0
	mail_read = {}
	mail_replies = {}
	mail_bags = []
	bag_day = {}
	bags_done = 0
	mail_told = 0
	coaches = 0
	voyages = 0
	ark_voyages = 0
	fame_told = 0
	fan_day = {}
	fan_gifts = 0
	shifts = {}
	shift_day = {}
	salary_day = {}
	wages = 0
	falls = {}
	weal = {}
	weal_n = 0
	weal_state = {}
	weal_from = {}
	weal_force = {}
	fallen = 0
	yielded = 0
	gamble_n = 0
	gamble_rounds = 0
	gamble_wins = 0
	gamble_won = 0
	gamble_lost = 0
	gamble_best = 0
	gamble_streak = 0
	gamble_triples = 0
	jobs = {}
	job_base = {}
	npc_talks = {}
	felled_kind = {}
	egg_pending = []
	cal = 0
	cal_month = -1
	pack_day = {}
	roll_told = {}
	stipends = 0
	_poll_day = 0
	creed = {}
	creed_told = ""
	repute_told = 0
	repute_seen = {}
	placed = {}
	fitted = {}
	misplaced = 0
	step_fit = 0
	slain = {}
	slain_n = 0
	thrown = 0
	bounty = {}
	crimes = []
	watch_day = {}
	hunter_day = -1
	hunted = 0
	served = 0
	bounty_paid = 0
	watch_slain = 0
	taboo = {}
	cull = {}
	cull_told = {}
	cull_worst = {}
	nets = {}
	nets_opened = 0
	trifles = {}
	pocket = []
	picked = 0
	pilfered = 0
	restored = 0
	treats = 0
	jumps = 0
	leaps = 0
	bumps = 0
	step_restore = 0
	step_leap = 0
	rites = {}
	rite_due = []
	rite_n = 0
	step_rite = 0
	bested = {}
	watched = {}
	watch_on = {}
	bettered = 0
	overmatched = 0
	bowed = 0
	pages = {}
	page_due = []
	seals = {}
	seals_sat = 0
	meets = {}
	said_to = {}
	bouts = 0
	bouts_won = 0
	words_said = 0
	purses = 0
	lots = {}
	lot_at = {}
	lots_won = 0
	lot_spent = 0
	lot_saved = 0
	mills = {}
	mill_crates = []
	mill_runs = {}
	mill_bought = 0
	mill_paid = 0
	crates_done = 0
	step_supply = 0
	sights = {}
	shaped = {}
	shaped_n = 0
	shaped_kinds = {}
	step_terra = 0
	channels = {}
	channels_n = 0
	insight = 0
	craft_xp = {}
	kept = {}
	crafted = {}
	crafted_n = 0
	masterworks = {}
	pets = []
	pet = -1
	pets_n = 0
	fetched = 0
	retreats = {}
	sat_day = {}
	sittings = 0
	slept = 0
	step_did = {}
	sect_q = {}
	sect_base = {}
	raids_broken = 0
	raids_fled = 0
	raid_done = {}
	step_raids = 0
	purse_day = {}
	alms_day = {}
	purses_cut = 0
	alms_taken = 0
	card_n = 0
	card_hands = 0
	card_wins = 0
	card_streak = 0
	card_best = 0
	card_tea = 0
	cards = {}
	leaves = {}
	leaf = ""
	step_cards = 0
	deeds_done = {}
	plights_met = {}
	deeds_good = 0
	deeds_bad = 0
	deeds_took = 0
	braid = []
	dao_part = {}
	braid_most = 0
	step_bid = 0
	sealed_bids = []
	parcels = []
	wrote = {}
	letters_sent = 0
	parcels_sent = 0
	remitted = 0
	UI.set_hero_name(Fashion.DEFAULT_FAMILY, Fashion.DEFAULT_GIVEN)
	hp = [float(max_hp(0)), 0.0]
	qi = [float(max_qi(0)), 0.0]
	note("Journey begins")

func note(text: String) -> void:
	timeline.append({"t": snappedf(playtime, 0.1), "text": text})

func toast(text: String) -> void:
	toasts.append(text)

# ---------------------------------------------------------------- party
func party_size() -> int:
	return 2 if companion else 1

func member_name(i: int) -> String:
	# (the name the player chose is put on screen by UI.named: the story's data keeps "Lin Feng")
	return "Lin Feng" if i == 0 else "Yue Ling"

func max_hp(i: int) -> int:
	# (his origin and outfit build his body only, not Yue Ling's: Fashion.gear)
	# (and her dress hers: Fashion.yue_gear)
	# (and what being promised, or wed, gives her: romance.gd)
	return int(Data.max_hp(level) * (1.0 if i == 0 else 0.85) * boon("hp", 1.0) * ((1.0 + talent_mod("hp")) * (1.0 + Fashion.gear(self, "hp")) * Channels.mod(self, "hp") * Crafts.mod(self, "hp") if i == 0 else (1.0 + Fashion.yue_gear(self, "hp")) * Romance.mod(self)) * Works.mod(self, "hp"))

func max_qi(i: int) -> int:
	# (his origin and his outfit may widen or narrow his dantian: Fashion.gear)
	# (a body that is parched or filthy holds less: needs.gd; nothing with survival off)
	return int(Data.max_qi(level) * (1.0 if i == 0 else 1.1) * ((1.0 + talent_mod("qi")) * (1.0 + Fashion.gear(self, "qi")) * Channels.mod(self, "qi") * Crafts.mod(self, "qi") if i == 0 else 1.0 + Fashion.yue_gear(self, "qi")) * Needs.mod(self, "qi"))

func fighter(i: int) -> Dictionary:
	var a := float(Data.atk(level)) * (1.0 + 0.12 * temper) * boon("atk", 1.0)
	if i == 1:
		a = float(Data.atk(level)) * 0.75 * (1.0 + Fashion.yue_gear(self, "atk"))
	# (needs.gd: the famished and the worn out strike less hard; 1 with survival off)
	a *= Needs.mod(self, "atk")
	# (betters.gd: and somebody carrying what a better left him with)
	# (the Red Seal release: the wound is his: Yue Ling used to limp with him)
	if i == 0:
		a *= Betters.mod(self, "atk")
		# (the Unblunted Knife release: the points of the chart he has opened, and what he forged and wears; 1 with neither)
		a *= Channels.mod(self, "atk") * Crafts.mod(self, "atk")
	# the Wandering Dao and the friendship of the Feathered Folk make Lin Feng quicker
	var spd: int = Data.speed(level) + (2 + int(Fashion.yue_gear(self, "spd")) if i == 1 else 0)
	if i == 0:
		spd += int(dao_mod("spd", 0.0) + boon("spd", 0.0) + talent_mod("spd") + Arms.mod(self, "spd", 0.0))
		spd += int(Channels.add(self, "spd") + Crafts.add(self, "spd"))
	spd += int(Needs.mod(self, "spd"))
	if i == 0:
		spd = int(round(float(spd) * Betters.mod(self, "spd")))
	return {
		"id": "pc%d" % i, "name": member_name(i), "side": "party", "idx": i, "lv": level, "boss": false,
		"hp": hp[i], "maxhp": float(max_hp(i)), "qi": qi[i], "maxqi": float(max_qi(i)),
		"atk": a, "def": float(Data.defense(level)) * (Channels.mod(self, "def") * Crafts.mod(self, "def") if i == 0 else 0.9), "spd": spd,
		"elem": "phys", "weak": "none", "col": Color("7ec8ff") if i == 0 else Color("ff9ac0"),
		"shape": "hero" if i == 0 else "healer", "skills": Data.known_skills(i, level, step) + dao_skills(i) + (Arms.skills(self) + Creed.skills(self) if i == 0 else []),
		"turns": 0, "flash": 0.0, "shake": 0.0, "dead": false, "fade": 1.0,
	}

# ---------------------------------------------------------------- daos (Part XI)
## Lin Feng's rank in a Dao (0 Novice, 1 Adept, 2 Master), the one he walks by default.
func dao_tier(id: String = "") -> int:
	if id == "":
		id = dao
	if id == "":
		return 0
	var xp: int = int(dao_xp.get(id, 0))
	var tier := 0
	for k in Data.DAO_TIERS.size():
		if xp >= Data.DAO_TIERS[k]:
			tier = k
	return tier

## A passive of the roads Lin Feng holds at his rank in each (braid.gd), or `fallback` if none has it.
func dao_mod(key: String, fallback: float) -> float:
	if dao == "":
		return fallback
	return Braid.mod(self, key, fallback)

## Start (or change) the road Lin Feng leads with; each Dao keeps its own mastery.  A road he holds already
## (braid.gd) comes to the front; any other takes the place of the one he led with.
func choose_dao(id: String) -> void:
	if not Data.DAOS.has(id) or id == dao:
		return
	if braid.has(id):
		Braid.lead(self, id)
		return
	if dao != "":
		dao_switches += 1
	dao = id
	dao_xp[id] = int(dao_xp.get(id, 0))
	# (the Uncarved Block release, rites.gd: a road first walked has a rite, played when he next stands free)
	Rites.earn(self, Rites.of_road(id))
	toast("You walk the %s" % Data.DAOS[id].n)
	note("Walks the %s" % Data.DAOS[id].n)

## A battle won while walking a Dao deepens it (a boss four times as much); reaching a rank is news.  Holding
## several, the point is shared out among them (braid.gd): the more roads, the less each learns.
func dao_battle_won(boss: bool) -> void:
	if dao == "":
		return
	for up in Braid.won(self, boss):
		var did := str(up[0])
		var after := int(up[1])
		toast("%s of the %s" % [Data.DAO_RANKS[after], Data.DAOS[did].n])
		note("Became %s of the %s" % [Data.DAO_RANKS[after], Data.DAOS[did].n])
		if after == 1:
			toast("New technique: %s" % Data.SKILLS[Data.DAOS[did].skill].n)

## The techniques of the roads he holds, for Lin Feng, once he is an Adept of each.
func dao_skills(i: int) -> Array:
	if i != 0 or dao == "":
		return []
	return Braid.skills(self)

## A technique as it stands now.  Most are what Data.SKILLS says; the technique of a weapon's Dao
## (arms.gd) is measured against the strongest technique of the same reach Lin Feng knows, so that a
## weapon picked up at Qi Condensation is still worth carrying at Hollow Vessel.
var _skill_now := {}

func skill_of(id: String) -> Dictionary:
	var s: Dictionary = Data.SKILLS[id]
	# (and the arts of the Way he walks, creed.gd: measured the same way)
	if not s.has("arm") and not s.has("creed"):
		return s
	var key := "%s|%d|%d" % [id, level, step]
	if _skill_now.has(key):
		return _skill_now[key]
	var bm := 1.3 if str(s.tgt) == "one" else 1.0
	var bc := 6.0
	for sid in Data.known_skills(0, level, step):
		var o: Dictionary = Data.SKILLS[sid]
		if str(o.tgt) == str(s.tgt) and not o.has("heal") and float(o.mult) > bm:
			bm = float(o.mult)
			bc = float(o.cost)
	var out := s.duplicate()
	out["mult"] = bm * float(s.k)
	out["cost"] = int(ceil(bc * float(s.ck)))
	if _skill_now.size() > 64:
		_skill_now.clear()
	_skill_now[key] = out
	return out

## What a technique costs to use (the Cauldron's Dao makes them cheaper).
func skill_cost(id: String) -> float:
	var c := float(skill_of(id).cost) * dao_mod("qi", 1.0) * Braid.qi(self) * Arms.mod(self, "qi", 1.0) * (1.0 - talent_mod("cost")) * (1.0 - Fashion.gear(self, "cost")) * Works.mod(self, "cost")
	# the crown of the Five-Phase Root: techniques that strike every foe cost a fifth less
	if talent_crown("five_phase") and str(Data.SKILLS[id].tgt) == "all":
		c *= 0.8
	return c

# ---------------------------------------------------------------- the Nine Heavens root (Part XII)
func talent(id: String) -> int:
	return int(talents.get(id, 0))

func talent_crown(id: String) -> bool:
	return talent(id) >= Data.TALENT_MAX

## What the woken branches add up to for one effect key (see Data.TALENTS fx): the sum over every
## branch of its per-rank amount times its rank.
func talent_mod(key: String) -> float:
	var v := 0.0
	for id in talents:
		var fx: Dictionary = Data.TALENTS[id].fx
		if fx.has(key):
			v += float(fx[key]) * int(talents[id])
	return v

## How much harder a technique of Lin Feng's lands for the branches he has woken: its element's root,
## and the Sword Bone for the plain strike, physical techniques and single-target techniques.
func talent_power(skill_id: String) -> float:
	var s: Dictionary = Data.SKILLS[skill_id]
	var m := 1.0 + talent_mod(str(s.elem))
	if skill_id == "strike":
		m += talent_mod("strike") - (talent_mod("phys") if str(s.elem) == "phys" else 0.0)
	if str(s.get("tgt", "")) == "one":
		m += talent_mod("one")
	return m

## A branch wakes (the first stirring of qi, a tribulation, a Founder's cave): one more rank to spend.
func awaken(why: String) -> void:
	talent_pts += 1
	awakenings += 1
	toast("A branch of the Nine Heavens root stirs")
	note("The root stirred: " + why)

## Spend an awakening on branch `id`.  Returns whether it took.
func wake_talent(id: String) -> bool:
	if talent_pts <= 0 or not Data.TALENTS.has(id) or talent(id) >= Data.TALENT_MAX:
		return false
	talent_pts -= 1
	talents[id] = talent(id) + 1
	var rank := talent(id)
	toast("%s: %s" % [Data.TALENTS[id].n, Data.TALENT_RANKS[rank]])
	note("Woke the %s (%s)" % [Data.TALENTS[id].n, Data.TALENT_RANKS[rank]])
	# the branches that grow the body and the dantian fill what they grow
	hp[0] = minf(float(max_hp(0)), hp[0] + Data.max_hp(level) * float(Data.TALENTS[id].fx.get("hp", 0.0)))
	qi[0] = minf(float(max_qi(0)), qi[0] + Data.max_qi(level) * float(Data.TALENTS[id].fx.get("qi", 0.0)))
	return true

## Total ranks woken.
func talent_ranks() -> int:
	var n := 0
	for id in talents:
		n += int(talents[id])
	return n

# ---------------------------------------------------------------- realms (Part XII)
func realm() -> int:
	return Data.realm_of(level)

## How the world addresses Lin Feng at his realm.
func address() -> String:
	return str(Data.REALM_INFO[mini(realm(), Data.REALM_INFO.size() - 1)].title)

## A pack this far below Lin Feng scatters before his aura rather than fight (Main.interact).
func scatters(group: Array) -> bool:
	# (dooms.gd: what cannot be beaten does not run from anybody's realm)
	if Dooms.in_group(group):
		return false
	var top := 0
	for g in group:
		top = maxi(top, int(g.lv))
	return realm() - Data.realm_of(top) >= Data.AURA_FLEE

# ---------------------------------------------------------------- the peoples of the realms (Part XI)
func race_tier(race: String) -> int:
	var st: int = int(standing.get(race, 0))
	return 2 if st >= Data.KIN else (1 if st >= Data.FRIEND else 0)

func race_title(race: String) -> String:
	return ["Stranger", "Friend", "Kin"][race_tier(race)]

## A people's name to start a sentence with: "The Shades of Youdu", "The Thousand Children of Landfall"
## (whose names already begin with "The": the toast used to read "The The Thousand Children...").
static func the_race(race: String) -> String:
	var n: String = str(Data.RACES[race].n)
	return n if n.begins_with("The ") else "The " + n

## Standing grows with help given; walking the Dao a people honours makes it grow half as fast again.
func race_gain(race: String, n: int) -> void:
	if not Data.RACES.has(race) or race == "human":
		return
	met[race] = true
	var before := race_tier(race)
	if dao != "" and Braid.honours(self, race):
		n = int(ceil(n * 1.5))
	# (echoes.gd: the peoples warm faster to somebody known to belong to the wide world)
	n = int(ceil(n * Echoes.lean_mod(self, "regard")))
	standing[race] = mini(int(standing.get(race, 0)) + n, Data.KIN)
	var after := race_tier(race)
	if after > before:
		toast("%s call you %s" % [the_race(race), race_title(race)])
		note("%s call Lin Feng %s" % [the_race(race), race_title(race)])
		if after == 1 and str(Data.RACES[race].boon_n) != "":
			toast("Boon: %s" % Data.RACES[race].boon_n)

## Give a people the keepsake they love (one from the inventory): standing grows. Returns whether
## anything was given.
func give_gift(race: String) -> bool:
	var item: String = str(Data.RACES.get(race, {}).get("gift", ""))
	if item == "" or inv.get(item, 0) <= 0:
		return false
	inv[item] -= 1
	race_gain(race, 12)
	add_renown(Trials.RENOWN_GIFT)
	return true

## The boons of the peoples who call Lin Feng friend: spd (speed), atk, miss, heal, hp and taken
## multipliers or additions; `fallback` when no friendly people grants it.
func boon(key: String, fallback: float) -> float:
	var v := fallback
	for race in standing:
		if race_tier(race) < 1 or str(Data.RACES[race].boon) != key:
			continue
		match key:
			"spd":
				v += 3.0
			"atk":
				v *= 1.06
			"miss":
				v += 0.05
			"heal":
				v *= 1.1
			"hp":
				v *= 1.08
			"taken":
				v *= 0.94
			# Part XII: the Thousand Children's thrift and the immortals' teaching
			"stones":
				v *= 1.1
			"exp":
				v *= 1.06
	# who he was before the sect (his origin) and what he wears (Fates and Faces): small strengths and
	# small weaknesses through the same channels
	var gv := Fashion.gear(self, key) if key != "hp" else 0.0
	if gv != 0.0:
		if key == "spd" or key == "miss":
			v += gv
		else:
			v *= 1.0 + gv
	return v

func heal_full() -> void:
	for i in party_size():
		hp[i] = float(max_hp(i))
		qi[i] = float(max_qi(i))

# ---------------------------------------------------------------- cultivation
func exp_need() -> int:
	return Data.EXP_NEED[mini(level, Data.EXP_NEED.size() - 1)]

func at_cap() -> bool:
	return Data.realm_cap(level) or level >= Data.MAX_LEVEL

func can_breakthrough() -> bool:
	return Data.realm_cap(level) and exp >= exp_need() - 0.001

func add_exp(x: float) -> bool:
	## returns true if a stage was gained
	var gained := false
	if level >= Data.MAX_LEVEL:
		return false
	exp += x
	while exp >= exp_need() and not Data.realm_cap(level):
		exp -= exp_need()
		level += 1
		gained = true
		heal_full()
		toast("Cultivation advanced: %s" % Data.level_name(level))
		note("Reached %s" % Data.level_name(level))
		level_changed.emit()
	if Data.realm_cap(level) and exp > exp_need():
		exp = float(exp_need())
	if gained:
		poll_steps()
	return gained

func record_kills(a: String, n: int, ids: Array = []) -> void:
	# (what falls is counted by kind: jobs.gd)
	for kid in ids:
		felled_kind[str(kid)] = int(felled_kind.get(str(kid), 0)) + 1
	# (the Answering Land release, weal.gd: what is cleared out of a country is felt in its towns)
	weal["kills|" + a] = int(weal.get("kills|" + a, 0)) + maxi(n, ids.size())
	# (the Higher Sky release: and the towns are told at once: weal.gd remembered the old answer until something
	# else moved, so the eightieth pack cleared out of a country brought it no peace until the next errand)
	weal_n += 1
	var s := cur_step()
	# (a hunt in a cave, Part XX, counts what is brought down in that cave)
	if not s.is_empty() and s.kind == "hunt" and s.area == a and (not s.has("cave") or layer == Caves.fid(a, int(s.cave))):
		# a hunt for particular foes (Part XIII: Chiyou's war-band) counts only those
		# (the Hundred Arms release: a hunt that asks for a weapon counts what falls while it is in the hand)
		if s.has("arm") and str(s.arm) != Arms.held(self):
			n = 0
		elif s.has("of") and not ids.is_empty():
			n = ids.filter(func(id): return str(id) in s.of).size()
		elif s.has("of"):
			n = 0
		hunt += n
		poll_steps()

func do_breakthrough() -> void:
	level += 1
	exp = 0.0
	heal_full()
	toast("Breakthrough! %s" % Data.level_name(level))
	note("Breakthrough to %s" % Data.level_name(level))
	level_changed.emit()
	poll_steps()

func med_rate(near_spring: bool) -> float:
	# an Enlightened Mind goes deeper into every meditation
	return (3.0 + 1.2 * level) * (3.0 if near_spring else 1.0) * (1.0 + talent_mod("med")) * Works.mod(self, "med") * Channels.mod(self, "med")

# ---------------------------------------------------------------- quests
func cur_step() -> Dictionary:
	if step >= Data.STEPS.size():
		return {}
	return Data.STEPS[step]

func reached(id: String) -> bool:
	return id == "" or step >= Data.step_index(id)

func done(id: String) -> bool:
	return id == "" or step > Data.step_index(id)

func advance() -> void:
	var s := cur_step()
	if s.is_empty():
		return
	stones += int(s.get("stones", 0))
	if s.get("stones", 0) > 0:
		toast("+%d spirit stones" % s.stones)
	toast("Quest complete: %s" % s.t)
	note("Quest complete: %s" % s.t)
	if Data.DIALOGUE.has("done:" + str(s.id)):
		done_pending.append(str(s.id))
	# a crossroads of the road waits behind this step (echoes.gd): asked once Lin Feng is free to answer
	for cid in Echoes.ORDER:
		if str(Echoes.CROSSROADS[cid].step) == str(s.id) and not picks.has(cid) and not cross_pending.has(cid):
			cross_pending.append(cid)
	# the story sets the hour here and there (clock.gd)
	Clock.story_hour(self, str(s.id))
	# (and the day of the year, almanac.gd)
	Almanac.story_date(self, str(s.id))
	# help given in the land of one of the peoples of the realms (Part XI) earns their standing
	for race in Data.AREAS.get(str(s.get("area", "")), {}).get("races", []):
		race_gain(race, 8 if s.kind == "kill" else 5)
	# (the Tall People release: a step done for a people who have no country of their own names them)
	if s.has("race"):
		race_gain(str(s.race), 8 if s.kind == "kill" else 5)
	# and what is done among a hearth of the land for its own people (cultures.gd): a step that names
	# its hearth is a deed for it; a word, an errand or a scene in its country is a small one
	if s.has("hearth"):
		# (echoes.gd: a keeper of the old ways is thanked a little more at every hearth)
		add_hearth(str(s.hearth), Cultures.DEED + int(Echoes.lean_mod(self, "hearth")))
	elif str(s.kind) in ["talk", "folk", "share", "visits", "rally"]:
		add_hearth(Cultures.of_area(str(s.get("area", ""))), 1)
	# an outfit or a ride the story gives here (the Elder's robe, the flying sword, an immortal's cloud)
	for rw in Fashion.step_rewards(str(s.id)):
		if rw[0] == "outfit":
			grant_outfit(str(rw[1]))
		else:
			grant_ride(str(rw[1]))
	# and a weapon (arms.gd): Iron Fang's sabre, the Empress's fan
	for aid in Arms.step_rewards(str(s.id)):
		grant_arm(str(aid))
	# (the Heavy Road release: what somebody puts into his hands when a step is done: an axe, a rod)
	for gk in s.get("gives", {}):
		add_item(str(gk), int(s.gives[gk]))
		toast("Given: %s" % str(Data.ITEMS[str(gk)].n))
	step += 1
	# (the Higher Sky release, betters.gd: the story forks where he met somebody above him; a step of the other
	# branch is stepped over)
	step = Betters.skip(self, step)
	# (memoir.gd: and what one of them had to say of it is written down)
	Memoir.written(self)
	step_raids = 0
	step_supply = 0
	step_terra = 0
	step_did = {}
	step_fit = 0
	step_toil = 0
	step_restore = 0
	step_leap = 0
	step_rite = 0
	step_haul = 0
	step_sunder = 0
	step_cook = 0
	step_phase = 0
	step_bid = 0
	step_cards = 0
	# the Three Burrows release (hold.gd): the town is founded when its steward has been heard out
	if str(s.id) == Hold.FOUND_STEP:
		Hold.found(self)
	hunt = 0
	step_uses = {}
	step_glide = 0
	# a step that asks for visits starts with nobody visited: somebody called on in an earlier chapter
	# (Smith Tie at the New Year, Auntie Rong with the new fire) is called on again
	var ns := cur_step()
	if not ns.is_empty() and str(ns.kind) == "visits":
		for vn in ns.get("npcs", []):
			visited.erase(vn)
	# (a step that asks to go and look at things that stand counts, if it says "new", only what is looked
	# at from now on: by Part XXVI a journey has looked at as many as it asks, and the step was done at once)
	if not ns.is_empty() and str(ns.kind) == "marks" and bool(ns.get("new", false)):
		marks_from = marks_seen.size()
	# (weal.gd: a step that asks for towns to be left the better counts from how they stand as it begins)
	if not ns.is_empty() and str(ns.kind) == "weal":
		Weal.mark_from(self)
	if step >= Data.STEPS.size():
		finished = true
		note("Ascended")
	# (the Answering Land release, weal.gd: a town whose state the story has just changed is news)
	Weal.poll(self)
	quest_changed.emit()
	poll_steps()

func poll_steps() -> void:
	var guard := 0
	while guard < 8:
		guard += 1
		var s := cur_step()
		if s.is_empty():
			return
		var ok := false
		match s.kind:
			"level":
				ok = level >= s.lv
			"collect":
				ok = inv.get(s.item, 0) >= s.n
			"hunt":
				ok = hunt >= s.n
			"breakthrough":
				ok = level >= s.to and not finished
			"gates":
				# Part XIII: any of the Eight Gates, in any order
				ok = gates_open.size() >= int(s.n)
			"visits", "fates":
				# any of the people named, in any order (Part XIII's invitations, Part XIV's five threads)
				ok = visits_done(s) >= int(s.n)
			"grudges":
				# Part XIV: the grudges that stayed, in any order, each fought and then answered
				ok = grudges.size() >= int(s.n)
			"memories":
				# Part XV: Yue Ling's memories, any of them, in any order (bonds.gd)
				ok = memories.size() >= int(s.n)
			"threads":
				# Part XV: the people who tied a thread for her, any of them, in any order
				ok = visits_done(s) >= int(s.n)
			"rally":
				# Part XVI: the towns reminded of the old ways, any of them, in any order
				ok = visits_done(s) >= int(s.n)
			"folk":
				# Part XVI: so many of the people of the towns (folk.gd) of one kind, any of them
				ok = folk_count(s) >= int(s.n)
			"clear":
				# Part XVII: so many of the obstacles of one kind in a region cleared with the sword
				ok = cleared_count(s) >= int(s.n)
			"works":
				# Part XIX: so many works built with his own hands, any of them (works.gd)
				ok = Works.count(self) >= int(s.n)
			"delve":
				# Part XX: so many caves gone to the very back of, any of them (caves.gd)
				ok = delved.size() >= int(s.n)
			"try":
				# Part XX: so many of the things of a cave done (props.gd), any of them or those named
				ok = tried_count(s) >= int(s.n)
			"arms":
				# Part XXI: so many Daos of arms learned to Adept (arms.gd)
				ok = Arms.adept(self) >= int(s.n)
			"summit":
				# Part XXII: the very top of a region's highest peak (`peak`), or so many summits, any of
				# them (peaks.gd)
				ok = summits.has("peak:%s:%d" % [str(s.peak), int(s.get("k", 0))]) if s.has("peak") else summits.size() >= int(s.n)
			"glide":
				# Part XXII: one flight under the cloud-kite of so many tiles, made since the step began
				ok = step_glide >= int(s.n)
			"jobs":
				# Part XXIII: so many commissions of the notice board done, any of them (jobs.gd)
				ok = Jobs.done_count(self) >= int(s.n)
			"airs":
				# Part XXIII: so many airs of the hearths learned (music.gd)
				ok = airs.size() >= int(s.n)
			"host":
				# Part XXIII: so many companies in the host (war.gd)
				ok = War.companies(self).size() >= int(s.n)
			"reckon":
				# the reckoning (reckon.gd): everybody the journey's choices made has been met
				ok = Reckon.left(self).is_empty()
			"falls":
				# Part XXIV: so many packs of what cannot be beaten stood in front of, and lost to (dooms.gd)
				ok = hunt >= int(s.n)
			"marks":
				# Part XXIV: so many of the things his choices left standing gone and looked at (marks.gd)
				ok = marks_count(s) >= int(s.n)
			"fit":
				# Part XXIX: so many houses put to rights since the step began (fitting.gd)
				ok = step_fit >= int(s.n)
			"restore":
				# Part XXXIV: so many lost things brought to whose they are since the step began (trifles.gd)
				ok = step_restore >= int(s.n)
			"rite":
				# the Uncarved Block release (rites.gd): so many rites of his Daos performed since the step began
				ok = step_rite >= int(s.n)
			"leap":
				# Part XXXIV: so many leaps made since the step began (world.gd)
				ok = step_leap >= int(s.n)
			"toil":
				# Part XXVII: the work of the hands done so many times since the step began (toil.gd)
				ok = step_toil >= int(s.n)
			"haul":
				# Part XXVII: so many of a good of the land brought to somebody (toil.gd, load.gd)
				ok = step_haul >= int(s.n)
			"sunder":
				# Part XXXVI (sunder.gd): so many things of the land broken since the step began, or (with `max`) so
				# many blows that broke something and no more than that
				ok = step_sunder >= int(s.n)
			"cook":
				# Part XXXVI (cooking.gd): so many meals cooked since the step began
				ok = step_cook >= int(s.n)
			"phase":
				# Part XXXVII (phases.gd): so many things of the land turned by a phase since the step began (or
				# so many times one phase overcame another, or was fed by it)
				ok = step_phase >= int(s.n)
			"seal":
				# Part XXXIX (seals.gd): so many papers of the Hall of Seals held
				ok = Seals.count(self) >= int(s.n)
			"meet":
				# Part XXXIX (lists.gd): a meet fought to an end, at whatever place
				ok = Lists.finished(self, str(s.meet))
			"bid":
				# Part XXXIX (auction.gd): so many lots won in an auction room since the step began
				ok = step_bid >= int(s.n)
			"cards":
				# Part XL (yezi.gd): so many hands of leaves won since the step began; with `of`, that master beaten
				ok = (int(cards.get(str(s.of), {}).get("won", 0)) > 0) if s.has("of") else step_cards >= int(s.n)
			"braid":
				# Part XL (braid.gd): so many roads held at once
				ok = Braid.count(self) >= int(s.n)
			"rescue":
				# Part XLI (raids.gd): so many raids on the roads and the camps broken since the step began
				ok = step_raids >= int(s.n)
			"sect":
				# Part XLI (sects.gd): so many tasks done for one of the sects of the Rivers and Lakes
				ok = Sects.done_count(self, str(s.sect)) >= int(s.n)
			"supply":
				# Part XLII (mills.gd): so many crates carried from one works to another since the step began
				ok = step_supply >= int(s.n)
			"sights":
				# Part XLII (deeps.gd): so many places of the sea floor found in the step's country
				ok = Deeps.found_in(self, str(s.get("area", ""))) >= int(s.n)
			"terra":
				# Part XLII (terra.gd): so many askings the ground answered since the step began
				ok = step_terra >= int(s.n)
			"train", "craft", "tame", "fetch", "retreat":
				# Part XLIII (channels.gd, crafts.gd, pets.gd, retreats.gd): so many points of the chart opened,
				# things made, beasts asked to stay, loads a beast brought back, sittings in a place of peace,
				# since the step began
				ok = int(step_did.get(str(s.kind), 0)) >= int(s.n)
			"weal":
				# Part XXVIII: so many towns of the land left the better for his coming since the step
				# began (weal.gd)
				ok = Weal.bettered(self) >= int(s.n)
			"hold":
				# Part XXV: the town that is his own has what the step asks of it (hold.gd): so many plots
				# built, a plot, a rank, so many households
				ok = Hold.need_met(self, s.need)
		if not ok:
			return
		if s.kind == "breakthrough":
			return # handled explicitly by main after the cutscene
		advance()

## Part XXIV: how many things that stand a "marks" step has seen looked at (since it began, if it says
## "new").
func marks_count(s: Dictionary) -> int:
	return marks_seen.size() - (marks_from if bool(s.get("new", false)) else 0)

## Part XX: how many of the things a "try" step asks for have been done since it began (any of the
## things of a cave, or the kinds it names).
func tried_count(s: Dictionary) -> int:
	var n := 0
	for k in step_uses:
		if (s.has("things") and str(k) in s.things) or (not s.has("things") and CaveThings.KINDS.has(str(k))):
			n += 1
	return n

## The High Roads: Lin Feng has stood on the very top of a peak: it is remembered, and it is news the
## first time.
func summit(pid: String, peak_name: String, height: float) -> void:
	if summits.has(pid):
		return
	summits[pid] = true
	note("Stood on %s (%d m)" % [peak_name, int(round(height))])
	toast("The summit of %s, %d metres up (%d summit%s)" % [peak_name, int(round(height)), summits.size(), "" if summits.size() == 1 else "s"])
	poll_steps()

## A flight under the kite has ended: `tiles` flown, `fell` metres come down.
func glide_done(tiles: int, fell: float) -> void:
	if tiles > glide_best:
		glide_best = tiles
	glide_drop = maxf(glide_drop, fell)
	step_glide = maxi(step_glide, tiles)
	if tiles >= 12:
		note("Flew %d metres under the cloud-kite" % (tiles * 2))
	poll_steps()

## Part XX: Lin Feng has been to the very back of a cave (he found what was left there): it is
## remembered, and it is news the first time.
func delve(fid: String, cave_name: String) -> void:
	if delved.has(fid):
		return
	delved[fid] = true
	note("Went to the very back of %s" % cave_name)
	toast("To the back of %s (%d cave%s)" % [cave_name, delved.size(), "" if delved.size() == 1 else "s"])
	add_renown(1)
	poll_steps()

func objective_text() -> String:
	# the beginning (cultures.gd): the farewell at the hero's own hearth
	if prologue != "" and Cultures.HEARTHS.has(prologue):
		var hh: Dictionary = Cultures.HEARTHS[prologue]
		return "Three years ago, at %s: say goodbye to %s" % [str(hh.n), Trials.npc_name(str(hh.keeper))]
	var s := cur_step()
	if s.is_empty():
		return "The journey is complete."
	var t: String = s.t
	if s.kind == "collect":
		t += "  (%d/%d)" % [mini(inv.get(s.item, 0), s.n), s.n]
	elif s.kind == "hunt" or s.kind == "falls":
		t += "  (%d/%d)" % [mini(hunt, s.n), s.n]
	elif s.kind == "marks":
		t += "  (%d/%d)" % [mini(marks_count(s), int(s.n)), int(s.n)]
	elif s.kind == "weal":
		t += "  (%d/%d)" % [mini(Weal.bettered(self), int(s.n)), int(s.n)]
	elif s.kind == "hold":
		var hp: Array = Hold.need_progress(self, s.need)
		t += "  (%d/%d)" % [int(hp[0]), int(hp[1])]
	elif s.kind == "gates":
		t += "  (%d/%d)" % [mini(gates_open.size(), int(s.n)), int(s.n)]
	elif s.kind == "visits" or s.kind == "fates":
		t += "  (%d/%d)" % [mini(visits_done(s), int(s.n)), int(s.n)]
	elif s.kind == "grudges":
		t += "  (%d/%d)" % [mini(grudges.size(), int(s.n)), int(s.n)]
	elif s.kind == "memories":
		t += "  (%d/%d)" % [mini(memories.size(), int(s.n)), int(s.n)]
	elif s.kind == "threads" or s.kind == "rally":
		t += "  (%d/%d)" % [mini(visits_done(s), int(s.n)), int(s.n)]
	elif s.kind == "folk":
		t += "  (%d/%d)" % [mini(folk_count(s), int(s.n)), int(s.n)]
	elif s.kind == "summit" and not s.has("peak"):
		t += "  (%d/%d)" % [mini(summits.size(), int(s.n)), int(s.n)]
	elif s.kind == "glide":
		t += "  (%d/%d m)" % [mini(step_glide, int(s.n)) * 2, int(s.n) * 2]
	elif s.kind == "clear":
		t += "  (%d/%d)" % [mini(cleared_count(s), int(s.n)), int(s.n)]
	elif s.kind == "works":
		t += "  (%d/%d)" % [mini(Works.count(self), int(s.n)), int(s.n)]
	elif s.kind == "delve":
		t += "  (%d/%d)" % [mini(delved.size(), int(s.n)), int(s.n)]
	elif s.kind == "try":
		t += "  (%d/%d)" % [mini(tried_count(s), int(s.n)), int(s.n)]
	elif s.kind == "arms":
		t += "  (%d/%d)" % [mini(Arms.adept(self), int(s.n)), int(s.n)]
	elif s.kind == "sunder":
		t += "  (%d/%d)" % [mini(step_sunder, int(s.n)), int(s.n)]
	elif s.kind == "cook":
		t += "  (%d/%d)" % [mini(step_cook, int(s.n)), int(s.n)]
	elif s.kind == "phase":
		t += "  (%d/%d)" % [mini(step_phase, int(s.n)), int(s.n)]
	elif s.kind == "toil":
		t += "  (%d/%d)" % [mini(step_toil, int(s.n)), int(s.n)]
	elif s.kind == "restore":
		t += "  (%d/%d%s)" % [mini(step_restore, int(s.n)), int(s.n), ", %d in his sleeve" % Trifles.carried(self).size() if not Trifles.carried(self).is_empty() else ""]
	elif s.kind == "rite":
		t += "  (%d/%d)" % [mini(step_rite, int(s.n)), int(s.n)]
	elif s.kind == "leap":
		t += "  (%d/%d)" % [mini(step_leap, int(s.n)), int(s.n)]
	elif s.kind == "fit":
		t += "  (%d/%d)" % [mini(step_fit, int(s.n)), int(s.n)]
	elif s.kind == "haul":
		t += "  (%d/%d, %d carried)" % [mini(step_haul, int(s.n)), int(s.n), Toil.on_hand(self, s)]
	elif s.kind == "seal":
		t += "  (%d/%d)" % [mini(Seals.count(self), int(s.n)), int(s.n)]
	elif s.kind == "bid":
		t += "  (%d/%d)" % [mini(step_bid, int(s.n)), int(s.n)]
	elif s.kind == "cards" and not s.has("of"):
		t += "  (%d/%d)" % [mini(step_cards, int(s.n)), int(s.n)]
	elif s.kind == "braid":
		t += "  (%d/%d)" % [mini(Braid.count(self), int(s.n)), int(s.n)]
	elif s.kind == "rescue":
		t += "  (%d/%d)" % [mini(step_raids, int(s.n)), int(s.n)]
	elif s.kind == "supply":
		t += "  (%d/%d)" % [mini(step_supply, int(s.n)), int(s.n)]
	elif s.kind == "sights":
		t += "  (%d/%d)" % [mini(Deeps.found_in(self, str(s.get("area", ""))), int(s.n)), int(s.n)]
	elif s.kind == "terra":
		t += "  (%d/%d)" % [mini(step_terra, int(s.n)), int(s.n)]
	elif s.kind in ["train", "craft", "tame", "fetch", "retreat"]:
		t += "  (%d/%d)" % [mini(int(step_did.get(str(s.kind), 0)), int(s.n)), int(s.n)]
	elif s.kind == "sect":
		t += "  (%d/%d)" % [mini(Sects.done_count(self, str(s.sect)), int(s.n)), int(s.n)]
	elif s.kind == "meet" and Lists.entered(self, str(s.meet)):
		t += "  (%s: %s)" % [str(Lists.ROUNDS[int(meets[str(s.meet)].round)].n), str(Data.ENEMIES[Lists.rival(self, str(s.meet))].n)]
	elif s.kind == "fate":
		t += "  - a fated encounter: Esc > Fates"
	if Trials.trial_of_step(s) != "" or s.kind == "gates":
		# a trial: more than one way to prepare for it (Esc > Journal)
		t += "  - a trial: Esc > Journal"
	return t

# ---------------------------------------------------------------- many roads (see trials.gd)
func renown_title() -> String:
	return Trials.renown_title(renown)

## The world thinks a little better of Lin Feng; a new title is news.
func add_renown(n: int) -> void:
	if n <= 0:
		return
	var before := Trials.renown_title(renown)
	renown += n
	var after := Trials.renown_title(renown)
	if after != before:
		toast("Renown: the world calls you %s" % after)
		note("Renown %d: %s" % [renown, after])

## Take path `pid` through the trial in front of boss `tid`: what it costs is paid now (once), and the
## path is returned for the battle.  An empty dictionary if it cannot be taken.
func take_path(tid: String, pid: String) -> Dictionary:
	var p := Trials.path(tid, pid)
	if p.is_empty() or not Trials.path_met(tid, p, self):
		return {}
	Trials.pay(tid, p, self)
	note("Faced %s %s: %s" % [Data.ENEMIES[tid].n, str(Trials.KINDS[p.kind].n).to_lower(), str(p.n)])
	return p

## A trial passed: remembered with the path that passed it, and the world hears of it.
func trial_won(tid: String, pid: String) -> void:
	trials[tid] = pid
	# (echoes.gd: a name that goes out from one valley comes back larger)
	add_renown(Trials.RENOWN_TRIAL + int(Echoes.lean_mod(self, "renown")))

## Make something at a cauldron or a forge.
func craft(id: String) -> bool:
	if not Trials.craft(id, self):
		return false
	toast("Crafted %s" % Data.ITEMS[id].n)
	note("Crafted " + str(Data.ITEMS[id].n))
	return true

## Do what a townsperson asked: they take what they wanted, pay what they can, and Lin Feng's name
## goes round.
func do_deed(id: String) -> bool:
	if deeds.has(id) or not Trials.deed_ready(id, self):
		return false
	var d: Dictionary = Trials.DEEDS[id]
	for k in d.want:
		inv[k] = int(inv.get(k, 0)) - int(d.want[k])
	deeds[id] = true
	stones += int(d.get("stones", 0))
	toast("Deed done: +%d renown, +%d spirit stones" % [int(d.renown), int(d.get("stones", 0))])
	note("A deed for %s" % Trials.npc_name(str(d.npc)))
	add_renown(int(d.renown) + int(Echoes.lean_mod(self, "renown")))
	return true

## How many of the people a "visits" step names Lin Feng has been to (for a "threads" step, Part XV:
## how many of them have tied a thread for Yue Ling).
func visits_done(s: Dictionary) -> int:
	var k := 0
	var seen_: Dictionary = threads if str(s.get("kind", "")) == "threads" else (rallied if str(s.get("kind", "")) == "rally" else visited)
	for id in s.get("npcs", []):
		if seen_.has(id):
			k += 1
	return k

## Part XVI: the townsfolk Lin Feng has done what step `s` asked with, and whether `id` is one.
func folk_count(s: Dictionary) -> int:
	return (folk_done.get(str(s.get("id", "")), {}) as Dictionary).size()

func folk_has(s: Dictionary, id: String) -> bool:
	return (folk_done.get(str(s.get("id", "")), {}) as Dictionary).has(id)

func folk_mark(s: Dictionary, id: String) -> void:
	var k := str(s.get("id", ""))
	if not folk_done.has(k):
		folk_done[k] = {}
	folk_done[k][id] = true

## Part XVII (impact.gd): how many obstacles of the kind a "clear" step names (`what`) are cleared in its
## region.
func cleared_count(s: Dictionary) -> int:
	var want := "%s|%s" % [str(s.get("what", "")), str(s.get("area", ""))]
	var n := 0
	for id in cleared:
		if str(cleared[id]) == want:
			n += 1
	return n

## Total essences of all kinds in hand.
func essences() -> int:
	var n := 0
	for k in Trials.ESSENCE_ORDER:
		n += int(inv.get(k, 0))
	return n

# ---------------------------------------------------------------- who he is, what he wears and rides (fashion.gd)
func hero_name() -> String:
	return Fashion.full_name(hero)

## Set who the player made him at creation: name, look, colours and origin; the origin's keepsakes are
## given now, and so is the outfit a hunter's orphan grew up in.
func create_hero(h: Dictionary) -> void:
	hero = Fashion.default_hero()
	for k in h:
		hero[k] = h[k]
	UI.set_hero_name(str(hero.family), str(hero.given), Fashion.fem(hero))
	# the hearth of the year away (cultures.gd): kin there from the first day, and its keepsakes
	var hid := Cultures.own(self)
	hearth = {hid: Cultures.KIN}
	var hh: Dictionary = Cultures.HEARTHS[hid]
	for k0 in hh.give:
		if k0 == "stones":
			stones += int(hh.give[k0])
		else:
			add_item(k0, int(hh.give[k0]))
	var o := Fashion.origin_of(self)
	for k2 in o.give:
		if k2 == "stones":
			stones += int(o.give[k2])
		else:
			add_item(k2, int(o.give[k2]))
	for oid in Fashion.OUTFITS:
		if str(Fashion.OUTFITS[oid].get("origin", "")) == str(hero.origin):
			outfits[oid] = true
	# the dantian and body the origin gives start full
	hp[0] = float(max_hp(0))
	qi[0] = float(max_qi(0))
	note("%s, %s, kin %s, sets out" % [hero_name(), Voice.her(str(o.short)) if Fashion.fem(hero) else str(o.short), str(hh.short)])

## Whether the hero is a woman (character creation), and one word or the other by it.
func fem() -> bool:
	return Fashion.fem(hero)

func gw(m: String, f: String) -> String:
	return f if fem() else m

## Standing earned with a hearth of the land (cultures.gd): told when it makes the hero a guest or kin.
func add_hearth(id: String, n: int) -> void:
	var t := Cultures.earn(self, id, n)
	if t > 0:
		toast(Cultures.welcome(id, t))
		note("%s of %s" % [Cultures.tier_name(t), str(Cultures.HEARTHS[id].n)])

## The first time the hero sits down with one of a hearth's named people (talk_npc).
func sit_with(npc: String) -> void:
	var id := Cultures.of_npc(npc)
	if id == "" or sat.has(npc) or prologue != "":
		return
	sat[npc] = true
	add_hearth(id, Cultures.SIT)

func grant_outfit(id: String) -> void:
	if outfits.has(id) or not Fashion.OUTFITS.has(id):
		return
	outfits[id] = true
	toast("New outfit: %s (Esc > Wardrobe)" % Fashion.OUTFITS[id].n)
	note("Received the " + str(Fashion.OUTFITS[id].n))

## Put on an outfit he owns: the passives change at once, and the health and qi it widens are filled.
func wear(id: String) -> bool:
	if not outfits.has(id) or id == outfit:
		return false
	var hp_r: float = hp[0] / float(max_hp(0))
	var qi_r: float = qi[0] / float(max_qi(0))
	outfit = id
	worn[id] = true
	hp[0] = minf(float(max_hp(0)), float(max_hp(0)) * hp_r)
	qi[0] = minf(float(max_qi(0)), float(max_qi(0)) * qi_r)
	note("Dressed in the " + str(Fashion.OUTFITS[id].n))
	return true

## The Thundering Pots release: a dress for Yue Ling (fashion.gd YUE_OUTFITS).
func grant_yue_outfit(id: String) -> void:
	if yue_outfits.has(id) or not Fashion.YUE_OUTFITS.has(id):
		return
	yue_outfits[id] = true
	toast("A new dress for Yue Ling: %s (Esc > Wardrobe)" % Fashion.YUE_OUTFITS[id].n)
	note("Yue Ling was given the " + str(Fashion.YUE_OUTFITS[id].n))

func wear_yue(id: String) -> bool:
	if not yue_outfits.has(id) or id == yue_outfit:
		return false
	var hp_r: float = hp[1] / maxf(1.0, float(max_hp(1)))
	var qi_r: float = qi[1] / maxf(1.0, float(max_qi(1)))
	yue_outfit = id
	hp[1] = float(max_hp(1)) * hp_r
	qi[1] = float(max_qi(1)) * qi_r
	note("Yue Ling wears the " + str(Fashion.YUE_OUTFITS[id].n))
	return true

## The dresses of hers the journey has earned (how close the two are, the steps of the story done).
func poll_wardrobe() -> void:
	if not companion:
		return
	for id in Fashion.yue_earned(self):
		grant_yue_outfit(str(id))

## What a feat, a commission or a find gives to wear (fashion.gd `feat`, `job`, `egg`).
func grant_earned(kind: String, id: String) -> void:
	for rw in Fashion.earned_by(kind, id):
		if str(rw[0]) == "outfit":
			grant_outfit(str(rw[1]))
		else:
			grant_yue_outfit(str(rw[1]))

# ---------------------------------------------------------------- the Eight Arms (arms.gd)
func grant_arm(id: String) -> void:
	if arms.has(id) or not Arms.WEAPONS.has(id):
		return
	arms[id] = true
	toast("New weapon: %s (Esc > Arms)" % Arms.WEAPONS[id].n)
	note("Took up " + str(Arms.WEAPONS[id].n).trim_prefix("The ").insert(0, "the ") if str(Arms.WEAPONS[id].n).begins_with("The ") else "Took up " + str(Arms.WEAPONS[id].n))

## Take a weapon he owns into his hand: its own blow, its own Dao and that Dao's passives, at once.
func wield(id: String) -> bool:
	if not arms.has(id) or id == arm or not Arms.WEAPONS.has(id):
		return false
	arm = id
	arm_switches += 1
	arm_xp[id] = int(arm_xp.get(id, 0))
	note("Took %s in hand" % str(Arms.WEAPONS[id].zh))
	quest_changed.emit()
	return true

## A battle won with a weapon in the hand deepens that weapon's Dao (a lord four times as much).
func arm_battle_won(boss: bool) -> void:
	var id := Arms.held(self)
	var before := Arms.tier(self, id)
	arm_xp[id] = int(arm_xp.get(id, 0)) + (4 if boss else 1)
	var after := Arms.tier(self, id)
	if after > before:
		var w: Dictionary = Arms.WEAPONS[id]
		toast("%s of the %s" % [Data.DAO_RANKS[after], w.dao.n])
		note("Became %s of the %s" % [Data.DAO_RANKS[after], w.dao.n])
		add_renown(1)
		if after == 1:
			toast("New technique: %s" % Data.SKILLS[str(w.skill)].n)
			# (the Uncarved Block release, rites.gd: an Adept of a weapon's Dao has its rite)
			Rites.earn(self, Rites.of_arm(id))
		poll_steps()

func grant_ride(id: String) -> void:
	if rides.has(id) or not Fashion.RIDES.has(id):
		return
	rides[id] = true
	toast("New ride: %s (Esc > Stable, R to ride)" % Fashion.RIDES[id].n)
	note("Gained a ride: " + str(Fashion.RIDES[id].n))
	# the first ride is saddled at once; a faster one replaces a slower one he was using
	if ride == "" or float(Fashion.RIDES[id].speed) > float(Fashion.RIDES[ride].speed):
		ride = id

## A small choice of the road (fate.gd PICKS) made: remembered for the rest of the game.
func pick(id: String, option: String) -> void:
	picks[id] = option
	note("Chose: %s" % option)

# ---------------------------------------------------------------- items
func add_item(id: String, n: int = 1) -> void:
	inv[id] = inv.get(id, 0) + n

func lowest_member() -> int:
	var best := 0
	var br := 2.0
	for i in party_size():
		var r: float = hp[i] / float(max_hp(i))
		if r < br:
			br = r
			best = i
	return best

func use_item_field(id: String) -> String:
	if inv.get(id, 0) <= 0:
		return "You have none."
	var i := lowest_member()
	if id == "hp_pill":
		if hp[i] >= max_hp(i) - 0.5:
			return "Everyone is already at full health."
		inv[id] -= 1
		hp[i] = minf(float(max_hp(i)), hp[i] + max_hp(i) * 0.4 * dao_mod("pill", 1.0) * Works.mod(self, "pill"))
		return "%s recovers health." % member_name(i)
	if id == "qi_pill":
		inv[id] -= 1
		var j := 0
		var lowest := 2.0
		for k in party_size():
			var r: float = qi[k] / float(max_qi(k))
			if r < lowest:
				lowest = r
				j = k
		if qi[j] >= max_qi(j) - 0.5:
			inv[id] += 1
			return "Everyone's qi is already full."
		qi[j] = minf(float(max_qi(j)), qi[j] + max_qi(j) * 0.5 * dao_mod("pill", 1.0) * Works.mod(self, "pill"))
		return "%s recovers qi." % member_name(j)
	# (the Sea Floor release, mills.gd: a thing made at one of the works of the sea floor: a share of health,
	# of qi, or of both, for whoever of the party is lowest)
	if Mills.USES.has(id):
		var u: Dictionary = Mills.USES[id]
		# (the Unblunted Knife release: a thing that only steadies the breath is for whoever is lowest in qi; it
		# used to ask the one lowest in health, and say nobody needed it while the other was drained)
		if u.has("qi") and not u.has("hp"):
			var lowq := 2.0
			for k in party_size():
				var rq: float = qi[k] / float(max_qi(k))
				if rq < lowq:
					lowq = rq
					i = k
		var need_hp: bool = u.has("hp") and hp[i] < max_hp(i) - 0.5
		var need_qi: bool = u.has("qi") and qi[i] < max_qi(i) - 0.5
		if not need_hp and not need_qi:
			return "Nobody has any need of it now."
		inv[id] -= 1
		if u.has("hp"):
			hp[i] = minf(float(max_hp(i)), hp[i] + max_hp(i) * float(u.hp))
		if u.has("qi"):
			qi[i] = minf(float(max_qi(i)), qi[i] + max_qi(i) * float(u.qi))
		return "%s is the better for it." % member_name(i)
	return ""

func respawn() -> void:
	deaths += 1
	stones = int(stones * 0.85)
	area = "sect"
	# a world tile: the sect's courtyard in front of the hall (Vector2i(20, 8) is the sect's own
	# tile, which used to be stored here as if it were a world tile)
	tile = Atlas.to_world("sect", Vector2i(20, 8))
	layer = "surface"
	heal_full()
	note("Defeated and carried back to the sect")
