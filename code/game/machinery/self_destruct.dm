/obj/machinery/self_destruct
	name = "nuclear cylinder inserter"
	desc = "A hollow space used to insert nuclear cylinders for arming the self destruct."
	icon = 'icons/obj/machines/self_destruct.dmi'
	icon_state = "empty"
	density = FALSE
	anchored = TRUE
	var/obj/item/nuclear_cylinder/cylinder
	var/armed = 0
	var/damaged = 0

/obj/machinery/self_destruct/welder_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_SUCCESS
	if(damaged)
		if(!tool.tool_start_check(user, 10))
			return
		USE_FEEDBACK_REPAIR_START(user)
		if(!tool.use_as_tool(src, user, 10 SECONDS, 10, 50, SKILL_CONSTRUCTION, do_flags = DO_REPAIR_CONSTRUCT))
			return
		USE_FEEDBACK_REPAIR_FINISH(user)
		damaged = 0

/obj/machinery/self_destruct/use_tool(obj/item/W, mob/living/user, list/click_params)
	if(istype(W, /obj/item/nuclear_cylinder))
		if(damaged)
			to_chat(user, SPAN_WARNING("[src] is damaged, you cannot place the cylinder."))
			return TRUE
		if(cylinder)
			to_chat(user, "There is already a cylinder here.")
			return TRUE
		user.visible_message("[user] begins to carefully place [W] onto the Inserter.", "You begin to carefully place [W] onto the Inserter.")
		if(do_after(user, 8 SECONDS, src, DO_PUBLIC_UNIQUE) && user.unEquip(W, src))
			cylinder = W
			set_density(TRUE)
			user.visible_message("[user] places [W] onto the Inserter.", "You place [W] onto the Inserter.")
			update_icon()
		return TRUE

	return ..()

/obj/machinery/self_destruct/physical_attack_hand(mob/user)
	if(cylinder)
		. = TRUE
		if(armed)
			if(damaged)
				to_chat(user, SPAN_WARNING("The inserter has been damaged, unable to disarm."))
				return
			var/obj/machinery/nuclearbomb/nuke = locate(/obj/machinery/nuclearbomb/station) in get_area(src)
			if(!nuke)
				to_chat(user, SPAN_WARNING("Unable to interface with the self destruct terminal, unable to disarm."))
				return
			if(nuke.timing)
				to_chat(user, SPAN_WARNING("The self destruct sequence is in progress, unable to disarm."))
				return
			user.visible_message("[user] begins extracting [cylinder].", "You begin extracting [cylinder].")
			if(do_after(user, 4 SECONDS, src, DO_PUBLIC_UNIQUE))
				user.visible_message("[user] extracts [cylinder].", "You extract [cylinder].")
				armed = 0
				set_density(TRUE)
				flick("unloading", src)
		else if(!damaged)
			user.visible_message("[user] begins to arm [cylinder].", "You begin to arm [cylinder].")
			if(do_after(user, 4 SECONDS, src, DO_PUBLIC_UNIQUE))
				armed = 1
				set_density(FALSE)
				user.visible_message("[user] arms [cylinder].", "You arm [cylinder].")
				flick("loading", src)
				playsound(src.loc,'sound/effects/caution.ogg',50,1,5)
		update_icon()
		src.add_fingerprint(user)

/obj/machinery/self_destruct/MouseDrop(atom/over)
	if(!CanMouseDrop(over, usr))
		return
	if(over == usr && cylinder)
		if(armed)
			to_chat(usr, "Disarm the cylinder first.")
		else
			usr.visible_message("[usr] beings to carefully pick up [cylinder].", "You begin to carefully pick up [cylinder].")
			if(do_after(usr, 7 SECONDS, src, DO_PUBLIC_UNIQUE))
				usr.put_in_hands(cylinder)
				usr.visible_message("[usr] picks up [cylinder].", "You pick up [cylinder].")
				set_density(FALSE)
				cylinder = null
		update_icon()
		src.add_fingerprint(usr)
	..()

/obj/machinery/self_destruct/ex_act(severity)
	switch(severity)
		if(EX_ACT_DEVASTATING)
			set_damaged()
		if(EX_ACT_HEAVY)
			if(prob(50))
				set_damaged()
		if(EX_ACT_LIGHT)
			if(prob(25))
				set_damaged()

/obj/machinery/self_destruct/proc/set_damaged()
		src.visible_message(SPAN_WARNING("[src] dents and chars."))
		damaged = 1

/obj/machinery/self_destruct/examine(mob/user)
	. = ..()
	if(damaged)
		. += SPAN_WARNING("[src] is damaged, it needs repairs.")
		return
	if(armed)
		. += SPAN_NOTICE("[src] is armed and ready.")
		return
	if(cylinder)
		. += SPAN_NOTICE("[src] is loaded and ready to be armed.")

/obj/machinery/self_destruct/on_update_icon()
	if(armed)
		icon_state = "armed"
	else if(cylinder)
		icon_state = "loaded"
	else
		icon_state = "empty"
