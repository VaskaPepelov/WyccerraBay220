/*
	Cyborg ClickOn()

	Cyborgs have no range restriction on attack_robot(), because it is basically an AI click.
	However, they do have a range restriction on item use, so they cannot do without the
	adjacency code.
*/

/mob/living/silicon/robot/ClickOn(atom/A, params)
	if(world.time <= next_click)
		return
	next_click = world.time + 1

	var/list/modifiers = params2list(params)
	if (LAZYACCESS(modifiers, CTRL_CLICK) && LAZYACCESS(modifiers, ALT_CLICK) && LAZYACCESS(modifiers, SHIFT_CLICK))
		if (A.BorgCtrlAltShiftClick(src) || A.AICtrlAltShiftClick(src) || CtrlAltShiftClickOn(A))
			return TRUE
	else if (LAZYACCESS(modifiers, CTRL_CLICK) && LAZYACCESS(modifiers, ALT_CLICK))
		if (A.BorgCtrlAltClick(src) || A.AICtrlAltClick(src) || CtrlAltClickOn(A))
			return TRUE
	else if (LAZYACCESS(modifiers, SHIFT_CLICK) && LAZYACCESS(modifiers, CTRL_CLICK))
		if (A.BorgCtrlShiftClick(src) || A.AICtrlShiftClick(src) || CtrlShiftClickOn(A))
			return TRUE
	else if (LAZYACCESS(modifiers, SHIFT_CLICK) && LAZYACCESS(modifiers, ALT_CLICK))
		if (A.BorgAltShiftClick(src) || A.AIAltShiftClick(src) || AltShiftClickOn(A))
			return TRUE
	else if (modifiers["middle"])
		if (A.BorgMiddleClick(src) || A.AIMiddleClick(src) || MiddleClickOn(A))
			return TRUE
	else if (LAZYACCESS(modifiers, SHIFT_CLICK))
		if (A.BorgShiftClick(src) || A.AIShiftClick(src) || ShiftClickOn(A))
			return TRUE
	else if (LAZYACCESS(modifiers, ALT_CLICK))
		if (A.BorgAltClick(src) || A.AIAltClick(src) || AltClickOn(A))
			return TRUE
	else if (LAZYACCESS(modifiers, CTRL_CLICK))
		if (A.BorgCtrlClick(src) || A.AICtrlClick(src) || CtrlClickOn(A))
			return TRUE

	if(incapacitated())
		return

	if(!canClick())
		return

	face_atom(A) // change direction to face what you clicked on

	if(silicon_camera.in_camera_mode)
		silicon_camera.camera_mode_off()
		if(is_component_functioning("camera"))
			silicon_camera.captureimage(A, usr)
		else
			to_chat(src, SPAN_CLASS("userdanger", "Your camera isn't functional."))
		return

	var/obj/item/W = get_active_hand()

	// Cyborgs have no range-checking unless there is item use
	if(!W)
		if(LAZYACCESS(modifiers, RIGHT_CLICK))
			var/secondary_result = A.attack_robot_secondary(src, modifiers)
			if(secondary_result == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN || secondary_result == SECONDARY_ATTACK_CONTINUE_CHAIN)
				return
			else if (secondary_result != SECONDARY_ATTACK_CALL_NORMAL)
				CRASH("attack_robot_secondary did not return a SECONDARY_ATTACK_* define.")
		A.add_hiddenprint(src)
		A.attack_robot(src)
		return

	// buckled cannot prevent machine interlinking but stops arm movement
	if( buckled )
		return

	if(W == A)

		W.attack_self(src)
		return

	// cyborgs are prohibited from using storage items so we can I think safely remove (A.loc in contents)
	if(A == loc || (A in loc) || (A in contents))
		// No adjacency checks

		var/resolved = W.resolve_attackby(A, src, params)
		if(!resolved && A && W)
			W.afterattack(A, src, 1, params) // 1 indicates adjacency
		return

	if(!isturf(loc))
		return

	var/sdepth = A.storage_depth_turf()
	if(isturf(A) || isturf(A.loc) || (sdepth != -1 && sdepth <= 1))
		if(A.Adjacent(src)) // see adjacent.dm

			var/resolved = W.resolve_attackby(A, src, params)
			if(!resolved && A && W)
				W.afterattack(A, src, 1, params) // 1 indicates adjacency
			return
		else
			W.afterattack(A, src, 0, params)
			return
	return

//Middle click cycles through selected modules.
/mob/living/silicon/robot/MiddleClickOn(atom/A)
	cycle_modules()
	return TRUE

/mob/living/silicon/robot/CtrlAltClickOn(atom/A)
	return pointed(A)

/atom/proc/BorgMiddleClick(mob/living/silicon/robot/user)
	return FALSE

/atom/proc/BorgCtrlAltClick(mob/living/silicon/robot/user)
	return FALSE

/atom/proc/BorgShiftClick(mob/living/silicon/robot/user)
	return FALSE

/atom/proc/BorgCtrlClick(mob/living/silicon/robot/user)
	return FALSE

/atom/proc/BorgAltClick(mob/living/silicon/robot/user)
	return FALSE

/atom/proc/BorgCtrlShiftClick(mob/living/silicon/robot/user)
	return FALSE

/atom/proc/BorgAltShiftClick(mob/living/silicon/robot/user)
	return FALSE

/atom/proc/BorgCtrlAltShiftClick(mob/living/silicon/robot/user)
	return FALSE

/*
	As with AI, these are not used in click code,
	because the code for robots is specific, not generic.

	If you would like to add advanced features to robot
	clicks, you can do so here, but you will have to
	change attack_robot() above to the proper function
*/
/mob/living/silicon/robot/UnarmedAttack(atom/target, proximity_flag, list/modifiers)
	target.attack_robot(src)

/mob/living/silicon/robot/ranged_attack(atom/target, list/modifiers)
	target.attack_robot(src)
	return TRUE

/**
 * Called when a silicon robot mob clicks on an atom.
 *
 * **Parameters**:
 * - `user` - The mob clicking on the atom.
 */
/atom/proc/attack_robot(mob/user)
	if (SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_ROBOT, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return
	attack_ai(user)

/atom/proc/attack_robot_secondary(mob/user, list/modifiers)
	if (SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_ROBOT_SECONDARY, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return
	return attack_ai_secondary(user, modifiers)

/obj/machinery/power/apc/attack_robot_secondary(mob/user, list/modifiers)
	return attack_ai_secondary(user, modifiers)

/obj/machinery/alarm/attack_robot_secondary(mob/user, list/modifiers)
	return attack_ai_secondary(user, modifiers)
