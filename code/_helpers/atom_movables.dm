/proc/get_turf_pixel(atom/movable/AM)
	RETURN_TYPE(/turf)
	if(!istype(AM))
		return

	//Find AM's matrix so we can use it's X/Y pixel shifts
	var/matrix/M = matrix(AM.transform)

	var/pixel_x_offset = AM.pixel_x + M.get_x_shift()
	var/pixel_y_offset = AM.pixel_y + M.get_y_shift()

	//Irregular objects
	if(AM.bound_height != world.icon_size || AM.bound_width != world.icon_size)
		var/icon/AMicon = icon(AM.icon, AM.icon_state)
		pixel_x_offset += ((AMicon.Width()/world.icon_size)-1)*(world.icon_size*0.5)
		pixel_y_offset += ((AMicon.Height()/world.icon_size)-1)*(world.icon_size*0.5)
		qdel(AMicon)

	//DY and DX
	var/rough_x = round(round(pixel_x_offset,world.icon_size)/world.icon_size)
	var/rough_y = round(round(pixel_y_offset,world.icon_size)/world.icon_size)

	//Find coordinates
	var/turf/T = get_turf(AM) //use AM's turfs, as it's coords are the same as AM's AND AM's coords are lost if it is inside another atom
	var/final_x = T.x + rough_x
	var/final_y = T.y + rough_y

	if(final_x || final_y)
		return locate(final_x, final_y, T.z)

// Walks up the loc tree until it finds a holder of the given holder_type
/proc/get_holder_of_type(atom/A, holder_type)
	RETURN_TYPE(/atom)
	if(!istype(A)) return
	for(A, A && !istype(A, holder_type), A=A.loc);
	return A

/atom/movable/proc/throw_at_random(include_own_turf = FALSE, maxrange = 1, speed)
	if(maxrange < 0)
		stack_trace("Negative `maxrange` passed")
		maxrange = 1

	var/turf/center = get_turf(src)
	if(!center)
		return

	var/list/turfs = include_own_turf ? RANGE_TURFS(center, maxrange) : ORANGE_TURFS(center, maxrange)
	if(length(turfs))
		return

	throw_at(pick(turfs), maxrange, speed)

/atom/movable/proc/do_simple_ranged_interaction(mob/user)
	return FALSE

/atom/movable/hitby(atom/movable/AM)
	..()
	if(density && prob(50))
		do_simple_ranged_interaction()

/proc/get_atom_closest_to_atom(atom/a, list/possibilities)
	RETURN_TYPE(/atom)
	if(!possibilities || !length(possibilities))
		return null
	var/closest_distance = get_dist(a, possibilities[1])
	. = possibilities[1]
	for(var/p in (possibilities - possibilities[1]))
		var/dist = get_dist(a, p)
		if(dist < closest_distance)
			closest_distance = dist
			. = p
