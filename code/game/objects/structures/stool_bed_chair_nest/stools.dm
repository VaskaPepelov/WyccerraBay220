//Todo: add leather and cloth for arbitrary coloured stools.
var/global/list/stool_cache = list() //haha stool

/obj/item/stool
	name = "stool"
	desc = "Apply butt."
	icon = 'icons/obj/structures/furniture.dmi'
	icon_state = "stool_preview" //set for the map
	item_state = "stool"
	randpixel = 0
	force = 10
	throwforce = 10
	w_class = ITEM_SIZE_HUGE
	var/base_icon = "stool"
	var/material/material
	var/material/padding_material

/obj/item/stool/padded
	icon_state = "stool_padded_preview" //set for the map

/obj/item/stool/New(newloc, new_material = DEFAULT_FURNITURE_MATERIAL, new_padding_material)
	..(newloc)
	material = SSmaterials.get_material_by_name(new_material)
	if(new_padding_material)
		padding_material = SSmaterials.get_material_by_name(new_padding_material)
	if(!istype(material))
		qdel(src)
		return
	force = round(material.get_blunt_damage()*0.4)
	update_icon()

/obj/item/stool/padded/New(newloc, new_material = DEFAULT_FURNITURE_MATERIAL)
	..(newloc, new_material, MATERIAL_CARPET)

/obj/item/stool/bar
	name = "bar stool"
	icon_state = "bar_stool_preview" //set for the map
	item_state = "bar_stool"
	base_icon = "bar_stool"

/obj/item/stool/bar/padded
	icon_state = "bar_stool_padded_preview"

/obj/item/stool/bar/padded/New(newloc, new_material = DEFAULT_FURNITURE_MATERIAL)
	..(newloc, new_material, MATERIAL_CARPET)

/obj/item/stool/on_update_icon()
	// Prep icon.
	icon_state = ""
	// Base icon.
	var/list/noverlays = list()
	var/cache_key = "[base_icon]-[material.name]"
	if(isnull(stool_cache[cache_key]))
		var/image/I = image(icon, "[base_icon]_base")
		I.color = material.icon_colour
		stool_cache[cache_key] = I
	noverlays |= stool_cache[cache_key]
	// Padding overlay.
	if(padding_material)
		var/padding_cache_key = "[base_icon]-padding-[padding_material.name]"
		if(isnull(stool_cache[padding_cache_key]))
			var/image/I =  image(icon, "[base_icon]_padding")
			I.color = padding_material.icon_colour
			stool_cache[padding_cache_key] = I
		noverlays |= stool_cache[padding_cache_key]
	SetOverlays(noverlays)
	// Strings.
	if(padding_material)
		SetName("[padding_material.display_name] [initial(name)]") //this is not perfect but it will do for now.
		desc = "A padded stool. Apply butt. It's made of [material.use_name] and covered with [padding_material.use_name]."
	else
		SetName("[material.display_name] [initial(name)]")
		desc = "A stool. Apply butt with care. It's made of [material.use_name]."

/obj/item/stool/proc/add_padding(padding_type)
	padding_material = SSmaterials.get_material_by_name(padding_type)
	update_icon()

/obj/item/stool/proc/remove_padding()
	if(padding_material)
		padding_material.place_sheet(get_turf(src))
		padding_material = null
	update_icon()

/obj/item/stool/apply_hit_effect(mob/living/target, mob/living/user, hit_zone)
	if (prob(5))
		user.visible_message(SPAN_DANGER("[user] breaks [src] over [target]'s back!"))
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		user.do_attack_animation(target)
		dismantle() //This deletes self.

		var/blocked = target.get_blocked_ratio(hit_zone, DAMAGE_BRUTE, damage = 20)
		target.Weaken(10 * (1 - blocked))
		target.apply_damage(20, DAMAGE_BRUTE, hit_zone, src)
		return 1

	return ..()

/obj/item/stool/ex_act(severity)
	switch(severity)
		if(EX_ACT_DEVASTATING)
			qdel(src)
			return
		if(EX_ACT_HEAVY)
			if (prob(50))
				qdel(src)
				return
		if(EX_ACT_LIGHT)
			if (prob(5))
				qdel(src)
				return

/obj/item/stool/proc/dismantle()
	if(material)
		material.place_sheet(get_turf(src))
	if(padding_material)
		padding_material.place_sheet(get_turf(src))
	qdel(src)

/obj/item/stool/wrench_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_SUCCESS
	if(!tool.use_as_tool(src, user, volume = 50, do_flags = DO_REPAIR_CONSTRUCT))
		return
	dismantle()
	qdel(src)

/obj/item/stool/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/stack))
		if(padding_material)
			to_chat(user, "[src] is already padded.")
			return
		var/obj/item/stack/C = W
		if(C.get_amount() < 1) // How??
			qdel(C)
			return
		var/padding_type //This is awful but it needs to be like this until tiles are given a material var.
		if(istype(W,/obj/item/stack/tile/carpet))
			padding_type = MATERIAL_CARPET
		else if(istype(W,/obj/item/stack/material))
			var/obj/item/stack/material/M = W
			if(M.material && (M.material.flags & MATERIAL_PADDING))
				padding_type = "[M.material.name]"
		if(!padding_type)
			to_chat(user, "You cannot pad [src] with that.")
			return
		C.use(1)
		if(!istype(src.loc, /turf))
			user.drop_from_inventory(src)
			src.dropInto(loc)
		to_chat(user, "You add padding to [src].")
		add_padding(padding_type)
		return
	else if (is_sharp(W))
		if(!padding_material)
			to_chat(user, "[src] has no padding to remove.")
			return
		to_chat(user, "You remove the padding from [src].")
		playsound(src, 'sound/items/Wirecutter.ogg', 100, 1)
		remove_padding()
	else
		..()

//Generated subtypes for mapping porpoises

/obj/item/stool/wood/New(newloc)
	..(newloc,MATERIAL_WOOD)
