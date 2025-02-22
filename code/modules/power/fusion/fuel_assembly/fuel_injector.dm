/obj/machinery/fusion_fuel_injector
	name = "fuel injector"
	icon = 'icons/obj/machines/power/fusion_fuel_injectors.dmi'
	icon_state = "injector"
	density = TRUE
	anchored = FALSE
	req_access = list(access_engine)
	idle_power_usage = 10
	active_power_usage = 500
	construct_state = /singleton/machine_construction/default/panel_closed
	uncreated_component_parts = null
	stat_immune = 0
	base_type = /obj/machinery/fusion_fuel_injector

	var/fuel_usage = 0.001
	var/initial_id_tag
	var/injecting = 0
	var/obj/item/fuel_assembly/cur_assembly
	var/injection_rate = 1

/obj/machinery/fusion_fuel_injector/Initialize()
	set_extension(src, /datum/extension/local_network_member)
	if(initial_id_tag)
		var/datum/extension/local_network_member/fusion = get_extension(src, /datum/extension/local_network_member)
		fusion.set_tag(null, initial_id_tag)
	. = ..()

/obj/machinery/fusion_fuel_injector/on_update_icon()
	ClearOverlays()
	if(panel_open)
		AddOverlays("[icon_state]_panel")
	if(injecting && cur_assembly)
		AddOverlays(emissive_appearance(icon, "[icon_state]_lights"))
		AddOverlays("[icon_state]_lights")

/obj/machinery/fusion_fuel_injector/Destroy()
	if(cur_assembly)
		cur_assembly.dropInto(loc)
		cur_assembly = null
	. = ..()

/obj/machinery/fusion_fuel_injector/mapped
	anchored = TRUE

/obj/machinery/fusion_fuel_injector/Process()
	if(injecting)
		if(inoperable())
			StopInjecting()
		else
			Inject()

/obj/machinery/fusion_fuel_injector/multitool_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_SUCCESS
	var/datum/extension/local_network_member/fusion = get_extension(src, /datum/extension/local_network_member)
	fusion.get_new_tag(user)

/obj/machinery/fusion_fuel_injector/welder_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_SUCCESS
	if(injecting)
		balloon_alert(user, "нужно отключить!")
		return
	if(!tool.use_as_tool(src, user, amount = 1, volume = 75, do_flags = DO_REPAIR_CONSTRUCT))
		return
	anchored = !anchored
	balloon_alert_to_viewers("[anchored ? "приварено к полу!" : "отварено от пола!"]")

/obj/machinery/fusion_fuel_injector/use_tool(obj/item/W, mob/living/user, list/click_params)
	if(istype(W, /obj/item/fuel_assembly))
		if(injecting)
			to_chat(user, SPAN_WARNING("Shut [src] off before playing with the fuel rod!"))
			return TRUE
		if(!user.unEquip(W, src))
			return TRUE
		if(cur_assembly)
			visible_message(SPAN_NOTICE("[user] swaps [src]'s [cur_assembly] for \a [W]."))
		else
			visible_message(SPAN_NOTICE("[user] inserts \a [W] into [src]."))
		if(cur_assembly)
			cur_assembly.dropInto(loc)
			user.put_in_hands(cur_assembly)
		cur_assembly = W
		return TRUE

	return ..()

/obj/machinery/fusion_fuel_injector/physical_attack_hand(mob/user)
	if(injecting)
		to_chat(user, SPAN_WARNING("Shut [src] off before playing with the fuel rod!"))
		return TRUE

	if(cur_assembly)
		cur_assembly.dropInto(loc)
		user.put_in_hands(cur_assembly)
		visible_message(SPAN_NOTICE("[user] removes [cur_assembly] from [src]."))
		cur_assembly = null
		return TRUE
	else
		to_chat(user, SPAN_WARNING("There is no fuel rod in [src]."))
		return TRUE

/obj/machinery/fusion_fuel_injector/proc/BeginInjecting()
	if(!injecting && cur_assembly)
		injecting = 1
		update_icon()
		update_use_power(POWER_USE_IDLE)

/obj/machinery/fusion_fuel_injector/proc/StopInjecting()
	if(injecting)
		injecting = 0
		update_icon()
		update_use_power(POWER_USE_OFF)

/obj/machinery/fusion_fuel_injector/proc/Inject()
	if(!injecting)
		return
	if(cur_assembly)
		var/amount_left = 0
		for(var/reagent in cur_assembly.rod_quantities)
			if(cur_assembly.rod_quantities[reagent] > 0)
				var/amount = cur_assembly.rod_quantities[reagent] * fuel_usage * injection_rate
				if(amount < 1)
					amount = 1
				var/obj/accelerated_particle/A = new/obj/accelerated_particle(get_turf(src), dir)
				A.particle_type = reagent
				A.additional_particles = amount
				A.move(1)
				if(cur_assembly)
					cur_assembly.rod_quantities[reagent] -= amount
					amount_left += cur_assembly.rod_quantities[reagent]
		if(cur_assembly)
			cur_assembly.percent_depleted = amount_left / cur_assembly.initial_amount
		AddOverlays(emissive_appearance(icon, "[icon_state]_lights_emitting"))
		AddOverlays("[icon_state]_lights_emitting")
	else
		StopInjecting()
		update_icon()

/obj/machinery/fusion_fuel_injector/verb/rotate_clock()
	set category = "Object"
	set name = "Rotate Generator (Clockwise)"
	set src in view(1)

	if (usr.incapacitated() || usr.restrained()  || anchored)
		return

	src.dir = turn(src.dir, -90)

/obj/machinery/fusion_fuel_injector/verb/rotate_anticlock()
	set category = "Object"
	set name = "Rotate Generator (Counter-clockwise)"
	set src in view(1)

	if (usr.incapacitated() || usr.restrained()  || anchored)
		return

	src.dir = turn(src.dir, 90)
