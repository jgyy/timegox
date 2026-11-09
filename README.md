# Ascension of the Azure Cloud

A xianxia cultivation RPG built in **Godot 4**, played in **full 3D from a third-person view**, and **all art is generated from scripts**: every tree, building, character, monster and spell effect comes from code in this repository (GDScript, shaders and **Blender Python**), never from hand-made or downloaded files (see [Art pipeline](#art-pipeline)).
Play Lin Feng (or whoever you make him: name, look, colours and where he came from), an orphaned sect sweeper with a hidden "Nine Heavens root", from Qi Condensation to Ten Thousand Hearths, across **one open world in four realms**: a continent of 42 regions round Azure Cloud Mountain, ringed by the sea, with the **Nine Heavens** floating above it, the **Nine Springs** under it, joined by the Jianmu, the world tree, and now the **Isles of the Eastern Sea** out past the edge of its shelf, reached in Mazu's boat. It has 215 bosses, twenty-one Heavenly Tribulations, a sky that keeps the hours from dawn to the dead of night, eleven towns lived in by **219 townsfolk with days of their own**, things in the streets that really break, and 86 buildings you can walk into, with 17 upper storeys and 13 cellars among them. Wake the **nine branches** of the Nine Heavens root, open the Founder's **sealed caves** as your realm allows, choose your road among **six Daos**, earn the trust of **eight peoples** of the realms, change into **twelve outfits**, ride **six mounts and vehicles**, decide the fates of **five people** met on the road, and walk the whole way with **Yue Ling**, who has a story of her own now.

> **Total gameplay duration: about 19 hours 28 minutes** (19:28:20 of game time for the end-to-end bot run, seed 1234), **1 hour 4 minutes more than the last release** (18:23:43). **The land lives now.** The sky keeps the hours: the sun comes up in the east and goes down in the west, dusk warms the horizon, the night is deep blue with a moon and stars, and every lantern and window in the land glows after dark; the HUD tells the double-hour (the Hour of the Rabbit, the second watch). **219 townsfolk** live in the eleven towns, each with a name, a home and a day of their own: farmers hoe their fields at dawn, fishermen are on the shore before light, merchants call their wares, porters carry shoulder poles between the market and the gate, children go to the teacher and fly kites in the afternoon, the sect's disciples sweep the courtyards and practise sword forms, everybody goes home at dusk, and the watchmen walk the streets all night with a lantern and a gong, calling the watches. They walk to their work along the streets, do it on **six new work animations** and the thirty the party already had (lent to every person's rig), step aside for the hero, greet him as he passes, and talk when he faces them (Enter). The named townsfolk work at their own places too (the smith at his anvil, the cook at her stove) and doze there late at night. **Things break**: jars, crates, barrels, haystacks, woodpiles and handcarts stand about every town; **F** swings the sword and a gallop goes straight through them, and they come apart into rigid-body pieces that fly, tumble on the ground and get kicked about, while the owner is paid or has words, and everything is mended by dawn; battles scorch the ground they are fought on, and heavy blows throw up the floor of the arena. **Part XVI, "The Year Turns", plays in about 1 hour 3 minutes**: the first New Year the world has had time for, Nian and Xi, red, fire and noise, the people of five towns reminded of the old ways, a last night of the year that will not end until the Year Beast is driven out, and a new realm, **Ten Thousand Hearths**. Bugs were found and fixed.

| | |
|---|---|
| ![the Dawn Market at mid-morning: townsfolk crowd its shop fronts, and one of them knows the hero ("It's him!")](docs/screenshots/living_yanggu_market.png) | ![the same market in the second watch: lit windows and lanterns under the stars](docs/screenshots/living_yanggu_night.png) |
| ![the square of Qingshi from one place at dawn, noon, dusk and night](docs/screenshots/living_hours.png) | ![Qingshi in the Hour of the Dragon: villagers round the well and the pond, a seller calling "Fresh today!", a farmer off with his basket](docs/screenshots/living_qingshi_morning.png) |
| ![F: the sword meets a jar of pickles, it comes apart into rigid-body pieces, and its owner is paid](docs/screenshots/living_strike.png) | ![Zao Jun, Lord of the Stove, who would not go up the chimney](docs/screenshots/part16_kitchen_god.png) |
| ![a town reminded of the old ways: Yanggu turns out with every gong and pot, Night-Watchman Lao Zhou at the front](docs/screenshots/part16_drill.png) | ![Xi, the Last Night, faced with the door gods' peach wood](docs/screenshots/battle_boss_xi_beast.png) |
| ![the vigil at Granny Wen's: nobody stays up alone](docs/screenshots/part16_vigil.png) | ![Nian, the Year Beast, faced by every pot in the land](docs/screenshots/battle_boss_nian.png) |
| ![New Year's Day: the children in red, and a red envelope](docs/screenshots/part16_hongbao.png) | ![the first dawn of the year: the bell, a hundred and eight times](docs/screenshots/part16_dawn_bell.png) |

More captures (every region from the ground and from above, a boss battle in every region and more, model galleries, turnarounds, animation strips, Yue Ling following the hero, and portraits) are in [`docs/screenshots`](docs/screenshots).

## What changed in this release

```mermaid
flowchart LR
    subgraph DN[Day and night: clock.gd]
    CL[a clock of twelve double-hours:<br/>a day in about twenty minutes,<br/>the night twice as fast] --> SKY[dawn, day, dusk, night: the sun east to west,<br/>moon and stars, morning mist,<br/>lanterns and windows glow]
    CL --> HOLD[the story holds it: noon for nine days in Part IX,<br/>the last night of the year in Part XVI]
    CL --> BED[a bed after dark:<br/>sleep till six]
    end
    subgraph PE[The people of the towns: folk.gd]
    TW[11 towns, 219 people: farmers, fishers, merchants,<br/>porters, cooks, washers, scholars, monks, guards,<br/>watchmen, lamplighters, elders, children, disciples] --> DY[a day each: home, work,<br/>a meal, tea, home]
    DY --> WK[A* along the streets,<br/>round people's things]
    DY --> AN[work on clips lent to every rig:<br/>hoe, chop, carry, bang, call, eat<br/>and 30 more]
    TW --> TK[Enter: they talk; they greet him,<br/>step aside, call their wares]
    NP[the named townsfolk work at their posts,<br/>doze late at night]
    end
    subgraph HV[Things that break: havoc.gd]
    BR[jars, crates, barrels, baskets, haystacks,<br/>woodpiles, carts, pots, lanterns] -->|F, or a gallop| RB[rigid-body pieces on a<br/>height field of the ground]
    BR --> OW[the owner is paid or has words;<br/>mended by the next dawn]
    BT[battles scorch the ground;<br/>heavy blows throw up the arena]
    end
    subgraph P16[Part XVI: the Year Turns]
    ZJ[the Kitchen God would not go up] --> OLD{five of six towns<br/>reminded of the old ways}
    OLD --> XI[Xi, the Last Night:<br/>a trial] --> NI[Nian, the Year Beast:<br/>a trial] --> TTH((Ten Thousand<br/>Hearths))
    end
    PE -.->|By the people: a new<br/>way through trials| XI
    CL -.->|a night that will not end| NI
    DN --> GAME((Game))
    PE --> GAME
    HV --> GAME
    P16 --> GAME
    GAME --> BOT[bot: 19:28:20,<br/>CI needs 16 h]
```

- **Day and night** (`scripts/clock.gd`, new). The world keeps a clock (`Game.clock`, `Game.day`): by day a minute of the day goes by every second of play and by night two, so a whole day takes a little under twenty minutes. The hours are the twelve double-hours of the old reckoning (the Hour of the Rat is midnight, the Hour of the Rabbit dawn) and the five watches of the night, shown on a dial under the minimap with the sun or the moon on its arc of sky.
  - **The sky follows it** (`Look.at_hour`, `Look.apply_hour`): the sun rises in the east, stands in the south at noon and sets in the west, its light warm at dawn and dusk, with long shadows; dusk warms the horizon; the night is deep blue, lit by a moon (a pale disc with grey seas, drawn by the sky shader where the light is) and stars; morning brings a little mist into the valleys. Every region keeps its own colours as its day, and the places whose light is not the sun's (the Void, the Primordial Chaos, the land of the dead, the caverns under the roots, the Moon Palace) follow the hours less. Lanterns and lit windows glow brighter after dark (one shared material), the hero carries a little light of his own at night, and sunlit leaves and grass lose their glow (a `night_k` shader global). Battles are fought at the hour they were met.
  - **The story holds it**: in Part IX the sun stood at noon for nine days, and now it does on screen too, until Xihe and Chang'e agree to take turns and the sun goes down; in Part XVI the last night of the year will not end until Nian is driven out. A bed after dark is a night's sleep: he wakes at six.
- **The people of the towns** (`scripts/folk.gd`, new): **219 townsfolk** in the eleven towns (the sect is one), with names, homes and **a day each**. Farmers, fishermen, merchants and shopkeepers, porters, cooks, washerwomen, scholars, monks, guards, watchmen, lamplighters, casters, grandparents, children, the sect's outer disciples and their stewards; in Featherfall they are Yumin with wings, in Tearwater Pearl-Weepers with fins, in Shazhou caravan hands in desert hoods, and in Youdu shades, who keep the night as other towns keep the day.
  - **Their days**: each kind of person has a plan (`Folk.ROLES`: where they go at what hour and what they do there), and each person's own places come from their town's map (doorsteps of the right kind of building, open fields at the edge of town, the shore, the market, the town gate, the things to do in the street). Between places they **commute**, walking the streets by A* (roads preferred, round the houses and round other people's jars), at a walking pace that stays true by night; at home they are indoors and out of sight. Where everybody is, is a pure function of the clock, so a day is the same day for the bot, the tests and the screenshots.
  - **Their work, animated**: hoeing a field, fishing from the bank, calling their wares, lifting loads, carrying a shoulder pole, chopping wood, stirring a pot, sweeping, reading, writing, praying, sword forms, archery, flying kites, dancing and clapping, eating, and at night the watchman's gong: **six new clips** made in Blender with the rest (`art/lib/person.py`: hoe, chop, carry, bang, call, eat) and the thirty interaction clips the party already had. Every person shares one rig, so the clips Lin Feng carries are **lent to anybody** at run time (`Assets.lend_clips`), scaled to a child's smaller rig and without the bones a person does not have; with the tool for the job in their hands (a hoe, an axe, a rod, a broom, a ladle, a book, a basket, a shoulder pole, a gong, a taper, a lantern after dark).
  - **They are people**: they step aside when the hero walks through them, turn to him when he stops beside them, bow (or wave, if they are children) and say a word as he passes, and call out their wares or the watch over the street; face one and press **Enter** and they talk, about their work, the hour, the news of the town (the latest boss he put down) and, on New Year's Day, nothing but the New Year.
  - **22 new commoner models** (`art/characters/folk_*.py`), dressed for every kind of person and people, each **dyed** on the fly (the character shader takes a robe and a sleeve colour per person and keeps the folds and the baked shading), so a town of a few dozen people is a few dozen different people from a few dozen materials and no extra meshes.
  - **The named townsfolk work too** (`Folk.POSTS`): Smith Tie hammers at his anvil, Alchemist Mo stirs his cauldron, Auntie Zhou stirs and chops, Little Bai sweeps, the fishwife calls her fish, the storyteller tells his stories, the scholars read and write; late at night most of them doze where they stand (the watchman is the other way round). They keep their places (the story finds them there), stop when the hero comes near and turn to him.
- **Things that break** (`scripts/havoc.gd`, new): jars of pickles by the inn, crates, baskets of greens and stacks of pots at the shops, barrels at the smithy, haystacks, woodpiles and handcarts at the farmhouses, lanterns on poles at the shrines: **116** in all, a couple round the walls of every town building, off the roads and out of everybody's way.
  - **F swings the sword** at whatever is in front of the hero (it cuts the grass when it meets nothing), and **a gallop goes straight through** them; on foot he only jostles them. A thing that breaks comes apart into **rigid bodies** (shards, planks, staves, cabbages that bounce, logs that roll) that fly from the blow, tumble on a height field sampled from the terrain under them, are **kicked about** by the party walking through them, and fade.
  - **The people notice**: the townsfolk round about start; the owner of a thing broken on purpose is paid for it (a few spirit stones, more for a cultivator of a higher realm), one ridden through gets a piece of the owner's mind instead, and by the next dawn the owner has mended it.
  - **Fights leave their mark**: a battle won in the land scorches the ground it was fought on (and breaks the things beside it) for a few hours, and in the arena a heavy blow throws up chunks of the floor and burns a scar into it.
- **Part XVI, "The Year Turns"**, adds a chapter, a realm (**Ten Thousand Hearths**) and two trials (see [below](#part-xvi-the-year-turns)), and a new way through a trial: **By the people**, the towns that remember the old ways.
- **The bot** plays all of it: it buys red paper from the towns' merchants and a fish from their fishermen, asks Qingshi's farmers about their year, guesses the lantern riddles, gives red envelopes to the children and pays its respects to the grandparents by walking up to them, turning to them and pressing Enter as a player would (waiting for them to come out of doors when they are not), reminds five towns of the old ways, takes Xi with the door gods' peach wood and Nian with every pot in the land, and walks round people's belongings rather than galloping through them.
- **Code**: the game's GDScript grew from 44,004 to 47,461 lines (`scripts/clock.gd`, `scripts/folk.gd` and `scripts/havoc.gd` are new) and the Blender Python from 21,542 to 21,984 lines: 22 commoners, the Kitchen God and the two door gods are new characters, six new clips, and Lin Feng (all four looks) and Yue Ling are rebuilt with them. The tests grew from 1,879 to 2,132 lines (22,603 checks).
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

### Previous release: Yue Ling's own story, more to do and Part XV

```mermaid
flowchart LR
    subgraph YL[Yue Ling: closer, and her heart her own]
    T[30 heart-to-hearts, one or more in every<br/>chapter: T when she wants to talk] --> R{a reply}
    R -->|leans her heart| H[three futures: his Dao companion,<br/>the lotus of the mountain,<br/>or a road of her own]
    R -->|closer| C[Companion, Trusted Friend, Dear Friend,<br/>Kindred Spirit, Heart's Companion]
    W[15 wishes: sit on a bench, ring a bell,<br/>fly a kite, name the stars, a hot spring,<br/>a dance under lanterns...] -->|done together| C
    D[anything done side by side] --> C
    end
    subgraph TD[More to do, more to see]
    S[14 new kinds of thing, seven of them buildings:<br/>pavilion, watchtower, open-air stage, hot spring,<br/>millstone, archery butts, lantern green] --> AN[14 new animations,<br/>for both of them]
    A[the Founder's hermitage and its bathhouse:<br/>moon gates, round windows, a lotus finial,<br/>a pagoda tier, a steam louver, cedar baths]
    end
    subgraph P15[Part XV: the Thread She Never Had]
    E[nobody can remember<br/>her name] --> P[the lotus pond<br/>where she woke] --> J[Judge Cui: no page<br/>for the never-born] --> G[the moths among the graves,<br/>the Founder's echo]
    G --> LM[the loom she was woven on,<br/>in the Founder's hermitage] --> M{six of seven memories, any order:<br/>drive off the moths, do it together,<br/>answer her}
    M --> Q[the Moth-Queen] --> U[the Unweaver:<br/>a trial] --> TH{six people tie<br/>a thread for her}
    TH --> WA[Suo, Warden of the Lock:<br/>a trial] --> N{the first line<br/>of her life} --> FE[the naming feast] --> KD((Kindred Dao))
    end
    C -.->|Side by side: a new way<br/>through both trials| U
    H -.->|her heart's choice is marked| N
    YL --> GAME((Game))
    TD --> GAME
    P15 --> GAME
    GAME --> BOT[bot: 18:23:43,<br/>CI needs 16 h]
```

- **Yue Ling, the hero's partner, has a story of her own now** (`scripts/bonds.gd`, Esc > Yue Ling, **T** to talk to her). She has walked beside Lin Feng since the bamboo forest; now she talks back.
  - **Heart-to-hearts**: whenever the story has given her something to say (30 of them, at least one in every chapter from the bamboo forest to Part XV) the corner says *Yue Ling wants to talk (T)*. She talks about her name and the pond she woke beside, the dragon king who bowed lower to her than to him, the girl in rose a little to the left of every bearer in the Mirror Lake, Xu Fu looking for a cure for death, the hands that remember more than she does, the winter she lost, the chains she was kept in, being the Seal, never ageing, having no ancestors to queue for, the song about a boat that Lin Feng's mother hummed, the Weaver and the Herdboy, never having seen the sea, being frightened before the war god's grave, the threads on his wrists and none on hers; and every one ends with Lin Feng's reply, chosen by the player. With nothing waiting, T gets a word from her about wherever they are (all 51 regions).
  - **Her heart**: every reply leans her a little towards one of **three futures** (to walk beside him as his Dao companion; to stay on the mountain as the lotus of its pond, keeper of the door the Seal became; or to go out as the wandering healer she once only pretended to be), and at the end of Part XV she chooses, with the one her heart leans to marked.
  - **Closeness**, in five steps from Companion to Heart's Companion, grows with every heart-to-hearts, every **wish** of hers granted (15, opened as the story goes: sit with me on a bench, pour me a real cup of tea, ring a great bell right underneath, teach me to fish, play the qin and I'll play the flute, push me on a swing, name the stars with me, dance under lanterns, find me a hot spring, fly a red kite, do the sword form on a stage and I'll clap...), every thing done side by side and every memory given back to her. Closeness is a new way through the trials: **Side by side**.
- **More to do in the world, and more of it built** (`scripts/structures.gd`, `scripts/props.gd`): **14 new kinds of thing** to do, 86 more of them out of doors (356 in all, and 554 things to do with the furniture), most of them done **together** and some of them **buildings**:

  | Thing | What they do there |
  |---|---|
  | **Pavilion** (a hexagonal *ting* on a stone platform, its opening turned to the view) | sit side by side on the bench across it and watch the land go by |
  | **Watchtower** (four posts, cross-braced, a platform with a railing and a roof, a ladder up the front) | he climbs the ladder hand over hand, looks out over the region from the top with his hand shading his eyes, and climbs down; she waves from the bottom |
  | **Open-air stage** (a *xitai*: a raised stage under a hip roof on bracket sets, a painted screen with its two doors, red lanterns) | he performs a sword form on the boards, blade in hand; she claps every figure |
  | **Hot spring** (a ring of rocks, a bamboo spout, a screen, a stone lantern) | they soak side by side, arms on the rim, until their fingers wrinkle (health and qi restored) |
  | **Millstone** (the upper stone turns on the lower, with a push bar) | he walks round and round pushing the bar, and the stone turns with him |
  | **Archery butts** (a straw target on a tripod, a bow rack, a quiver) | he draws a horn bow and looses; the arrow stays in the target |
  | **Lantern green** (a stone dancing floor under strings of red lanterns on four poles) | they dance a sleeve dance together |
  | **Kite post**, **armillary sphere**, **sky lanterns**, **lotus lanterns** on a jetty, a **writing table**, a **flute** left on a rock, a **cedar bath** | fly a red kite (it climbs on its string and comes down after), lie back in the grass and watch the stars (the bronze rings turn), let a sky lantern go together (both lanterns rise and drift east), set a lotus lantern on the water (it drifts away), write a line of verse, play the bamboo flute (she dances to it), soak |

  **14 new animations** for both of them (built in Blender with the rest, `art/lib/person.py`): play the flute, a sleeve dance, fly a kite, watch the stars, let a sky lantern go, set a lantern on the water, write with a brush, draw a bow, soak, push, climb, look out, clap, and a sword form (the one thing done with the blade out). Yue Ling now plays her flute to his qin, pours her own tea and reads her own book. The bigger things stand in clearings of their own (the forest stands back from them), and every region has up to three of them, chosen by its theme.
- **New architecture**: the **Founder's Hermitage** under the Last Cave on Azure Cloud Mountain, where she wove Yue Ling, and its **bathhouse**: two new building styles with four new features any building can have: a **moon gate** (a round stone doorway with a carved name band) and round lattice windows, a bronze **lotus finial** on the ridge, a two-storey **pagoda tier** rising out of the roof, and a raised **steam louver** along the ridge of the bathhouse; and a new piece of furniture, the **cedar bath**.
- **Part XV, "The Thread She Never Had"**, adds a chapter, a realm (**Kindred Dao**) and two trials (see [below](#part-xv-the-thread-she-never-had)): when every thread went slack at the Wheel, Yue Ling, who was woven and never born, had none, and the world is tidying her away. Sit with her by the lotus pond where she woke; ask Judge Cui for a page; drive the moths that eat forgetting out of the Graveyard of Sword Saints; meet the **Founder's echo** (a new Blender-built character); sit at the loom she was woven on, in the Founder's hermitage; give back **six of the seven memories** the Founder pressed where Yue Ling was happiest with the bearers before him (in any order, each guarded, each a scene the two of them play out together); face the **Moth-Queen of Forgetting** and **the Unweaver**; ask six of the people who knew her (her friends among them) to tie a thread for her; face **Suo, Warden of the Lock**; at the lotus pond let her write the first line of her own life; and give the sect a sword form at her naming feast.
- **The bot** plays all of it: it hears out every heart-to-heart as soon as she wants one and answers by a plan (`TALK_PLAN`) that leans her heart all three ways, grants her wishes when a thing that can grant one stands near its road, goes round six of the memories (`MEMORY_ROUTE`, `MEMORY_PLAN`), takes the Unweaver **side by side** and the Warden with the Key of the Open Door, and lets her write the future her heart leans to. In the verified run (seed 1234) it plays the whole game in **18:23:43**, **1 hour 1 minute more than the last release** (17:22:16).
- **Code**: the game's GDScript grew from 41,154 to 44,004 lines (`scripts/bonds.gd` and `scripts/structures.gd` are new) and the Blender Python from 21,088 to 21,542 lines: the Founder's echo is a new character, and Lin Feng (all four looks) and Yue Ling were rebuilt from their scripts with the fourteen new clips.
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

| | |
|---|---|
| ![a heart-to-heart in the courtyard: "Do you still want me beside you, now you know what I am?"](docs/screenshots/talk_seal.png) | ![a memory given back: what do you say to her?](docs/screenshots/memory_choice.png) |
| ![the lantern green: a sleeve dance under strings of red lanterns](docs/screenshots/lotus_lantern_green.png) | ![the armillary sphere in the Void Rift: lying back to watch the stars](docs/screenshots/lotus_armillary.png) |
| ![the millstone in Heaven's Forge: pushed round and round](docs/screenshots/lotus_millstone.png) | ![lotus lanterns set on the water together, in the Stone Forest](docs/screenshots/lotus_river_lantern.png) |
| ![a red kite high over the Cloud-Tea Terraces, at Chun's kite post](docs/screenshots/kite_sky.png) | ![the Echo of Founder Qing Lian, threading a needle by her barrow](docs/screenshots/founder_echo.png) |
| ![the hermitage's moon gate](docs/screenshots/hermitage_gate.png) | ![Suo, Warden of the Lock, and the Key of the Open Door](docs/screenshots/battle_lock_warden.png) |
| ![the moths that eat forgetting](docs/screenshots/battle_forgetting.png) | ![the new things to do, in use](docs/screenshots/props_lotus_sheet_0.png) |

### Previous release: fates and faces, outfits, rides and Part XIV

```mermaid
flowchart LR
    subgraph CC[Character creation]
    NG[New Game] --> MK[name, look, hair, eyes,<br/>robe, origin] --> J((the journey))
    MK -.->|origin| OL[a strength, a weakness,<br/>a keepsake, lines of its own]
    end
    subgraph FA[Fated encounters: five people, five meetings each]
    C1[Part I: Tala, Qiu Ye,<br/>Little Hu, Xu Lan, Liu Ying] --> CH{a choice at<br/>every meeting}
    CH -->|the state it leaves them in| C2[Parts III-XII: the next<br/>chapter is written for it]
    C2 --> CH
    CH -->|a battle, a ride, an outfit,<br/>a cheaper cauldron| R[rewards and costs]
    CH -->|the right state| BO[a way through a trial:<br/>By an old bond]
    C2 --> F14[Part XIV: friends come to the Wheel,<br/>enemies are fought, spared or fall]
    end
    subgraph LO[Every foe has a story]
    B1[355 foes] --> BC[first meeting: its story<br/>over the battle's opening]
    B1 --> BS[every boss: who it was,<br/>told before the fight]
    BC & BS --> BE[the Bestiary]
    end
    subgraph RD[Wardrobe and stable]
    OU[12 outfits: colours, hats,<br/>crowns, pauldrons, a passive] --> W[Esc > Wardrobe]
    RI[6 rides: horse, qilin, tiger,<br/>flying sword, cloud, sky-barque] --> S[R to ride, Esc > Stable]
    end
    subgraph P14[Part XIV: the Ripening of Karma]
    E[the Elder: every cause<br/>comes home] --> JC[Judge Cui at the Wheel] --> GR[the grudges round its rim]
    GR --> FV{settle the five,<br/>in any order} --> MI[the Mirror again:<br/>six grudges that stayed]
    MI --> GS{lay each to rest where<br/>it fell, in any order:<br/>pay it, a friend answers,<br/>or leave it to the Wheel}
    GS -->|unpaid grudges feed Nie| NIE[Nie, the Unpaid:<br/>a trial] --> KF((Karma Fulfilled))
    end
    CC --> GAME((Game))
    FA --> GAME
    LO --> GAME
    RD --> GAME
    P14 --> GAME
    GAME --> BOT[bot: 17:22:16,<br/>CI needs 16 h]
```

- **Character creation** (`scripts/create.gd`, `scripts/fashion.gd`). New Game no longer drops you straight onto the steps: first, over the moonlit cliff of the title screen, you make the sweeper. **Name** him (from the sect's rolls with Left/Right, or Enter to type your own: the story then calls him by it everywhere, Granny Wen's "Feng'er" and the juniors' "Senior Brother Lin" included, while the data keeps the name it was written with), choose his **look** (four Blender builds of the same rig: the Sweeper's topknot, the Wanderer's braid, the Wild Child's untameable hair, the Scholar's Ward's neat crop), the colour of his **hair** (six), his **eyes** (six) and his **sweeper's robe** (six colourings of robe, trousers and trims), and his **origin**: what he was in Qingshi Village before he climbed the steps at thirteen (Granny Wen's boy, the ferry-hand, Scholar Wang's pupil, the old hunter's apprentice, the runner of the Four Roads). Each origin has a small strength and a small weakness (a ferry-hand's back: health +8%, speed -1; a scholar's mind: qi +8% and cheaper techniques, health -5%...), a keepsake to start with, and lines of its own: in the prologue, in the Elder's first summons, at Granny Wen's door in Part VII and at the very end. The hero turns on the cliff as you choose, recoloured on the fly (`Assets.hero_instance` keeps every vertex's brightness relative to its part, so the baked occlusion, the folds, the embroidery and the hair's sheen survive the dye).
- **The wardrobe** (Esc > Wardrobe). **Twelve outfits**, earned along the road (the Elder's white robe at Foundation, the Dragon King's scale-silk, the Phoenix-Plume Robe, the Heaven-Gate Armour, an immortal's moon-white robe, the Weaver Star's star-river silk, the Sea-Wanderer's coat of Landfall's first sailcloth, the Robe of the Many Peoples from the Conclave), given by the people met on the road (Tala's hunter's greens, the Ashen Moon's black robe and mask) or bought from Dyer Su at the Dawn Market. Each recolours robe, trousers and trims and hangs things on the hero's bones (a straw douli, a jade crown, a phoenix crest, coral horn-combs, a traveller's beaded hat, a lacquered half-mask, gold-and-white pauldrons, a feather mantle, a collar of small stars), and carries a small passive (qi +5%, harm taken -4%, attack +5%, foes miss 3% more...). The hero in the world changes as the cursor moves.
- **Mounts and vehicles** (R to ride, Esc > Stable). **Six rides**: the **Mountain Horse** (a new Blender asset, `art/mounts/horse.py`, sculpted in clay over the muscle masses like the qilin, saddled and bridled, with a four-beat walk and a bounding gallop), the **Azure Qilin** and **Bai Hu's cub** (the Blender monsters in their own colours, with a saddle laid on), the **Flying Sword** (his own jian grown three paces long), an **Auspicious Cloud** in five colours and the **Sky-Barque of Landfall** (all three built in code). Lin Feng sits astride or stands on the deck with three new clips (`ride`, `ride_idle`, `ride_stand` in `art/lib/person.py`, baked into all four looks and Yue Ling, who rides pillion). Riding carries the party over open ground 15 to 45% faster, never indoors (the ride waits outside and comes back), and the rides are earned in the story: the horse from Tala's herd, the sword at Golden Core, the qilin if you let it choose you, the cloud at the True Immortal ascension, the tiger from Bai Hu, the barque from Landfall.
- **Fated encounters: five people, a choice at every meeting, and choices that matter to the end** (`scripts/fate.gd`, `scripts/fate_text.gd`, Esc > Fates). Five new characters (Blender-built, `art/characters/tala.py`, `qiu_ye.py`, `little_hu.py`, `hu_grown.py`, `xu_lan.py`, `liu_ying.py`) are met in Part I and again in three later chapters, each time in the state the earlier choices left them in, and settled in Part XIV:

  | Who | First met | Met again | The question |
  |---|---|---|---|
  | **Tala of the Horse-Folk** | Thunder Valley: starving apes have penned her herd | the Aurora Steppe's long winter, the drought on the Millet Plains | keep the herd, feed the apes, or let the horses run free? |
  | **Qiu Ye, the Second Son** | the sect at night, a stolen Foundation pill in his hand | the Graveyard of Sword Saints, the queue of the dead at the Yellow Springs | report him, keep his secret, or pay for the pill yourself? |
  | **Little Hu, Iron Fang's son** | over his father's body with a kitchen knife | Qingshi Village under the Weaver's threads, Longmen | the village, the sect, or the bamboo? and later: was his father a hero? |
  | **Xu Lan, the Moon's Daughter** | in silver chains in the Blood Moon Palace, the purge coming up the stairs | her father's echo in the Mirror Lake, his shade in Youdu | hand her over, cut her loose, or vouch for her? |
  | **Liu Ying, the Hag's Apprentice** | sorting poisons in the Marsh Hag's hut | the spore-blight of Glowcap Vale, the immortals' elixir on Fangzhang | Alchemist Mo, her family, or the grimoire? |

  Every chapter is written for every state a choice can leave its person in (**65 variants, 120 options, about 400 lines of dialogue**; the tests walk every path through every thread and fail if any state could run into a chapter with nothing written for it). A choice may cost something (spirit stones, essences, pills, a name the world respects), be fought out (a fight with a pack, or with the person themselves, in their own model, and a second choice once they lie beaten: spare them or end it), and bring something (a horse, an outfit, stones). And it is **remembered**: the next chapter opens on it, the Fates page lists every choice in words, the person stays where they are (or is gone from where they were met), and it pays off:
  - **By an old bond**, a new kind of way through a trial: Tala's riders run Bifang ragged, Qiu Ye walks into King Yama's court at Lin Feng's side, Fang Hu cuts the Weaver's threads with the village watch, Xu Lan turns Youdu's lanterns on Li, Liu Ying's antidotes meet Tianwu's venom, each only if their story went that way.
  - Liu Ying at Alchemist Mo's side makes every one of his recipes 15% cheaper.
  - In **Part XIV** the friends Lin Feng made come to the Wheel (three or more open **By the bonds you made** through Nie's trial, and they strike Nie every round), and the ones he made enemies of have been reached by Nie's whisper: they are fought, and spared or ended. Friends also answer the grudges of the road: Fang Hu speaks to his father's grudge, Liu Ying gives the Marsh Hag back her name, Qiu Ye makes the Headless Saint's bow.
  - The narrator tells what became of all five, and of the hero's village, before the ending's film; the results count the friends and the fallen.
- **Every foe has a story** (`scripts/lore.gd`, Esc > Bestiary). All **369 foes** (155 kinds of monster and 214 bosses) have a history: who or what they were, what happened to them and why they stand in the road. The first battle against a species shows its story on a card over the battle's opening; before every boss's battle (and every trial's choice of ways) the narrator tells who it was; the **Bestiary** keeps every foe met, with its element, weakness, how often it has been fought and its story. The early bosses, who used to have one line each ("Intruder in my grove"), now have a past: the Jade Mantis Matriarch guarding a season of egg-cases, Iron Fang turned away at the sect gate at twelve for want of a spirit root, the Marsh Hag who was the settlers' herb-wife before the red water took them.
- **Part XIV, "The Ripening of Karma"**, adds a chapter, a realm (**Karma Fulfilled**) and a final trial (see [below](#part-xiv-the-ripening-of-karma)): the Elder explains why threads have appeared on Lin Feng's wrists, Judge Cui shows him the darkness gathering round the Wheel of the Six Paths, he drives back the grudges round its rim (three new monsters), settles his five threads in any order, goes back across the whole world (the old roads round the sect, up the Jianmu to the Nine Heavens, out to the Returning Ruins) to lay to rest **the six grudges that stayed** where their owners fell (six new bosses, each with its story, each fought and then answered: paid, answered by a friend, or left to feed Nie), and faces **Nie, the Unpaid**, the shadow of every debt of the journey, by his friends, by his own strength, by his renown or by a mirror of settled debts.
- **The bot** plays all of it: it makes the story's sweeper, rides the fastest ride it has, wears the newest outfit, takes every fated encounter by a plan (`FATE_PLAN`) that makes friends of three and enemies of two (one spared at the end, one who falls), takes the bond paths through King Yama, the Weaver and Bifang, goes round the six grudges that stayed (`GRUDGE_ROUTE`, `GRUDGE_PLAN`: a friend answers where one can, else it pays, and it leaves the Admiral to the Wheel), and reaches Nie with four friends and one grudge unpaid. In the verified run (seed 1234) it plays the whole game in **17:22:16**, **1 hour 19 minutes more than the last release** (16:02:51); CI now requires **16 hours**.
- **Code**: the game's GDScript grew from 31,270 to 41,101 lines (`create.gd`, `fashion.gd`, `fate.gd`, `fate_text.gd`, `grudges.gd` and `lore.gd` are new) and the Blender Python from 20,578 to 21,088 lines: ten new characters (the five people met on the road, a grown Fang Hu, three more looks for the hero) and a new art group, `art/mounts`; Lin Feng and Yue Ling were rebuilt from their scripts with the riding clips.
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

| | |
|---|---|
| ![character creation: "Who swept the steps?", the story's sweeper turning on the cliff](docs/screenshots/create.png) | ![the four looks (the Sweeper, the Wanderer, the Wild Child, the Scholar's Ward) in four colourings](docs/screenshots/hero_looks.png) |
| ![eight of the twelve outfits, with their hats, crowns, masks, pauldrons and mantles](docs/screenshots/outfits.png) | ![the five people met on the road, and Fang Hu grown](docs/screenshots/fated_people.png) |
| ![on the Flying Sword](docs/screenshots/riding_sword.png) | ![on the Auspicious Cloud](docs/screenshots/riding_cloud.png) |
| ![Tala of the Horse-Folk, Qiu Ye and Fang Hu grown](docs/screenshots/fated_portraits.png) | ![Xu Lan, Liu Ying and Little Hu](docs/screenshots/fated_portraits2.png) |
| ![a fated encounter: Xu Lan in silver chains in the Blood Moon Palace](docs/screenshots/fate_chapter.png) | ![a fated battle: Qiu Ye of the Ashen Moon among the sword saints' barrows](docs/screenshots/battle_fate_qiu_ye.png) |
| ![a species met for the first time: its story over the battle's opening](docs/screenshots/battle_lore.png) | ![the Bestiary](docs/screenshots/bestiary.png) |
| ![Kui's grudge over the aeries of Juntian, where the drum of its hide was struck](docs/screenshots/grudge_kui.png) | ![a battle with Kui's grudge](docs/screenshots/battle_grudge_kui.png) |
| ![the Journal in Part XIV: the six grudges, where each stands and what became of it](docs/screenshots/grudges_journal.png) | ![the ending's results: Karma Fulfilled, the friends and the fallen, the grudges laid to rest](docs/screenshots/ending.png) |

![the ending's film: each wonder the story set right, with its line of the epilogue](docs/screenshots/ending_film.png)

### Two releases ago: many roads, crafting, renown and Part XIII

```mermaid
flowchart LR
    subgraph TR[Trials: the story's battles are guarded]
    B[a chapter's lords, the eight<br/>Gate Generals, Chiyou] -->|stronger: x1.3-2.0 health,<br/>+10-25% attack, enraged below 35%| T{how will you face it?}
    T --> MI[by might: a level, the peak<br/>of a realm, tempering, the root]
    T --> CR[by craft: something made at<br/>the cauldron or the forge]
    T --> WE[by wealth: spirit stones]
    T --> RE[by respect: renown]
    T --> DA[by the Dao you walk]
    T --> PE[by the friendship of a people]
    T --> RL[by a relic found and kept]
    MI --> BO[the battle changes: a weaker foe,<br/>allies striking every round, wards,<br/>a weakness shown, the first blow]
    CR --> BO
    WE --> BO
    RE --> BO
    DA --> BO
    PE --> BO
    RL --> BO
    end
    subgraph LO[Where the means come from]
    FI[every battle] -->|40% a foe| ES[essences of seven elements]
    ES -->|recipes| CR
    ES --> DE[28 deeds for townsfolk]
    DE --> RE
    BS[bosses, trials, gifts] --> RE
    end
    subgraph P13[Part XIII: the Eight Gates, +49 minutes]
    SE[Sect: eight bars of gold<br/>in the sky] --> MP[Yinglong; the Maple Gorge:<br/>Chiyou's fetters, his war-band] --> G{open any 4 of 8 gates,<br/>in any order, in 4 realms}
    G --> H[the field of Zhuolu] --> EN{invite any 4 of 8<br/>peoples' leaders} --> R{three roads}
    R --> SW[the Sword] --> E((Myriad Daos as One))
    R --> PP[the Many Peoples] --> E
    R --> CA[the Cauldron] --> E
    E --> EF[the ending: a film of the wonders<br/>set right, then the results]
    end
    TR --> GAME((Game))
    LO --> GAME
    P13 --> GAME
    GAME --> BOT[bot: 16:02:51,<br/>CI needs 15 h]
```

- **The game is no longer a straight line: 34 trials, each with three or four ways through** (`scripts/trials.gd`, `Main.open_trial`). The battles that carry the main story forward are now **trials**: two lords in every chapter, three in the first, from the bandit chief Iron Fang to Xu Fu (25 bosses), the eight **Gate Generals** of Part XIII and **Chiyou** at the end. A trial's boss is **harder** than the bosses before it (1.3 to 2.0 times the health, 10 to 25% more attack, and *enraged* once it is brought below 35%), and **nobody unprepared may fight it**: walking up to it opens a choice screen with every way through, what each one needs (ticked off or not) and what it does in battle. Only a way whose needs are met can be taken. The ways:

  | Way | What it asks for | What it does in battle (typically) |
  |---|---|---|
  | **By might** | a cultivation level, **cultivation full at the peak of a realm**, a sword **tempered** so many times, so many **ranks of the Nine Heavens root** awake | nothing: you face it at full strength |
  | **By craft** | an item **made** at Alchemist Mo's cauldron or Smith Tie's forge (a talisman, a lens, a seal, an ink, a mirror, an elixir...) | the foe begins weaker, its devastating blows are blunted, or its weakness cuts deeper |
  | **By wealth** | **spirit stones**, paid (once: a lost battle does not charge again) | the foe begins weaker or strikes softer |
  | **By respect** | **renown**: the respect of the world | allies strike the foe every round and the party takes less harm |
  | **By the Dao** | **walking a Dao** (change at any Dao Stele), sometimes as an Adept or a Master | a weakness shown, the first blow, less harm |
  | **By friendship** | the **standing** of one of the peoples of the realms (Friend or Kin) | the people's warriors fight beside you |
  | **By a relic** | something **found** (a keepsake hidden upstairs or in a cellar, a boss's trophy), kept or given up | the foe weakens |

  The way taken is remembered: the battle log names it, the **Journal** lists every trial passed and how, the Annals keep it, and the **ending names the road you walked most** ("Lin Feng, Master of Cauldron and Forge", "Friend of the Four Realms", "the Unbending Sword"...).
- **Crafting from what monsters leave behind.** Every foe beaten in an ordinary battle may leave an **essence** of its element (40%; bosses always leave three): Wood, Fire, Water, Earth, Thunder, Yin and Metal Essence. Alchemist Mo and Smith Tie now **craft** from essences, the things found on the quests (Thunder Shards, Saint Relics, Jade Seals, Keys of the Gate of Heaven...) and spirit stones: **29 recipes**, each listed once the story reaches it, from Smoke-Pellets for Iron Fang (two Wood Essences and a Spirit Herb) to the Elixir of Coming Home for Chiyou (five essences of each of five elements, an autumn leaf from his own maples and 300,000 spirit stones). The shops show what each recipe needs and what it is for, and a row of your essences.
- **Respect has to be earned.** **Renown** grows with every boss (+2), every trial passed (+4) and every keepsake given to a people (+2), and with **28 deeds**: requests from townsfolk all over the world, from Auntie Zhou's pickling brine and Old Shen's cracked bell at the sect to Granny Wen's mulberries, the Yumin's cold egg-cellar and Landfall's first keel in two thousand years. A townsperson with a request asks it when you talk to them; bring what they want and they pay, and the world thinks better of you, through seven titles from *Unknown* to *Legendary*. Every respect path asks for more renown than the bosses and trials alone give, so it is the path of a player who helps people.
- **Wealth matters.** Spirit stones used to pile up past a million by the end with nothing to spend them on; the wealth paths (from 150 stones to bribe Iron Fang's lieutenants to 420,000 to buy back the Lost Fleet), the recipes and the deeds' rewards give them a use.
- **The Journal** (Esc > Journal): your renown and title, your essences and treasures, the townsfolk's requests (and which you can do now), the trial ahead with every way through and its needs ticked off, the Eight Gates during Part XIII, and the trials you have passed and how.
- **Part XIII, "The Eight Gates"**, adds 49 minutes of play (see [below](#part-xiii-the-eight-gates)) and is **non-linear**: after the briefing, Yinglong's account of Zhuolu and a hunt of the war god's war-band, **open any four of eight gates, in any order**, two in each of the four realms, each a trial of its own (one asks for a Dao, another for a people's friendship, another for wealth, renown, a crafted key, a relic or plain strength); every gate opened beyond four weakens the war god at the heart; carry the invitations to the Conclave to **any four of the eight peoples' leaders, in any order**; and then reach the end by **one of three roads**, each with its own requirements, its own battle and its own epilogue. A new realm, **Myriad Daos as One**, its tribulation, eight Gate Generals and Chiyou, five new monsters, two war-bands marching in every gate's region, and a new ending (below).
- **A new ending: the Ascension, as a short film** (`scripts/ending.gd`). The old results screen had piled thirteen chapters' finales into one frame around the hero (the pillars, Nuwa's rings, the Wheel, the Loom's threads, the bridge, the sun and the moon, the cauldrons, the Jianmu, the isles, the gates), under a camera six metres away, with a yellow lotus and lily pads filling the foreground, seven lines of epilogue printed straight over the brightest part of the sky and the results in a box over the characters' feet. Now every wonder the story set right has a place of its own on a sea of clouds at sunset and a **shot of its own, with its line of the epilogue as a subtitle** between letterbox bars: the magpie bridge over the Star River with the sun and the moon taking turns, the Nine Cauldrons with their river, the Jianmu (the crown the world builds in the Nine Heavens), the Isles of the Eastern Sea on their sleeping turtles, the Eight Gates standing open under the Jianmu, and the Wheel of the Six Paths between two of Nuwa's pillars with Lin Feng's parents walking up a road of light to it. Then the camera draws back from Lin Feng and Yue Ling on a lotus, the sun going down behind the gates, and **the results come up beside them**: the time, the realm and the Dao, the battles, renown and deeds, a bar of the ways taken through the trials, the name the climb earned (from the way taken most) and how the war god's story ended on the road chosen. Enter skips the film.
- **Things to do: 810 things in the world Lin Feng can use, on 18 new animations** (`scripts/props.gd`, `World.start_use`, `art/lib/person.py` INTERACT). Facing one, the hint names it ("Enter: Strike the bell"); Enter, and he steps up to it (or onto it, to sit), does it, steps back, and something comes of it. **Outdoors**, every region has things of its own beside the road, chosen by its theme (270 in all, 20 kinds): a stone bench, a well, a wayside shrine, a bronze bell and a great drum, a qin on a stone table, a fishing jetty and a fish pond, a swing, a wishing tree hung with red ribbons, an inscribed stele, spirit herbs, a campfire, training stones, a broom and a heap of leaves (he swept the sect's steps for three years; his hands still know how), a weiqi board, a tea table, a stone lion, wind chimes, a stone lantern. **Indoors**, every piece of furniture in every building, upstairs and in the cellars, can be used (540, 22 kinds): pray at the altars, bow to the founders' statues, meditate on the cushions, read at the bookshelves and desks, look at the calligraphy, drink tea at the tables and taste from the barrels, sit on the stools, stir the cauldrons, cook at the stoves, warm your hands at the hearths, work the anvils, practise a form at the weapon racks, weave at the looms, sleep in the beds, trim the lanterns.

  | | What he does | What he holds | How it answers | What comes of it |
  |---|---|---|---|---|
  | bench, swing, stool | sits (beside Yue Ling on a bench; on the swing, higher and higher) | | the swing goes | rest: health and qi |
  | well, tea, table, barrel | draws water or pours tea and drinks | a dipper, a cup | the bucket comes up | a drink: health |
  | shrine, altar, statue, cushion | lights incense and prays, bows, meditates (Yue Ling prays too) | | incense smoke | qi |
  | bell, drum | takes the hanging beam and strikes | | the bell swings and rings out | a line of lore |
  | qin, chimes, broom, loom, cauldron, koi | plays, sets them ringing, sweeps, weaves, stirs, feeds the fish | a broom, a ladle | notes, chimes, leaves, steam, the fish rise | qi |
  | fishing | fishes from the jetty | a rod | the float bobs and dips | a quiet hour: health and qi |
  | stele, bookshelf, desk, scroll, shelf, counter, lantern, nest, weiqi | lays a hand on it, reads, looks, studies the game | a book | the inscription glows; the lantern stays lit | a line of lore |
  | wishing tree, stone lion, cabinet | throws up a wish ribbon, rubs the lion's head, looks inside | | the ribbon flies up | a find: spirit stones (once) |
  | herbs | kneels and gathers | | sparkles | a Wood Essence (again after a while) |
  | training stones, anvil, weapon rack | lifts the stone lock overhead, works the anvil, practises | a stone lock, a hammer | dust, sparks | a little cultivation (again after a while) |
  | campfire, hearth, stove | warms his hands, cooks | a ladle | the fire flares, embers rise | rest |
  | bed | sits on the edge and nods off | | | sleep: everybody restored |

  Every thing has three things said of it, in turn; the first time Lin Feng does each kind of thing it is a new **pastime** (renown +1, "A new pastime: strike the bell (12 of 42)"). Yue Ling joins in or reacts: she sits beside him on a bench, sits on the bank while he fishes and beside the table while he plays, prays at the shrines, warms her hands at the fire, laughs when he lifts the stones. While he does something Enter or Esc stops him. Nothing stands in anyone's way: the things outdoors stand on the forest edge or in the water by the bank (in a little clearing of their own), and the furniture on the tiles it already filled (the walk-over pieces, a cushion or a stool, are used by facing them), so no road changes and the bot, which never uses them, plays the same game to the second.

  The **animations** are new Blender clips for the party (`art/lib/person.py` INTERACT, baked into Lin Feng and Yue Ling): sit on a bench, doze, drink, strike, read, play the qin, meditate, fish, pray, gather, warm the hands, stir, hammer, sweep, weave, lift, toss and touch, each starting and ending in the idle pose or holding a breathing loop, the clips that sit or crouch lowering the hips themselves. A swordsman's rig now has a **sword bone** in the right hand (Lin Feng and three others), so a clip that needs both hands puts the blade away; what he holds is built in code and hung on his hand bone while he needs it.

```mermaid
flowchart LR
    W[face a thing:<br/>Enter: the hint names it] --> S{where is it done?}
    S -->|face| F[a step up to it]
    S -->|seat| SE[onto it, turned round to sit]
    S -->|before| B[sitting down in front of it]
    S -->|on| O[on its own tile: a cushion]
    F & SE & B & O --> C[the clip: sit, drink, strike, read,<br/>play the qin, fish, pray, gather,<br/>warm, stir, hammer, sweep, weave,<br/>lift, toss, touch, meditate, doze]
    C --> H[in his hand: a dipper, a cup, a rod,<br/>a broom, a hammer, a ladle, a book, a stone]
    C --> A[the thing answers: the bell swings,<br/>the fire flares, the fish rise]
    C --> Y[Yue Ling sits beside him,<br/>prays, warms her hands, laughs]
    C --> E[what comes of it: rest, a drink,<br/>qi, lore, a find, herbs, cultivation]
    E --> P[the first time: a new pastime,<br/>renown +1]
```

![things to do, in use: the bench, the well, the shrine, the bell, the qin and the fishing jetty](docs/screenshots/props_sheet_0.png)
![more things to do: the swing, the wishing tree, the campfire, the training stones, the broom and the fish pond](docs/screenshots/props_sheet_1.png)
![and indoors: the altar, the bookshelf, the bed, the cauldron, the anvil and the loom](docs/screenshots/props_sheet_2.png)
- **The bot** walks every kind of road: its plan takes the trials by every way there is (in the verified run: craft 9, respect 5, wealth 5, might 5, dao 4, relic 1, peoples 1), and it hunts essences, crafts at the cauldron and the forge, does deeds for renown, fetches keepsakes from upper storeys and cellars, changes Daos at the steles and opens the gates nearest first. The other two roads into the heart are verified with `--bot-start=s_p13_heart --route=sword|cauldron`. **16:02:51** for the whole game, **1 hour 56 minutes more than the last release**; CI now requires **15 hours**.
- **Code**: the game's GDScript grew from 26,632 to 31,270 lines (`scripts/trials.gd`, the trials, recipes, deeds and renown, and `scripts/props.gd`, the things to do, are new). Every new boss and monster is one of the existing script-built models in a palette of its own; five character exports were rebuilt from their scripts (Lin Feng and Yue Ling with the interaction clips, and the swordsmen with the sword bone).
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

| | |
|---|---|
| ![a trial: the Demon Lord's four ways, one of them open](docs/screenshots/trial_choice.png) | ![crafting at Alchemist Mo's cauldron](docs/screenshots/crafting.png) |
| ![the Journal: renown, essences, requests and the trial ahead](docs/screenshots/journal.png) | ![a townsperson's request](docs/screenshots/deed_request.png) |
| ![the Journal during Part XIII: the Eight Gates](docs/screenshots/journal_gates.png) | ![the Gate of Harm: the drum of Kui's hide on Mount Buzhou, a war-band of Chiyou's brothers nearby](docs/screenshots/gate_kui_drum.png) |
| ![the Gate of Life: the Fetter-Maple in the Maple Gorge](docs/screenshots/gate_fetter_maple.png) | ![Xingtian at the Gate of Opening, by the friendship of the foxes: allies strike every round](docs/screenshots/battle_boss_xingtian.png) |
| ![Chiyou, War God of the Nine Li, on the Road of the Many Peoples](docs/screenshots/battle_boss_chiyou.png) | ![the ending: the results beside Lin Feng and Yue Ling on the lotus, the sun going down behind the Eight Gates](docs/screenshots/ending.png) |

![the ending's film: the magpie bridge, the Nine Cauldrons, the Jianmu, the Isles of the Eastern Sea, the Eight Gates and the Wheel of the Six Paths, each with its line of the epilogue](docs/screenshots/ending_film.png)

#### References for that release

Background for that release (the Eight Gates, Chiyou and the war at Zhuolu):

- **Chiyou and the battle of Zhuolu**: the war god of the Nine Li, with bronze heads and iron brows, who made the first weapons of metal and fought the Yellow Emperor through a hundred days of fog; the Wind Earl and the Rain Master who fought for him, Nüba who dried the rain, the drum of Kui's hide whose beat broke his army, and the fetters struck off him that grew into the first maples, in the "Great Wilderness" chapters of the [*Classic of Mountains and Seas*](https://en.wikipedia.org/wiki/Classic_of_Mountains_and_Seas) ([Chiyou](https://en.wikipedia.org/wiki/Chiyou), [the battle of Zhuolu](https://en.wikipedia.org/wiki/Battle_of_Zhuolu)); "Chiyou's Banner", the red vapour that rose from his tomb every autumn and later the name of a comet.
- **Xingtian**, the giant who fought on after the Yellow Emperor cut off his head, with eyes in his chest and a mouth in his belly ([Xingtian](https://en.wikipedia.org/wiki/Xingtian)).
- **The Eight Gates**: Opening, Rest, Life, Harm, Closing, Sight, Alarm and Death of [Qimen Dunjia](https://en.wikipedia.org/wiki/Qimen_Dunjia), taught to the Yellow Emperor by the Mysterious Lady of the Nine Heavens, laid on the eight trigrams ([Bagua](https://en.wikipedia.org/wiki/Bagua)); the "Eight Gates Golden Lock" formation of the *Romance of the Three Kingdoms*, which falls when it is entered by the right gate.
- **Wang and Liang, Chi and Mei**: the goblins of the mountains, old things and waters that fought in Chiyou's host.

### Three releases ago: realms and talents that matter, cutscenes and Part XII

```mermaid
flowchart LR
    subgraph RM[Realms that matter]
    LV[Lin Feng's realm] -->|a whole realm apart| SU[realm suppression:<br/>x1.2 per realm, up to three]
    LV -->|two realms below| SC[packs scatter,<br/>counting for hunts]
    LV -->|the realm on the door| CV[nine Founder's caves<br/>on the mountain]
    LV --> TW[townsfolk greet it;<br/>deeper lore at higher realms]
    end
    subgraph TA[Talents: the nine branches]
    AW[an awakening:<br/>first qi, every tribulation,<br/>every cave] --> CH{wake which branch?}
    CH --> BR[Sword Bone, Thunder, Five-Phase<br/>and Yin Roots, Vajra Body, Sea of Qi,<br/>Enlightened Mind, Heaven's Favour,<br/>Spirit Sense: 3 ranks and a crown]
    BR --> PW[battle, meditation,<br/>stones, hidden caches]
    PW --> WG[the world grows with the root;<br/>tribulations test a woken root harder]
    end
    subgraph CU[Cutscenes]
    LN[a line of dialogue] --> EM[gesture: named in the line<br/>or read from its words]
    EM --> PL[the speaker plays it,<br/>the listener answers]
    LN --> CAM[two-shot conversation camera]
    end
    subgraph P[Part XII: +1 hour 23 minutes]
    SE[Sect: the tide went out] --> FS[Fusang: Mazu's boat] --> PG[Penglai] --> FZ[Fangzhang] --> YZ[Yingzhou] --> GX[Guixu]
    end
    CV --> AW
    RM --> GAME((Game))
    TA --> GAME
    CU --> GAME
    P --> GAME
    GAME --> BOT[bot: 14:06:51,<br/>CI needs 12 h]
```

- **Cultivation levels matter a lot more** (`data.gd` `REALM_INFO`, `suppression`, `game.gd`, `battle.gd`, `main.gd`):
  - **Realm suppression**: a fighter a whole major realm above another strikes **20% harder** and is struck 20% softer, up to three realms (x1.6); it is announced as the battle opens ("Realm suppression: your Golden Core weighs on them"). It works both ways, so rushing a region under-cultivated hurts. Heavenly Tribulations are heaven itself and press on every realm alike.
  - **Aura**: a pack whose strongest beast is **two realms below** Lin Feng scatters as he walks into it rather than fight; it still counts as driven off for a hunt.
  - **The Founder's nine sealed caves**: Founder Qing Lian sealed a cave on Azure Cloud Mountain for each realm from Golden Core to Primordial Sovereign; a stone door opens only to a cultivator of the realm carved on it. Inside are her letters to the bearers who would come after her, the scratched notes of two bearers Xu Mo caught before they reached the next door, a gift of spirit stones and an **awakening of the root**. The Annals keep what is written in them.
  - **What a realm is**: the new **Cultivation** page (Esc > Cultivation) shows Lin Feng's realm, his lifespan (120 years at Qi Condensation, 100,000 as a True Immortal, then beyond counting), how the world addresses him (young friend, Daoist friend, senior, elder, Immortal, Sovereign, Venerable, Sage...) and what the realm is like from the inside.
  - **The world notices**: the first time a townsperson sees him after a breakthrough they say so, in six bands of awe; and **realm-gated lore**: fifteen people (the Elder, the Archivist, Old Wu, Granny Wen, the immortals...) tell a high enough cultivator things they tell nobody else (`Data.CHAT_DEEP`).
- **Cultivation talents matter a lot too: the nine branches of the Nine Heavens root** (`Data.TALENTS`, `Game.talent_*`):

  | Branch | Each rank (of three) | Crown (rank three) |
  |---|---|---|
  | **Sword Bone** | Sword Strike and physical techniques +22%, single-target techniques +6% | the first blow of every battle lands as a critical strike |
  | **Thunder Root** | thunder techniques +18% | a thunder technique on a weakness strikes again for half |
  | **Five-Phase Root** | fire, water, wood and earth techniques +12% | techniques that strike every foe cost a fifth less |
  | **Yin Root** | dark techniques +18% | a dark technique heals Lin Feng for a tenth of its harm |
  | **Vajra Body** | health +10%, harm taken -5% | once a battle, a fatal blow leaves him one breath |
  | **Sea of Qi** | qi +10%, +1% qi a turn, techniques 3% cheaper | once a battle, a third of his qi floods back when it runs low |
  | **Enlightened Mind** | meditation +12%, cultivation from battle +6% | every battle teaches the Dao he walks twice over |
  | **Heaven's Favour** | spirit stones +15%, critical strikes +3%, pills found +8% | a boss always leaves a third healing pill |
  | **Spirit Sense** | speed +2, slips 3% of blows; feels hidden caches | he moves first in every battle; foes miss more |

  - A branch wakes one rank at each **awakening**: when his qi first stirs (the Elder explains the root's nine branches), at **every tribulation** he survives and in **every Founder's cave** he opens, and he chooses which on a new choice screen; an unspent awakening waits on the Cultivation page.
  - **The world grows with the root**: every foe is a little tougher for each rank a cultivator of its level would be expected to have woken (`Data.expected_ranks`), so the branches a player wakes (and the caves they open) decide whether they keep pace; and a **Heavenly Tribulation tests a woken root harder** (+1.5% per rank awake, heaven's jealousy).
  - **Spirit Sense** reveals four caches hidden on the isles; the ending names the ranks awake.
- **Custom animations in the cutscenes**: every person in the game (153 Blender characters) has **ten new gesture clips** baked in `art/lib/person.py` (nod, shake, point, wave, laugh, grieve, think, kneel, offer, shock). A line of dialogue can name its gesture (`["Speaker", "text", "kneel"]`), a narrator's line can direct somebody present (`"Mazu, Who Brings the Boats Home:offer"`), and otherwise one is read from the words (`Data.emote_for`: thanks bow, refusals shake their heads, welcomes wave, directions point, questions think); the listener answers (a bow for a gift, a wave for a wave, a nod for grief). A **conversation camera** eases from the chase camera into a two-shot from the side at head height (higher indoors), drifts during narration and eases back. The ending screen has Yue Ling waving, bowing and laughing and Mazu waving from her boat.
  | | |
  |---|---|
  | ![Lin Feng kneels with the cultivator's salute](docs/screenshots/anim_lin_feng_kneel.png) | ![Yue Ling waves](docs/screenshots/anim_yue_ling_wave.png) |
  | ![Lin Feng thinks, hand to his chin](docs/screenshots/anim_lin_feng_think.png) | ![Yue Ling grieves](docs/screenshots/anim_yue_ling_grieve.png) |
  | ![Lin Feng laughs](docs/screenshots/anim_lin_feng_laugh.png) | ![Yue Ling shows the way](docs/screenshots/anim_yue_ling_point.png) |
  | ![Lin Feng nods](docs/screenshots/anim_lin_feng_nod.png) | ![Yue Ling offers something with both hands](docs/screenshots/anim_yue_ling_offer.png) |
  | ![Elder Qing Xuan, startled](docs/screenshots/anim_elder_qing_shock.png) | ![Mazu offers her lantern](docs/screenshots/anim_mazu_offer.png) |
  | ![a cutscene: Mazu waves as she speaks, framed by the conversation camera](docs/screenshots/cutscene_mazu2.png) | ![the conversation camera during narration](docs/screenshots/cutscene_mazu.png) |

- **More people in every town**: 22 new townsfolk with their own Blender models and three lines each: a new disciple and the herb-gardener at the sect; a former tax-clerk of the Court carrying noodles, the noodle-seller and a courier at Cloudfoot; the ox-herd and the schoolteacher at Qingshi; a lantern-maker and the archery-master at Yanggu; a star-glass blower and a Sogdian merchant at Shazhou; a scholar who failed the examinations nine times and a cormorant fisher at Longmen; a bell-tuner and the keeper of the casting pits at Tushan; a Yumin who cannot fly and a rain-clerk at Featherfall; a silk-diver and a fruit-trader of the Deathless at Tearwater; a roll-clerk and the lamplighter at Youdu; and a fox of one tail at the Gate of Heaven. Landfall adds twelve more.
- **A richer, more consistent world**: two new peoples (the **Thousand Children of Landfall**, mortals on the isle of the immortals for two thousand years, and the **Immortals of the Isles**) with their Daos, keepsakes and boons; **progress-aware chat** (`Data.CHAT_LATER`: people only speak of falling stars and Jade Emperors once those have happened); the Founder's caves and their letters; realm-gated lore; and **nineteen plot holes fixed** (see [below](#narrative-plot-holes-found-and-fixed)).
- **Part XII, "The Returning Ruins"** adds 1 hour 23 minutes (see [below](#part-xii-the-returning-ruins)), verified by the playthrough bot; CI now requires **12 hours**.
- **Code**: the game's GDScript grew from 23,697 to 25,537 lines and the Blender Python from 19,113 to 20,039 lines; all 219 assets (153 people, 40 monsters, 26 props) rebuild from their scripts.
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

#### References for that release

Background for that release (the Isles of the Immortals and the Returning Ruins, and the people met there):

- **Guixu and the five isles**: the ravine without a bottom east of the Bohai into which every water and the Silver River pour, the five mountains Daiyu, Yuanqiao, Fanghu, Yingzhou and Penglai, the fifteen giant turtles (ao) set to bear them in three shifts of sixty thousand years under Yu Qiang, and the giant of Longbo who caught six of them, in the "Tang Wen" chapter of the [*Liezi*](https://en.wikipedia.org/wiki/Liezi); [Penglai](https://en.wikipedia.org/wiki/Penglai_(mythology)) and the [Eight Immortals](https://en.wikipedia.org/wiki/Eight_Immortals).
- **Xu Fu**: the magician the First Emperor of Qin sent east with three thousand boys and girls to find the elixir of immortality, in the *Records of the Grand Historian* ([Xu Fu](https://en.wikipedia.org/wiki/Xu_Fu)).
- **The sea's gods and creatures**: [Mazu](https://en.wikipedia.org/wiki/Mazu), with her generals Qianliyan and Shunfeng'er; [Jingwei](https://en.wikipedia.org/wiki/Jingwei), the Flame Emperor's daughter who fills the sea with pebbles, and Tianwu, the eight-headed water god, in the *Classic of Mountains and Seas*; Yu Qiang, god of the northern sea; Ruo of the Northern Sea and the River Earl in the "Autumn Floods" chapter of the [*Zhuangzi*](https://en.wikipedia.org/wiki/Zhuangzi_(book)); [Wu Zixu](https://en.wikipedia.org/wiki/Wu_Zixu), god of the tidal bore; the *shen*, the clam whose breath builds the mirages of the sea ([haishi shenlou](https://en.wikipedia.org/wiki/Fata_Morgana_(mirage))); the Sea-Monk (haiheshang) of the fishermen's tales.
- **Cultivation realms and talents**: the realms, spiritual roots and talents of [xianxia](https://en.wikipedia.org/wiki/Xianxia) cultivation fiction, and realm suppression ("jingjie yazhi"), a staple of the genre.

### Four releases ago: three realms, six Daos, six peoples and Part XI

| | |
|---|---|
| ![the Nine Heavens: islands over a sea of cloud, the Jianmu's crown among them](docs/screenshots/realm_heaven.png) | ![the Nine Springs: a cavern country over a glowing abyss](docs/screenshots/realm_under.png) |
| ![the Jianmu, grown overnight west of the sect](docs/screenshots/jianmu.png) | ![the Jianmu's crown in Juntian, the Level Heaven](docs/screenshots/jianmu_crown.png) |
| ![Featherfall, the Feathered Folk's town in the sky](docs/screenshots/town_featherfall.png) | ![Youdu, the Dark Capital](docs/screenshots/town_youdu.png) |
| ![Tearwater on the black water of the Nine Springs](docs/screenshots/town_tearwater.png) | ![the Gate of Heaven at Changhe](docs/screenshots/changhe_gate.png) |
| ![upstairs in the Aerie Tower](docs/screenshots/upper_aerie_tower.png) | ![the Sealed Archive, down the stairs under the Scripture Library](docs/screenshots/cellar_sealed_archive.png) |
| ![choosing a road at a Dao Stele](docs/screenshots/dao_choice.png) | ![the Daos and the peoples of the realms](docs/screenshots/dao_peoples.png) |
| ![the Feathered Folk and the dragon-kin](docs/screenshots/gallery_yumin_dragons.png) | ![the celestial foxes and the Pearl-Weepers](docs/screenshots/gallery_foxes_jiaoren.png) |
| ![the Deathless, Houtu and the shades of Youdu](docs/screenshots/gallery_deathless_shades.png) | ![Part XI bosses: Leigong, Jiufeng, Zhulong, Black Impermanence, Tubo and Li](docs/screenshots/gallery_part11.png) |
| ![the map of the Nine Heavens](docs/screenshots/world_map_heaven.png) | ![the map of the Nine Springs](docs/screenshots/world_map_under.png) |

```mermaid
flowchart LR
    subgraph RE[Height and depth: three realms]
    HV[Nine Heavens, 96 m up:<br/>islands over a sea of cloud] <-->|a stair up the trunk| JM{{the Jianmu}}
    LD[the Unbroken Land:<br/>the tree's foot west of the sect] <--> JM
    JM <-->|a stair down the roots| NS[Nine Springs, 64 m down:<br/>caverns over an abyss]
    end
    subgraph FL[Buildings with floors]
    UP[12 upper storeys] --- CE[11 cellars]
    UP --> IN[people, quest scenes<br/>and keepsakes inside]
    CE --> IN
    end
    subgraph DA[Six Daos]
    CH[choose one when the tree grows,<br/>change at any Dao Stele] --> MA[mastery: Novice, Adept, Master;<br/>passives grow, a technique at Adept]
    MA --> TA[the story answers<br/>the Dao you walk]
    end
    subgraph PE[Six peoples]
    RA[Feathered Folk, dragon-kin,<br/>celestial foxes, Pearl-Weepers,<br/>Deathless, shades] --> ST[standing from help<br/>and keepsakes]
    ST --> BO[a friend grants a boon]
    end
    subgraph P[Part XI: +1h18m]
    SE[Sect: a tree<br/>in the night] --> JT[Juntian] --> CG[Changhe] --> NN[Nine Springs] --> YD[Youdu]
    end
    RE --> GAME((Game))
    FL --> GAME
    DA --> GAME
    PE --> GAME
    P --> GAME
    GAME --> BOT[bot: 12:46:15,<br/>CI needs 11 h]
```

- **More height above and an underworld below.** The land used to be the whole world. Now it is the middle of three (`scripts/atlas.gd`, `world.gd`, `terrain3d.gd`):
  - **Two new realms, each a world of its own**, built by the same atlas as the continent: regions round sites, organic borders under a domain warp, roads by A*, Lotus Seals where the chapter is not open yet. Where the continent's land runs out into the sea, theirs runs out into the sky or the dark.
  - **The Nine Heavens** float **96 m above the land**: Juntian, the Level Heaven, and Changhe, the Gate of Heaven, are islands with steep rock undersides over a sea of cloud that runs on to the horizon, under bright high air and a violet-and-gold dusk.
  - **The Nine Springs** lie **64 m below**: the cavern country under the roots and Youdu, the Dark Capital, on rock shelves over a faintly glowing abyss, lit by glowing moss, lanterns and the Torch Dragon's eye.
  - **The Jianmu**, the Standing Tree of the old myths, grows overnight on the open ground west of the sect: a trunk wider than the Hall that goes up through the clouds to a crown of leaf-clouds in Juntian, with roots that split the hillside and come out in the roof of the Nine Springs. The realms are laid out so that the crown stands right above its foot and the roots right below. **A stair winds up the trunk and another goes down the roots**; walking onto one carries Lin Feng up or down in a lift and a fade, and the world on the other side streams in around him.
  - The minimap and the HUD follow the realm you are in, and the **world map has a page for each realm** (Left/Right switches between them), with the Jianmu marked on each.
- **Multi-storey buildings and cellars to explore.** A building can have an **upper storey** (`upper`) and a **cellar** (`cellar`) in `Data.AREAS`, each a small world of its own (`Atlas._floor`) reached by a flight of **stairs** inside the building. Upstairs is a plank floor laid on the ground floor's walls, with walls, windows and furniture of its own and the roof raised a storey higher (`Architecture.house`); while Lin Feng is on the ground floor the storey lifts away with the roof, so you can still see him. A cellar is a room of dressed stone and timber posts lit by lanterns (`Architecture.cellar`), with dark, close air of its own (`Look.cellar_environment`). There are **23 floors** (12 up, 11 down), furnished with beds, shelves, barrels, altars, cushions, bookshelves, desks, nests and lanterns:
  - **The sect**: the Sealed Archive under the Scripture Library (where Archivist Lan kept everything the Court ordered forgotten), the ancestral crypt under the Hall and the upper dormitory.
  - **The old towns**: the letter room over Cloudfoot's post station and the upper gallery of the Teahouse of Ten Thousand Tales, Granny Wen's root cellar in Qingshi Village, the guest rooms of the Leaping Carp Inn and the harbourmaster's flood-record store in Longmen, and the wine cellar of the Inn of the Late Arrival in Tushan.
  - **Featherfall** (the top of the Aerie Tower, Yu Jian's feather loft, the warm cellar under the Egg-Nursery, the Archive of Rain under the Rain Ministry), **Changhe** (the moon terrace of the Pavilion of the Moon-Foxes, the Moon-Wine Shop's wine loft, the old gatehouse cellar), **Tearwater** (the pearl vault, the Tide-Singer's singing room, the loft under the Great Root) and **Youdu** (the magistrate's upper room, Zhi Ma's paper store, the deep hall of Sovereign Earth, the lodgings of the Inn of the Last Lantern).
  - Quest scenes happen upstairs and downstairs, and the **keepsakes the peoples love** are hidden on these floors.
- **Six Daos to choose from.** With the Court gone, so is its one road (obedience). When the Jianmu grows back the Elder asks which road Lin Feng will walk, on a new choice screen, and he can change roads at any **Dao Stele** (one stands in the sect's courtyard and one in each new region). Every Dao keeps its own **mastery**: battles won while walking it raise it from Novice to Adept to Master, and its passive grows with it. At **Adept** it teaches a technique of its own. The people he meets **answer the Dao he walks**: the Elder when he chooses, every people when they first meet him, Chong and Li after their fights, and the ending tells the story his way.

  | Dao | Motto | What it does (Novice, Adept, Master) | Technique from Adept | Honoured by |
  |---|---|---|---|---|
  | **the Sword** | "A blade has one direction: forward." | single-target techniques x1.15 / 1.22 / 1.3, the plain sword strike x1.5 / 1.6 / 1.7 | Ten Thousand Swords Return to One | humans and the dragon-kin |
  | **Free Wandering** | "The Peng rises on a wind of ninety thousand li, and goes where it likes." | +3 / 5 / 7 speed, the party slips 7 / 10 / 14% of blows | Peng's Wind of Ninety Thousand Li | the Feathered Folk |
  | **the Compassionate Heart** | "Hold the sky only as long as you choose, and ask for help." | heals x1.2 / 1.3 / 1.4, Lin Feng heals 3 / 4 / 5% a turn, the party takes 4 / 6 / 8% less harm | Lotus Heart Sutra (heals and raises the party) | the Pearl-Weepers |
  | **Formations** | "The land keeps its shape because it is allowed to." | the party takes 12 / 16 / 20% less harm | Eight Trigrams Grand Array | the shades of Youdu |
  | **the Cauldron** | "Every pill is borrowed time. Borrow wisely, and for others." | pills x1.6 / 1.8 / 2.0, spirit stones x1.25 / 1.35 / 1.5, techniques cost 8 / 12 / 15% less qi | Nine-Turn Golden Elixir Fire | the Deathless |
  | **the Mirror** | "The moon in the water is still the moon." | foes miss 7 / 10 / 13% of the time, weaknesses cut x1.65 / 1.75 / 1.85 (normally x1.5) | Mirror-Flower, Water-Moon | the celestial foxes |

- **The peoples of the realms.** Six peoples live above and below the land, each with its own home, the Dao it honours, the keepsake it loves and a boon for a friend (`Data.RACES`). **Standing** with a people grows with the help Lin Feng gives in their lands (every quest step there, more for a boss) and by half as much again if he walks the Dao they honour; a **keepsake** given to any of their people adds more. At 50 they call him **Friend** and grant their boon; at 100, **Kin**. Their townsfolk speak to the Dao he walks now and then, and when he carries the keepsake their people love he can give it to them. The **Dao & Peoples** page in the pause menu shows it all.

  | People | Home | Honours | Loves | Boon as a friend |
  |---|---|---|---|---|
  | **Yumin, the Feathered Folk** | Featherfall, in Juntian | Free Wandering | a wutong seed | Lin Feng acts sooner (+3 speed) |
  | **Dragon-kin of the Rain Ministry** | the Rain Ministry, in Juntian | the Sword | a night-shining pearl | Lin Feng hits harder (+6% attack) |
  | **Tianhu, the celestial foxes** | Changhe, the Gate of Heaven | the Mirror | peach-blossom wine | foes miss a little more often |
  | **Jiaoren, the Pearl-Weepers** | Tearwater, in the Nine Springs | the Compassionate Heart | a pressed moon lotus | every heal is 10% stronger |
  | **The Deathless** | the root-groves of the Nine Springs | the Cauldron | a pressed autumn leaf | Lin Feng is hardier (+8% health) |
  | **Shades of Youdu** | Youdu, the Dark Capital | Formations | ancestor incense | the party takes 6% less harm |

  - **19 new Blender-built characters** for them (`art/lib/race.py`, a new library hooked into `person.py`): **wings** of coverts over cubic-curve flight feathers that sway with the robe, a **crest** of plumes, **fox ears** with a cupped inner ear and fur tufts, **one to nine tails** fanned in two rows from under the sash, **fin ears** with rays and a pale edge, branching **dragon antlers**, **scales** on the cheekbones and the backs of the hands, and **whiskers** (barbels from the upper lip); the Deathless are black-skinned and the shades pale as paper. Among them: Ling Yu and Feather-Mother Yu Hua of the Feathered Folk, Rain-Minister Ao Run, Hu Qingyi the Ninth-Tail Matron, Pearl-Weaver Shui Lian, Elder Bu Si of the Deathless, Lantern-Magistrate Ming Yi and Houtu, Sovereign Earth.

    | | |
    |---|---|
    | ![Hu Qingyi, the Ninth-Tail Matron: fox ears and nine tails](docs/screenshots/turnaround_hu_qingyi.png) | ![Feather-Mother Yu Hua: wings and a crest](docs/screenshots/turnaround_yu_hua.png) |
    | ![Rain-Minister Ao Run: dragon antlers, scales and whiskers](docs/screenshots/turnaround_ao_run.png) | ![Pearl-Weaver Shui Lian: fin ears and scales](docs/screenshots/turnaround_shui_lian.png) |

- **Part XI, "The Ladder of Heaven"** adds 1 hour 18 minutes (see [below](#part-xi-the-ladder-of-heaven)), verified by the playthrough bot; CI now requires **11 hours**.
- **Code**: the game's GDScript grew from 20,722 to 23,687 lines (+14%) and the Blender Python from 17,939 to 19,113 lines; all 174 assets (108 people, 40 monsters, 26 props) rebuild from their scripts.
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

#### References for that release

Background for this release (the myths of the Jianmu and the realms, the Daos and the peoples):

- **The Jianmu and the severing of heaven and earth**: the Jianmu, the tree at the centre of the world by which the gods went up and down, in the [*Classic of Mountains and Seas*](https://en.wikipedia.org/wiki/Classic_of_Mountains_and_Seas) ("Classic of the Regions within the Seas") and the [*Huainanzi*](https://en.wikipedia.org/wiki/Huainanzi) ("Terrestrial Forms"); Zhuanxu sending Chong to lift heaven and Li to press down the earth, in the [*Guoyu*](https://en.wikipedia.org/wiki/Guoyu_(book)) ("Discourses of Chu") and the *Book of Documents* ("Lü Xing"); the [world tree](https://en.wikipedia.org/wiki/World_tree) and the [axis mundi](https://en.wikipedia.org/wiki/Axis_mundi).
- **The realms above and below**: the Nine Heavens and their fields (the *Huainanzi*, "Celestial Patterns"), the Nine Springs and the Yellow Springs ([Diyu](https://en.wikipedia.org/wiki/Diyu)), Youdu, the Dark Capital, with its earl Tubo, in the "Summons of the Soul" of the [*Chu Ci*](https://en.wikipedia.org/wiki/Chu_Ci), [Houtu](https://en.wikipedia.org/wiki/Houtu), Sovereign Earth.
- **The Daos**: the Peng and free and easy wandering in the [*Zhuangzi*](https://en.wikipedia.org/wiki/Zhuangzi_(book)) ([Peng](https://en.wikipedia.org/wiki/Peng_(mythology))), "mirror flowers and water moons" (the illusions of Buddhist and Daoist writing), the eight trigrams of formations, and nine-turn cinnabar alchemy.
- **The peoples**: the Feathered People, the Deathless (black-skinned people who eat of the immortal tree) and the dragon-kin in the *Classic of Mountains and Seas*; the Jiaoren, whose tears turn to pearls, in the *Bowuzhi* and Gan Bao's *Soushen Ji*; celestial foxes who climb to heaven at a thousand years ([huli jing](https://en.wikipedia.org/wiki/Huli_jing)).
- **The bosses**: [Leigong](https://en.wikipedia.org/wiki/Leigong), Duke of Thunder; Feilian, Earl of the Wind; Kui, the one-legged thunder ox of the *Classic of Mountains and Seas*; Jiufeng, the nine-headed bird of Chu; [Pixiu](https://en.wikipedia.org/wiki/Pixiu); Shentu and Yulei, the door gods under the peach tree ([Menshen](https://en.wikipedia.org/wiki/Menshen)); [Zhulong](https://en.wikipedia.org/wiki/Zhulong_(mythology)), the Torch Dragon whose open eye is day; Wangxiang, the water goblin; [Heibai Wuchang](https://en.wikipedia.org/wiki/Heibai_Wuchang), Black and White Impermanence.

### Five releases ago: an organic continent, four towns and Part X

```mermaid
flowchart LR
    subgraph OLD[Before]
    G1[38 rectangles in<br/>nine east-west bands] --> G2[a mountain column<br/>down the west side]
    G2 --> G3[ladder of L-shaped<br/>roads, rectangular world]
    end
    subgraph MAP[The new world map: atlas.gd]
    S[a site and a way<br/>for every region] --> T[maps turned to face<br/>their road]
    T --> V[anisotropic Voronoi<br/>under a two-scale warp]
    V --> C[coast where land runs out:<br/>the Four Seas, an inner sea]
    V --> O[open ground: a warped ellipse<br/>with lobes and bays]
    V --> R[roads by A*: winding,<br/>one border crossing, land bridges]
    R --> SL[Lotus Seals where<br/>each road crosses]
    end
    subgraph WB[World-building]
    TW[4 new towns, 26 new<br/>Blender-built people] --> AN[history of every region<br/>and town: the Annals]
    AN --> WM[world map shows where<br/>you are and what it was]
    end
    subgraph P[Part X: +1h14m]
    CF[Cloudfoot] --> LM[Longmen, the Dragon Gate] --> DF[Drowned Fields of Gun] --> TS[Tushan, the cauldron-casters] --> BZ[Mount Buzhou]
    end
    OLD ==>|the Court's squares give way| MAP
    MAP --> GAME((Game))
    WB --> GAME
    P --> GAME
    GAME --> BOT[bot: 11:27:54,<br/>CI needs 10 h]
```

- **The world map is no longer a grid.** The old world was 38 rectangles packed into nine east-west bands with a 60-tile mountain column down the west side: every region's open ground a rounded rectangle, every border a straight seam between rows, the coast a frame. Now (`scripts/atlas.gd`, `scripts/mapgen.gd`):
  - **Sites, not rows.** Every region has a site and a *way*, the direction its road runs through it, and its own map is turned to face that way. Each chapter winds outward from Azure Cloud Mountain as a province of its own: Part I east and up the east coast, Part II west along the north coast, Part IX east to the sunrise, Part V south-east, Part III south, Part VIII south-south-west, Part VII south-west, Part VI west, Part IV west and up into the sky, and Part X north to the river and the broken pillar.
  - **Organic borders.** A tile belongs to the region whose site is nearest, measured in that region's own half-sizes (an anisotropic, weighted Voronoi diagram), so long regions own long land, and the point is first moved by a two-scale domain warp, so borders wander like coasts and ridges. The land round everything that matters in a region (people, bosses, gates, buildings, monster packs) always belongs to it.
  - **A coast.** Land runs out about two half-sizes from the nearest site, so the continent has bays, capes, fjords between the mountain's spurs and an inner sea in the north-east. The sea is one surface for the whole world (sea tiles are cut out of every region's terrain) with foam along the coast, water carried under the coastal land, the ocean running on past the edge of the world and a seabed under it.
  - **Open ground with a shape.** A region's open ground is an ellipse filling its map, pushed and pulled into lobes and bays by a domain warp, bitten by a second noise and frayed at the edge, with forest beyond; clearings stay round everything that matters and trails join any that end up in the forest. A test checks that every region's corners are mostly forest.
  - **Roads that find their way.** Roads are searched for with A* across the land: old paths are cheap, open ground cheap, forest dear and water dearer, and a slow noise field makes them wind. Each road crosses from one region to the next exactly once, at the point of their border that makes the way shortest, and the Lotus Seal stands right there, turned across the road. Land bridges are raised along every road, so none has to cross the sea.
  - **Rivers, ponds and winding streets** inside regions (`river`, `ponds` and `roads` in `Data.AREAS`): a river runs through Longmen under the main street's bridge, a pond gives Shazhou its oasis, and towns and dykes get curved streets drawn as splines.
  - The **world map** is a full-screen page now: one sea colour with paler shallows, every region's name at its site (a town at a region's heart names it), towns marked in gold, closed seals in red, and beside the map the history of the region Lin Feng is standing in.
- **Four new towns and a deeper world.**
  - **Cloudfoot**, the post town at the foot of the mountain where the north road leaves for the river: a post station, Cartographer Pei's House of Maps, the Teahouse of Ten Thousand Tales, the Caravanserai of the Four Roads, a shrine to Xiu, god of roads, and the post stables.
  - **Longmen**, the ferry town below the Dragon Gate: the Leaping Carp Inn, the Temple of the River Earl with its flood stele, a boatyard, the fish market, the lock-keeper's house, a teahouse on stilts and the harbourmaster's office, on a river with a bridge.
  - **Tushan**, the cauldron-casters' town on Mount Kuaiji: the Hall of the Nine Cauldrons, Tu Lan's foundry, the bell works, the stone-carver's workshop, the Inn of the Late Arrival and the charcoal-burner's lodge, round a great bronze cauldron.
  - **Shazhou Oasis**, a caravan town round a sweet well in the Desert of Fallen Stars: a caravanserai, the Sweet Well, the Temple of the Fallen Stars and the camel yard.
  - **26 new people, all Blender-built** with their own props and three things each to say, and those things tie the world together: the postmaster knows who writes to whom between the towns, the caravan master's camels know every road from the desert to the Silk Woods, the stone-carver cuts the flood marks for Longmen's stele.
  - **A history for every region and town** (`Data.REGION_LORE`, `Data.TOWNS`): where it lies, who lives there and what happened there. It is shown beside the world map, and the new **Annals** page in the pause menu keeps every place Lin Feng has been.
  - **Part X tells why the map changed**: the Heavenly Court had surveyed the land into squares and pinned it with Yu the Great's Nine Cauldrons; with the Court gone the land is lying down in its own shape again.
- **Part X, "The Nine Cauldrons"** added 1 hour 14 minutes (see [below](#part-x-the-nine-cauldrons)), verified by the playthrough bot; CI then required **10 hours**.
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

#### References for that release

Background for this release (the techniques behind the new map, cartography and the myths of Part X):

- **Map generation**: [Red Blob Games: polygonal map generation](https://www.redblobgames.com/maps/polygon-map-generation/) (Voronoi regions, coasts by distance), [Red Blob Games: making maps with noise](https://www.redblobgames.com/maps/terrain-from-noise/) (island shaping by distance), [Inigo Quilez: domain warping](https://iquilezles.org/articles/warp/), [Frozen Fractal: continents and domain warping](https://frozenfractal.com/blog/2023/11/2/around-the-world-1-continents/), [weighted Voronoi diagrams](https://en.wikipedia.org/wiki/Weighted_Voronoi_diagram), [A* for roads (Red Blob Games: introduction to A*)](https://www.redblobgames.com/pathfinding/a-star/introduction.html), [Catmull-Rom splines](https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline).
- **Cartography**: [Pei Xiu and his six principles of map-making](https://en.wikipedia.org/wiki/Pei_Xiu), [Yu Gong (the Tribute of Yu) and the Nine Provinces](https://en.wikipedia.org/wiki/Nine_Provinces).
- **The myths of Part X**: [Nine Tripod Cauldrons](https://en.wikipedia.org/wiki/Nine_Tripod_Cauldrons), [Yu the Great and the Great Flood](https://en.wikipedia.org/wiki/Great_Flood_(China)), [Gun](https://en.wikipedia.org/wiki/Gun_(Chinese_mythology)) and [Xirang](https://en.wikipedia.org/wiki/Xirang), [Gonggong](https://en.wikipedia.org/wiki/Gonggong) and [Mount Buzhou](https://en.wikipedia.org/wiki/Mount_Buzhou), [Xiangliu](https://en.wikipedia.org/wiki/Xiangliu), [Yinglong](https://en.wikipedia.org/wiki/Yinglong), [Longmen and the carp that leap the Dragon Gate](https://en.wikipedia.org/wiki/Longmen_(mythology)), [He Bo and Ximen Bao](https://en.wikipedia.org/wiki/He_Bo), [Taotie](https://en.wikipedia.org/wiki/Taotie), Fangfeng and the assembly at Kuaiji ([Yu the Great](https://en.wikipedia.org/wiki/Yu_the_Great)), [Kuafu](https://en.wikipedia.org/wiki/Kuafu), [Kun and Peng](https://en.wikipedia.org/wiki/Peng_(mythology)), [Tushan and the nine-tailed fox](https://en.wikipedia.org/wiki/Huli_jing).

### Six releases ago: hanfu characters, five-colour monsters and Part IX

```mermaid
flowchart LR
    subgraph R[References studied]
    RC[anime proportions, Genshin and<br/>Guilty Gear shading, hanfu cut,<br/>hair clumps]
    RA[walk, run and idle key poses,<br/>quadruped gaits, game rigs]
    RW[Voronoi and domain-warped maps,<br/>toon water, Hui-style villages]
    RP[60-30-10 colour, countershading,<br/>focal accents, Shan Hai Jing colours]
    end
    subgraph CH[Characters]
    GA[garment.py: sloping shoulders,<br/>pipa sleeves, V-neck,<br/>wrap-around skirt]
    HA[hair.py: clumps,<br/>curtains of long hair]
    SH[mat_actor: soft cel ramp,<br/>tinted shadows, coloured ink]
    RG[37-bone rig, 11 clips:<br/>run, talk, bow, die ...]
    end
    subgraph MO[Monsters]
    CL[clay.py metaball sculpting,<br/>canine, feline, bird]
    PT[painted coats: stripes,<br/>saddles, masks, scales]
    IK[IK gaits, 5 clips each,<br/>3 new creatures]
    PA[five-role palettes: dominant,<br/>underside, secondary, markings,<br/>element accent]
    end
    subgraph WO[The land]
    SHO[curved shorelines,<br/>recessed water]
    BO[meandering borders,<br/>irregular forest edges]
    TO[9 new buildings,<br/>20 new townsfolk]
    end
    subgraph P[Part IX: +1 hour]
    YG[Yanggu Dawn Market] --> MF[Scorched Millet Plains] --> FS[Fusang Valley] --> GH[Moon Palace]
    end
    RC --> CH
    RA --> CH
    RA --> MO
    RP --> PA
    RW --> WO
    CH --> G((Game))
    MO --> G
    WO --> G
    P --> G
    G --> BOT[bot: 10:17:41,<br/>CI needs 9 h]
```

- **Characters, rebuilt again: they now look like people in hanfu.** The old figures had square, horizontal shoulders with the sleeves set on like shoulder pads, wide trapezoid "bell" sleeves with black insides, a white stripe of inner robe running from collar to hem like an apron, a turtleneck collar, thin strands of hair round a helmet and neon costumes. Now (`art/lib/garment.py`, `hair.py`, `person.py`):
  - **The cut of the robe**: narrower, sloping shoulders that run on into the sleeve with no seam (hanfu sleeves are cut in one with the bodice), arms that hang close to the body, a **V at the throat** where the crossed collars meet, and a **wrap-around skirt**, left over right, whose overlap edge carries the collar line down to the hem as one trimmed line.
  - **Sleeves** swept from the shoulder to the cuff as one surface: narrow seen from the front, deep seen from the side, the **pipa-shaped pocket** (mei) sagging behind the hand and gathered into a trimmed cuff (qu), on its own bone so it swings a beat behind the arm.
  - **Hair** in big clumps instead of thin strands: long hair falls as one continuous mass cut into pointed clumps at the ends, ponytails are full tails, side locks and fringes are wider; a highlight ring runs across dark hair.
  - **Proportions** of about 6.6 heads (a slightly larger head reads better at game distance), a thicker neck, softened plant-dye colours, a cape gathered over the shoulders on three bones.
- **Cel shading for characters and monsters** (`MB.mat_actor`): a soft two-tone ramp on the key light with **tinted shadows** (warm rose on skin, cool lavender on cloth and fur) instead of Godot's hard toon terminator, the ambient light that used to double every colour into neon cut back, a thin rim only on the lit side, toon highlights on metal, crystal and scales, and **coloured ink lines** (dark rose under skin, deep blue under a blue robe) drawn thinner than the scenery's.
- **Rigs**: every character gains a pocket bone per sleeve, finger and thumb bones, toe bones, a mouth bone for speech, a second hair bone and a third cape bone (26 to 37 bones).
- **Animation**: eleven clips instead of seven.  **Walk** rebuilt on contact, down, passing and up poses (the arms used to swing *with* the leg on the same side), a **qinggong run** with a flight phase and the cape, sleeves and hair streaming back (the hero crosses a 2 m tile every 0.16 s, so the old walk slid along the ground), **talk** (gestures, nods and a moving mouth), **bow** (the cupped-fist salute), **die** (a collapse that stays down), and idle, sit, attack, cast, hurt and victory redone with anticipation, follow-through and overlapping cloth.
- **Life in the world**: the hero and Yue Ling run on the road; whoever is speaking in a conversation gestures and moves their mouth; people bow as you walk up; **monster packs amble about their ground** with walk cycles and stop to face you when you come close; a fallen fighter collapses and stays down (party members until they are raised).
- **The world is no longer made of rectangles.**
  - **Shorelines** follow a smooth water field (the share of water round each corner, blurred and warped by noise, rounded towards the middle of every water tile) instead of tile corners; shore tiles are subdivided so the waterline curves, lone water tiles become round pools, banks slope down to a recessed waterline, and the foam follows the real depth instead of outlining every square tile in white. Water has teal shallows, deeper blue middles and a quieter sky reflection.
  - **Region borders meander**: ownership uses a two-scale domain warp, so borders wander like coasts and ridges on the world map and on the ground.
  - **No more rectangular clearings**: the forest reaches into every region from its edge by a depth that varies with noise, keeping clearings round every gate, arrival, person, boss, pickup, building and monster pack, and reconnecting anything it cuts off with trails that go round buildings.
  - Regions sit off the grid inside their bands.
- **More town buildings and people.** New building styles: **Huizhou houses** with white walls, black tiles and stepped horse-head fire walls, **thatched farmhouses**, a **two-storey teahouse** with a gallery, **shops** with awnings and signboards, **dormitories** and a **kitchen** with a smoking chimney. The sect gains a kitchen, a hall of martial practice and the disciples' dormitory; Qingshi Village a teahouse, a tofu shop, a carpentry, a farmhouse, a scholar's study and a granary. **Twelve new people** with their own Blender models and chat: Senior Brother Han, Junior Sister Mei, Auntie Zhou the cook, Little Bai (who sweeps the steps with Lin Feng's old broom), Gate Disciple Wu, Old Shen the bell-ringer, Farmer Lao, Little Hua, Tofu Seller Sun, Scholar Wang, Carpenter Gu and Xiao Lan the herb-picker.
- **Monsters sculpted, painted and animated** (`art/lib/clay.py`, `anatomy.py`, `canine.py`, `feline.py`, `bird.py`, `creature.py`): bodies are modelled from metaballs (balls, ellipsoids and capsule chains, each carrying smooth bone weights) instead of hundreds of outlined fur cards, with fur as shingled clumps that belong to the silhouette. Heads are built per species (the tiger's broad skull and cheek ruffs, the wolf's long muzzle and stop, the qilin's dragon head with one ridged horn and cloven hooves, the dragon's nine resemblances on an S-curved serpent body), and coats are painted in the grey values so a recolour still reads as an animal: tiger stripes and the king mark, the wolf's dark saddle and mask, the fox's white bib and black stockings, scales and belly plates. Horns, claws and fangs taper and shade from base to tip. Rigs gained spine, neck, jaw, ear, toe and long tail chains; every monster has **idle, walk, attack, hurt and die**, quadrupeds walk in the four-beat lateral sequence with the hips and chest bouncing out of step and the tail following through, insects and crabs walk on IK legs in an alternating tripod. Three new creatures: the **sun crow**, the **jade rabbit** and **Bifang**. The simpler shapes were restyled too: a **golem** of split, lichen-spotted boulders over a core that glows through the seams, a real **tortoise** (a high shell of raised scutes with growth rings over a plated underside, neck folds, a hooked beak and thick scaly legs), **scorpion, crab, spider and mantis** built from keeled exoskeleton segments (`anatomy.sclerite`) with proper chelae, an uneven crusher claw and raptorial forelegs, a **slime** that sags into a puddle with drips and half-swallowed things, a **jellyfish** with frilled oral arms and trailing tentacles, **mushroom folk** whose stems are their bodies, a **koi** with painted scales, barbels and trailing fins, a lofted **manta**, a scowling **thundercloud**, solid wisp flames and a tattered wraith. The person-shaped monsters (Ox-Head, Horse-Face, the hopping corpse, the Queen Mother and the rest) are built with the new character library.
- **Monsters in five colours, not one** (`Assets.palette`, `Builder.coat_slots`, research below). Each enemy's colour now expands into a palette with a clear hierarchy, as creature designers build one: a **dominant** colour over most of the body; a pale, cream-leaning **underside** (countershading on the belly, throat, bib and inner legs); **markings** that contrast in value (dark stripes, saddles, masks and tail tips on a light coat, pale ones on a dark coat); a **secondary** a clear step round the colour wheel and different in value (manes, wings, shells, fins, skirts of hair); and one small, saturated **accent** for the focal points, taken from the element (fire gold, water cyan, wood spring green, earth amber, thunder violet, dark magenta) or its alternate when the body already has that hue. The painted grey coats are split automatically (the pale parts blend into the underside, the dark ones into the markings, measured against the coat's median by surface area), and every creature got accent parts: the eyes of all of them, the dragon's dorsal spines, tail tuft and elbow flames, the qilin's horn, the serpent's horns and fin rays, the tiger's king mark, the wolf's brow spots, fox-fire, bird crests, the phoenix's tail eyes, the golem's molten core and faults, the ape's crest, crab claws, the scorpion's venom gland, spider and mantis eyes, moth eyespots, ghost-fire, storm runes and the jelly's glowing organs. The classic creatures keep the colours of the old texts: **Bifang** red markings on a blue-green body (the *Shan Hai Jing*: "red markings on a blue-green ground and a white beak"), **Hundun** a yellow sack red as cinnabar, **Bai Hu** white with black stripes, **Zhu Que** vermilion and gold, **Xuan Wu** a black shell lined in gold, the **Azure Dragon King** with a golden mane and cream belly plates, a nine-tailed fox with blue fox-fire.
- **Yue Ling no longer runs sideways** (see [bugs](#bugs-found-and-fixed)).
- **Part IX, "The Tenth Sun"** added +1 hour (see [below](#part-ix-the-tenth-sun)), verified by the playthrough bot; CI then required **9 hours**.
- **Art code** grew from 12,550 to 17,548 lines of Blender Python (+40%) and the game's GDScript from 17,359 to 19,113 lines; all 129 assets (63 people, 40 monsters, 26 props) rebuild from their scripts in about three minutes on four cores (the build now runs in parallel).
- **Bugs found and fixed** (see [below](#bugs-found-and-fixed)).

#### References for that release

Researched for that release (characters, creatures, rigs, animation, landscape and towns):

- **Stylised characters and faces**: [PoseMyArt anime head guide](https://posemy.art/blog/anime-head-drawing-guide/), [anime proportions step by step](https://www.alibaba.com/product-insights/how-to-draw-anime-characters-with-correct-proportions-step-by-step.html), [80.lv: capturing anime art style in 3D](https://80.lv/articles/cg-jolyne-cujoh-here-s-how-to-capture-anime-art-style-in-3d), [Blender Studio stylised character workflow](https://studio.blender.org/training/stylized-character-workflow/5e70a631db0e8bc0c8b226f2), [3D character body](https://tinakuang.myblog.arts.ac.uk/?p=656).
- **Toon shading**: [Adrian Mendez, Genshin shading breakdown](https://adrianmendez.artstation.com/projects/wJZ4Gg), [B. J. Ayers, recreating the Genshin shader](https://bjayers.artstation.com/blog/category/5), [URP Simple Genshin Shaders](https://github.com/NoiRC256/URPSimpleGenshinShaders), [80.lv Genshin shader for EEVEE](https://80.lv/articles/genshin-impact-character-shader-for-eevee), [GDC 2015: Guilty Gear Xrd's art style](https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The) ([handout](https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf)).
- **Hanfu**: [Ru (upper garment)](https://en.wikipedia.org/wiki/Ru_(upper_garment)), [newhanfu: basic features and forms](https://www.newhanfu.com/73124.html), [hanfu garment types](https://culturechina.com/blog/what-is-zhiduo-and-other-hanfu-garment-types-explained.html).
- **Hair**: [BlenderNation: flat-modelling anime hair](https://www.blendernation.com/2020/02/01/flat-modeling-anime-hair/), [80.lv: hairstyle modelling for an anime-like character](https://80.lv/articles/a-closer-look-at-hairstyle-modeling-for-an-anime-like-3d-character), [CG Cookie: modelling hair](https://cgcookie.com/posts/how-to-model-hair-in-blender).
- **Walks, runs and idles**: [Walk cycle](https://en.wikipedia.org/wiki/Walk_cycle), [UW CSE 459 walk cycle notes](https://courses.cs.washington.edu/courses/cse459/19au/assignments/assignment_5/index.html), [SIGGRAPH walking exercise](https://education.siggraph.org/static/HyperGraph/animation/character_animation/walking/walking_excercise.htm), [AnimSchool: breathing life into idle animations](https://blog.animschool.edu/2024/06/14/breathing-life-into-idle-animations), [idle animation for games](https://mocaponline.com/blogs/mocap-news/idle-animation-design-guide).
- **Rigs**: [skeleton hierarchy guide](https://mocaponline.com/blogs/mocap-news/skeleton-hierarchy-animation-guide), [demystifying character rigging for games](https://gamedev.net/blogs/entry/2277565-demystifying-character-rigging-for-games/), [CRYENGINE jiggle bones](https://www.cryengine.com/docs/static/engines/cryengine-5/categories/23756816/pages/44959301).
- **Creatures**: [creating a furry 3D character](https://www.creativebloq.com/how-to/create-a-furry-3d-character-from-scratch), [80.lv: stylised characters for games](https://80.lv/articles/building-stylized-characters-for-games-tips-and-tricks), [digitigrade legs](https://www.line-of-action.com/zh-Hant/article/digitrade-animals-dont-have-backward-knees), [how to draw a tiger](https://chriswilsonstudio.com/how-to-draw-a-tiger/), [Chinese dragon (Loong)](https://www.wikiwand.com/en/articles/Loong), [A Chinese Bestiary (Strassberg)](https://abookofcreatures.com/category/china).
- **Quadruped gaits**: [Animation Mentor quadruped walk](https://www.animationmentor.com/?p=46186), [animating four-legged beasts](https://gamedeveloper.com/art/animating-four-legged-beasts), [animating dogs: gaits](https://animuppetry.blogspot.com/2013/01/animating-dogs-part-ii-more-gaits-and.html).
- **Landscape**: [Red Blob Games: polygon map generation](https://www.redblobgames.com/maps/polygon-map-generation/), [Frozen Fractal: continents and domain warping](https://frozenfractal.com/blog/2023/11/2/around-the-world-1-continents/), [stylised water with depth fade](https://godotshaders.com/shader/stylized-water-with-depthfade/), [toon water](https://godotshaders.com/shader/toon-water/).
- **Monster colour**: [the 60-30-10 rule applied to characters](https://pixflow.net/blog/the-ultimate-guide-to-creating-memorable-character-color-palettes/), [Fiveable: colour balance and proportion](https://fiveable.me/color-theory-and-application/unit-6/color-balance-proportion/study-guide/gJcxbcR9KQVhlVIz), [colour palettes and game design](https://www.gamedeveloper.com/design/where-colour-meets-design-colour-palettes-and-game-design), [evolution of Pokemon designs: one main colour and contrasting details](https://www.gamedeveloper.com/design/evolution-of-pokemon-designs-gen-1), [2 to 6 colours with a hierarchy](https://forums.thousandroads.net/threads/caniss-thoughts-on-pok%C3%A9mon-design.1886), [concept and colour theory for creatures](https://www.cinemamakeup.com/?p=6170), [Polycount: Monster Hunter base colours](https://polycount.com/discussion/comment/2382718/), [Proko: values before colour](https://www.proko.com/course-lesson/painting-in-greyscale), [Gnomon: the face as the focal point](https://www.thegnomonworkshop.com/tutorials/creature-and-character-design), [countershading and warning colours](https://en.wikipedia.com/wiki/Animal_marking), [Shan Hai Jing creatures](https://abookofcreatures.com/category/china).
- **Towns**: [Hui-style architecture](https://en.wikipedia.org/wiki/Hui_Style_architecture), [Xidi and Hongcun](https://worldheritagesite.org/list/Xidi+and+Hongcun), [Jiangnan architecture](https://news.cgtn.com/news/2024-05-01/VHJhbnNjcmlwdDc4NTI5/index.html).

### Seven releases ago: rebuilt models and Part VIII


```mermaid
flowchart LR
    subgraph R[References studied]
    REF1[anime / Genshin-style<br/>proportions, faces, shading]
    REF2[dog, horse and big-cat<br/>anatomy: digitigrade legs]
    REF3[Chinese dragon:<br/>nine resemblances]
    end
    subgraph L[New Blender libraries: art/lib]
    SC[sculpt.py<br/>lofts, profiles, noise, strands]
    FA[face.py<br/>skull, nose, lips, lidded eyes,<br/>ears, ageing, beards]
    HA[hair.py<br/>scalp, locks, bangs,<br/>8 styles, sheen]
    GA[garment.py<br/>layered hanfu, sleeves, armour,<br/>hats, brocade, weapons]
    AC[accessory.py<br/>29 hand props + poses]
    AN[anatomy.py<br/>quadruped bodies, legs, paws,<br/>heads, fur, feathers, scales]
    FE[feline.py + bird.py]
    end
    subgraph C[Colour]
    PAL[palette slots in the UVs:<br/>primary / secondary / accent]
    HAR[harmonised costumes,<br/>hair sheen]
    end
    subgraph P[Part VIII: +1 hour]
    SF[Starfall Ferry] --> MG[Magpie Bridge Heights] --> SP[Weaver Star Palace] --> JP[Jasper Pool of Kunlun]
    end
    R --> L
    L --> ASSETS[39 people, 37 monsters,<br/>26 props rebuilt]
    C --> ASSETS
    ASSETS --> G((Game))
    P --> G
    CHK[check_assets.py<br/>GLB validator in CI] --> ASSETS
```

- **Characters look like people.** Every character is built by `art/lib/person.py` from new libraries. **Faces** (`face.py`) are sculpted on a skull: brow ridge, cheekbones, jaw and chin, a nose with alar wings, lips with a philtrum, eyes set into sockets under lids with a crease and lashes, ears with a helix, laugh lines and crow's feet for the old, and beards that grow from the face. **Hair** (`hair.py`) grows from a scalp with a real hairline as tapered locks, with fringes, side locks, a crown whorl and eight styles (topknot, long, bun, twin buns, braid, short, wild, bald), and dark hair gets a lighter sheen. **Clothes** (`garment.py`) are layered hanfu lofted around the body: inner robe, crossed collar, sash, hanging sleeves with a lining, a skirt that drapes, and armour of lamellar plates, pauldrons and tassets; hats, crowns, weapons, brocade motifs (cloud scrolls, waves, cranes, plum blossom), scars and freckles. Builds (slight to burly), age (the old stoop), femininity, and anime-leaning proportions (about 7 heads tall, larger eyes) follow the references. **Props and poses** (`accessory.py`): 29 hand-held items (gourds, fans, scrolls, lanterns, oars, fishing rods, abacus, flute, a cormorant...) with matching holding poses, so every NPC carries their trade.
- **Natural motion.** Idle with contrapposto and breathing, a walk with heel strike and counter-swinging arms, sitting, attacking, casting, hurt and victory clips; held props keep their pose while walking.
- **Monsters have anatomy.** `anatomy.py` builds quadrupeds the way the animals are built: a keel-shaped ribcage and tucked waist, withers and croup, muscled shoulders and haunches, **digitigrade legs** with the stifle forward and the hock back, paws with toe pads and claws, canine and feline skulls with a stop and a separate jaw, groomed fur clumps, feathers with a rachis, scale rows, plates, compound eyes, bristles, bark-covered limbs and veined leaves. The dragon follows the **nine resemblances** (camel head, deer antlers, rabbit eyes, cow ears, snake neck, clam belly, carp scales, eagle claws, tiger palms). All 29 old shapes were rebuilt and 8 new ones added: **qilin, ape, tiger, Queen Mother, River Warden, Crow Marshal, nine-faced Kaiming and magpie**, so lions, tigers, apes and qilin are no longer drawn as wolves.
- **Much richer colour palettes.** The art pipeline now stores a **palette slot** per vertex (primary, secondary, accent) next to the tint weight. In game, `Assets.palette()` turns one enemy colour into a scheme: a shade and a light of the primary blended by the surface's own value, an analogous secondary and a complementary accent (gold or blue for grey creatures). Quadrupeds get pale bellies and darker lower legs, manes, crests, fins and horns take the secondary, eyes, claws and glows the accent. Characters' costumes are **harmonised** from their robe colour: a pastel inner robe, deeper trousers, a contrasting sash and collar, light trim.
- **Landmarks** (all 26 props) gained sculpted detail within their triangle budgets, and four new ones mark Part VIII: the ferry post, the magpie pine, the star pillar and the jade peach tree.
- **Part VIII** adds +1 hour (see below), verified by the playthrough bot; CI now requires **8 hours**. The ending gains the **magpie bridge** (`art/props/magpiebridge.py`) with the Cowherd and the Weaver meeting on it.
- **Asset validation in CI.** `art/check_assets.py` reads every exported GLB without Blender and checks the script-to-file pairing, the three material slots, vertex colours and tint UVs, triangle budgets, the bones the game drives and the animation clips.
- **Blender Python art code doubled**: 6,272 to 12,549 lines (`art/lib` 5,389, characters 770, monsters 4,704, props 1,489, tools 198).
- **Bugs found and fixed** (see below).

#### References for that release

The models were rebuilt after studying how stylised and anatomical 3D characters are made:

- Anime proportions and faces: [how to draw anime characters with correct proportions](https://www.alibaba.com/product-insights/how-to-draw-anime-characters-with-correct-proportions-step-by-step.html), [3D character body](https://tinakuang.myblog.arts.ac.uk/2024/03/26/3d-character-body/), [making a stylised face](https://www.hitem3d.ai/de/ai-faq/how-to-make-a-face-3d-model-look-stylized).
- Toon shading and model evolution in Genshin Impact: [Adrian Mendez's shading breakdown](https://adrianmendez.artstation.com/projects/wJZ4Gg), [B. J. Ayers' blog](https://bjayers.artstation.com/blog/category/5), [character model evolution 1.0 to 7.0](https://topuplist.com/blogs/detail/genshin-impact-character-model-evolution-version-1-0-to-7-0), [Natlan model changes](https://thenerdstash.com/genshin-impact-fans-discover-a-small-yet-welcome-change-in-the-new-natlan-character-models).
- Quadruped anatomy: [digitigrade animals don't have backward knees](https://www.line-of-action.com/zh-Hant/article/digitrade-animals-dont-have-backward-knees), [canine hindlimb](https://en.wikivet.net/Canine_Hindlimb_-_Anatomy_&_Physiology), [canine phalanges](https://en.wikivet.net/Canine_Phalanges_-_Anatomy_%26_Physiology), [dog anatomy](https://www.wikiwand.com/en/articles/Dog_anatomy), [equine anatomy and biomechanics](https://mink-studios.blogspot.com/2016/11/equine-anatomy-and-biomechanics-primer.html), [eastern dragon anatomy](https://w.blackdrago.com/science/anatomy_east.htm).
- The Chinese dragon: [Loong](https://www.wikiwand.com/en/articles/Loong) (the nine resemblances), [how to draw a dragon](https://www.sixthtone.com/news/1014614/how-to-draw-a-dragon).

### Eight releases ago: one open world and Part VII

```mermaid
flowchart LR
    subgraph O[One open world]
    AT[atlas.gd<br/>every region on one tile grid] --> RD[roads between gates,<br/>Lotus Seals instead of teleports]
    AT --> SM[noise-warped borders,<br/>forest belts between regions]
    AT --> ST[world.gd streams regions in<br/>and out around the player]
    AT --> MAP[world map in the pause menu,<br/>scrolling minimap]
    end
    subgraph S[Less squarish land]
    W1[wandering trails instead of<br/>L-shaped corridors] --> LAND((terrain))
    W2[shorelines follow the ground,<br/>oval sect pond] --> LAND
    W3[hilliness blends across<br/>region borders] --> LAND
    end
    subgraph B[Buildings you can enter]
    H["architecture.gd house():<br/>walls, door, plank floor,<br/>furniture, lanterns"] --> RF[roof lifts away<br/>while you are inside]
    H --> NPC[Elder, Alchemist, Smith,<br/>Archivist and villagers indoors]
    end
    subgraph P[Part VII: +1 hour]
    V[Qingshi Village] --> TE[Cloud-Tea Terraces] --> SK[Mulberry Silk Woods] --> LM[Loom of Borders]
    end
    O --> G((Game))
    S --> G
    B --> G
    P --> G
```

- **One open world.** All 30 regions and the sect now lie on one continuous map (492 x 448 tiles, about 1 x 0.9 km). Azure Cloud Mountain with the sect on its slope runs down the west side; each chapter's chain of regions runs east from it as a band of land, and Part II's chain snakes back west beneath Part I's. You walk from region to region along roads: there are no loading gates or teleports any more. A region the story has not opened yet is closed by a **Lotus Seal** barrier across its road, which dissolves into an open archway when the Elder (or the boss before it) lets you through. The 3D view streams regions in as you approach them and drops the far ones; the minimap scrolls with you, and **Esc > World Map** shows the whole land.
- **Less squarish terrain.** Region borders are no longer straight walls: the land between two regions is a forest-and-rock belt whose edges wander with noise, and the change of ground, trees and sky follows the same wavy line. Connecting trails wander on the diagonal instead of running in L-shaped corridors, the mountain roads meander, the water plane runs on under the banks so shorelines follow the shape of the ground, the sect's lotus pond is an oval, and hilliness blends smoothly from one region to the next.
- **Buildings you can enter.** The sect's Hall of Azure Clouds, the Alchemist's Pharmacy, the Smithy and a new Scripture Library are hollow buildings with a door, plank floors, lattice windows, lanterns and furniture (altar and founder statue, cauldron and herb racks, hearth, anvil and weapon rack, bookshelves). Qingshi Village has five more (Granny Wen's house, an inn, a shrine, a weaver's workshop and an abandoned house) and the tea terraces and silk woods one each. Walk in through the door and the roof lifts away; the Elder, Alchemist Mo, Smith Tie and the villagers wait inside.
- **Part VII** adds +1 hour (see below), verified by the playthrough bot; CI now requires **7 hours**.
- **Bugs found and fixed** (see below).

### Nine releases ago: natural landscapes and Part VI

```mermaid
flowchart LR
    subgraph N[Natural landscapes]
    NA[nature.gd<br/>painted leaf textures,<br/>foliage-card and grass shaders] --> FL[flora.gd<br/>43 species, grown<br/>recursively in variants]
    RK[rocks.gd<br/>noise-displaced rocks,<br/>karst towers] --> SC
    FL --> SC[scatter.gd<br/>distance fields, grove noise,<br/>forest edges, meadows, shores]
    FA[fauna.gd<br/>birds, cranes, butterflies,<br/>dragonflies, fish, moths, bats]
    end
    subgraph A[Architecture]
    AR[architecture.gd<br/>halls, curved roofs, dougong,<br/>walls, archways, pagoda,<br/>bridges, dwellings, ruins]
    end
    subgraph B[Blender art]
    PE[person.py<br/>layered hair, eyes, fingers,<br/>folds, embroidery, animal heads] --> CH[28 characters<br/>19 new]
    CR[creature.py chain rigs] --> MO[29 monsters<br/>17 new: every shape<br/>is now Blender-built]
    PR[21 props<br/>10 new landmarks]
    end
    subgraph I[Image]
    IM[4x MSAA, highlight-only glow,<br/>light fog, no grain or fringing,<br/>visible water, new sky and water]
    end
    subgraph P[Part VI: +1 hour]
    D1[Maple Gorge] --> D2[Stone Forest] --> D3[Yellow Springs] --> D4[Wheel of Six Paths]
    end
    N --> Play((Game))
    A --> Play
    B --> Play
    I --> Play
    P --> Play
```

- **Natural landscapes instead of stamped copies.** Trees are grown by code from 43 species recipes, each in several seeded variants, with leaf-card canopies lit as one soft volume that glow when back-lit and move in rolling gusts. An ecology layer places them: dense tall forest inside blocked areas, young trees and shrubs at the edges, species gathering in natural stands, ferns, logs and stumps along forest borders, reeds and lotus at the water, flowers in meadows, rocks where the ground is rocky, and thick wind-blown grass. Wildlife moves through it.
- **Architecture.** The sect's halls are rebuilt the traditional way (platform, balustrade, lions, columns with bracket sets, lattice doors, painted beams, curved double-eaved roofs), with a courtyard wall, gate archways and a pagoda. Every road that crosses water gets a stone bridge; huts, shrines, watchtowers, tents, yurts, pavilions and ruins dot the wilds; the built regions get 10 new Blender landmarks.
- **Characters and monsters.** The character builder gained layered hair, richer eyes, fingers, cloth folds, embroidery and animal heads; 19 new characters (every NPC is now a Blender model) and 17 new monsters, so no enemy shape uses the old primitive models any more.
- **A clearer image.** The "slightly blurry lens" look is gone. The frame had no anti-aliasing and was softened by a low-threshold bloom over everything, a soft-light glow, heavy fog with aerial perspective, film grain and chromatic aberration. Now: 4x MSAA, glow only on genuinely bright highlights, light fog, and no grain or fringing.
- **Third-person follow camera.** The camera sits low behind Lin Feng and swings round behind him whenever he walks, so you see his back rather than his side; a held direction key keeps its heading while the camera turns. Trees, rocks, landmarks and buildings standing between the camera and the hero dissolve in an ordered dither, and Yue Ling walks at his shoulder instead of in the camera's way.
- **Part VI** adds +1 hour (see below), verified by the playthrough bot; CI now requires **6 hours**.
- **Graphics code grew from 8,667 to 15,036 lines** (+73%: 8,862 lines of GDScript graphics modules, 6,174 lines of Blender Python).
- **Bugs and plot holes found and fixed** (see below), including one that hid every pond, lake and river in the game.

## 3D graphics

| Area | Before | Now |
|---|---|---|
| Trees | 1-2 meshes per region, one per blocked tile | 43 procedurally grown species in 5 variants each, leaf-card canopies with spherized normals, translucency, gusting wind; per-instance hue, size, lean and yaw |
| Placement | a landmark on every blocked tile, a tuft on every open tile | ecology: distance fields to forest edge, water and road; grove noise; forest-edge undergrowth; meadows, shore plants, logs, rock outcrops; a dwelling per neighbourhood |
| Ground cover | one tuft mesh | curved grass blades with root-to-tip colour, dry and lush patches and gusts; ferns, flowers, lotus, spider lilies, glowshrooms, agave, kelp |
| Rocks | one sphere-like boulder | noise-displaced icospheres: boulders, slabs, spires, scree, pebbles, limestone towers; moss, snow or sand on top |
| Buildings | boxes with a pyramid roof | curved hip roofs with swept corners, tile ribs, ridge ornaments; bracket sets, lattice doors, platforms, lions; walls, archways, pagoda, bridges, 8 kinds of dwelling |
| Landmarks | primitive obelisks, columns, gears | 10 new Blender landmarks (obelisk, jade pillar, column, furnace, gear, monolith, floating island, shard, stone lantern, ghost pagoda) |
| Wildlife | none | flocks, crane formations, butterflies, dragonflies, fish that leap, moths, bats |
| Water | flat, hidden under the ground skirt | visible; sky reflection, sun glints, waves lapping at the shore |
| Mountains | grey six-sided cones | massifs with forested foothills, snow caps and shoulder peaks |
| Characters | 9 Blender people | 28: layered hair and fringes, iris gradients, fingers, folds, embroidered hems and lapels, animal heads |
| Monsters | 12 Blender shapes, 15 primitive | all 29 shapes Blender-built (serpent, crab, spider, mantis, jelly, manta, wisp, wraith, plant, slime, storm, tome, fox, koi, Ox-Head, Horse-Face, hopping corpse, ...) |
| Image | soft, misty | 4x MSAA, highlight-only bloom, light fog, distance-scaled ink outline |

| ![landmarks](docs/screenshots/gallery_landmarks.png) | ![spirits](docs/screenshots/gallery_spirits.png) |
|---|---|
| ![npcs6](docs/screenshots/gallery_npcs_part6.png) | ![keepers](docs/screenshots/gallery_npcs_keepers.png) |
| ![beasts](docs/screenshots/gallery_beasts.png) | ![giants](docs/screenshots/gallery_giants.png) |

```mermaid
flowchart TD
    G[tile grid from mapgen] --> DF[distance fields<br/>to forest, water, road]
    DF --> WT{blocked tile}
    DF --> FT{open tile}
    WT -- edge --> E[shrubs, saplings,<br/>dwelling facing out]
    WT -- interior --> I[tall trees,<br/>sometimes two]
    WT -- built region --> L[Blender landmark]
    FT --> GR[grass by meadow noise]
    FT -- by forest --> FE[ferns, logs, stumps]
    FT -- by water --> SH[reeds, lilies]
    FT -- meadow --> FW[flowers]
    GV[grove noise per species] --> I
    GV --> E
    I --> MM[(MultiMesh per chunk:<br/>variant, hue, size, lean)]
    E --> MM
    GR --> MM
```

## Art pipeline

**Rule: all art is generated from scripts.** Every model, texture, animation and effect must be reproducible by running code that lives in this repository. Hand-made, downloaded or AI-image-generated asset files are not allowed. Rendered screenshots in `docs/screenshots` are outputs, not inputs.

| Source | Use it for | Where |
|---|---|---|
| **Godot code** (GDScript and shaders) | anything built from game data or changing at runtime: terrain, weather, spell effects, shaders, UI | `scripts/` |
| **Blender Python** (`bpy`, Blender 5.2) | hero assets: characters, monsters, rigs and animations, landmarks | `art/` |

- `art/lib/kit.py`: the toolkit. Coordinates are written in Godot space; primitives (ellipsoids, superquadrics, swept tubes with per-point bone weights, lathes, double-sided sheets, leaves, eyes), organic bodies from Blender's **Skin + Subdivision modifiers**, **ray-cast ambient occlusion** baked into vertex colours, the **Decimate** modifier for landmark triangle budgets, armatures, clips baked from Python functions and GLB export.
- `art/lib/person.py` builds every character from options (robe, hair style, hat, weapon, beard, horns, build, age, props, pose, brocade, tinting) with `face.py`, `hair.py`, `garment.py` and `accessory.py`, and the features of the peoples of the realms (wings, crests, fox and fin ears, tails, antlers, scales, whiskers) with `race.py`; `sculpt.py` holds the shared modelling tools (lofts through cross-section profiles, noise, splines, strands).
- `art/lib/clay.py` sculpts creature bodies from metaballs (balls, ellipsoids, capsule chains) that carry smooth bone weights and paint tags; `anatomy.py` builds species heads, torsos, legs, paws, hooves, tails, fur clumps, eyes, ears, horns, claws and fangs; `canine.py`, `feline.py` and `bird.py` build the dog, cat and bird families; `art/lib/creature.py` holds the rigs, IK for legs, gait timing, the shared four-legged motion set and the clip helpers.
- `art/characters/*.py`, `art/monsters/*.py`, `art/props/*.py`: one script per asset, each writing `assets/<group>/<name>.glb`.
- Vertex colour alpha carries the toon shader's surface class, UV.x a tint weight, UV.y a **palette slot** (0 dominant, 0 to 0.2 blending into the underside, 0.5 secondary, 0.6 to 0.8 blending into the markings, 1 accent; `Builder.coat_slots` fills the underside and markings from a monster's painted coat, and `Assets.palette` turns the enemy's colour and element into the five colours), and the material slot (`toon`, `plain`, `glow`) chooses the game shader; `scripts/assets.gd` swaps the materials in at load time and turns the enemy's colour into a palette, so Blender and procedural models share one look.
- `python art/check_assets.py` validates every export (pairing with its script, materials, colours and UVs, triangle budgets, bones, clips); CI runs it after the rebuild.
- Builds are deterministic: rebuilding produces byte-identical files on the same machine. CI rebuilds every asset from its script.
- Every art change is checked visually with the screenshot tour (`--tour`, `--gallery`).

```sh
pip install bpy==5.2.3                        # Blender as a Python module (or use a Blender install)
python art/build_all.py                       # rebuild all 174 assets in parallel (several minutes on 4 cores; ART_JOBS=N)
python art/check_assets.py                     # validate the exports
blender --background --python art/monsters/hundun.py   # or one asset with Blender itself
godot --headless --path . --import            # re-import into Godot
```

```mermaid
flowchart LR
    LIB[art/lib<br/>kit, sculpt, face, hair, garment,<br/>accessory, anatomy, feline, bird] --> BS
    BS[art/*/*.py<br/>Blender Python] -->|bpy / blender --background| GLB[assets/*.glb]
    GLB --> CK[check_assets.py]
    GLB --> AS[assets.gd<br/>game shaders, tint, palette, clips]
    GD[scripts/*.gd<br/>GDScript + shaders] --> GAME((Game))
    AS --> GAME
    GAME -->|--tour --gallery| SHOT[docs/screenshots<br/>visual check]
```

## Run it (terminal)

Requires [Godot 4.3+](https://godotengine.org/download) (developed on 4.7.2) available as `godot` on your PATH and a GPU/driver that supports OpenGL 3 (the project uses the Compatibility renderer).

```sh
git clone https://github.com/jgyy/timegox.git && cd timegox
godot --path . --import      # first time only: imports the project
godot --path .               # play it manually in a window
```

Other terminal commands:

```sh
godot --headless --path . --script tests/run_tests.gd           # data-integrity and 3D-asset tests
godot --headless --path . --script tests/manual_input_test.gd   # real keyboard-event smoke test
godot --headless --fixed-fps 30 --path . -- --bot --min-time=57600   # bot plays the whole game, prints play time
godot --fixed-fps 30 --path . -- --bot --timescale=1            # (drop --fixed-fps for real time) watch the bot
```

| Key | Action |
|---|---|
| Arrows / WASD | move (relative to the camera; a held key keeps its direction while the camera turns), navigate menus |
| Q / E | rotate the camera (it swings back behind Lin Feng as soon as he walks) |
| R | summon your ride or get down (out of doors; it waits outside buildings) |
| T | talk to Yue Ling: a heart-to-heart when she wants one (the corner says so), else a word about where you are |
| Enter / Z / Space | confirm, interact (talk to a townsperson you face), advance dialogue |
| F | swing the sword at what is in front of you: things break (and are paid for) |
| Esc / X | menu (Meditate, Breakthrough, Items, Cultivation, Journal, Fates, Yue Ling, Wardrobe, Stable, Bestiary, ...), cancel |
| Letters, Backspace | type a name of your own at character creation (Enter on a name row) |

Walk into NPCs, enemies, pickups, stairs and bosses to interact with them; walking up to a boss that guards the story opens its trial, with every way through it. There is no save system yet: a full run takes about seventeen hours. Esc > Journal shows your renown, essences and treasures, what townsfolk have asked of you, and every way through the trial ahead. Esc > Cultivation shows your realm (and what it means) and the branches of the Nine Heavens root you have woken; Esc > World Map shows the whole land and the history of where you are (Left/Right turns to the Nine Heavens, the Nine Springs and the Eastern Sea once you have been there); Esc > Annals keeps the history of everywhere you have been; Esc > Dao & Peoples shows the Daos you have walked and your standing with the peoples of the realms; Esc > Fates shows the people whose lives you changed and every choice you made about them; Esc > Wardrobe and Esc > Stable change your outfit and your ride; Esc > Bestiary keeps the story of every foe you have met.

## Gameplay

- **Day and night**: a clock of twelve double-hours (the dial under the minimap); dawn, day, dusk and a moonlit night, lanterns and windows lit after dark, a bed after dark sleeps till six, and a story that can hold the hour.
- **The people of the towns**: 219 townsfolk with homes, work, meals and a night watch, who walk to their work, do it, greet the hero, step aside and talk (Enter); the named townsfolk work at their own places and doze there at night.
- **Things that break**: F at a jar, a crate or a haystack (or a gallop through it) and it comes apart into pieces that fly, tumble and get kicked about; the owner is paid or has words; battles scorch the ground.
- **Yue Ling** (T to talk, Esc > Yue Ling): 30 heart-to-hearts across the journey, each ending in a reply that leans her heart towards one of three futures; 15 wishes of hers to grant by doing things together; a closeness that grows from Companion to Heart's Companion and opens the **Side by side** way through the trials; and in Part XV a story of her own.
- **Character creation**: name the sweeper (or keep the story's name), choose his look, hair, eyes and robe, and his origin in Qingshi Village, which gives him a small strength, a small weakness, a keepsake and lines of his own in the story.
- **Fated encounters** (Esc > Fates): five people met in Part I and again and again until Part XIV, a choice at every meeting; each choice decides the next chapter, can open a way through a trial (**by an old bond**), and decides who stands with Lin Feng at the end and who is fought.
- **Outfits and rides**: twelve outfits (Esc > Wardrobe) with their own colours, hats, crowns and armour and a small passive each; six rides (R to ride, Esc > Stable): a horse, a qilin, a white tiger, a flying sword, a cloud and a sky-barque, faster than running over open ground.
- **Every foe has a story**: the first battle against a kind of monster tells its story over the opening, every boss's story is told before the fight, and the Bestiary (Esc > Bestiary) keeps them all. In Part XIV six of the foes put down on the road come back as **grudges**, each asking what it was owed: pay it, let a friend answer it, or leave it to feed Nie.
- **Cultivation**: gain cultivation by meditating (Esc, Meditate) and winning battles. 61 stages across twenty-one realms (up to Kindred Dao); at the end of each realm you must pass a **Heavenly Tribulation** boss fight to break through. **Realms matter**: a whole realm between two fighters is felt in every blow (realm suppression, x1.2 a realm, up to three), beasts two realms below you scatter, the Founder's nine caves on the mountain open only at their realm, and the world notices the realm you have reached (Esc > Cultivation).
- **Talents: the nine branches of the Nine Heavens root** (Esc > Cultivation): when your qi first stirs, at every tribulation and in every Founder's cave a branch wakes and you choose which: the Sword Bone, the Thunder, Five-Phase and Yin Roots, the Vajra Body, the Sea of Qi, the Enlightened Mind, Heaven's Favour or Spirit Sense, three ranks each and a crown at full leaf. The world grows with the root, so what you wake decides how you keep up.
- **Trials and many roads**: 34 battles that carry the story forward (two lords in every chapter, three in the first, the eight Gate Generals and Chiyou) are trials, harder than the bosses before them and open only to a cultivator who has prepared one of their three or four ways: by might, by craft, by wealth, by respect, by the Dao, by a people's friendship or by a relic. The way taken changes the battle (a weaker foe, allies striking every round, wards, a weakness shown) and the ending names the road you walked most.
- **Crafting**: every foe may leave an essence of its element (bosses always do); Alchemist Mo's cauldron and Smith Tie's forge make 29 talismans, lenses, seals, inks, mirrors and elixirs from essences, things found on the quests and spirit stones.
- **Renown and deeds**: bosses, trials and gifts raise your renown, and so do 28 deeds, requests from townsfolk all over the world; seven titles from Unknown to Legendary, and every respect path asks for a name earned by helping people.
- **Turn-based combat** with qi-costed techniques, elemental weaknesses (fire / water / wood / earth / thunder / dark), pills, a healer companion (Yue Ling) and boss heavy attacks.
- **Fifty regions in four realms**: forty-two on a continent within the Four Seas, two in the Nine Heavens above it, two in the Nine Springs below it and four on the Isles of the Eastern Sea out past its shelf, each with elites, bosses and a hunt objective, joined by winding roads, the Jianmu and Mazu's boat, and **eleven towns** (the sect, Cloudfoot, Qingshi Village, Yanggu, Shazhou Oasis, Longmen, Tushan, Featherfall, Tearwater, Youdu and Landfall). **Part I**: the Sect, Whispering Bamboo Forest, Crimson Marsh, Frostpeak Caverns, Thunder Valley and the Blood Moon Palace. **Part II**: the Sunken Dragon Palace, Ashen Volcano, Void Rift Expanse and the Celestial Gate. **Part III**: the Mirror Lake of Echoes, the Graveyard of Sword Saints, the River of Ten Thousand Years and the Origin of the Dao. **Part IV**: the Sea of Clouds Archipelago, the Ruins of the Jade Court, Heaven's Forge and the Garden of Immortal Peaches. **Part V**: the Desert of Fallen Stars, Glowcap Vale, the Aurora Steppe and the Primordial Chaos. **Part VI**: the Maple Gorge of Returning Souls, the Stone Forest of the Nine Bends, the Yellow Springs of Red Lilies and the Wheel of the Six Paths. **Part VII**: Qingshi Village Below the Mountain, the Cloud-Tea Terraces, the Mulberry Silk Woods and the Loom of Borders. **Part VIII**: the Starfall Ferry on the Silver River, the Heights of the Magpie Bridge, the Palace of the Weaver Star and the Jasper Pool of Kunlun. **Part IX**: Yanggu, the Dawn Market; the Scorched Millet Plains; Fusang, the Valley of Sunrise; and Guanghan, the Palace of the Moon. **Part X**: Longmen, the Dragon Gate Ferry; the Drowned Fields of Gun; Tushan, the Town of the Cauldron-Casters; and Mount Buzhou, the Broken Pillar. **Part XI**: Juntian, the Level Heaven, and Changhe, the Gate of Heaven, in the Nine Heavens; the Nine Springs beneath the Roots and Youdu, the Dark Capital, in the Nine Springs. **Part XII**: Penglai, the Isle of the Immortals (Landfall); Fangzhang, the Square-Pot Isle; Yingzhou, the Isle of Mists; and Guixu, the Returning Ruins, in the Eastern Sea. **Part XIII**: the Eight Gates, in eight of these regions across all four realms, and the buried field of Zhuolu under the oldest maples of the Maple Gorge. **Part XIV (new)**: the five threads of the journey, settled where their people wait, six grudges that stayed where their owners fell (in the Bamboo Forest, the Crimson Marsh, the Graveyard of Sword Saints, Tushan, Juntian and Guixu), and Nie at the heart of the Wheel of the Six Paths. **Part XVI (new)**: the New Year, in the sect, the bamboo forest, the towns of Qingshi, Yanggu, Cloudfoot, Longmen, Tushan and Shazhou, the Cloud-Tea Terraces, the snows of Frostpeak and the Garden of Immortal Peaches.
- **Techniques** for the late game: Abyssal Tide, Meteor Rain, Void Rending Slash, Celestial Judgement, Chrono Severance, Genesis Sword, Ten Thousand Starfall, Ledger-Breaking Stroke, Sky-Mending Sword, Five-Colour Stone Rain, Pillar of Heaven Strike, Six Paths Wheel Slash, Ten Thousand Lantern Rain, Samsara Sword, Seam-Cutting Sword, Thousand-Thread Rain, Boundless Heart Sword, Magpie Bridge Sword, Silver River Torrent, Seventh-Night Reunion Sword, Noon-Splitting Sword, Fall of the Nine Suns, Tenth Arrow Sword, Dragon Gate Leap, Swelling Earth Rampart, Nine Cauldrons Sword, Strike of the Standing Tree, Torrent of the Nine Springs, Three Realms Concord Sword, **Returning Tide Sword**, **Rain over the Five Isles** and **Jingwei's Stone Sword**, plus Yue Ling's Starlight Rain, Dawn Lotus, Seal Bloom, Five-Colour Thread, Nuwa's Mending, Spirit Lantern Ward, Lotus of Rebirth, Silver Silk Snare, Homeward Lantern, Starweave Net, Magpie Wing Ward, Osmanthus Moon Rain, Moon-Dew Ward, Reed-Boat Blossom, River-Mother's Ward, Rain of Phoenix Feathers, Ward of the Standing Tree, **Spray of the Pearl Trees** and **Mazu's Red Lantern** (the reviving heals also raise a fallen ally); and the six **Dao techniques** (Ten Thousand Swords Return to One, Peng's Wind of Ninety Thousand Li, Lotus Heart Sutra, Eight Trigrams Grand Array, Nine-Turn Golden Elixir Fire and Mirror-Flower, Water-Moon), one for each Dao from Adept on.
- **Upstairs and down**: 30 upper storeys and cellars, each reached by its stairs, with people, quest scenes and hidden keepsakes; the Jianmu's stairs climb to the Nine Heavens and go down to the Nine Springs, and Mazu's boat sails from Fusang to the isles.
- **Cutscenes**: conversations over the world play out with gestures (nod, shake, point, wave, laugh, grieve, think, kneel, offer, shock, bow) picked from each line, answered by the listener, and framed by a two-shot conversation camera.
- **Daos** (Esc > Dao & Peoples): choose one of six roads when the Jianmu grows back and change at any Dao Stele; each has a mastery from Novice to Master, passive powers that grow with it and a technique from Adept on, and the story answers the one you walk.
- **The peoples of the realms**: the Feathered Folk, the dragon-kin, the celestial foxes, the Pearl-Weepers, the Deathless, the shades of Youdu, the Thousand Children of Landfall and the Immortals of the Isles; your standing with each grows with the help you give in their lands and with the keepsakes you give them, faster if you walk the Dao they honour, and a people that calls you Friend grants a boon.
- **The Annals** (Esc > Annals): the history of every region and town Lin Feng has been to, and the Founder's words from every cave he has opened; the world map shows the one he is standing in.
- **Economy**: spirit stones buy pills, tempering for your sword, what the cauldron and the forge make, and the wealth paths through the trials.

```mermaid
flowchart LR
    subgraph P1[Part I: about 1h06m]
    Sect[Azure Cloud Sect<br/>hub, shops, Elder] --> Bamboo[Bamboo Forest]
    Bamboo --> Marsh[Crimson Marsh]
    Marsh --> Frost[Frostpeak Caverns]
    Frost --> Thunder[Thunder Valley]
    Thunder --> Palace[Blood Moon Palace<br/>Demon Lord Xu Mo]
    end
    subgraph P2[Part II: about 1h04m]
    Palace ==>|Deity Tribulation| Dragon[Sunken Dragon Palace]
    Dragon --> Volcano[Ashen Volcano]
    Volcano -->|Void Tribulation| Void[Void Rift Expanse]
    Void --> Gate[Celestial Gate<br/>Jade Emperor of Ruin]
    end
    subgraph P3[Part III: about 1h01m]
    Gate ==>|Dao Merging, Lotus Seal recalls you| Sect2[Sect: the Elder's confession]
    Sect2 --> Mirror[Mirror Lake of Echoes<br/>Echo of Xu Mo]
    Mirror --> Grave[Graveyard of Sword Saints<br/>Founder Qing Lian]
    Grave -->|Mahayana Tribulation| Time[River of Ten Thousand Years<br/>Tian Xuan]
    Time --> Origin[Origin of the Dao<br/>The Hollow Heaven]
    end
    subgraph P4[Part IV: about 1h06m]
    Origin ==>|True Immortal, names written in the sky| Sect3[Sect: the Jade Ledger]
    Sect3 -->|west gate| Clouds[Sea of Clouds<br/>Herald Qian Shu]
    Clouds --> Court[Ruins of the Jade Court<br/>Registrar Si Ming]
    Court --> Forge[Heaven's Forge<br/>Forge-Lord Tian Gong]
    Forge --> Garden[Garden of Immortal Peaches<br/>The Jade Ledger]
    end
    subgraph P5[Part V: about 1h08m]
    Garden ==>|Dao Ancestor, stars fall at noon| Sect4[Sect: the falling sky]
    Sect4 -->|south-east road| Dunes[Desert of Fallen Stars<br/>Bai Hu, White Tiger]
    Dunes --> Fungal[Glowcap Vale<br/>Zhu Que, Vermilion Bird]
    Fungal --> Aurora[Aurora Steppe<br/>Xuan Wu, Black Tortoise]
    Aurora --> Chaos[Primordial Chaos<br/>Hundun, the Faceless]
    end
    subgraph P6[Part VI: about 1h07m]
    Chaos ==>|Primordial Sovereign, the dead stop moving on| Sect5[Sect: the queue at the gate]
    Sect5 -->|south-west funeral road| Maple[Maple Gorge<br/>Ox-Head]
    Maple --> Karst[Stone Forest<br/>Horse-Face]
    Karst --> Springs[Yellow Springs<br/>The Thousand Unforgotten]
    Springs --> Wheel[Wheel of the Six Paths<br/>King Yama]
    end
    subgraph P7[Part VII: about 1h07m]
    Wheel ==>|Samsara Transcendence, threads across the roads| Sect6[Sect: the Weaver's seams]
    Sect6 -->|south road| Village[Qingshi Village<br/>Needle General Zhen]
    Village --> Terraces[Cloud-Tea Terraces<br/>Thread Matron]
    Terraces --> Silk[Mulberry Silk Woods<br/>Thousand Hands]
    Silk --> Loom[Loom of Borders<br/>Madam Qianxian]
    end
    subgraph P8[Part VIII: about 1h11m]
    Loom ==>|Boundless Heart, the Silver River floods| Sect7[Sect: drowned stars in the pond]
    Sect7 -->|south road, the old Sky Road| Ferry[Starfall Ferry<br/>Qilin of the Rising Tide]
    Ferry --> Magpie[Magpie Bridge Heights<br/>Crow Marshal]
    Magpie --> Star[Weaver Star Palace<br/>Heavenly Warden of the River]
    Star --> Jasper[Jasper Pool of Kunlun<br/>Xiwangmu, Queen Mother of the West]
    end
    subgraph P9[Part IX: about 1h19m]
    Jasper ==>|Star River Crossing, the sun will not set| Sect8[Sect: noon for nine days]
    Sect8 -->|the new south road| Yanggu[Yanggu Dawn Market<br/>Hanba, the Drought Fiend]
    Yanggu --> Millet[Scorched Millet Plains<br/>Bifang, the Fire Crane]
    Millet --> Fusang[Fusang Valley of Sunrise<br/>Jinwu, the Sun Crow]
    Fusang --> Guanghan[Guanghan, Palace of the Moon<br/>Xihe, Mother of Suns]
    end
    subgraph P10[Part X: about 1h14m]
    Guanghan ==>|Sun-Moon Harmony, the maps are wrong| Sect9[Sect: the Court's squares give way]
    Sect9 -->|the north gate| Cloudfoot[Cloudfoot<br/>Cartographer Pei]
    Cloudfoot --> Longmen[Longmen, the Dragon Gate<br/>He Bo, Earl of the River]
    Longmen --> Drowned[Drowned Fields of Gun<br/>Gun, the Swelling Earth]
    Drowned --> Tushan[Tushan of the Cauldrons<br/>Taotie, the Glutton]
    Tushan --> Buzhou[Mount Buzhou<br/>Gonggong, God of the Flood]
    end
    subgraph P11[Part XI: about 1h18m]
    Buzhou ==>|Mountain-River Oneness, a tree in the night| Sect10[Sect: the Jianmu<br/>and the Sealed Archive]
    Sect10 -->|up the trunk| Juntian[Juntian, the Level Heaven<br/>Leigong, Duke of Thunder]
    Juntian --> Changhe[Changhe, the Gate of Heaven<br/>Chong, Who Lifts Heaven]
    Changhe -->|down the roots| NineSprings[The Nine Springs<br/>Zhulong, the Torch Dragon]
    NineSprings --> Youdu[Youdu, the Dark Capital<br/>Li, Who Presses Down the Earth]
    end
    subgraph P12[Part XII: about 1h23m]
    Youdu ==>|Three Realms Concord, the tide goes out| Sect11[Sect: a boat on an ox-cart]
    Sect11 -->|east to Fusang, Mazu's boat| Penglai[Penglai, Landfall<br/>the Giant of Longbo]
    Penglai --> Fangzhang[Fangzhang<br/>Tianwu]
    Fangzhang --> Yingzhou[Yingzhou<br/>Yu Qiang]
    Yingzhou --> Guixu[Guixu, the Returning Ruins<br/>Xu Fu]
    end
    subgraph P13[Part XIII: about 49 minutes]
    Guixu ==>|Ten Thousand Waters Return, eight bars of gold| Sect12[Sect: the eve of the Conclave]
    Sect12 -->|the funeral road| MapleH[Maple Gorge: the lantern monk]
    MapleH --> Gates{any four of the Eight Gates,<br/>in any order, in four realms}
    Gates --> Zhuolu[the field of Zhuolu: Chiyou,<br/>by the Sword, the Many Peoples or the Cauldron]
    end
    subgraph P14[Part XIV: about 49 minutes]
    Zhuolu ==>|Myriad Daos as One, threads on his wrists| Sect13[Sect: the ripening of karma]
    Sect13 -->|the funeral road| Wheel2[the Wheel: Judge Cui,<br/>the grudges round its rim]
    Wheel2 --> Five{settle the five threads,<br/>in any order}
    Five --> Grudges{the six grudges that stayed,<br/>where they fell, in any order:<br/>bamboo, marsh, graves, Tushan,<br/>Juntian, Guixu}
    Grudges --> Nie[Nie, the Unpaid,<br/>by the bonds you made]
    end
    subgraph P15[Part XV: about 47 minutes]
    Nie ==>|Karma Fulfilled, and nobody remembers her name| Sect14[Sect: the lotus pond where she woke]
    Sect14 -->|the funeral road| Wheel3[the Wheel: Judge Cui]
    Wheel3 --> Graves[the Sword Graveyard:<br/>the moths, the Founder's echo]
    Graves --> Loom[the hermitage:<br/>the loom she was woven on] --> Mem{six of seven memories,<br/>any order, in seven regions}
    Mem --> MothQ[the Silk Woods:<br/>the Moth-Queen] --> Unw[the Loom: the Unweaver]
    Unw --> Thr{six people tie<br/>a thread for her} --> Ward[the mountain: Suo,<br/>Warden of the Lock]
    Ward --> Pond[the lotus pond:<br/>the first line of her life] --> Feast[the mountain: her naming feast]
    end
    Feast ==> End((Kindred Dao))
```

```mermaid
flowchart TD
    A[Meditate / fight] -->|exp >= threshold| B{Realm cap?}
    B -- no --> C[Stage up<br/>HP and Qi restored]
    C --> A
    B -- yes --> D[Complete zone quests]
    D --> E[Heavenly Tribulation battle]
    E -- win --> F[Next realm]
    E -- lose --> G[Wake in sect<br/>lose 15% stones]
    G --> A
    F --> A
```

## Part III: The Hollow Heaven

After the Jade Emperor falls and Lin Feng merges with the Dao, the Heavenly Lotus Seal recalls him to the sect, where Elder Qing Xuan finally explains what the Seal is, who the Emperor was and why the sky is still cracking. Four new regions, 16 bosses, 12 monsters and five dialogue-heavy quest chains (about +1 hour) follow:

| Region | Levels | Story beat | Final boss |
|---|---|---|---|
| Mirror Lake of Echoes | 18-19 | The lake remembers the nineteen bearers before Lin Feng | Echo of Xu Mo |
| Graveyard of Sword Saints | 19-20 | The Seal's key and the founder of the sect | Founder Qing Lian |
| *Mahayana tribulation* | | | |
| River of Ten Thousand Years | 21-22 | The Emperor's origin as the first sweeper | Tian Xuan, the First Sweeper |
| Origin of the Dao | 22-23 | Yue Ling's secret and the Hollow Heaven | The Hollow Heaven |
| *True Immortal tribulation and ending* | | | |

## Part IV: The Unwritten Ledger

Lin Feng ascends as a True Immortal, but across the golden dawn someone is writing names in jade ink: the nineteen bearers, and his own. The Lotus Seal pulls him home, where everyone who ever survived a tribulation is ageing by the hour. The harvest had a bookkeeper: the Heavenly Court's **Jade Ledger**, still trying to balance its columns by collecting years from the living. Four new regions, 16 bosses, 12 monsters, five quest chains (each with a hunt, a collection and a delivery scene) and a new realm follow:

| Region | Levels | Story beat | Final boss |
|---|---|---|---|
| Sea of Clouds Archipelago | 24-25 | The Court's tollgate in the sky; a cloud-step woven from feathers | Herald of the Ledger, Qian Shu |
| Ruins of the Jade Court | 25 | A runaway scribe, four Jade Seals and the brush that wrote every name | Grand Registrar Si Ming |
| Heaven's Forge | 25-26 | Where every tribulation bolt was hammered; the brush is reforged to unwrite | Forge-Lord Tian Gong |
| Garden of Immortal Peaches | 26 | The nineteen bearers wake and remember their names | The Jade Ledger |
| *Dao Ancestor tribulation and new ending* | | | |

Part III's ending now flows into Part IV (the final ascension sets up the Ledger instead of closing the story), and the ending screen reflects the new finale.

## Part V: The Falling Sky

Lin Feng keeps his word and sweeps the steps, until stars start falling at noon. The Heavenly Court had propped up the sky with the years it harvested; with the Ledger closed, nothing holds it. Nuwa once mended the sky with stones of five colours and set four pillars beneath it. The eastern pillar still stands because the Azure Dragon King (freed in Part II) holds it up out of gratitude; the other three wardens have starved and gone wild, and at the centre Hundun, the faceless chaos from before the world, is waking. Four regions, 16 bosses, 12 monsters, five quest chains and a new realm:

| Region | Levels | Story beat | Final boss |
|---|---|---|---|
| Desert of Fallen Stars | 27 | Nomads who sing star fragments back into the sky | Bai Hu, White Tiger of the West |
| Glowcap Vale | 27-28 | A spore-witch's glowcaps rekindle a cold fire | Zhu Que, Vermilion Bird of the South |
| Aurora Steppe | 28-29 | The sky's breath, caught on the snow, wakes a frozen god | Xuan Wu, Black Tortoise of the North |
| Primordial Chaos | 29 | The First Lightning, Pangu's shadow and the Ancestor Lin Feng refused to become | Hundun, the Faceless Chaos |
| *Primordial Sovereign tribulation and new ending* | | | |

New creature types built in Blender for Part V: scorpion, mushroom folk, mammoth, lantern moth and Hundun (four wings, six legs, no face).

## The open world

```mermaid
flowchart TD
    D[(data.gd: 51 areas,<br/>gates, NPCs, bosses, caves,<br/>buildings, floors, rivers, roads)] --> MG[mapgen.gd: each region's own map<br/>organic outline, river, ponds,<br/>spline roads, A* trails]
    S[atlas.gd SITES: a site and a way<br/>for every region] --> L[layout: maps turned<br/>to face their road]
    MG --> AT[atlas.gd _build]
    L --> AT
    AT --> PIN[pins: the land round people,<br/>bosses, gates and buildings]
    AT --> OW[ownership: nearest site in its own<br/>half-sizes, after a two-scale warp]
    PIN --> OW
    OW --> SEA[coast: land runs out about two<br/>half-sizes out; the Four Seas]
    OW --> BE[forest belt where<br/>two regions meet]
    SEA --> IS[land bridges along<br/>every road]
    IS --> RO[roads: A* over the land,<br/>one border crossing each]
    RO --> SE[Lotus Seal across the road<br/>where it crosses]
    RO --> CO[reconnect anything cut off]
    CO --> G[one world grid 1040 x 900:<br/>558k tiles of land, 378k of sea]
    G --> BOT[bot: AStarGrid2D over the world]
    G --> W[world.gd]
    W --> STR[stream regions within 46 tiles:<br/>land slice + shared heights + Terrain3D.build]
    W --> SEAR[Terrain3D.world_sea:<br/>one ocean for the whole world]
    W --> IN[houses: roof lifts while inside]
    AT --> RLM[the same build for the Nine Heavens<br/>and the Nine Springs, 260 x 200 each:<br/>islands over cloud, caverns over an abyss]
    AT --> ESEA[and for the Eastern Sea, 520 x 200:<br/>four isles in real sea, sandbar causeways]
    RLM --> LAD[ladders: the Jianmu's stairs line up<br/>across the realms, layer_origin;<br/>Mazu's boat sails from Fusang]
    ESEA --> LAD
    AT --> FLR[floors: every upper storey and cellar<br/>a small world of its own, with stairs]
    LAD --> W
    FLR --> W
```

| Way out of the mountain | Chapter | Regions | Entered from |
|---|---|---|---|
| east, then north up the east coast | Part I | Bamboo Forest, Crimson Marsh, Frostpeak, Thunder Valley, Blood Moon Palace | the sect's east gate |
| west along the north coast | Part II | Sunken Dragon Palace, Ashen Volcano, Void Rift, Celestial Gate | the road on from the Blood Moon Palace |
| south | Part III | Mirror Lake, Sword Graveyard, River of Ten Thousand Years, Origin of the Dao | the sect's south gate |
| west, then north into the sky | Part IV | Sea of Clouds, Jade Court, Heaven's Forge, Peach Garden | the sect's west gate |
| south-east | Part V | Desert of Fallen Stars (Shazhou Oasis), Glowcap Vale, Aurora Steppe, Primordial Chaos | the south-east road |
| west-south-west | Part VI | Maple Gorge, Stone Forest, Yellow Springs, Wheel of the Six Paths | the south-west funeral road |
| south-west | Part VII | Qingshi Village, Cloud-Tea Terraces, Mulberry Silk Woods, Loom of Borders | the village road |
| south-south-west | Part VIII | Starfall Ferry, Magpie Bridge Heights, Weaver Star Palace, Jasper Pool of Kunlun | the old Sky Road |
| east to the sunrise | Part IX | Yanggu, Scorched Millet Plains, Fusang, Guanghan | the east road from the south gates |
| north, then west to the broken pillar | Part X | Longmen, Drowned Fields of Gun, Tushan, Mount Buzhou | the north gate, through Cloudfoot |
| up the Jianmu's trunk, then east across the islands | Part XI | Juntian (Featherfall), Changhe | the stair round the Jianmu, west of the sect |
| down the Jianmu's roots, then east through the caverns | Part XI | the Nine Springs (Tearwater), Youdu | the stair down the roots, from the root-cave at the Jianmu's foot |
| east over the sea in Mazu's boat, then east from isle to isle | Part XII | Penglai (Landfall), Fangzhang, Yingzhou, Guixu | Mazu's jetty on the pool of the suns in Fusang |

Each region is still generated from its own seed by `mapgen.gd` (so every boss, NPC and herb keeps its place), but its open ground is no longer the rectangle of its map: an ellipse filling the map is pushed into lobes and bays by a domain warp, bitten by a second noise and frayed at the edge, with clearings kept round everything that matters and trails (a cost-weighted A* that goes round buildings) joining anything left in the forest. `atlas.gd` then turns the map to face the way its road runs and lays it at its site. Every tile of the world belongs to the region whose site is nearest, measured in that region's own half-sizes after a two-scale domain warp (and the land round a region's people, bosses, gates and buildings always belongs to it); a forest belt marks where two regions meet. Land runs out about two half-sizes from the nearest site, which gives the continent its coast, the fjords between the mountain's spurs and the inner sea in the north-east, and fades out towards the edge of the world, which is always open sea. Roads are searched for with A* across the land (old paths cheap, forest dear, water dearer, a slow noise to make them wind), keep to their own two regions and cross the border between them exactly once, on a land bridge raised for them; where a chapter is not open yet, a Lotus Seal stands across the road at that crossing. Tests check that every entity can be walked to, that with all seals shut only the sect, the mountain (with Cloudfoot) and the bamboo forest can be reached, that the sea rings the land, that regions are not laid out in rows and columns, that every region's corners are mostly forest, and that the world is deterministic.

**The realms above and below** (Part XI) are built by the same `Atlas._build`, one realm at a time (`Atlas.world_of(layer)`): `STRATA` gives each its own 260 x 200 grid, the sites of its regions, how far land reaches from a site (land runs out into open sky or into the abyss instead of the sea) and how many holes to open in the wild ground between regions (gaps of sky between the islands, chasms between the caverns). `layer_origin` lays each grid over the land's so that the Jianmu's crown in the Nine Heavens floats straight above its trunk on the mountain and its roots in the Nine Springs hang straight below. The ends of a ladder are two linked entities, one in each realm; walking onto one lifts or lowers Lin Feng and puts him on the free tile beside the other end. The Nine Heavens are drawn 96 m above the land and the Nine Springs 64 m below it, and `world.gd` keeps a bundle per realm (its land, its streamed regions, its sea of cloud or glowing abyss) and shows only the one Lin Feng is in. A **floor** (`Atlas.floor_id`, `f:<region>:<building>:<level>`) is a world of its own the size of its building, holding the people and things that live on it and the stairs back.

The 3D view builds a region when the player comes within 46 tiles of the bounding box of its land: its own land is cut out of the world grid (other regions' tiles and the open sea blanked), corner heights come from one shared height field so neighbours meet without a crack, and the usual terrain, ecology, wildlife and buildings are built for it. The sea is a single surface for the whole world (`Terrain3D.world_sea`), running on to the horizon. Far regions are hidden and the furthest dropped.

## Part XVI: The Year Turns

For the first time since Lin Feng picked up a broom, a year can simply end. The snow comes; the road from Cloudfoot fills with cabbages, firewood and red paper; Little Bai sweeps the bad luck out of the whole sect. Then, on the Little New Year, when every stove in the land sends its Kitchen God up the chimney to report on the household, the sect's Kitchen God climbs down out of the smoke instead and asks for a cup of tea. **Nian is awake**: the Year Beast, who sleeps under the mountains all year and eats every fear anybody had in it, and comes down to the villages on New Year's Eve for the rest. It has eaten the longest, most frightening year the world ever had, and the towns, worn out by it, have forgotten the three things it is afraid of: **red, fire and noise**.

| Step | Where | What happens |
|---|---|---|
| The Kitchen God would not go up | the sect | the Elder: Zao Jun is sitting on Auntie Zhou's stove, and will only speak to the sweeper |
| Zao Jun, Lord of the Stove | the sect's kitchen | Nian is awake and has never been this big; before it comes Xi, the Last Night, who eats the last light of the year; and nobody must be alone on the night itself |
| The last sweeping | the courtyard | he sweeps the old year out with the old broom, and she asks what he thought about for three years (her heart leans) |
| Red paper | the towns' markets | buy red paper for the sect's couplets from **four merchants of the towns** (face one and press Enter) |
| The couplets | the Scripture Library | he and Yue Ling write the sect's New Year couplets on the red paper (her heart leans) |
| The Kitchen God's report | Qingshi | ask **five of the village's farmers** what their year was like, for Zao Jun's report to Heaven; each has a story (the flood, the nine days of noon, a wedding, a death and a birth) |
| Thunder bamboo | the Bamboo Forest | four stalks of the bamboo that bangs on a fire, the first firecrackers |
| **The old ways, in five of six towns** | Qingshi, Yanggu, Cloudfoot, Longmen, Tushan, Shazhou | Granny Wen, the night-watchman, the postmaster, the lock-keeper, the bell-caster and the well-keeper bring their towns out to practise: every pot, gong and bell in the street (and in Longmen, Yue Ling cuts red paper carp for every window) |
| The hunger on the terraces | the Cloud-Tea Terraces | drive off the Lean Months, the candle-eating moths and Nian's cubs (three new monsters, each with its story) |
| The Lean Month King | the top of the terraces | a new boss: a crowned skeleton on a throne of empty rice jars, counting the grain that is left |
| The door gods' peach wood | the Garden of Immortal Peaches | Shenshu and Yulei, home under the great peach tree because nobody pasted them up this year, give him two boards of peach wood with their names on |
| Winter plum | the snows of Frostpeak | eight sprigs of the plum that flowers in the snow, for the vases on the reunion table |
| A fish for the table | Longmen | buy the reunion dinner's fish (so that every year has more than enough) from **five fishermen** of the towns; Longmen's are on the river |
| The candle-moths | the Dawn Market | Xi's candle-eating moths and the Lean Months are eating the market's lanterns: drive them out of the lanes |
| The reunion dinner | the sect's kitchen, New Year's Eve | the whole sect squeezed into the kitchen, a god on the stove, a coin in a dumpling: her first New Year's Eve (her heart leans); a courier: the lanterns of Yanggu are going out |
| **Xi, the Last Night** | the Dawn Market | a trial: **the door gods' peach wood** (relic), **every gong in the market** (by the people: three towns), thunder-bamboo crackers (craft) or might; then the night stops: Xi has eaten the hours with the light |
| The vigil | Granny Wen's house in Qingshi | the whole village on stools round her table, nobody asleep (her heart leans) |
| **Nian, the Year Beast** | Qingshi, at midnight | a trial: **every pot in the land** (by the people: four towns), **not alone** (side by side), the Lantern of Ten Thousand Doors (craft), the name the world knows (respect 900) or might |
| The first dawn of the year | the sect's bell | a hundred and eight strikes, one for every trouble a person can have (her heart leans) |
| Nian's cubs | the Whispering Bamboo Forest | New Year's morning: the cubs that followed Nian down hide in the bamboo and jump out at the children in their new clothes; drive twenty of them back into the hills |
| Red envelopes | the towns | New Year's Day: **eight children of the towns**, in their new red clothes |
| The grandparents | the towns | pay New Year respects to **four grandparents of the towns** |
| New Year calls | the sect | wish six of the sect's people a good new year, in any order |
| Lantern riddles | the Dawn Market | the stallholders hang riddles on their lanterns: guess **six** of them (a lantern, a broom, tangyuan, the New Year, the upside-down Fu, the moon), and the evening of the festival comes |
| The Lantern Festival | the Dawn Market | the fifteenth night: every lantern in Yanggu, sweet dumplings, and a sword form on the stage at the crossroads (her heart leans) |
| *Ten Thousand Hearths* | | the last tribulation comes from every lit window in the land, asking him in out of the cold |

```mermaid
flowchart TD
    H[the Kitchen God would not go up] --> ZJ[Zao Jun: Nian is awake;<br/>red, fire and noise] --> SW{the last sweeping:<br/>what do you sweep out?}
    SW --> PA[red paper from four merchants] --> CP{the couplets} --> RP[five farmers' years<br/>for the Kitchen God's report] --> BA[four stalks of thunder bamboo]
    BA --> RA{five of six towns reminded:<br/>Qingshi, Yanggu, Cloudfoot,<br/>Longmen, Tushan, Shazhou}
    RA --> HU[the hunger on the terraces] --> LK[the Lean Month King] --> DG[the door gods' peach wood]
    DG --> PL[winter plum in the snows<br/>of Frostpeak] --> FI[a fish for the table<br/>from five fishermen] --> EV{the reunion dinner:<br/>her first New Year's Eve} --> MO[the candle-moths<br/>in the market] --> XI{Xi, the Last Night:<br/>peach wood, the people,<br/>crackers or might}
    XI --> NT[the night will not end] --> VG{the vigil at Granny Wen's} --> NI{Nian, the Year Beast:<br/>the people, not alone,<br/>a lantern, respect or might}
    NI --> DW{the first dawn:<br/>a hundred and eight strikes} --> CB[Nian's cubs in the bamboo] --> HB[red envelopes for eight children] --> GP[respects to four grandparents] --> CA[New Year calls round the sect] --> RI[six lantern riddles] --> LF{the Lantern Festival} --> TT((Ten Thousand Hearths))
    RA -.->|By the people| XI
    RA -.->|By the people| NI
    T[four heart-to-hearts: her first New Year,<br/>the hungry winters, the long night,<br/>the first morning] -.-> NI
```

## Part XV: The Thread She Never Had

For nine days after the last tribulation nothing on Azure Cloud Mountain is owed to anybody. On the tenth morning Disciple Han sets out the Elder's tea and frowns at the second cup: *who is it for?* It is for Yue Ling, and it has been for ten years. When every thread in the world went slack at the Wheel, one thing had no thread to go slack: she was **woven, not born** (the Founder made her out of the Lotus Seal's own lotus so that the bearer would never face the end alone), and everything she did on the road went into Lin Feng's column. Now that nothing is owed, the world is very tidy, and it is putting her away, gently, the way a book goes back on a shelf: people forget her name, and petals come away from her hands.

| Step | Where | What happens |
|---|---|---|
| Nobody remembers her name | the sect | the Elder explains: she needs a place in the world that is hers, a page in the Book of Life and Death |
| The lotus pond | the sect | they set lotus lanterns on the pond where she woke; she tells him what is happening to her, and he promises her something (her heart leans) |
| No page for the never-born | the Wheel of the Six Paths | Judge Cui: a page is grown, not made, from a past of your own, people who remember you, and a first line you write yourself; and something is eating her past |
| The moths among the graves | the Graveyard of Sword Saints | drive off the Loose Threads, Moths of Forgetting and Unweaving Shuttles (three new monsters, each with its story) |
| The Founder's echo | beside her barrow | Qing Lian, threading a needle: every time a bearer died Yue Ling was unwoven and woven again, and the Founder pressed what she remembered where she had been happiest; and the part of the Seal that was a lock calls itself the Warden now, and wants her back |
| The loom she was woven on | the Founder's Hermitage under the Last Cave, on the mountain | he sits at the loom and she guides his hands on the shuttle, feeling where the Founder was tired and where she sang; what do they weave? (her heart leans) |
| **Six of seven memories, in any order** | the Bamboo Forest, Frostpeak, the Yellow Springs, the Starfall Ferry, the Cloud-Tea Terraces, the Magpie Bridge, Yanggu | at each, fight off what is eating it, then do there what she did with that bearer, together, while she remembers it; then answer her (her heart leans) |
| The Moth-Queen of Forgetting | the Mulberry Silk Woods | a new boss; out of her scales come the things the moths had eaten |
| **The Unweaver** | the Loom of Borders | a trial: **hand in hand**, side by side (closeness: Dear Friend), a shuttle of pressed petals (craft), her friends' threads (bonds) or cut every thread it holds (might) |
| Six threads | anywhere | any six of Qiu Ye, Tala, Fang Hu, Xu Lan, Liu Ying, Alchemist Mo, Smith Tie, Archivist Lan, Granny Wen, Mazu and Meng Po tie a thread on her wrist and tell what they remember of her (so it can always be done, even if every one of the five fell) |
| **Suo, Warden of the Lock** | under the Founder's Last Cave, by her hermitage | a trial: **she chooses to stay** (closeness: Kindred Spirit), the Key of the Open Door (craft), a name the world will not forget (respect 800) or break the lock (might) |
| The first line of her life | the lotus pond, at dawn | the Book of Life and Death has a page for her; she writes the first line herself: his Dao companion, the lotus of the mountain, or a road of her own (the one her heart leans to is marked) |
| The naming feast | the open-air stage on the mountain, below the Jianmu | the sect decides she has just been born and throws her a naming feast; he gives them a sword form on the stage, and says who it is for |
| *Kindred Dao* | | the last tribulation comes up out of the pond: two reflections, his and hers; nobody reaches the top of the mountain alone |

The seven memories (`Bonds.MEMORIES`), each one of the bearers she walked beside before Lin Feng:

| The memory | Where | The bearer | What the two of them do there |
|---|---|---|---|
| **Ah Zhu's flute stone** | the Bamboo Forest | Ah Zhu, the third bearer, a woodcutter's daughter who played the flute terribly | she plays Ah Zhu's tune on the flute left on the rock |
| **Bai Shan's hot spring** | Frostpeak Caverns | Bai Shan, the sixth bearer, a soldier home from a war, who could not sleep | they soak in the snow, and nobody asks anybody anything |
| **Old Jiang's lantern jetty** | the Yellow Springs | Old Jiang, the ninth bearer, a ferryman who lost his wife to the river | two lotus lanterns on the water, so neither goes alone |
| **Chun's kite post** | the Cloud-Tea Terraces | Chun, the twelfth bearer, a tea-picker of fourteen | he flies her red kite; hold the string, tie it, or cut it, as Chun did |
| **Wen Shu's lantern green** | the Magpie Bridge Heights | Wen Shu, the fifteenth bearer, a scholar who failed four times and married on Qixi | they dance under the lanterns, as she danced at his wedding |
| **Fat Bao's millstone** | Yanggu, the Dawn Market | Bao, the seventeenth bearer, a noodle-maker who fed the whole market | he pushes the millstone; feed them first, save the world after |
| **Xing Yao's armillary** | the Starfall Ferry | Xing Yao, the eighteenth bearer, the Court's dismissed astronomer | they lie back in the grass, and she finds the star Xing Yao named for her |

```mermaid
flowchart TD
    H[the Elder: her name is slipping] --> P{the lotus pond:<br/>what do you promise?}
    P -->|I'll remember you| C1[companion]
    P -->|the mountain won't let you go| L1[lotus]
    P -->|let's go and find your past| W1[wander]
    C1 & L1 & W1 --> J[Judge Cui] --> GR[the graves: drive off the moths] --> FE[the Founder's echo]
    FE --> LO{the loom she was woven on:<br/>what do you weave?}
    LO --> MEM{any six of seven memories}
    MEM --> F1[fight what is eating it] --> SC[the scene: they do it together] --> AN{what do you say?}
    AN -->|leans her heart| MEM
    MEM -->|six| MQ[the Moth-Queen] --> UN{the Unweaver:<br/>side by side, a shuttle,<br/>her friends' threads, might}
    UN --> TH{six people tie a thread}
    TH --> WD{Suo, Warden of the Lock:<br/>she chooses to stay, a key,<br/>respect, might}
    WD --> NM{the first line of her life}
    NM -->|his Dao companion| FS[the naming feast:<br/>a sword form on the mountain's stage]
    NM -->|the lotus of the mountain| FS
    NM -->|a road of her own| FS
    FS --> KD((Kindred Dao))
    T[30 heart-to-hearts on the road,<br/>15 wishes, things done together] -.->|closeness and her heart| UN
    T -.-> WD
    T -.-> NM
```

## Part XIV: The Ripening of Karma

The first Conclave goes on for nine days, and on the tenth everybody goes home. In the evening, sweeping the steps, Lin Feng finds threads on his wrists, fine as spider silk and warm, running out over the edge of the mountain and all pulling, very gently, south-west. **Cause and effect**, the Elder says: everything a cultivator set moving on the road comes home at the end of it and asks to be settled. Most threads are light; a few were people, and those are heavy. And at the far end of every thread that was cut instead of tied, something has been feeding: **Nie**, the shadow of everything owed and never paid, gathering where debts are reckoned, at the Wheel of the Six Paths.

| Step | Where | What happens |
|---|---|---|
| The threads | the sect | the Elder explains the ripening of karma, and sends Lin Feng to the Wheel |
| The Karma Mirror | the Wheel of the Six Paths | Judge Cui shows the five threads running into the darkness round the Wheel's rim |
| The grudges | the Wheel | drive back the Grudge Wisps, Debt Shades and Karma Moths (three new monsters, each with its story) |
| The five threads | the sect, Cloudfoot, Qingshi Village, the Blood Moon Palace, the Crimson Marsh | settle Tala, Qiu Ye, Fang Hu, Xu Lan and Liu Ying, **in any order**: each meeting is written for what Lin Feng made of them, and ends with a friend, an enemy fought (and spared or ended) or a parting |
| The Mirror again | the Wheel | Judge Cui shows six grudges that never came to the Wheel: their owners went over the bridge, but what they were owed took root where they fell, and Nie drinks from all six |
| **The grudges that stayed** | the Bamboo Forest, the Crimson Marsh, the Sword Graveyard, Tushan, Juntian (the Nine Heavens), Guixu (the Eastern Sea) | six new bosses, **in any order**, each standing beside the place its owner fell, in its owner's shape gone to soot: it fights first (as hard as a trial's boss), then says what it was owed, and Lin Feng chooses: **pay it**, **let a friend answer it** (only if that thread went that way), or **leave it to the Wheel**. Every grudge left unpaid gives Nie 15% more health, every one laid to rest takes 4% off; Nie names the ones it carries, and the ending tells what came of the rest |
| Nie, the Unpaid | the heart of the Wheel | a trial: **by the bonds you made** (three or more friends; they strike Nie every round), **by might** (the peak of Myriad Daos and a fully tempered sword), **by respect** (renown 760: the dead have heard of you) or **by craft** (a Mirror of Settled Debts, forged from two spokes of the Wheel) |
| Home | the sect | every thread goes slack at once, like a bell rope when the ringing stops |
| *Karma Fulfilled* | | the last tribulation is every face met on the road, waiting to hear what Lin Feng will say; then the narrator tells what became of all five, and of his village |

```mermaid
flowchart TD
    Q1{Part I, the sect at night:<br/>Qiu Ye and a stolen pill} -->|take him to the Elder| EX[expelled]
    Q1 -->|keep his secret| SE[secret]
    Q1 -->|pay Mo for the pill| SH[shared]
    EX -->|fight him: he flees| BE[beaten]
    EX -->|offer your hand| DO[doubt]
    SE -->|break the cursed sword: its guardians rise| FR[freed]
    SE -->|let him keep it| PO[possessed]
    SH -->|duel him honestly| FI[friend]
    SH -->|let him win| FL[flattered]
    BE & PO -->|Part VI: stop the binding of his father's shade| FOE[foe]
    BE & PO -->|help him say goodbye| TU[turning]
    DO & FR & FI & FL -->|walk them to the Naihe Bridge| BR[brother]
    DO & FR & FI & FL -->|leave them to it| DI[distant]
    FOE -->|Part XIV: he comes with the Ashen Moon; spare him| RE((redeemed: at the Wheel))
    FOE -->|end it| FA((fallen))
    TU -->|vouch for him| RE
    TU -->|refuse| PA((parted))
    BR --> AL((ally: at the Wheel))
    DI -->|ask him as an equal| AL
    DI -->|let him go home| PA
    BR -.->|Part VI: a way through King Yama's trial| KY[By an old bond]
    TU -.-> KY
```

*Qiu Ye's thread, every way through it (the other four are as branched: 65 variants in all).*

The six grudges (`scripts/grudges.gd`), every one a foe Lin Feng put down on the road and never asked about:

| The grudge | Where it fell | What it was owed | The answers |
|---|---|---|---|
| **Iron Fang's** | the Bamboo Forest (Part I) | a test at the sect gate: at twelve he was sent down the steps for his father's patched sleeves, without even the stone | let **Fang Hu** answer his father (if he stands with you), **test him at last** and pay for testers at the gate (30,000 stones), or the Wheel |
| **The Marsh Hag's** | the Crimson Marsh (Part I) | a winter of cures for thirty-six settler families the Court never paid for, and her own name, which she has forgotten | let **Liu Ying** read her name from the grimoire's first page, **pay the settlers' bill** (40,000 stones), or the Wheel |
| **The Headless Saint's** | the Sword Graveyard (Part III) | his name, taken off the sect's ancestral tablets because a saint who refused an Emperor was an awkward ancestor | let **Qiu Ye** make the old bow, **put his name back** (renown 450), or the Wheel |
| **Fangfeng's** | Tushan (Part X) | somebody to ask why he was late: he stood in a burst dyke for a day and a night, and was beheaded before he could say so | **ask him** (free), **raise him a shrine** on the dyke (25,000 stones), or the Wheel |
| **Kui's** | Juntian, in the Nine Heavens (Part XI) | its joy: its hide became a war drum, and every thunderclap since has sounded like the drum | **carry it home** to Liubo (three rides of your own), **unstring the drum** (six thunder essences), or the Wheel |
| **The Admiral's** | Guixu, out at sea (Part XII) | word of his daughter, rowed ashore at Penglai at eleven with a red ribbon | **read him her name** from Xu Fu's log, **bring his wheel to Landfall** (30,000 stones), or the Wheel |

```mermaid
flowchart LR
    M[the Karma Mirror:<br/>six grudges that<br/>never came] --> G{any order}
    G --> F1[fight it where<br/>its owner fell] --> O{what was<br/>it owed?}
    O -->|a friend answers it| E[laid to rest]
    O -->|pay it| P[paid]
    O -->|leave it to the Wheel| U[unpaid]
    E & P -->|Nie health -4% each,<br/>a line of the ending| N((Nie, the Unpaid))
    U -->|Nie health +15% each,<br/>Nie names it| N
```

## Part XIII: The Eight Gates

Every water has come home, and for a whole autumn nothing goes away that does not come back. So the peoples of the four realms agree to meet on Azure Cloud Mountain, under the Jianmu, for the first **Conclave of the Realms**, with no Court at the head of the table because there is no head of the table. On the eve of it eight bars of gold light go up at once, two in each realm. The Elder knows what they are: the **Eight Gates** of the Qimen art, which the Mysterious Lady of the Nine Heavens taught the Yellow Emperor to win the war at Zhuolu, and which the Court, not yet the Court, set round the grave of the war god **Chiyou** so that his war would never wake. The lock answered to the Court. The Court is gone, every water comes home through Lin Feng now, and it seems the dead would like to as well.

This chapter is **not a line**. After the Elder, the Archivist (who found the Lady's own war-book propping up a table), **Yinglong** at Mount Buzhou (the winged dragon who killed Chiyou at Zhuolu, and never flew home to heaven after it: "He was a smith. The first. He made ploughs before he ever made an axe") and the lantern monk of the Maple Gorge (where Chiyou's fetters, struck off him, grew into the first maples), and once his war-band has been driven back off the funeral road, **any four of the eight gates, in any order**, break the lock, and each gate is a **trial** with its own ways through:

| Gate | Trigram | Where | General | Its ways |
|---|---|---|---|---|
| **Opening** | Qian, heaven | Changhe, the Nine Heavens | Xingtian, Who Dances Without a Head | the Sword (Adept), Kin of the celestial foxes, 150,000 stones (Pixiu's gold given back) |
| **Alarm** | Dui, lake | Juntian, the Nine Heavens | Yu Shi, the Rain Master of Zhuolu | Free Wandering (Adept), Kin of the Feathered Folk, the Fan of Nuba's Drought (crafted) |
| **Rest** | Kan, water | the Nine Springs | Liang, Goblin of the Black Springs | the Compassionate Heart (Adept), Kin of the Pearl-Weepers, two Vials of the Nine Springs poured back |
| **Death** | Kun, earth | Youdu | the Bronze-Headed Brothers of Chiyou | Formations (Adept), Kin of the shades, renown 560 |
| **Sight** | Li, fire | Yingzhou, the Eastern Sea | Chiyou's Banner, the Red Comet | the Mirror (Adept), the Mirror of Clear Sight (crafted), Middle Ten Thousand Waters Return |
| **Closing** | Xun, wind | Guixu, the Eastern Sea | Mei, Goblin of the Old Mast | 160,000 stones (the Lost Fleet's wages), Yu Qiang's conch and a handful of mainland earth, Kin of the Thousand Children |
| **Life** | Gen, mountain | the Maple Gorge, the land | the Fetter-Maple of Chiyou | the Cauldron (Adept), Kin of the Deathless, two pressed autumn leaves |
| **Harm** | Zhen, thunder | Mount Buzhou, the land | the Drum of Kui's Hide | Middle Ten Thousand Waters Return and a fully tempered sword, the Drumstick of the Thunder-Beast (crafted), renown 580 |

A **war-band** of Chiyou's host (Warriors of the Nine Li, the Fog of Zhuolu, Bronze-Browed Brothers, Fetter-Maple Saplings and Embers of Chiyou's Banner) marches in every gate's region once the formation wakes: the only foes in the old regions who still stand and fight a cultivator of Ten Thousand Waters Return, and the way to the new realm. Every gate opened beyond four takes 6% off Chiyou. When the fourth falls, the fog lifts off the Maple Gorge and the buried field of **Zhuolu** lies open under the oldest maples. Before walking into it Lin Feng carries the Elder's invitations to the Conclave to **any four of the eight peoples' leaders, in any order** (the Feather-Mother, the Rain-Minister, the Ninth-Tail Matron, the Pearl-Weaver, the elder of the Deathless, the Lantern-Magistrate, the Headwoman of Landfall and He Xiangu), each with something to say about the war god, and then there are **three roads** into the field:

| Road | What it asks | The battle | How it ends |
|---|---|---|---|
| **The Road of the Sword** | Master of the Dao you walk, and cultivation full at Late Ten Thousand Waters Return | Chiyou at his full strength (twice the health of a boss, a quarter more attack), as the Yellow Emperor met him; his weakness shown, and the first blow yours | Chiyou laughs, lies down in the field and closes his eyes for the first time since he died; his axes hang in the Hall of Azure Clouds |
| **The Road of the Many Peoples** | every people of the realms calls you Friend, and renown 600 | the envoys of four realms at your back, quarrelling: allies strike every round and the party takes a fifth less harm | the war god of the Nine Li, who fought for nine tribes arguing round one fire, takes a seat at the Conclave as the envoy of a people five thousand years gone |
| **The Road of the Cauldron** | the Elixir of Coming Home: five essences of five elements, an autumn leaf and 300,000 spirit stones at Alchemist Mo's cauldron | he smells the Nine Li on it: he begins at 60% of his strength and strikes softer | he drinks it, turns to autumn leaves from the feet up and blows away east to the plains where his people lived |

Then the Conclave meets (on the sect's practice ground, the only place flat enough for a dragon to sit down) and the last tribulation asks Lin Feng which road he will choose, and he does not have to: **Myriad Daos as One**, a realm in which every road leads somewhere worth going.

```mermaid
flowchart TD
    S[Sect: eight bars of gold in the sky<br/>the Elder, the Archivist] --> Y[Mount Buzhou: Yinglong,<br/>who killed Chiyou]
    Y --> M[Maple Gorge: the lantern monk,<br/>Chiyou's fetters grown into maples]
    M --> HU[drive the war-band<br/>off the funeral road]
    HU --> G{the Eight Gates:<br/>open any four, any order}
    G --> O[Opening, Changhe<br/>Xingtian]
    G --> A[Alarm, Juntian<br/>Yu Shi]
    G --> R[Rest, the Nine Springs<br/>Liang]
    G --> D[Death, Youdu<br/>the Bronze Brothers]
    G --> SI[Sight, Yingzhou<br/>Chiyou's Banner]
    G --> C[Closing, Guixu<br/>Mei of the Old Mast]
    G --> L[Life, the Maple Gorge<br/>the Fetter-Maple]
    G --> H[Harm, Mount Buzhou<br/>the Drum of Kui's Hide]
    O & A & R & D & SI & C & L & H --> F[four open: the lock breaks,<br/>the field of Zhuolu]
    F --> EN{invitations to the Conclave:<br/>any four of eight leaders, any order}
    EN --> W{three roads}
    W -->|Master of a Dao, full cultivation| SW[the Sword: Chiyou at full strength]
    W -->|every people a Friend, renown 600| PE[the Many Peoples: allies at your back]
    W -->|the Elixir of Coming Home| CA[the Cauldron: he wants to go home]
    SW & PE & CA --> CO[the Conclave of the Realms]
    CO --> T[tribulation: every road at once]
    T --> E((Myriad Daos as One))
```

## Part XII: The Returning Ruins

Every road goes somewhere now, and for a season Lin Feng sweeps the steps in the mornings and the first hundred steps of the Standing Tree in the evenings. Then a fishing boat comes up the south-east road on an ox-cart: the sea went out in the night and did not come back. East of the Eastern Sea, the *Liezi* says, lies **Guixu, the Returning Ruins**, a ravine without a bottom into which every river, every sea and the Silver River pour, and which never fills and never empties, because everything that goes in comes back. Over it stood the five **Isles of the Immortals**, held up on the heads of fifteen great turtles; a giant of Longbo fished up six of them and two isles sank. The Court hid the rest in a mirage, so nobody could pick years off the pearl trees while it was selling them by the column, and put a bronze stopper in Guixu so that water came back only where the Rain Ministry signed for it. Somebody has pulled the stopper out. At Fusang, where the sun rises out of the sea, **Mazu**, who brings the boats home, takes Lin Feng across what is left of the sea in her boat.

| Region | Realm | Size | Levels | Story beat | Final boss |
|---|---|---|---|---|---|
| *Azure Cloud Sect and Fusang* | the land | | | The Elder and the Archivist on Guixu, the five isles and the Court's stopper; Mazu at the pool of the suns gives Yue Ling her red lantern | |
| Penglai, the Isle of the Immortals | the Eastern Sea | 100 x 64 | 48-49 | Landfall, the town of the Thousand Children Xu Fu brought from Qin and never came back for; the Slips of the Thousand Names; Lu Dongbin explains the elixir: a ripe fruit lets you stop when you choose, an unripe one just stops you | the Giant of Longbo, fishing the turtles off the bare shelf |
| Fangzhang, the Square-Pot Isle | the Eastern Sea | 92 x 60 | 49 | He Xiangu's dying pearl trees; Zhang Guolao, who rides backwards, remembers the Court bringing its stopper | Tianwu, the eight-headed god who kept the stopper |
| Yingzhou, the Isle of Mists | the Eastern Sea | 96 x 62 | 49-50 | Jingwei, who has carried stones to fill the sea for four thousand years, finds she was building a reef that can hold the isle; Old Gui of the turtles and forty thousand years without a shift | Yu Qiang, God of the Northern Sea, who keeps the turtles' shifts |
| Guixu, the Returning Ruins | the Eastern Sea | 100 x 64 | 50 | The wreck of Xu Fu's flagship and its ghostly steersman; Xu Fu's torn logbook; the drowned summit of Daiyu at the lip of the Ruins | Xu Fu, Who Sought the Elixir |
| *Ten Thousand Waters Return tribulation: every water in the world passes through Lin Feng into the Ruins, and the Ruins remember how to give it back* | | | | | |

```mermaid
sequenceDiagram
    participant E as Elder and Archivist
    participant M as Mazu
    participant Q as Xu Qian and Lu Dongbin
    participant H as He Xiangu and Zhang Guolao
    participant J as Jingwei and Old Gui
    participant Y as Yu Qiang
    participant X as Xu Fu
    E->>E: The sea went out. Guixu has stopped returning
    E-->>M: Go east to Fusang
    M-->>Q: A boat that floats, to the isle in the mirage
    Q->>Q: Three thousand names in one hand, and a promise
    Q-->>H: The unripe fruit stops you. Xu Fu pulled the stopper
    H-->>J: Tianwu: who decides where the water goes?
    J->>J: Not filling the sea. Building a reef to hold it
    J-->>Y: Forty thousand years without a shift
    Y->>Y: Blows the conch. Two turtles in three sleep
    Y-->>X: Down the bare sea floor to the lip of the Ruins
    X->>X: Eats the ripe fruit, and grows old
    X->>E: Home to Landfall, and the water comes home: Ten Thousand Waters Return
```

| | |
|---|---|
| ![Landfall, the town of the Thousand Children](docs/screenshots/town_landfall.png) | ![the Pavilion of Penglai on its sea-cliff, a mirage over the water](docs/screenshots/penglai_pavilion.png) |
| ![the Eastern Sea from above Penglai](docs/screenshots/realm_sea.png) | ![Mazu's boat at the pool of the suns in Fusang](docs/screenshots/mazu_boat.png) |
| ![Fangzhang, the Square-Pot Isle](docs/screenshots/isle_fangzhang.png) | ![Yingzhou, the Isle of Mists](docs/screenshots/isle_yingzhou.png) |
| ![the bare sea floor at the Returning Ruins](docs/screenshots/vista_guixu.png) | ![the lip of Guixu](docs/screenshots/guixu_whirl.png) |
| ![Lu Dongbin's drinking-room upstairs in the wine-house](docs/screenshots/upper_drinking_room.png) | ![the steersman's cabin in the wreck of Xu Fu's flagship](docs/screenshots/upper_steersman_cabin.png) |
| ![Jingwei, Old Gui, the mist-fisher, Furnace-Boy Dan, Steersman Hong, Ah Fu and Xu Fu](docs/screenshots/gallery_isles.png) | ![the monsters of the Eastern Sea](docs/screenshots/gallery_part12_monsters.png) |

- **A fourth realm**, the **Eastern Sea** (`Atlas.STRATA.sea`), built like the others (sites, warped ownership, land that runs out into real sea, roads and seals) on a 520 x 200 grid of its own: four isles in a chain running east, the sea between them crossed on the sandbars the drain has left bare. **Mazu's boat** joins it to Fusang: a new kind of crossing (`"style": "sail"`) at a jetty on the pool where the ten suns bathed, with a boat built in code (a junk with a red batten sail and eyes on the bow), a sea-blue fade and its own map page.
- **Sixteen bosses** from the old texts: Qianliyan and Shunfeng'er, Mazu's runaway generals, hired by Xu Fu as lookouts; the Sea-Monk who drowns fishermen; **the Giant of Longbo**; the White Deer of Longevity; the Elixir Furnace That Walked Away; the Pearl Tree That Will Not Fruit; **Tianwu**, the eight-headed god of the waters; **Wu Zixu**, god of the tidal bore, who stopped the tide; **Shen**, the clam-dragon whose breath made the mirage; the Great Ao who bears Yingzhou; **Yu Qiang**; the Admiral of the Lost Fleet; the Bronze Stopper of Guixu; **Ruo of the Northern Sea**, the sea itself (who once humbled the River Earl of Part X); and **Xu Fu**. Xu Fu and Yu Qiang answer the Dao Lin Feng walks.
- **Twelve new monsters**: Mirage Wisps, Sharks Stranded by the Low Tide and Sandbar Crabs on Penglai; Cinnabar Toads of the Furnaces, Cranes Who Steal Elixirs and Herb-Thief Rabbits on Fangzhang; Phantoms of the Sea-Mist, White Horses of the Tidal Bore and Shell-Armoured Tide Soldiers on Yingzhou; Drowned Sailors of the Lost Fleet, Eels of the Bottomless Ravine and Sentinels of the Sunken Isles at Guixu.
- **Two new peoples**: the **Thousand Children of Landfall** (honour the Compassionate Heart, love a handful of mainland earth, their friendship finds more spirit stones) and the **Immortals of the Isles** (honour Free Wandering, love a cake of new Cloud-Tea, their friendship makes every battle teach more).
- **New techniques**: the Returning Tide Sword, Rain over the Five Isles and Jingwei's Stone Sword (taught by Jingwei) for Lin Feng; Spray of the Pearl Trees and Mazu's Red Lantern (it raises the fallen) for Yue Ling.
- **A new town, Landfall**, with a Hall of the Thousand Names (and its gallery upstairs), the Wine-House of the Drunken Immortal (where Lu Dongbin drinks upstairs), a temple to Mazu, a shipyard on the sand (and its rope store) and the net-menders' house; Fangzhang has He Xiangu's Lotus Hall, the House of the Nine Furnaces and the herb-keepers' lodge; Yingzhou the Shrine of the Fifteen Turtles and its tally-room; Guixu the wreck of the flagship *Penglai-Seeker*. **23 new characters**, among them the Eight Immortals (Lu Dongbin with his sword and fly-whisk, Iron-Crutch Li, Lan Caihe, Han Xiangzi with his flute, He Xiangu with her lotus, Zhang Guolao with his fish-drum, Zhongli Quan with his fan and Cao Guojiu with his broken court tablet), Mazu, Jingwei with her speckled wings, and the ghosts of Xu Fu's lost fleet.
- **Set pieces built in code** (`terrain3d.gd`): the **Pavilion of Penglai**, an octagonal two-storey pavilion on a white sea-cliff with a mirage of pale towers hanging over the water; and **the lip of Guixu**, the sea pouring round and round in a funnel of dark water and foam down into a ravine without a bottom, with a faint glow far below. Four new region looks: the pearl-white haze of Penglai, the golden afternoon of the immortals' gardens, the grey-green mists of Yingzhou and the violet storm over the bare sea floor at the Ruins.
- **A new realm**, Ten Thousand Waters Return, with its own tribulation; the ending adds the isles on their sleeping turtles below the clouds, with Jingwei's reefs beside them, Mazu's lantern-boat drifting between them and Jingwei flying a pebble over the sea.

## Part XI: The Ladder of Heaven

The land keeps its own shape, and for a season everybody lets it. Then one morning the whole mountain shudders, and by sunrise a tree stands west of the sect that was not there the night before: a trunk wider than the Hall, not one branch below the clouds, roots that have split the hillside open. The Elder knows it. It is the **Jianmu**, the Standing Tree, the ladder at the middle of the world by which gods climbed down to visit and people climbed up to complain, until the sage-king Zhuanxu sent his grandsons Chong to lift heaven up and Li to press the earth down, and between them they cut the ladder through. The Court made a government of the severing: one ladder, kept by the Court, one road up it, obedience. With the land in its own shape again the tree has remembered how to grow, and whatever comes down it, or up through its roots, will ask Lin Feng one thing first: what is your Dao? He chooses a road, finds the record of the severing in the Sealed Archive under the Scripture Library and goes to meet whoever has climbed down the trunk.

| Region | Realm | Size | Levels | Story beat | Final boss |
|---|---|---|---|---|---|
| *Azure Cloud Sect and the Jianmu's foot* | the land | | | The Elder asks which Dao Lin Feng will walk; Archivist Lan reads the record of the severing in the Sealed Archive; Ling Yu of the Feathered Folk climbs down the tree to see whether the middle world is as horrible as the stories | |
| Juntian, the Level Heaven | the Nine Heavens | 100 x 64 | 45-46 | Featherfall's chicks will not hatch while the winds run wild; four wind bells go back up the Aerie Tower, and the Rain-Minister, sulking in the Archive of Rain because nobody signs his ledgers any more, picks up a brush himself | Leigong, Duke of Thunder |
| Changhe, the Gate of Heaven | the Nine Heavens | 92 x 60 | 45-46 | The celestial foxes keep the Gate as a joke and hid its four keys as the punchline; the door gods let Lin Feng through to Chong, who has held heaven up for four thousand years and cannot hear any more | Chong, Who Lifts Heaven |
| The Nine Springs beneath the Roots | the Nine Springs | 96 x 62 | 46-47 | Down the roots to Tearwater on the black water: the springs run thin and bitter, the Deathless explain that the tree pushes up while Li pushes down, and the roots are caught between them like a hand in a door | Zhulong, the Torch Dragon |
| Youdu, the Dark Capital | the Nine Springs | 100 x 64 | 47 | The rolls of the dead have scattered and Black and White Impermanence are collecting the living; Houtu, Sovereign Earth, gives Lin Feng the earth's own blessing; Tubo opens the inner gate | Li, Who Presses Down the Earth |
| *Three Realms Concord tribulation: hold heaven, earth and the middle world in one breath, the way you hold a ladder steady for somebody else to climb* | | | | | |

```mermaid
sequenceDiagram
    participant E as Elder and Archivist
    participant Y as Ling Yu and Yu Hua
    participant R as Rain-Minister Ao Run
    participant F as Hu Qingyi
    participant C as Chong
    participant J as Shui Lian and Bu Si
    participant H as Houtu
    participant L as Li
    E->>E: The Jianmu grows back. What is your Dao?
    E-->>Y: Something came down the trunk at dawn. Go and be polite at it
    Y-->>R: The winds run wild and the chicks will not hatch
    R->>R: Signs his own rain, with no ledger to answer to
    R-->>F: Through Changhe to the Gate of Heaven
    F-->>C: Four keys, and the door gods open the Gate
    C->>C: Puts his hands down to fight. Heaven does not fall
    C-->>J: My brother presses the earth down. Tell him
    J-->>H: The tree pushes up, Li pushes down, the roots are caught
    H-->>L: The earth's own blessing on your sword
    L->>L: Lifts his hands. The earth does not rise
    L->>E: The tablet and the weight go to the tree: Three Realms Concord
```

- **Sixteen bosses** from the old texts: Feilian, Earl of the Wind, with his bag of winds; Kui, the one-legged thunder ox; Jiufeng, the nine-headed bird whose heads cannot agree which way the wind blows; **Leigong**, Duke of Thunder, striking at everything; Pixiu, eating the gold off the Gate; the door gods **Shentu** under the peach tree and **Yulei** with his rope of reeds; **Chong**, who lifts heaven; the wyrm gnawing the Jianmu's great root; the Weeping Pearl-Mother; Wangxiang, the goblin who muddies the springs; **Zhulong**, the Torch Dragon whose open eye is the only day below; **Bai Wuchang** and **Hei Wuchang**, White and Black Impermanence; **Tubo**, the three-eyed Earl of the Dark Capital; and **Li**, who presses down the earth. Chong and Li each answer the Dao Lin Feng fought them with.
- **Twelve new monsters**: Cloud Kites, Loose Thunder-Motes and Rain Serpents Without a Ledger in Juntian; Gilded Gate-Lions, Foxfire Wisps and Cloud-Armour Soldiers Still at Their Posts at Changhe; Root-Gnawer Worms, Blind Carp of the Black Water and Glow-Shell Cave Crabs in the Nine Springs; Ghost Soldiers, Paper Horses Who Ran Away and Lantern Shades in Youdu.
- **New techniques**: the Strike of the Standing Tree, the Torrent of the Nine Springs and the Three Realms Concord Sword (Houtu's blessing) for Lin Feng; the Rain of Phoenix Feathers and the Ward of the Standing Tree (it raises the fallen) for Yue Ling; and six **Dao techniques**, one for each Dao from Adept on.
- **A new realm**, Three Realms Concord, with its own tribulation of three storms at once.
- **Set pieces built in code** (`terrain3d.gd`): the **Jianmu**, a trunk of bronze-dark bark nine metres across, ribbed and slightly twisted, with no branch for a hundred and fifty metres, buttress roots over the hillside, a stair of planks on brackets winding up it past lanterns, a root-cave glowing blue on its east face (the way down) and, as the old books say, no shadow at noon; its **crown** of leaf-clouds among the islands of Juntian; its **roots**, veined with blue-green light, coming down through the roof of the Nine Springs; the **Gate of Heaven**, red lacquer and gold on the highest island of Changhe; and the **inner gate of Youdu**, black stone and iron with ghost-fire lanterns and a red glow from the deep beyond it. Four new region looks: the bright high air of Juntian over the cloud sea, the violet-and-gold dusk at the Gate of Heaven, the teal glow of the caverns under the roots (lit red from the east by the Torch Dragon's eye) and the ghost-fire of the Dark Capital.
- **Three new towns**: **Featherfall**, the Feathered Folk's aeries round the Jianmu's crown, with an Aerie Tower, a fletching loft, an Egg-Nursery and the Rain Ministry; **Tearwater**, a town of shell and silk on the black water, with the Hall of the Pearl-Weavers and the House under the Great Root; and **Youdu**, the Dark Capital, with its Ward Office, a paper-horse shop, the Inn of the Last Lantern and the Palace of Sovereign Earth.
- The **ending** raises the Jianmu behind everything, from the clouds below to the top of the sky, with feathers, pearls and lanterns climbing it and a slow ring of the six Daos' colours round its trunk; and the last words of the story ("Later they will tell it as the story of...") follow the Dao Lin Feng walked.

## Part X: The Nine Cauldrons

A month after the sun and the moon agree to take turns, Archivist Lan comes running into the courtyard in her nightcap: the great map in the Scripture Library, the Court's survey, is wrong. The rivers have moved; the coasts have bays; the roads go round bends that were never drawn. The Elder explains that the Heavenly Court surveyed the land into squares so that every square could be taxed in years, and pinned the corners with the Nine Cauldrons that Yu the Great cast when he tamed the Flood, engraved with the true map of the Nine Provinces. With the Court gone the land is lying down in its own shape again (the world map you walk through is the true one). But land that moves floods, and under the Court's squares lay something Yu never killed, only channelled: Gonggong, the Flood God, who once broke a pillar of heaven with his head.

| Region | Size | Levels | Story beat | Final boss |
|---|---|---|---|---|
| *Cloudfoot (on the mountain)* | | | Cartographer Pei, twelve years right about the Court's maps, draws the north road properly | |
| Longmen, the Dragon Gate Ferry | 100 x 60 | 42 | A ferry town on a river that runs backwards in its sleep; the carp will not leap the Dragon Gate; He Bo's flood tablet goes back to his temple | He Bo, Earl of the Yellow River |
| The Drowned Fields of Gun | 96 x 58 | 42-43 | Bo Yi, who dug the channels with Yu, and the Swelling Earth rising out of the flood: Gun has come back to finish his dam | Gun, Who Stole the Swelling Earth |
| Tushan, the Town of the Cauldron-Casters | 96 x 60 | 43-44 | The stone-carver reads the flood tablet; Tu Lan recasts the Ninth Cauldron from its shards, the land as Yu drew it | Taotie, the Glutton on the Cauldron |
| Mount Buzhou, the Broken Pillar | 96 x 58 | 44 | Yinglong, who drew every river with his tail; Xiu who loved roads, the Kun, Xiangliu and Kuafu round the black lake | Gonggong, God of the Flood |
| *Mountain-River Oneness tribulation: the land is allowed to keep its own shape* | | | | |

```mermaid
sequenceDiagram
    participant E as Elder and Archivist
    participant P as Cartographer Pei
    participant J as Jiang Yao and He Bo
    participant B as Bo Yi and Gun
    participant T as Tu Lan
    participant Y as Yinglong
    participant G as Gonggong
    E->>P: The maps are wrong. The land is lying down in its own shape
    P-->>J: The north road, drawn properly. The carp will not leap
    J-->>B: The river runs backwards. Someone upstream builds with earth that grows
    B-->>T: Gun never learned channels. Ask what became of the cauldrons
    T->>T: Recasts the Ninth Cauldron: the land as Yu drew it
    T-->>Y: Show him the rubbing
    Y->>G: Every river runs east because of you
    G-->>G: Then let the water go where it goes
    G->>E: The Nine Cauldrons hold the land as it really is: Mountain-River Oneness
```

- **Five bosses in each region** from the old texts: the Carp Who Would Not Leap, Black Eel and his river-rats, the Drowned Temple Bell, the Stone Lion of the ferry stage and **He Bo**, who used to demand a bride every spring until Ximen Bao threw his priests in the river; the Toad Who Swallowed the Dykes, the Heron Lord of the Drowned Paddies, the Mud Dragon, the Turtle Who Carried Gun's Earth (the *Tianwen*'s owls and turtles) and **Gun**, Yu's father, still building his wall; the Slag Serpent, the Stone Mother (Yu's wife, turned to stone), Fangfeng (executed for coming late to Yu's assembly), the White Nine-Tailed Fox of Tushan and the **Taotie**, the glutton cast on every cauldron, eating the map off the shards; Xiu, Gonggong's son and god of roads, the Kun of the Northern Darkness, Xiangliu with nine heads, Kuafu who drank the rivers dry and **Gonggong** himself.
- **Twelve new monsters** (Dragon-Gate Carp, River-Rat Eel Bandits, Silt-Shell Crabs, Paddy Flood-Toads, Mud-Wading Herons, Drowned-Rice Wraiths, Slag Golems, Bronze Taotie Hounds, Charcoal-Pit Wisps, Black-Water Wolves, Pillar-Shard Sentinels and Kun-Fish Fry); most of the flood is water and weak to earth.
- **Five new techniques**: Dragon Gate Leap, Swelling Earth Rampart and the Nine Cauldrons Sword (taught by Tu Lan) for Lin Feng; Reed-Boat Blossom and the River-Mother's Ward (it raises the fallen) for Yue Ling.
- **Three set-piece landmarks** built in code (`Terrain3D.landmark`): the **Dragon Gate**, two banded cliffs with a carved gate across the gorge and the falls pouring through it in three sheets; the **great cauldron** of Tushan on three legs with taotie faces round its belly and molten bronze glowing inside; and the **stump of Mount Buzhou**, a banded column of black stone leaning north-west with a shattered crown, chains and fallen blocks.
- **New region looks**: the ochre river and cliff pines of Longmen under river mist, the grey flood and reeds of the Drowned Fields in the rain, the smoke and bronze-glow of Tushan with sparks in the air, and the storm over the black lake at Buzhou.
- **The guides and townsfolk are Blender-built**: Harbourmistress Jiang Yao with her oar, Bo Yi in his straw hat with the hoe he dug the first channels with, Tu Lan in a scorched apron with her clan's hammer, Yinglong as an old man with dragon horns, and the people of Longmen, Tushan, Cloudfoot and Shazhou.
- The **ending** sets the Nine Cauldrons, recast, in an arc on the clouds with a river winding between them to the sea.

## Part IX: The Tenth Sun

The magpie bridge holds, and the next morning the sun comes up and does not go down. The Elder tells the oldest story of all: Xihe, Mother of the Ten Suns, drove her children across the sky one a day from the Fusang tree in the Valley of Sunrise, until the morning all ten rose together and the archer Hou Yi shot nine of them down. After that the Heavenly Court drove the last sun and counted the days. With the Court gone the sun kept to its road out of habit, until something frightened it: now it hangs at noon over the scorching east, the west lies in endless night, and the embers of the nine fallen suns are waking in the ground. Only Chang'e, alone in the Moon Palace, still walks the moon round the sky, and she is tiring.

| Region | Size | Levels | Story beat | Final boss |
|---|---|---|---|---|
| Yanggu, the Dawn Market | 104 x 60 | 39 | A riverside market town where it has been noon for nine days: seven buildings you can enter, market lanes and eight townsfolk; Ah Mei the lantern-maker hangs the Noon Embers in her lanterns and sees them all lean east | Hanba, the Drought Fiend |
| The Scorched Millet Plains | 100 x 52 | 39-40 | Old Farmer Tian prays to Hou Ji for a little night; four Rain-Stones raise a cloud that cannot rain, because rain wants an evening | Bifang, the One-Legged Fire Crane |
| Fusang, the Valley of Sunrise | 88 x 64 | 40-41 | Feng Meng, Hou Yi's last apprentice, reads the fallen sun-feathers, confesses his master's murder and gives Lin Feng the tenth arrow that was never shot | Jinwu, the Three-Legged Sun Crow |
| Guanghan, the Palace of the Moon | 92 x 56 | 41 | Chang'e hears Feng Meng's apology after four thousand years; Wu Gang puts down his axe, Tiangou stops eating the moon, the Jade Rabbit finally sleeps | Xihe, Mother of the Ten Suns |
| *Sun-Moon Harmony tribulation: the sun and the moon walk the sky by agreement, not by decree* | | | | |

```mermaid
sequenceDiagram
    participant E as Elder Qing Xuan
    participant L as Lin Feng
    participant A as Ah Mei and Farmer Tian
    participant F as Feng Meng
    participant J as Jinwu, the Sun Crow
    participant C as Chang'e
    participant X as Xihe
    E->>L: Nobody counts the days now. The sun is afraid to go down
    L->>A: Noon Embers and Rain-Stones
    A-->>L: The embers lean east. Rain wants an evening
    L->>F: Four sun-feathers
    F-->>L: It is afraid of archers. Take the tenth arrow instead of a bow
    L->>J: The tenth arrow was never shot
    J-->>L: Mother is singing my brothers up out of the ground
    L->>C: Feng Meng is sorry
    C-->>L: Tell him to look up
    L->>X: Your youngest is waiting for you at the top of the sky
    X-->>C: There was always room for both of us. We only had to take turns
    X->>X: The nine fallen suns rise as the nine stars of the Dipper and count the days
    L->>L: Holds the dawn and the dusk at once: Sun-Moon Harmony
```

New Blender characters: Ah Mei the lantern-maker (a lit lantern and a carrying pole of unsold ones), Old Farmer Tian (straw hat, hoe, gourd and a sheaf of withered millet), Feng Meng (horn bow and quiver) and Chang'e (cloud brocade, osmanthus sprig, the Jade Rabbit in her arms). The Dawn Market's eight townsfolk have their own Blender models too (Watchman Zhou with his gong and unlit lantern, Innkeeper Bao, Tea Seller Pan, Dyer Su, Monk Huiming, Granny Gu of the granary, Porter Niu and Little Dou with his drum), and the market's buildings are shop fronts with awnings, a two-storey teahouse, a Huizhou inn and a thatched granary. New Blender creatures: `sun_crow` (Jinwu, three-legged, ringed with sun-fire), `jade_rabbit` (an upright hare with mortar and pestle) and `bifang` (the one-legged fire crane). New region looks: a market town under a white-hot noon with the sun high in the east, cracked yellow drought fields in heat haze (a new cracked-earth ground), a steaming green-gold valley under a blazing dawn round the colossal Fusang tree, and the silver-blue frost and osmanthus of the moon under a western moonlight. The ending adds the sun and the moon in the sky together, taking turns, with Xihe, Chang'e and the nine new stars of the Dipper.

## Part VIII: The River of Heaven

On the seventh night of the seventh month the whole sect climbs onto the hall roof to watch the magpies gather in the sky, as they have every year. No magpies come. Instead the Silver River across the sky spills over and stars rain into the lotus pond. The Elder tells the old story: the Weaver Star fell in love with a cowherd, and the Queen Mother of the West drew her golden hairpin across the sky to part them. That line became the River of Heaven, the oldest border there is. Qianxian bound its banks with her thread for ten thousand years, and now that she is unpicking her borders the river is pouring down the old Sky Road into the world.

| Region | Levels | Story beat | Final boss |
|---|---|---|---|
| Starfall Ferry on the Silver River | 36 | Niu Lang the Cowherd fishes drowned stars out of the flooded rice fields and reads where they fell | Qilin of the Rising Tide |
| Heights of the Magpie Bridge | 36-37 | Que Lao, the Old Magpie, calls the scattered flock home with the plumes the storm tore away | Crow Marshal of the Broken Bridge |
| Palace of the Weaver Star | 37-38 | Zhi Nu stopped weaving the river's banks to make it go away; it went down instead | Heavenly Warden of the River |
| Jasper Pool of Kunlun | 38 | Dong Shuang brings Lin Feng before the Queen Mother with four peaches of Kunlun | Xiwangmu, Queen Mother of the West |
| *Star River Crossing tribulation and the magpie bridge in the ending* | | | |

```mermaid
sequenceDiagram
    participant E as Elder Qing Xuan
    participant L as Lin Feng
    participant N as Niu Lang
    participant M as Que Lao and the Crow Marshal
    participant Z as Zhi Nu
    participant X as Xiwangmu
    E->>L: The river is a border, and its banks are coming undone
    L->>N: Four drowned stars from the fields
    N-->>L: They fell where the bridge always stood
    L->>M: The Court fell two years ago. You have no orders
    M-->>L: The magpies come back, enough to carry you across
    L->>Z: Four threads of starlight
    Z-->>L: Banks this time, not a wall. And a ford every night
    L->>X: Prove the world can stand without your lines
    X-->>L: Nobody said I could only draw rivers
    X->>X: Draws a bridge of light across the river
    L->>L: Holds the bridge through the last tribulation: Star River Crossing
```

New Blender characters: Niu Lang the Cowherd (straw hat, flute, ox tether), Zhi Nu the Weaver Star (star crown, shuttle), Que Lao the Old Magpie (feather cloak) and Dong Shuang, maid of the Jasper Pool (peach branch). New creatures: the qilin, the ape, the great cat (tiger, lion, lynx), the magpie, and dedicated models for the Queen Mother, the River Warden, the Crow Marshal and nine-faced Kaiming. New region looks: flooded paddies under a sky of falling stars, wind-bent cliff pines full of magpie nests, the silver-and-lilac palace among star pillars, and the jade peach orchards around the green Jasper Pool.

## Part VII: The Unbroken Land

Spring comes, and silver threads appear across the mountain roads overnight. The Elder explains why the world was ever cut into separate realms joined by gates: the Heavenly Court's Weaver, **Madam Qianxian, Lady of a Thousand Threads**, sewed it into a quilt so that each realm could be harvested alone. When Lin Feng turned the Wheel her stitches came undone and the land grew back into one (the open world). Now she is sewing the mortal lands shut again, and spinning the newly reborn into thread, Little Wan among them.

| Region | Levels | Story beat | Final boss |
|---|---|---|---|
| Qingshi Village Below the Mountain | 33 | Granny Wen, the midwife who raised Lin Feng, reads the stolen threads in her own house | Needle General Zhen |
| Cloud-Tea Terraces | 33-34 | Tea Master Lu Yu brews tea that wakes thread-sleepers, and Yue Ling finds she was being sewn too | Thread Matron of the Hills |
| Mulberry Silk Woods | 34 | Can Niang unwinds soul-cocoons and frees four children's souls | Thousand Hands of the Spinning Hall |
| Loom of Borders | 35 | Zhi, the last weaver-girl, helps take the shuttles out of the Loom | Madam Qianxian, Lady of a Thousand Threads |
| *Boundless Heart tribulation and new ending* | | | |

```mermaid
sequenceDiagram
    participant E as Elder Qing Xuan
    participant L as Lin Feng
    participant W as Granny Wen
    participant C as Can Niang
    participant Q as Madam Qianxian
    E->>L: The gates were her seams, and she wants them back
    L->>W: Who is missing?
    W-->>L: Three newborns. One of them is Little Wan
    L->>C: Four soul-cocoons from the mulberries
    C-->>L: Four children go home. Little Wan's went on to the Loom
    L->>Q: A wall keeps the wind out. A door makes it a home
    Q-->>L: I never thought to sew a door
    L->>L: Opens the door to the last tribulation: Boundless Heart
```

New characters (Blender scripts in `art/characters`): Granny Wen, Innkeeper Fu, Weaver Liu, Tea Master Lu Yu, Can Niang, Zhi and Archivist Lan of the sect's new library. New region looks: rice paddies and village lanes, steep green tea terraces in river mist, sunlit mulberry woods and the lilac marble floor of the Loom under a gold-and-violet sky.

## Part VI: The Turning Wheel

The sky holds, but on the night of the Ghost Festival the lanterns on the lotus pond gather at the sect's south-west gate, and the dead stand among them in a queue that no longer moves. The Heavenly Court did not only prop up the sky with stolen years; it also turned the Wheel of Rebirth, letting souls back up only when the Ledger allowed. With the Court gone the Wheel has stopped, and the overflow of the dead is walking back up the old funeral road. The Elder finally tells Lin Feng where he found him: under a maple in that gorge, beside two nameless graves.

| Region | Levels | Story beat | Final boss |
|---|---|---|---|
| Maple Gorge of Returning Souls | 30 | A lantern monk, lost soul lanterns, and the nameless graves | Ox-Head, Runner of the Ten Courts |
| Stone Forest of the Nine Bends | 30-31 | A cormorant fisher dives for dropped memories; one is a lullaby Lin Feng thought he invented | Horse-Face, Runner of the Ten Courts |
| Yellow Springs of Red Lilies | 31 | Meng Po brews a gentler soup that lets each soul keep one thing; Lin Feng meets his parents | The Thousand Unforgotten |
| Wheel of the Six Paths | 31-32 | Judge Cui mends the spokes; King Yama stopped the Wheel to spare souls a cruel world | King Yama, Lord of the Wheel |
| *Samsara Transcendence tribulation and new ending* | | | |

```mermaid
sequenceDiagram
    participant E as Elder Qing Xuan
    participant L as Lin Feng
    participant M as Meng Po
    participant P as Lin Shan and Su Wan
    participant Y as King Yama
    E->>L: I found you in the Maple Gorge, beside two graves
    L->>M: Herbs of Forgetting for a gentler soup
    M->>P: Drink, and keep one thing
    P->>L: You have his nose. Walk with us to the Wheel
    L->>Y: The world above is kind now
    P->>Y: He swept the steps for three years and never stopped being kind
    Y-->>L: The Wheel turns
    L->>L: Turns it gladly: Samsara Transcendence
```

New Blender creatures for Part VI: the nine-tailed fox, the koi carp, Ox-Head, Horse-Face and the hopping corpse (jiangshi). New characters: Lantern Monk Jing Kong, Cormorant Fisher Old Yu, Meng Po, Judge Cui Jue, and Lin Feng's parents Lin Shan and Su Wan. New region looks: autumn leaf-litter ground and falling maple leaves, limestone towers above the river, fields of spider lilies under a golden spring, and the blue ghost-fire flagstones of the Ten Courts, with the Naihe Bridge and the great Wheel on the horizon.

## Bugs found and fixed

Found in this release by playing, by screenshots, by reading the bot's logs and by new tests, each confirmed before it was fixed:

| Bug | Fix |
|---|---|
| **Two people spoke under names nobody in the world has, so nothing they said was acted out.** The cutscene gestures and the conversation camera find a speaker by the name they go by in the world; Senior Brother Han spoke as "Disciple Han" in the Elder's tea scene, and Granny Wen the Midwife as "Granny Wen" when she tied her thread for Yue Ling, so neither of them ever gestured or was framed | Their lines carry their names, and a test checks that everybody who speaks in a conversation held in the world goes by the name they have there |
| **Three objectives ran out of their panel.** The objective panel holds two lines; "Ask six of the people who knew her to tie a thread for Yue Ling..." and "The sect throws Yue Ling a naming feast..." (Part XV) needed three, and the third was drawn below the panel over the minimap's frame | A long objective is set a little smaller until it fits two lines (`UI.objective_size`), and a test checks every objective with its count and trial note |
| **Every scene shared with Yue Ling was remembered as happening by the lotus pond.** The closeness a shared scene brings was always put down "(by the lotus pond)" in the timeline and the Annals: the loom in the Founder's hermitage and the naming feast on the mountain's stage too | Each scene is remembered where it happened (`Bonds.share_place`), with a test |
| **A thing to pick up could not choose when it appears.** Every pickup of a region appeared with the region's first collecting step, whatever it was for, so Part XVI's thunder bamboo would have been lying in the Bamboo Forest from the first morning of Part I | A pickup may name its own step (`vis`) |
| **Asking a model without an animation player for a clip raised an error.** `get_meta("ap", null)` treats a default of null as no default at all, so `Assets.has_clip` and `Assets.animate` errored on a procedural model | They check `has_meta` first |
| Caught in this release's own new code before it shipped: townsfolk walked straight through the walls of houses when no street led where they were going (a missing route fell back on a straight line), a busy porter's day in Youdu ran past midnight and he jumped across town at the turn of the day, every merchant of a one-shop town stood on one tile, the camera of the town screenshots parked behind roofs, held tools and speech bubbles were looked up with that same null default, sunlit leaves glowed in the dark, Shenshu's armour and cape went 506 triangles over the character budget, Part XVI's thunder bamboo was listed under a second `pickups` key that would have hidden the Bamboo Forest's herbs, and the New Year calls round the sect said "Invitation delivered" (they went through the Conclave's visits) | Routes that cannot be walked are made out of sight ("round the back way"), a day that runs over wraps into the next, doorsteps spread along a building's front with a little room for each person, a crowd camera that checks its line of sight, `has_meta` checks, a `night_k` shader global for foliage, no cape, one list, and a step that says what its visits are ("Wished Smith Tie a good new year") |

### Bugs fixed in the Part XV release

| Bug | Fix |
|---|---|
| **Walking along a border between two regions flickered the whole look of the world.** Every step that crossed the border and back switched the region at once: its banner, a line in the timeline ("Entered Starfall Ferry", "Entered Heights of the Magpie Bridge", "Entered Starfall Ferry"... four times in two seconds on the road past the Magpie Bridge, dozens of times a game) and its sky, fog, light and weather | The game still knows at once which region the hero is in (hunts and quests count it), but a region is only announced (banner, timeline, sky and weather) once he has been in it for a moment (`World._announce`) |
| **The bot could sit down and meditate for the rest of the game on its way to a fight.** When nothing near it would fight (beasts two realms below scatter), it only went looking for a region with foes that would if it happened to be standing in the sect; anywhere else it meditated on the spot. On its way to the graves in Part XV it sat down in the Mirror Lake, whose beasts all scatter, and meditated for 45 game-minutes until the stall watchdog ended the run | It goes on to where the quest or the trial ahead has something to fight from wherever it is (`Bot._grind`) |
| **Yue Ling drank from an empty hand and read thin air.** When Lin Feng poured tea at a tea table or a table, or read at a bookshelf, she joined in with the drinking and reading clips but nothing in her hands | She has her own cup and her own book (`comp_hold`), and a test checks that every clip of hers that needs something has it |
| **"Quest complete" was cut off mid-word in 176 of the 475 quests.** A line in the corner (a quest done, a trial passed, a new pastime) was drawn 600 pixels wide and clipped there, and most quests' names are longer than that: "Quest complete: Find the Founder's echo beside her barrow in the Gr" | A line that does not fit is made a little smaller, and if it still does not fit it is broken over two lines, 840 pixels wide (`World._draw` toasts); a test checks that every quest's line fits in two |
| Caught in this release's own new code before it shipped: a new boss reused the id of an older one (the Moth Empress's `moth_queen`), which broke the whole data file; the lotus lantern memory had nowhere to stand at the Mirror Lake (its shore has no tile by a road), so it moved to the Yellow Springs, where the dead cross; the watchtower's roof sat at head height over its platform; the sect's stage had a shop's signboard standing up through its boards; the sword form's sparkles, the stars over the armillary and the flash of a sky lantern were each the size of a door; the flute's memory was told with Yue Ling playing while the animation had Lin Feng play; the ending's new line about Yue Ling ran into "Press Enter" at the foot of the results; the battle log read "Side by side: Side by side" when the Unweaver was faced the new way (its way is now *Hand in hand*); the lotus pond's lantern jetty stood off the sect's bridge, so the two of them stood in the bridge's arch; every reply's note read "Leans her heart towards his dao companion"; 15 of her replies were cut off mid-word at the edge of the choice list ("You came from our mountain. That's famil"); a long wish on her page ran into the one below it; in a scene played out side by side the cinematic camera framed Lin Feng against the air ahead of him during narration, and could line up so that she was hidden behind him; and the bot asked about every heart-to-heart of the game at once on a developer start (`--bot-start`) | A new id (`forgetting_queen`), a placement fallback (the region's own thing of that kind, then a looser spacing) and a test that every memory stands in its region, the roof raised, the bigger things kept three tiles clear of any building (tested), small sparks, words that match the picture, a taller results panel with "Press Enter" kept below the last line, the jetty moved to the bank (a memory's place is never on a bridge), a future's name that keeps its capitals mid-sentence (`Bonds.toward`, tested), a choice label made a little smaller to fit rather than cut off (`UI.menu_list`; a test that every reply to her fits), wishes spaced by their lines, the two of them framed together in a shared scene (`World._cutscene`), and the heart-to-hearts before the start are had as the plan answers them |

### Bugs fixed in the Part XIV release

| Bug | Fix |
|---|---|
| **Round things with an uncommon number of sides were drawn as boxes.** The mesh builder only knew the cylinders and cones of 4, 6, 8, 14 and 24 sides; anything else fell through to a cube, so the great drum (20 sides), the hall columns (10), the pillars of heaven and the five- and seven-sided spires stood square | Every number of sides is built round, at the height the cube had, so nothing changes size (`MB._proto`; the standard cylinders' two-unit height is now documented) |
| **Holding a key into a flight of stairs bounced the hero between floors for ever.** He arrives facing the stairs back (they stand side by side), and a key still held walked him straight in again: 14 changes of floor in ten seconds; 66 of the 204 ways between floors and realms arrive like that | After the stairs, a ladder, the Jianmu or the boat, the movement keys wait to be let go |
| **The courtyard's Dao Stele ran the Elder's choice early.** It stands from the moment the Elder is ready to speak of the six roads; used first, it opened the one-time "Which road will you walk?" (no way out of it), the Elder's answer came from the stone, and the Elder then offered "The Dao Stele: walk another road?" | Until the Elder has spoken the stele is only carved stone, and says so |
| **Walking into a closed Lotus Seal flooded the corner with copies of one message.** Every frame of a held key added the same toast, four of them pushed out "Quest complete" and whatever else had just been said | The same message again keeps its one line up for longer |
| **The Dao page lost the last of the peoples.** Each people took about 85 pixels, so with seven or eight met (the Road of the Many Peoples needs all eight as Friends) the seventh ran over "Enter / Esc: back" and the eighth, the Immortals of the Isles, was off the bottom of the screen | Name and standing share a row, the rest one or two lines beneath: all nine fit |
| **The qi a technique costs was cut off in battle.** The technique menu is 222 pixels wide, and 32 of the 65 techniques' labels were wider ("Nine Heavens Thunder  [22") | The cost has a right-aligned column of its own and the name shrinks to fit beside it (`UI.menu_list`, a tab in the label) |
| **Meditation counted cultivation it did not give.** At the peak of a realm cultivation stops until the breakthrough, but "(+N this session)" went on rising | Only what is gained is counted |
| **The training stones wasted their time at the peak of a realm and could not complete a stage.** They started their ten-minute wait before finding there was nothing to teach, and wrote what they taught straight into the cultivation bar, so reaching a stage's threshold did not reach the stage | They check first, and teach through `add_exp` like any other cultivation |
| Caught in this release's own new code before it shipped: the people met on the road lost their mark on the way into the world (all twenty stood about from the first morning, two Qiu Yes in the courtyard, and only ever said "..."); the meditation screen and the ending showed the story's sweeper (or the first game's hero on a second New Game), not the one the player made; the ending's results card said "Lin Feng" whatever the hero was called; and the Bestiary counted foes, not battles | The mark is carried, both screens rebuild the hero when he has changed, the card uses the chosen name, a battle counts once per kind of foe |

### Bugs fixed in the Part XIII release

| Bug | Fix |
|---|---|
| **"The The Thousand Children call you Friend."** The toast, the timeline and the gift screen put "The" in front of a people's name, and two peoples' names (the Thousand Children of Landfall, the Immortals of the Isles) already begin with it | `Game.the_race` adds "The" only where the name has none |
| **The bot chased beasts that run away.** Under-levelled in a region whose packs were all two realms below Lin Feng, its grind walked from pack to pack watching each scatter before his aura (a pack that scatters teaches nothing), and its meditation broke off whenever one came back; at the Eight Gates, where the old regions' beasts all scatter, it could never have levelled | Grinding (and the wait for packs to return) counts only packs that will stand and fight |
| **The ending was hard to look at.** Every release had added its finale to the same frame: thirteen chapters of set pieces within twenty metres of the hero under a camera six metres away (one of the Jianmu's predecessors, a pillar of heaven, a winged Hundun and the gates all stood behind the characters' heads), a yellow lotus with dark lily pads across the foreground, seven lines of text on the brightest part of the sky with no backing, and the results box over the characters' feet | The ending is a short film: each set piece has its own place and its own shot, subtitles sit on a shaded band between letterbox bars, and the results are laid out on a panel beside the two of them (see [What changed](#what-changed-in-this-release)) |
| **The bot meditated for hours at the sect when it needed a stage.** Back at the sect (or on the mountain, or upstairs) when the quest wanted more cultivation, it sat down and meditated rather than go where there was something to fight; after the Conclave the last tribulation wants cultivation full, and it stalled for 45 game-minutes | It goes back to the region of the quest or trial ahead (or, for a breakthrough, the latest region on the quest with foes that will fight) |

### Bugs fixed in the Part XII release

| Bug | Fix |
|---|---|
| **Nobody ever bowed.** Townsfolk were meant to greet the hero with the cultivator's salute when he walked up, but the bow was started on the world clock while each person is animated on a clock of their own (offset by their tile, `t + e.pos.x`), so it began hundreds of seconds in the past and was dropped unplayed | The gesture is started on the model's own clock; the cutscene gestures use the same rule |
| **Any action a model had no clip for played its attack.** `Assets.animate` fell back on the attack clip for everything but `die` and `bow`, so a gesture on an older or a monster model would have swung a sword at whoever was talking | Only battle actions (cast, hurt, victory) fall back on the attack; anything else is skipped |
| **The bot could meditate for hours instead of fighting.** Under-levelled for a boss in the higher realms, its grind fell back on meditation (57 cultivation a second at Mountain-River Oneness, against 705,000 for the stage) whenever no pack was within 60 steps, and only stopped when the stage was reached; it stalled in Juntian for 45 game-minutes in testing | The grind walks to the nearest pack anywhere in the region (leaving an upper storey or cellar first) and leaves meditation as soon as the party is fit and a pack is back |
| **The status panel's attack, defence and speed** were worked out from the level and tempering alone, leaving out the Daos and the peoples' boons (and now the root) | It shows the numbers the battle uses (`Game.fighter`) |
| The bot's fifteen-hour `max_time` would have stopped a game of 14 h 7 min near its end | Seventeen hours |

### Bugs fixed in the Part XI release

| Bug | Fix |
|---|---|
| **The tests passed while a script did not compile.** `tests/run_tests.gd` runs in `_init()`, before the autoloads exist, so it never compiled the screens that use `Game` (`main.gd`, `battle.gd`, `ending.gd` and the rest); a type that could not be inferred in a new line of `ending.gd` passed every test, and the keyboard smoke test printed the parse error and passed too, while the game made its ending screen without a script | On its first frame, once the autoloads are up, the test runner compiles every script in `scripts/` and `tests/` and fails on any that does not compile; checked by putting the error back |
| **Everyone indoors stood about 0.3 m deep in the floor.** A building's floor is a plank platform 0.31 m above the ground under its middle (`Architecture.house`), but the hero, Yue Ling and the people inside were all placed at the height of the ground under their own tile | `World._stand_y`: indoors, people stand on the planks (and upstairs on the upper storey's) |
| **Battle messages were cut off mid-word in 36 of the 45 regions.** The battle log drew each message on one 440-pixel line, and "Enemies appear!" with three monster names ran past it (up to 759 pixels: "Frost Hare of the Moon, Three-Legged Moon Toad, Silver Crane of the Long Night"); three monster names were also wider than their 200-pixel labels | A long message wraps onto more rows of the log, which shows the newest five; names and boss banners shrink to fit, and a name that would run into its neighbour's moves down a row; a test measures every name with the game's font |
| The bot's twelve-hour `max_time` would have stopped a game of 12 h 46 min before its end | Fifteen hours |

### Bugs fixed in the Part X release

| Bug | Fix |
|---|---|
| **Trails broke through the walls of houses.** `MapGen._carve` joined anything cut off by a greedy random walk towards the target that turned whatever it stepped on into path, building walls included; once a region's open ground stopped being its whole map, the Tea House of the Nine Terraces, the Silkworm House, the Cowherd's Ferry House and the Sleepless Inn each lost wall tiles | A trail is the cheapest way across a cost grid (open ground cheap, forest and water dear, a little noise so it still wanders) where buildings and the map's edge cannot be crossed; the "walls all round except the door" test covers every building |
| **The bot could meditate for ever in a region it had reached**: it counted itself "in" a region as soon as it crossed the border, and looked for monsters only within 64 steps; in the new world, borders lie well outside a region's open ground, so at the Blood Moon Palace every pack was out of reach and it waited 45 game-minutes for a "respawn" | If nothing is close, the bot walks to the nearest pack anywhere in the region, and the respawn wait ends when any pack of the region is back |
| **Buildings in a mirrored region would have stood at the wrong end of it**: a building's rectangle was moved into the world by its top-left corner (`Rect2i(to_world(position), size)`), which on a flipped map is the top-right corner (no flipped region happened to have a building) | `Atlas.rect_to_world` maps both corners; needed now that maps are turned to face their road |
| **Techniques ran off the pause menu**: the list had four fixed columns of seven (28 places), and Lin Feng knows 30 techniques by the end of Part IX, so the last two were drawn past the right edge of the panel | Four columns with as many rows as the list needs; Part X brings it to 33 |
| **Long objectives were cut off mid-sentence**: the HUD drew the objective on one 480-pixel line, and 40 of the 344 quest objectives are longer (up to 770 pixels: "Follow the east road onto the Scorched Millet Plains and find Old Farmer Tian at the shrine of Hou Ji") | Objectives that do not fit wrap onto a second line in place of the heading |
| `Game.tile`, a world tile, was set to the sect's own tile (20, 8) by `reset()` and `respawn()`, a spot in the north-west sea of the new world | The sect's courtyard in world tiles |
| The Nomad Matriarch had only two things to say (every other townsperson has three) | A third line, and a test that every townsperson has three |
| Nothing checked that dialogue fits the dialogue box (four lines); one new line of Part X ran to five | A test measures every line of dialogue and chat with the game's font; the long line was split |
| **Two of this README's diagrams did not render on GitHub**: the big gameplay flowchart had an extra `end` after Part VIII's subgraph, and the open-world release's flowchart had `house():` unquoted inside a node label; Mermaid rejects both | Fixed; every Mermaid block in this README was checked with Mermaid's own parser (11.4) for this release |

### Bugs fixed in the Part IX release

| Bug | Fix |
|---|---|
| **Every exported clip ran a quarter too slow.** `kit.bake_action` keys a pose every 1/30 s on consecutive frames, but Blender's factory scene runs at 24 frames per second, so a 0.55 s attack lasted 0.69 s and every walk dragged | The scene runs at 30 fps and clips start at 0 s (`kit.reset`, `kit.export`), so loops meet their first frame |
| **Characters walked like pacing camels**: in the walk clip `thigh.L` and `upper_arm.L` were driven by the same `sin(phase)` with the same sign, so each arm swung forward with the leg on its own side | Arms counter-swing, a few frames behind the legs |
| **The hero slid along the road**: he crosses a 2 m tile every 0.16 s (12.5 m/s) on a walk cycle of 0.7 s per stride | A run clip with a flight phase for the hero and Yue Ling |
| **Monsters never moved** in the world: only `idle` was ever played | Packs amble round their spot on walk cycles and turn to face the hero |
| **Fallen fighters shrank away in half a second** | A death clip that holds its last frame; fallen allies stay on the field until raised |
| **Every pond was a set of white-rimmed squares**: corners touching water were forced under the surface and the foam marked every corner that touched land, so shorelines were staircases outlined in white | A smooth water field for shore heights, subdivided shore tiles, foam by real depth |
| **Costumes glowed neon**: ambient light (0.85) plus the sun (1.1) plus a fill light lit every surface at about twice its colour | Actor shading with a reduced ambient term and a key light that keeps a lit surface near its painted colour |
| A white stripe of inner robe ran **from the collar to the hem like an apron**, and the collar stood up the neck like a turtleneck | A wrap-around skirt with a trimmed overlap edge; a V at the throat |
| **Part VIII's four guides were drawn as procedural stand-ins**: `_npc_opts` had no entry for them | Each uses its Blender model; any NPC with a Blender model uses it |
| The bot's ten-hour `max_time` would have stopped a ten-hour game before its end | Twelve hours |
| **Yue Ling ran sideways, and kept running on the spot**: she turned to face the hero while her place is off his shoulder (0.7 m behind, 1.4 m to the side), so she ran about 60 degrees off her path, and "moving" was judged by her distance to him, which is always 1.6 m there | `World.companion_step`: she faces the way she actually moves, runs only while her speed says so (with hysteresis), then looks where the hero looks, and turns to him in a conversation (`--follow` in the tour films it) |
| **Monsters were one colour**: each enemy's single colour tinted almost the whole body (85 to 98% of most models), white bellies and dark stripes came out as light and dark shades of that one hue, and the "secondary" sat only 40 degrees round the colour wheel at the same value | Five-role palettes (below) |

### Bugs fixed in the Part VIII release

| Bug | Fix |
|---|---|
| **The ending screen was hidden behind a giant tree trunk.** The six floating islands were spread round a full circle (`i * 1.1 + 0.4`), which put one peach-tree island at z = 5, between the camera and the hero | The islands sit on the far half of the sky only |
| **Lotus of Rebirth and Homeward Lantern could not raise the fallen**: the heal only targeted living allies, so a knocked-out Lin Feng stayed down; the bot never tried | Reviving heals (`"revive": true`) reach the fallen and raise them; the bot uses them when an ally is down; regression test |
| Lions, tigers, lynxes, apes, macaques and qilin (**11 enemies**, including the White Tiger boss) were drawn with the **wolf** model | New tiger, ape and qilin models; enemies remapped |
| **Character heads were almost half a metre tall** (two stacked ellipsoids, under five heads to the body) with eyes stuck onto the surface | Sculpted heads at about seven heads to the body, eyes set into sockets |
| Hanging sleeves were **inside out** (black) when a loft's cross-sections ran clockwise | `loft()` detects the winding and flips faces so normals point out; linings are built inside on purpose |
| The post-processing rect set a `size` on top of full-rect anchors, printing a warning on every launch | The anchors size it |
| A defeat message was guarded by `if not quiet or true` (always true) | Removed the dead condition |
| `plate_segments` crashed on per-axis radii; `bake_ao` created an unused random generator | Componentwise radii; removed |
| Exported assets were only checked by playing the game | `art/check_assets.py` validates every GLB in CI |

### Bugs fixed in the open-world release

| Bug | Fix |
|---|---|
| The pause-menu **techniques list ran off the right of the panel** once Lin Feng knew more than 21 techniques (three columns of seven) | Four narrower columns of seven |
| The sect's **pagoda stood outside the map** past the east wall, on land the hero could walk across in an open world | It stands on its own blocked footprint on the mountain |
| Map **connection trails were straight L-shaped corridors** cut through forests, the most "squarish" thing in every region | Trails wander on the diagonal (`MapGen._carve`) |
| **Monster groups could spawn inside buildings**, and a trail carved to an indoor NPC could break through a wall | Spawns skip floors under a roof; trails to anything indoors go to the doorstep; clearing round NPCs never removes a wall |
| **Hunt kills were credited to the region the player stood in**, not the one the monsters came from, so a fight just across a border would not count | Kills are credited to the monsters' own region; enemy ids carry their region |
| The water surface stopped at the **square edge of each water tile** | The water plane runs on under the bank, so the shoreline follows the ground |
| The bot's **breadth-first search** would have been far too slow over a whole world | `AStarGrid2D` for routes, a capped search for nearby monsters |

### Bugs fixed in the landscapes release

| Bug | Fix |
|---|---|
| **Every pond, lake and river was invisible.** The far-ground "skirt" that extends the land to the horizon also lay flat across the whole map at y = -0.05, above the water surface (-0.12), covering it with a sheet of grass | Inside the map the skirt now drops below the deepest pond bed |
| **The image looked misty and slightly blurred**: no anti-aliasing; a bloom with a 0.62 threshold added a blurred copy of most of the frame; a soft-light glow; heavy fog with aerial perspective; film grain and chromatic aberration | 4x MSAA; bloom and glow only on bright highlights; fog at 30% density without aerial perspective; grain and fringing removed |
| The bot could **walk back and forth forever** between two tiles when two monster groups were about equally far away (the "nearest" target swapped with every step); the 45-minute stuck detector would have failed CI | The current target is kept unless another is clearly closer |
| Large trees beside the road could **hide the hero** from the chase camera | Foliage within a few metres of the camera dissolves in a dither pattern |
| Rotated boxes in the mesh builder are scaled along world axes, so rotated walls stretched off the map | Architecture uses axis-aligned extents (documented in `architecture.gd`) |
| The toon ink outline had a fixed model-space width: **thick in close-ups**, thin far away | Outline width scales with view depth |
| `ribbon`/`sheet` in the Blender kit returned nothing, and `recolor` erased the outline-skip flag of thin sheets | Both return their vertices; recolouring keeps the surface flag |

### Bugs fixed in the Part V release


| Bug | Fix |
|---|---|
| The bot's path-finding treated **portal tiles as walkable**, so a path that brushed past another gate teleported it (it bounced between the sect and the forest forever once a second road ran past the east gate) | Gates other than the goal block the path |
| The bot healed with Dawn Lotus at best and **never used Seal Bloom** | It picks the strongest heal Yue Ling knows |
| **Battle menus had no scrolling**: the late-game technique list (up to 17 entries) ran off the bottom of the screen and the cursor moved onto invisible entries | `UI.menu_list` scrolls with the cursor and shows scroll hints |
| The pause-menu **techniques list** overflowed its two columns of eight | Three columns of seven |
| The **HP and Qi bars** in the world HUD and on the meditation screen covered the numbers once they reached four digits | Bars moved clear of the text |
| **Long boss names** were clipped under their health bars, and party names were drawn underneath the translucent command panels | Wider labels for bosses; party labels removed (the status panel shows them) |
| **Long speaker names** ("Xuan Wu, Black Tortoise of the North") overflowed the dialogue name tag | The tag grows with the name |
| A conversation with **no lines** opened an empty dialogue box that Enter could never close | `say([])` runs its callback directly |
| Starting a **second game** from the title kept the previous run's toasts and NPC chat rotation | Reset in `new_game()` |
| A script error made `tests/run_tests.gd` **hang until CI's 40-minute timeout** instead of failing | A watchdog fails the run on the first frame; the smoke test has a frame limit |

### Bugs fixed in earlier releases

| Bug | Fix |
|---|---|
| Two identical foes (same species, level and HP) were drawn **on top of each other** in battle: `Array.find()` compares dictionaries by value, so both resolved to the same stage slot | Each foe gets an explicit `slot` (`Data.make_foes`); regression test added |
| The sect's **east gate** faced the wrong way (rotation only applied to `x > 40`, but the sect is 40 tiles wide) | Orientation is computed from the map edges |
| Cancelling **Yue Ling's basic attack** target selection opened the Skills menu instead of the main menu | Both basic attacks (`strike`, `needle`) return to the main menu |
| Using a pill from the pause menu at **full HP or Qi** silently wasted it | The pill is kept and a message is shown |
| The **techniques list** in the pause menu overflowed the panel once more than 12 techniques were known | Two columns of eight |
| The **Jade Mantis Matriarch** was drawn as a wolf and the **Eon Tortoise** as a crab | New mantis and tortoise models |
| The bot's default `--max-time` (4 h) would have cut off a longer game | Raised to 6 h |

## Narrative plot holes found and fixed

Nineteen holes found in this release by reading every quest step, conversation and townsperson's chat against the quest order and the world map:

| Plot hole | Fix |
|---|---|
| **Lin Feng gave the Nine Heavens root away** to the Hollow Heaven as a seed in Part III, yet everyone still calls him its bearer, and it goes on waking | Yue Ling sees it at once: a seed that is given is a seed that is planted, and the Hollow's dawn grew one back in him with every branch the old root had woken |
| **The sect's townsfolk talked about the future on the first morning**: stars falling in the pond, saving the sky twice, three demon lords and a Jade Emperor, feeding immortals, a new sweeper with Lin Feng's old broom while Lin Feng was still sweeping | Those lines wait until the story has got there (`Data.CHAT_LATER`); Little Bai takes up the broom when Lin Feng leaves the sect; the others got lines for the beginning |
| Houtu thanks Lin Feng for turning the Wheel "**and then** closing the Ledger": the Ledger closed in Part IV, the Wheel turned in Part VI | The right order |
| **Who holds the sky up?** Part V: Nuwa's pillars (and once the Court's stolen years); Part XI: Chong, for four thousand years | Chong holds heaven *away from the earth*; Nuwa's pillars bear its weight |
| **The Court's age**: ten thousand years by every ledger, but the Moon Palace was kept "since before the Court was built" and the Jianmu stood "before the Court, before Yu" | Chang'e has kept it since the archer's day; the Jianmu stood before Yu |
| The Weaver Star is **"the Jade Emperor's granddaughter"**, and this world's Jade Emperor is the one Lin Feng ended | The Queen Mother's granddaughter, as Xiwangmu herself says |
| The Weaver Star wove the river's banks for **three thousand** years; everybody else counts ten thousand | Ten thousand |
| **Fox-tail arithmetic**: a thousand years for nine tails, a thousand for each, nine hundred, three hundred for three | A thousand years to grow all nine; a one-tailed fox cub at the Gate now complains that nobody will tell him the real sums |
| **The sect's age**: three hundred years, but its Seal was co-forged by an ancestor who "waited three thousand years", its dead lie in a graveyard "a thousand years" old and its chime was "cracked for a thousand years" | Three hundred years throughout |
| **The four pillars are not at the corners of the world**: the "western" pillar is in a desert south-east of the sect | The Elder explains that Nuwa ringed the tear in the sky at the world's south-east edge, so the books' directions are the pillars', not the map's |
| The Moon Palace was **"in the west"** although it lies past Fusang in the far east | Over the top of the sky, into the night |
| Longmen had **three hundred years of boats** but its River Earl took brides for a thousand | A thousand years of boats |
| The sleeping babies of Part VII were **"gone"** in the morning, but their bodies are in their cradles | They would not wake: nobody was home behind the eyes |
| The Naihe Bridge was open **"for the first time in sixteen years"**; the Wheel had only stopped a season before | For the first time since the Wheel stopped |
| The Void Rift lay on the volcano's **eastern** slope (it is west), and the hermit who "knows the Emperor's name" never says it | The western slope; he knows what the Emperor is |
| Gun says Yu **"had his mother's sense"**: in this telling Yu was cut from Gun's own body | "He did not get that from me" |
| **Four Part X guides each forgot a boss** of their region in the briefing (the Stone Lion, Gun's turtle, the white fox, Kuafu) | Each names all five |
| **"Nobody could climb up or down to check"**, although Lin Feng had climbed the Court's stair and walked the sun's road | The Archivist: the Court's stair went to its own door and no further; the Level Heaven is above it |
| The Seal is **"the lotus at your belt"**, three lines before it "slept in Lin Feng's dantian"; Bai Ze's "I told you the Gate had opened for three" pointed back at a line most players never hear; the Needle General's needle was kept and never used | The lotus mark over his dantian; Bai Ze says it in the scene; the needle goes to Weaver Liu to unpick the last threads |

### Plot holes fixed in the Part VII release

| Plot hole | Fix |
|---|---|
| Why did every forest, marsh and desert have **a gate in it**, and why does the world now run on without them? | Part VII: the gates were the Court Weaver's seams; when the Wheel turned they came undone and the land grew back into one |
| The **village midwife** who raised Lin Feng (Part VI) was never seen | Granny Wen is Part VII's first guide, in her own house |
| The finale's **baby girl who knows Lin Feng's face** was left unexplained | Part VII: she is Little Wan, Su Wan reborn; the story turns on bringing her home |

### Plot holes fixed in the Part VI release

| Plot hole | Fix |
|---|---|
| Lin Feng is "an orphaned sect sweeper", but **his parents were never mentioned again** in five parts | Part VI: the Elder found him as a baby beside two nameless graves; his parents, Lin Shan and Su Wan, hid him from Xu Mo's hunters, refused Meng Po's soup for sixteen years to wait for him, and walk on to rebirth in the finale |
| If the Elder found him as a baby, why has he only **swept the steps for three years**? | The Elder left him with the village midwife below the mountain, where no hunter would look for a bearer; he climbed the steps at thirteen |
| Yue Ling "woke beside a lotus pond **three winters ago**", the same winter Lin Feng arrived, with no reason given | The Seal woke her when the bearer came up the mountain |
| The Court's harvest held up the sky (Part V), but **death and rebirth**, which every soul passes through, were never addressed | Part VI: the Court also turned the Wheel of Rebirth; with the Ledger closed it stopped |

### Plot holes fixed in earlier releases


| Plot hole | Fix |
|---|---|
| The Elder asks for **three** Frost Jades but the quest needs four | Elder now says four |
| The **Heaven-Cleaving Sword** was usable from Early Nascent Soul, before Ancestor Jian Wuchen teaches it | Technique is gated on beating the Thunder Roc (`after` field) and covered by a test |
| The Elder demands the **Roc's feather** that the player is never given | The Roc now drops a feather item, mentioned in dialogue |
| The Dragon King gives a **pearl "as proof"** that never exists, and greets Lin Feng as if they had met ("how you have grown") | He gives a Dragon King's Scale which Sage Huo Rong recognises; the greeting no longer implies a past meeting |
| Sage **Chi Rong** and the villain **Chi Yan** shared a surname with no relation | Sage renamed Huo Rong |
| Xu Mo "hunted you for **three centuries**" although Lin Feng is a teenager | Reframed as hunting the *root's* bearers, and resolved by Part III (Lin Feng is the twentieth bearer) |
| Marsh Hag called Lin Feng the **seal's bearer**; everyone else says root bearer | Unified to "bearer of the Nine Heavens root" |
| Iron Fang jeers at a **"sweeper boy"** he could not know about | Now a "sect boy" |
| The **Jade Mantis** hunt had no in-story motivation | The Elder's briefing mentions the mantis claiming the herb groves |
| Alchemist says "take these pills" but gives none | Now "take this payment" |
| Yue Ling's origin (a random healer who happens to be bound nearby) had no foreshadowing | She wakes beside a lotus pond three winters ago; paid off in Part III |
| Sage Huo Rong lists three fire bosses but there are four; the hermit says "three who shepherd" the horrors but there are four; the Gatekeeper lists the wrong guardians | Counts and lists corrected |
| Quest items (pearls, embers, star fragments) were collected and never used | Each is now referenced in the following dialogue |
| The **sect storyline was abandoned**: the failing Seal, the Elder and Xu Mo's army were never resolved and the game ended in a distant gate | Part III returns Lin Feng to the sect and resolves the Seal, the Elder, Yue Ling and the Emperor |

## Architecture

Game logic (`game.gd`, `data.gd`, `mapgen.gd`, the battle rules and the bot) is unchanged by the 3D port; only the presentation layer is new. Screens derive from `ScreenBase` (`screen.gd`): each owns an optional `Node3D` scene plus a 2D overlay drawn with the UI helpers.

```mermaid
flowchart TD
    subgraph Screens
        W[world.gd<br/>four realms and their floors, streaming,<br/>ladders, chase and conversation cameras,<br/>cutscene gestures, HUD]
        B[battle.gd<br/>3D arena, shoulder camera]
        T[title / ending / meditate<br/>3D scenes]
        M[menu / shop / dialogue / choice /<br/>create: 2D overlays]
    end
    W --> ATL[atlas.gd<br/>four realms: sites, warped Voronoi,<br/>coast, A* roads, seals, ladders, floors]
    ATL --> MG2[mapgen.gd<br/>regions, buildings]
    W --> TER[terrain3d.gd<br/>height field, ground and water shaders,<br/>horizon, bridges]
    TER --> SC[scatter.gd<br/>ecology placement]
    SC --> FL[flora.gd + nature.gd<br/>grown plants, leaf cards, grass]
    SC --> RK[rocks.gd]
    TER --> ARC[architecture.gd<br/>halls, enterable houses, upper storeys,<br/>cellars, stairs, walls, dwellings]
    TER --> FA[fauna.gd<br/>wildlife]
    W --> MOD[models.gd<br/>procedural people and monsters,<br/>action poses]
    MOD --> AS[assets.gd<br/>Blender GLBs: 163 people with<br/>21 clips each, the party 53,<br/>40 monsters, 26 props;<br/>palettes from one tint]
    B --> MOD
    B --> FX[fx3d.gd<br/>weather, spells, slashes, projectiles]
    W --> FX
    TER --> MB[mb.gd<br/>primitives, limbs, lathes, ribbons<br/>toon + outline + aura shaders]
    MOD --> MB
    FX --> MB
    TER --> LK[(look.gd<br/>50 region looks, cellar air,<br/>sky shader)]
    TER --> AS
    W --> UI[ui.gd and gfx.gd<br/>panels, bars, minimap,<br/>the chosen name on screen]
    W --> FS[fashion.gd<br/>looks, origins, outfits, rides]
    MOD --> FS
    M --> FT[fate.gd + fate_text.gd<br/>five threads, their states,<br/>bonds through the trials]
    M --> GD[grudges.gd<br/>the six grudges that stayed,<br/>what each was owed, Nie]
    M --> BD[bonds.gd<br/>Yue Ling: closeness, heart-to-hearts,<br/>wishes, her heart, Part XV's memories]
    W --> PR[props.gd + structures.gd<br/>things to do: pavilions, a watchtower,<br/>a stage, a hot spring and more]
    W --> CK[clock.gd<br/>the hours: sun, moon, stars,<br/>the story holding the hour]
    CK --> LK
    W --> FK[folk.gd<br/>219 townsfolk: plans, places,<br/>A* walks, lent clips, words]
    FK --> AS
    W --> HK[havoc.gd<br/>things that break: rigid-body<br/>pieces, owners, battle scars]
    B --> HK
    BD --> PR
    GD --> FT
    B --> LR[lore.gd<br/>a story for every foe]
    B --> UI
```

Highlights of the renderer: merged vertex-coloured meshes (a few draw calls per chunk) whose vertex alpha selects a procedural surface texture in the toon shader, an inverted-hull ink outline (skipped for thin double-sided geometry), MultiMesh instancing for landmarks, boulders, decorations and grass, a height-field terrain with a per-region ground shader, animated water/lava with foam, a sky shader per region, two-layer weather (snow, rain, petals, embers, bubbles, void stars, sand, clouds, lanterns, sparks, plus fireflies, pollen, ash or haze), rigged characters and monsters, and element-specific spell effects.

The screenshot tour also renders model galleries (`--gallery`).

Regenerate screenshots (needs a GL context; use `xvfb-run` on a server):

```sh
godot --path . --fixed-fps 30 -- --tour=docs/screenshots              # everything
godot --path . --fixed-fps 30 -- --tour=out --areas=mirror,grave --no-extras   # some regions
godot --path . --fixed-fps 30 -- --tour=out --areas=garden --no-extras --gallery  # one region + model galleries
godot --path . --fixed-fps 30 -- --tour=out --areas=maple --no-extras --world-only --vista  # ground and aerial views
godot --path . --fixed-fps 30 -- --tour=out --areas=none --no-extras --portraits  # character close-ups
godot --path . --fixed-fps 30 -- --tour=out --areas=none --no-extras --props=pavilion,watchtower  # things to do, in use
godot --path . --fixed-fps 30 -- --tour=out --areas=none --no-extras --lotus  # Yue Ling and Part XV (--hermitage or --kite: one part)
```

## The playthrough bot

`scripts/bot.gd` plays the entire game end to end through the **same input surface a human uses** (`up/down/confirm/cancel` presses on the top screen and a held movement direction). It pathfinds across the open world with `AStarGrid2D` (seals still closed and other monsters count as blocked), grinds and meditates when under-levelled, rests when hurt, shops, picks skills by elemental weakness, heals with pills or Spring Rain, and handles tribulations. Since Part XII it also wakes the branches of the Nine Heavens root by a plan, opens the Founder's caves it passes once its realm allows, and when it must grind in the higher realms it goes looking for packs anywhere in the region rather than meditate for hours. Since Part XIII it **prepares for every trial** by a plan that takes each one a different way (`TRIAL_PLAN`: craft, respect, wealth, might, the Dao, a relic) and falls back on the cheapest feasible way: it hunts the essences a recipe needs, crafts at the cauldron or the forge, earns stones, does deeds for renown (nearest first), fetches keepsakes from upper storeys and cellars, changes Daos at a stele, tempers its sword, and opens the Eight Gates in the order of `GATE_PLAN`; `--route=sword|peoples|cauldron` picks its road into the heart (the default is the Many Peoples). Since the Fates and Faces release it makes the story's sweeper at the creation screen, summons the fastest ride it owns (R) whenever it is out of doors, changes into the newest outfit it has earned, answers every fated encounter by `FATE_PLAN` (Tala, Qiu Ye and Fang Hu become friends, Xu Lan an enemy spared at the end, Liu Ying an enemy who falls, so one run walks friendship, enmity, sparing and ending), takes the bond paths through King Yama, the Weaver and Bifang, goes round the six grudges that stayed in the order of `GRUDGE_ROUTE` and answers each by `GRUDGE_PLAN` (a friend where one can, else it pays, and it leaves the Admiral to the Wheel so that one run sees a grudge feed Nie). Since the Lotus release it hears out every heart-to-heart as soon as Yue Ling wants one (T) and answers by `TALK_PLAN` (mostly towards walking beside him, now and then towards the mountain or a road of her own), grants her wishes when a thing that can grant one stands near its road (giving up on one it cannot reach in half a minute), goes round six of her memories in Part XV (`MEMORY_ROUTE`, `MEMORY_PLAN`), takes the Unweaver side by side and the Warden with the Key of the Open Door, and lets her write the future her heart leans to. Since the Living Land release it buys red paper from the towns' merchants and a fish from their fishermen, gives red envelopes to their children and guesses the stallholders' lantern riddles the way a player would (it walks up to the nearest one standing still out of doors, turns to them and presses Enter, and waits in the town for them to come out when they are all indoors), reminds the nearest five towns of the old ways, takes Xi with the door gods' peach wood and Nian by the people, and walks round the jars and woodpiles of the towns (a cost on those tiles in its A*) rather than galloping through them.

To make its clock a fair estimate of a person's playtime it uses human-scale pacing: 0.2 to 0.4 s per key press, and each dialogue line is "read" for about `length / 40` seconds after it finishes typing.

```sh
godot --headless --fixed-fps 30 --path . -- --bot --seed=1234 --report=build/bot_report.json
```

**Is the game sped up?** No. `--fixed-fps 30` makes each frame advance the game clock by exactly 1/30 s regardless of how fast the machine renders it. All movement, typing, battle animation and meditation run off that same frame time, so a full hour of *game time* is simulated in under a minute of *wall-clock* time. `Game.playtime` is the game clock, and it is the number reported. Drop `--fixed-fps` (and optionally pass `--timescale=N`) to watch the bot in real time.

Latest result (seed 1234, identical across runs). The last release took 18:23:43. The same bot now reaches the end of Part XV at 18:25:06 (the old chapters take about as long as they did: it walks round the towns' jars and woodpiles, and the townsfolk step aside for it), and Part XVI plays in about 1 hour 3 minutes: the game is now **1 hour 4 minutes longer**. It passes 35 trials (might 4, craft 9, wealth 4, respect 5, dao 4, peoples 1, relic 2, bond 4, side by side 1, by the people 1), opens 4 of the Eight Gates, does 5 deeds and reaches the heart by the Road of the Many Peoples; it has all 34 heart-to-hearts and every one of Yue Ling's wishes; in Part XVI it reminds five towns of the old ways, cuts winter plum in the snows of Frostpeak, buys the reunion dinner's fish from five fishermen, takes Xi with the door gods' peach wood and Nian by the people, drives Nian's cubs out of the bamboo, walks up to the children of the towns with red envelopes on New Year's Day (turning to each and pressing Enter as a player would) and guesses six lantern riddles in the Dawn Market. Its one defeat is early in Part I, in the Bamboo Forest's cull: it gets there a second later than it used to, so the fights there roll differently; it is carried back to the sect and goes on.

```
game play time  : 19:28:20 (70101 s)
wall clock      : ~23 min (headless)
final realm     : Early Ten Thousand Hearths
battles / kills : 1787 / 3291   deaths: 1
time by screen  : battle 22176 s, meditate 12085 s, dialogue 21342 s, world 13870 s, menu 644 s, shop 26 s, choice 70 s
meditation for  : rest 11969 s, grind 53 s, respawn 38 s, children 26 s
trials passed   : 35 (might 4, craft 9, wealth 4, respect 5, dao 4, peoples 1, relic 2, bond 4, side by side 1, by the people 1), renown 733, deeds 5, gates 4
time by area    : sect 3845, mountain 3465
                  bamboo 2216, marsh 1340, frost 1619, thunder 754, palace 891
                  dragon 748, volcano 1249, void 746, celestial 1533
                  mirror 896, grave 1745, time 797, origin 1298
                  cloudsea 787, court 771, forge 858, garden 1492
                  dunes 882, fungal 830, aurora 948, chaos 1251
                  maple 2619, karst 981, springs 1199, wheel 1615
                  village 1637, terraces 1508, silk 1116, loom 1327
                  starferry 1155, magpie 1119, starpalace 1026, jasper 1322
                  yanggu 1755, millet 1437, fusang 1368, guanghan 1226
                  longmen 1703, drowned 1462, tushan 1500, buzhou 1493
                  juntian 1543, changhe 1167, ninesprings 1525, youdu 1275
                  penglai 1392, fangzhang 1245, yingzhou 1203, guixu 1336
result          : PASS (needs >= 57600 s)
```

Bot flags: `--bot`, `--seed=N`, `--report=PATH`, `--min-time=SECONDS` (default 3600; CI uses 57600), `--max-time=SECONDS`, `--timescale=N`, `--shots=DIR` (needs a window, saves screenshots at key moments), and `--tour=DIR` (screenshot tour, see Architecture), and for development `--bot-start=STEP_ID` (start a fresh game at a quest step with the level and boss kills a player would have) and `--bot-trace=SECONDS` (print the bot state, its goal and the trial ahead every frame after that game time), and `--route=sword|peoples|cauldron` (the road into the heart of the Eight Gates).

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) downloads Godot, imports the project, runs the data-integrity tests (`tests/run_tests.gd`: quest/dialogue/NPC/boss references, gate symmetry, map reachability and determinism, the open world (everything reachable, seals closing every unopened region, determinism), every building's walls and door, every 3D model and terrain builds, story consistency, the realms, floors, Daos and peoples, the Eastern Sea, realm suppression, the nine branches of the root and the Founder's caves, cutscene gestures and progress-aware chat, every trial and its ways, the recipes and where their ingredients come from, the deeds, renown, the Eight Gates and the three roads, character creation, the outfits and rides, a story for every foe, every path through every fated encounter, the grudges that stayed, Yue Ling's heart-to-hearts, wishes and futures, the bigger things to do, Part XV's memories, threads and trials, and that every script compiles), then runs the bot headless and **fails the build if the game is not completed or takes less than 16 hours of game time**. A second job installs Blender as a Python module, rebuilds every asset in `art/` from its script and validates the exports with `art/check_assets.py`. The bot report is uploaded as an artifact and shown in the job summary.

```mermaid
flowchart LR
    PR[Push / PR] --> DL[Download Godot 4.7.2<br/>cached]
    DL --> IMP[Import project]
    IMP --> T[Data-integrity tests]
    T --> B[Bot plays whole game<br/>--fixed-fps 30]
    B --> G{completed and<br/>game time >= 16h?}
    PR --> ART[pip install bpy<br/>art/build_all.py] --> CHK[check_assets.py]
    G -- yes --> OK[Pass + report artifact]
    G -- no --> FAIL[Fail]
```

## Project layout

```
scripts/data.gd      content: skills, enemies, areas, quest chain, dialogue
scripts/trials.gd    many roads: trials and their ways, essences, crafting recipes, renown and deeds
scripts/props.gd     things to do: outdoor props by theme (and the bigger things after them), usable furniture, what comes of using them
scripts/fashion.gd   who Lin Feng is (character creation: names, looks, colours, origins), outfits and rides
scripts/create.gd    the character creation screen over the title's cliff
scripts/fate.gd      fated encounters: the five threads, their chapters and states, bonds, presence, rewards
scripts/fate_text.gd the words of the fated encounters: every chapter's variants, choices, states, epilogues
scripts/lore.gd      a story for every foe: the bestiary's monsters and the bosses' pasts
scripts/grudges.gd   Part XIV's six grudges that stayed: what each was owed, the answers, Nie's weight, epilogues
scripts/bonds.gd     Yue Ling: closeness, heart-to-hearts, her wishes, her heart and her future, Part XV's memories
scripts/structures.gd the bigger things to do: pavilion, watchtower, stage, hot spring, millstone, archery, lantern green...
scripts/clock.gd     the hours of the day: double-hours and watches, the sun and the moon, the story holding the hour
scripts/folk.gd      the people of the towns: who lives where, their days, walks, work, words and tools
scripts/havoc.gd     things that break: what stands where, who owns it, the rigid-body pieces, battle scars
scripts/mb.gd        mesh builder (primitives to merged ArrayMesh)
scripts/models.gd    3D people, monsters, props
scripts/terrain3d.gd 3D terrain, landmarks, buildings
scripts/look.gd      per-region look (sky, fog, light, weather)
scripts/fx3d.gd      weather, combat particles and technique effects
scripts/assets.gd    loader for the Blender assets (materials, tint, animation clips)
scripts/post.gd      screen-space post-processing pass
scripts/nature.gd    painted leaf textures, foliage-card and grass shaders
scripts/flora.gd     procedural plant species grown in variants
scripts/scatter.gd   ecology: where every plant, rock and dwelling goes
scripts/rocks.gd     procedural rocks and limestone towers
scripts/fauna.gd     ambient wildlife
scripts/architecture.gd  halls, roofs, walls, archways, bridges, dwellings
art/lib/kit.py       Blender (bpy) toolkit: geometry, skinning, AO, rigs, clips, export
art/lib/person.py    character builder shared by every person asset, and its 21 clips (ten cutscene gestures),
                     and the party's 18 interaction clips
art/lib/face.py, hair.py, garment.py, accessory.py   heads, hair, clothes, hand props
art/lib/race.py      wings, crests, fox and fin ears, tails, antlers, scales, whiskers
art/lib/sculpt.py    lofts, profiles, noise, splines, strands
art/lib/clay.py      metaball sculpting with bone weights (creature bodies)
art/lib/anatomy.py   animal heads, bodies, legs, fur, feathers, scales; canine.py, feline.py, bird.py
art/lib/creature.py  monster rigs, leg IK, gaits and the shared motion clips
art/check_assets.py  validator for the exported GLBs
art/characters, art/monsters, art/mounts, art/props   one Blender script per asset (art/mounts: the horse)
art/build_all.py     rebuild every asset
assets/              generated .glb files (never edited by hand)
scripts/screen.gd    ScreenBase: 3D scene + 2D overlay
scripts/gfx.gd       2D UI ornaments, panels, minimap
scripts/tour.gd      screenshot tour (developer tool)
scripts/game.gd      autoload: state, progression, quest engine, play clock
scripts/main.gd      screen stack, input, story flow
scripts/choice.gd    a choice over the world: which Dao to walk, which branch of the root to wake, a gift for one of the peoples, a trial's ways, a townsperson's request
scripts/shop.gd      the alchemist's and the smith's: pills, tempering and crafting
scripts/menu.gd      the pause menu: cultivation, the Journal, Daos and peoples, the world map, the Annals
scripts/world.gd     3D third-person open world: realms, floors, streaming, movement, interiors, HUD
scripts/atlas.gd     the three realms and the floors of buildings: layout, ownership, borders, roads, seals, ladders
scripts/mapgen.gd    seeded map generator with reachability guarantee
scripts/battle.gd    turn-based combat on a 3D stage
scripts/bot.gd       end-to-end playthrough bot
tests/run_tests.gd   data-integrity tests
```
