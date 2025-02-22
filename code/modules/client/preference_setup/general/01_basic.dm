/datum/preferences
	var/age = 30						//age of character
	var/spawnpoint = "Default" 			//where this character will spawn (0-2).
	var/metadata = ""
	var/real_name						//our character's name

/datum/category_item/player_setup_item/physical/basic
	name = "Basic"
	sort_order = 1

/datum/category_item/player_setup_item/physical/basic/load_character(datum/pref_record_reader/R)
	pref.spawnpoint = R.read("spawnpoint")
	pref.metadata = R.read("OOC_Notes")
	pref.real_name = R.read("real_name")

/datum/category_item/player_setup_item/physical/basic/save_character(datum/pref_record_writer/W)
	W.write("spawnpoint", pref.spawnpoint)
	W.write("OOC_Notes", pref.metadata)
	W.write("real_name", pref.real_name)

/datum/category_item/player_setup_item/physical/basic/sanitize_character()
	pref.spawnpoint         = sanitize_inlist(pref.spawnpoint, spawntypes(), initial(pref.spawnpoint))
	// This is a bit noodly. If pref.cultural_info[TAG_CULTURE] is null, then we haven't finished loading/sanitizing, which means we might purge
	// numbers or w/e from someone's name by comparing them to the map default. So we just don't bother sanitizing at this point otherwise.
	if(pref.cultural_info[TAG_CULTURE])
		var/singleton/cultural_info/check = SSculture.get_culture(pref.cultural_info[TAG_CULTURE])
		if(check)
			pref.real_name = check.sanitize_name(pref.real_name, pref.species)
			if(!pref.real_name)
				pref.real_name = random_name(pref.gender, pref.species)


/datum/category_item/player_setup_item/physical/basic/content()
	. = list()
	//. += "[TBTN("spawnpoint", pref.spawnpoint, "Spawn Point")]<br />"
	. += "[TBTN("rename", pref.real_name, "Name")] [BTN("random_name", "Randomize")]"
	. = jointext(., null)


/datum/category_item/player_setup_item/physical/basic/OnTopic(href, list/href_list, mob/user)
	if(href_list["rename"])
		var/raw_name = tgui_input_text(user, "Choose your character's name", "Character Name", max_length = MAX_NAME_LEN)
		if(isnull(raw_name) && CanUseTopic(user))
			return

		var/singleton/cultural_info/check = SSculture.get_culture(pref.cultural_info[TAG_CULTURE])
		var/new_name = check.sanitize_name(raw_name, pref.species)
		if(new_name)
			pref.real_name = new_name
			return TOPIC_REFRESH
		else
			to_chat(user, SPAN_WARNING("Invalid name. Your name should be at least 2 and at most [MAX_NAME_LEN] characters long. It may only contain the characters A-Z, a-z, -, ' and ."))
			return TOPIC_NOACTION

	else if(href_list["random_name"])
		pref.real_name = random_name(pref.gender, pref.species)
		return TOPIC_REFRESH

	else if(href_list["spawnpoint"])
		var/list/spawnkeys = list()
		for(var/spawntype in spawntypes())
			spawnkeys += spawntype
		var/choice = tgui_input_list(user, "Where would you like to spawn when late-joining?", "Late-Join", spawnkeys)
		if(!choice || !spawntypes()[choice] || !CanUseTopic(user))
			return TOPIC_NOACTION
		pref.spawnpoint = choice
		return TOPIC_REFRESH

	return ..()
