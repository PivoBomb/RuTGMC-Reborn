/turf/open/space/transit
	name = "\proper hyperspace"
	icon_state = "black"
	dir = SOUTH
	baseturfs = /turf/open/space/transit
	explosion_block = INFINITY
	///The number of icon state available
	var/available_icon_state_amounts = 15

/turf/open/space/transit/atmos
	name = "\proper high atmosphere"
	baseturfs = /turf/open/space/transit/atmos
	available_icon_state_amounts = 8
	plane = FLOOR_PLANE

//Overwrite because we dont want people building rods in space.
/turf/open/space/transit/attackby(obj/item/I, mob/user, params)
	return

/turf/open/space/transit/south
	dir = SOUTH

/turf/open/space/transit/north
	dir = NORTH

/turf/open/space/transit/west
	dir = WEST

/turf/open/space/transit/east
	dir = EAST

/turf/open/space/transit/Entered(atom/movable/crosser, atom/old_loc, list/atom/old_locs)
	. = ..()

	if(isobserver(crosser) || crosser.anchored || isxenohivemind(crosser))
		return

	if(!isobj(crosser) && !isliving(crosser))
		return

	if(!isspaceturf(old_loc))
		var/turf/projected = get_ranged_target_turf(crosser.loc, dir, 10)
		INVOKE_ASYNC(crosser, TYPE_PROC_REF(/atom/movable, throw_at), projected, 50, 2, null, TRUE, targetted_throw = TRUE)
		addtimer(CALLBACK(src, PROC_REF(handle_crosser), crosser), 0.5 SECONDS)

/turf/open/space/transit/proc/handle_crosser(atom/movable/crosser)
	if(QDELETED(crosser))
		return

	// you just jumped out of a dropship, have fun living on the way down!
	var/list/ground_z_levels = SSmapping.levels_by_trait(ZTRAIT_GROUND)
	if(!length(ground_z_levels))
		return qdel(crosser)

	//find a random spot to drop them
	var/list/area/potential_areas = shuffle(SSmapping.areas_in_z["[ground_z_levels[1]]"])
	for(var/area/potential_area in potential_areas)
		if(potential_area.flags_area & NO_DROPPOD || !potential_area.outside) // no dropping inside the caves and etc.
			continue
		if(isspacearea(potential_area)) // make sure its not space, just in case
			continue

		var/turf/open/possible_turf
		var/list/area_turfs = get_area_turfs(potential_area)
		for(var/i in 1 to 10)
			possible_turf = pick_n_take(area_turfs)
			// we're looking for an open, non-dense, and non-space turf.
			if(!istype(possible_turf) || is_blocked_turf(possible_turf) || isspaceturf(possible_turf))
				continue

		if(!istype(possible_turf) || is_blocked_turf(possible_turf) || isspaceturf(possible_turf))
			continue // couldnt find one in 10 loops, check another area

		// we found a good turf, lets drop em
		crosser.handle_airdrop(possible_turf)
		return
	return qdel(crosser)

/atom/movable/proc/handle_airdrop(turf/target_turf)
	pixel_z = 360
	forceMove(target_turf)
	if(isliving(src))
		var/mob/living/mob = src
		mob.Knockdown(0.6 SECONDS) // so the falling mobs are horizontal for the animation
	animation_spin(0.5 SECONDS, 1, dir == WEST ? FALSE : TRUE)
	animate(src, 0.6 SECONDS, pixel_z = 0, flags = ANIMATION_PARALLEL)
	target_turf.ceiling_debris(2 SECONDS)
	sleep(0.6 SECONDS) // so we do stuff like dealing damage and deconstructing only after the animation end

/obj/handle_airdrop(turf/target)
	. = ..()
	if(!CHECK_BITFIELD(resistance_flags, INDESTRUCTIBLE) && prob(30)) // throwing objects from the air is not always a good idea
		visible_message(span_danger("[src] falls out of the sky and mangles into the uselessness by the impact!"))
		playsound(src, 'sound/effects/metal_crash.ogg', 35, 1)
		deconstruct(FALSE)

/obj/structure/closet/handle_airdrop(turf/target_turf) // good idea but no
	if(!opened)
		break_open()
		for(var/atom/movable/content in src)
			content.handle_airdrop(target_turf)
	..()

/obj/item/handle_airdrop(turf/target_turf)
	. = ..()
	if(QDELETED(src))
		return
	if(!CHECK_BITFIELD(resistance_flags, INDESTRUCTIBLE) && w_class < WEIGHT_CLASS_NORMAL) //tiny and small items will be lost, good riddance
		visible_message(span_danger("[src] falls out of the sky and mangles into the uselessness by the impact!"))
		playsound(src, 'sound/effects/metal_crash.ogg', 35, 1)
		deconstruct(FALSE)
		return
	if(locate(/mob/living) in target_turf)
		var/mob/living/victim = locate(/mob/living) in target_turf
		throw_impact(victim, 20)
		return
	explosion_throw(200) // give it a bit of a kick
	playsound(loc, 'sound/weapons/smash.ogg', 35, 1)

/mob/living/handle_airdrop(turf/target_turf)
	. = ..()
	remove_status_effect(/datum/status_effect/spacefreeze)
	playsound(target_turf, pick('sound/effects/bang.ogg', 'sound/effects/meteorimpact.ogg'), 75, TRUE)
	playsound(target_turf, "bone_break", 75, TRUE)

	Knockdown(10 SECONDS)
	Stun(3 SECONDS)
	take_overall_damage(300, BRUTE, BOMB, updating_health = TRUE)
	take_overall_damage(300, BRUTE, MELEE, updating_health = TRUE)
	spawn_gibs()
	visible_message(span_warning("[src] falls out of the sky."), span_highdanger("As you fall out of the sky, you plummet towards the ground."))

/mob/living/carbon/human/handle_airdrop(turf/target_turf)
	. = ..()
	if(istype(wear_suit, /obj/item/clothing/suit/storage/marine/boomvest))
		var/obj/item/clothing/suit/storage/marine/boomvest/vest = wear_suit
		vest.boom(usr)

/turf/open/space/transit/Initialize(mapload)
	. = ..()
	update_icon()

/turf/open/space/transit/update_icon()
	. = ..()
	transform = turn(matrix(), get_transit_angle(src))

/turf/open/space/transit/update_icon_state()
	icon_state = "speedspace_ns_[get_transit_state(src, available_icon_state_amounts)]"

/turf/open/space/transit/atmos/update_icon_state()
	icon_state = "Cloud_[get_transit_state(src, available_icon_state_amounts)]"

/proc/get_transit_state(turf/T, available_icon_state_amounts)
	var/p = round(available_icon_state_amounts / 2)
	. = 1
	switch(T.dir)
		if(NORTH)
			. = ((-p*T.x+T.y) % available_icon_state_amounts) + 1
			if(. < 1)
				. += available_icon_state_amounts
		if(EAST)
			. = ((T.x+p*T.y) % available_icon_state_amounts) + 1
		if(WEST)
			. = ((T.x-p*T.y) % available_icon_state_amounts) + 1
			if(. < 1)
				. += available_icon_state_amounts
		else
			. = ((p*T.x+T.y) % available_icon_state_amounts) + 1

/proc/get_transit_angle(turf/T)
	. = 0
	switch(T.dir)
		if(NORTH)
			. = 180
		if(EAST)
			. = 90
		if(WEST)
			. = -90
