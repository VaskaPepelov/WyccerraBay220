
/obj/item/bodybag/rescue
	name = "rescue bag"
	desc = "A folded, reusable bag designed to prevent additional damage to an occupant, especially useful if short on time or in \
	a hostile enviroment."
	icon = 'icons/obj/closets/rescuebag.dmi'
	icon_state = "folded"
	origin_tech = list(TECH_BIO = 2)
	var/obj/item/tank/airtank

/obj/item/bodybag/rescue/loaded
	airtank = /obj/item/tank/oxygen_emergency_double

/obj/item/bodybag/rescue/Initialize()
	. = ..()
	if(ispath(airtank))
		airtank = new airtank(src)
	update_icon()

/obj/item/bodybag/rescue/Destroy()
	QDEL_NULL(airtank)
	return ..()

/obj/item/bodybag/rescue/attack_self(mob/user)
	var/obj/structure/closet/body_bag/rescue/R = new /obj/structure/closet/body_bag/rescue(user.loc)
	R.add_fingerprint(user)
	if(airtank)
		R.set_tank(airtank)
		airtank = null
	qdel(src)

/obj/item/bodybag/rescue/screwdriver_act(mob/living/user, obj/item/tool)
	if(!airtank)
		balloon_alert(user, "нет баллона!")
		return
	. = ITEM_INTERACT_SUCCESS
	if(!tool.use_as_tool(src, user, volume = 50, do_flags = DO_REPAIR_CONSTRUCT))
		return
	balloon_alert_to_viewers("баллон снят!")
	airtank.dropInto(loc)
	airtank = null

/obj/item/bodybag/rescue/attackby(obj/item/W, mob/user, click_params)
	if(istype(W,/obj/item/tank))
		if(airtank)
			to_chat(user, "[src] already has an air tank installed.")
			return TRUE
		if(user.unEquip(W))
			W.forceMove(src)
			airtank = W
			to_chat(user, "You install [W] in [src].")
			return TRUE
	. = ..()

/obj/item/bodybag/rescue/examine(mob/user)
	. = ..()
	if(airtank)
		. += SPAN_NOTICE("The pressure meter on [airtank] shows '[airtank.air_contents.return_pressure()] kPa'.")
		. += SPAN_NOTICE("The distribution valve on [airtank] is set to '[airtank.distribute_pressure] kPa'.")
	else
		. += SPAN_WARNING("The air tank is missing.")

/obj/structure/closet/body_bag/rescue
	name = "rescue bag"
	desc = "A reusable plastic bag designed to prevent additional damage to an occupant, especially useful if short on time or in \
	a hostile enviroment."
	icon = 'icons/obj/closets/rescuebag.dmi'
	item_path = /obj/item/bodybag/rescue
	storage_types = CLOSET_STORAGE_MOBS
	var/obj/item/tank/airtank
	var/datum/gas_mixture/atmo

/obj/structure/closet/body_bag/rescue/Initialize()
	. = ..()
	atmo = new()
	atmo.volume = 0.1*CELL_VOLUME
	START_PROCESSING(SSobj, src)

/obj/structure/closet/body_bag/rescue/Destroy()
	QDEL_NULL(airtank)
	return ..()

/obj/structure/closet/body_bag/rescue/proc/set_tank(obj/item/tank/newtank)
	airtank = newtank
	if(airtank)
		airtank.forceMove(null)
	update_icon()

/obj/structure/closet/body_bag/rescue/on_update_icon()
	..()
	ClearOverlays()
	if(airtank)
		AddOverlays(image(icon, "tank"))

/obj/structure/closet/body_bag/rescue/screwdriver_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_SUCCESS
	if(!airtank)
		balloon_alert(user, "нет баллона!")
		return
	if(!tool.use_as_tool(src, user, volume = 50, do_flags = DO_REPAIR_CONSTRUCT))
		return
	balloon_alert_to_viewers("баллон снят!")
	airtank.dropInto(loc)
	update_icon()
	airtank = null

/obj/structure/closet/body_bag/rescue/use_tool(obj/item/tool, mob/user, list/click_params)
	// Tank - Install air tank
	if (istype(tool, /obj/item/tank))
		if (airtank)
			USE_FEEDBACK_FAILURE("[src] already has [airtank] installed.")
			return TRUE
		if (!user.unEquip(tool, src))
			FEEDBACK_UNEQUIP_FAILURE(user, tool)
			return TRUE
		set_tank(tool)
		user.visible_message(
			SPAN_NOTICE("[user] installs [tool] into [src]."),
			SPAN_NOTICE("You install [tool] into [src].")
		)
		return TRUE

	return ..()


/obj/structure/closet/body_bag/rescue/fold(user)
	var/obj/item/tank/my_tank = airtank
	airtank = null // Apparently this is required to avoid breaking my_tank checks further down after the parent proc runs qdel(src)
	var/obj/item/bodybag/rescue/folded = ..()
	if (folded && istype(folded))
		if (my_tank)
			my_tank.air_contents.merge(atmo)
			folded.airtank = my_tank
			my_tank.forceMove(folded)
	else
		airtank = my_tank

/obj/structure/closet/body_bag/rescue/Process()
	if(!airtank)
		return
	var/env_pressure = atmo.return_pressure()
	var/pressure_delta = max(airtank.distribute_pressure, 51) - env_pressure
	if(airtank.air_contents.temperature > 0 && pressure_delta > 0)
		var/transfer_moles = calculate_transfer_moles(airtank.air_contents, atmo, pressure_delta)
		pump_gas_passive(airtank, airtank.air_contents, atmo, transfer_moles)

/obj/structure/closet/body_bag/rescue/return_air() //Used to make stasis bags protect from vacuum.
	return atmo

/obj/structure/closet/body_bag/rescue/examine(mob/user)
	. = ..()
	if(airtank)
		. += SPAN_NOTICE("The pressure meter on [airtank] shows '[airtank.air_contents.return_pressure()] kPa'.")
		. += SPAN_NOTICE("The distribution valve on [airtank] is set to '[airtank.distribute_pressure] kPa'.")
	else
		. += SPAN_WARNING("The air tank is missing.")
	. += SPAN_NOTICE("The pressure meter on [src] shows '[atmo.return_pressure()] kPa'.")
	if(Adjacent(user)) //The bag's rather thick and opaque from a distance.
		. += SPAN_INFO("You peer into [src].")
		for(var/mob/living/L in contents)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(examinate), user, L), 0.1 SECONDS)
