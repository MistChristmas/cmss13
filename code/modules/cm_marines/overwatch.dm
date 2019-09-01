/obj/machinery/computer/overwatch
	name = "Overwatch Console"
	desc = "State of the art machinery for giving orders to a squad."
	icon_state = "dummy"
	req_access = list(ACCESS_MARINE_BRIDGE)

	var/mob/living/carbon/human/current_mapviewer = null
	var/datum/squad/current_squad = null
	var/state = 0
	var/obj/machinery/camera/cam = null
	var/list/network = list("Overwatch")
	var/x_supply = 0
	var/y_supply = 0
	var/x_bomb = 0
	var/y_bomb = 0
	var/living_marines_sorting = FALSE
	var/busy = 0 //The overwatch computer is busy launching an OB/SB, lock controls
	var/dead_hidden = FALSE //whether or not we show the dead marines in the squad.
	var/z_hidden = 0 //which z level is ignored when showing marines.
//	var/console_locked = 0


/obj/machinery/computer/overwatch/attackby(var/obj/I as obj, var/mob/user as mob)  //Can't break or disassemble.
	return

/obj/machinery/computer/overwatch/bullet_act(var/obj/item/projectile/Proj) //Can't shoot it
	return 0

/obj/machinery/computer/overwatch/attack_ai(var/mob/user as mob)
	if(!ismaintdrone(user))
		return src.attack_hand(user)

/obj/machinery/computer/overwatch/attack_hand(mob/user)
	if(..())  //Checks for power outages
		return

	if(!ishighersilicon(usr) && user.mind.cm_skills && user.mind.cm_skills.leadership < SKILL_LEAD_EXPERT && !Check_WO())
		to_chat(user, SPAN_WARNING("You don't have the training to use [src]."))
		return


	user.set_interaction(src)
	var/dat = "<head><title>Overwatch Console</title></head><body>"

	if(!operator)
		dat += "<BR><B>Operator:</b> <A href='?src=\ref[src];operation=change_operator'>----------</A><BR>"
	else
		dat += "<BR><B>Operator:</b> <A href='?src=\ref[src];operation=change_operator'>[operator.name]</A><BR>"
		dat += "   <A href='?src=\ref[src];operation=logout'>{Stop Overwatch}</A><BR>"
		dat += "----------------------<br>"

		switch(src.state)
			if(0)
				if(!current_squad) //No squad has been set yet. Pick one.
					dat += "Current Squad: <A href='?src=\ref[src];operation=pick_squad'>----------</A><BR>"
				else
					dat += "Current Squad: [current_squad.name] Squad</A>   "
					dat += "<A href='?src=\ref[src];operation=message'>\[Message Squad\]</a><br><br>"
					dat += "<A href='?src=\ref[src];operation=mapview'>\[Toggle Tactical Map\]</a><br><br>"
					dat += "----------------------<BR><BR>"
					if(current_squad.squad_leader)
						dat += "<B>Squad Leader:</B> <A href='?src=\ref[src];operation=use_cam;cam_target=\ref[current_squad.squad_leader]'>[current_squad.squad_leader.name]</a> "
						dat += "<A href='?src=\ref[src];operation=sl_message'>\[MSG\]</a> "
						dat += "<A href='?src=\ref[src];operation=change_lead'>\[CHANGE SQUAD LEADER\]</a><BR><BR>"
					else
						dat += "<B>Squad Leader:</B> <font color=red>NONE</font> <A href='?src=\ref[src];operation=change_lead'>\[ASSIGN SQUAD LEADER\]</a><BR><BR>"

					dat += "<B>Primary Objective:</B> "
					if(current_squad.primary_objective)
						dat += "<A href='?src=\ref[src];operation=check_primary'>\[Check\]</A> <A href='?src=\ref[src];operation=set_primary'>\[Set\]</A><BR>"
					else
						dat += "<B><font color=red>NONE!</font></B> <A href='?src=\ref[src];operation=set_primary'>\[Set\]</A><BR>"
					dat += "<B>Secondary Objective:</B> "
					if(current_squad.secondary_objective)
						dat += "<A href='?src=\ref[src];operation=check_secondary'>\[Check\]</A> <A href='?src=\ref[src];operation=set_secondary'>\[Set\]</A><BR>"
					else
						dat += "<B><font color=red>NONE!</font></B> <A href='?src=\ref[src];operation=set_secondary'>\[Set\]</A><BR>"
					dat += "<BR>"
					dat += "<A href='?src=\ref[src];operation=insubordination'>Report a marine for insubordination</a><BR>"
					dat += "<A href='?src=\ref[src];operation=squad_transfer'>Transfer a marine to another squad</a><BR><BR>"

					dat += "<A href='?src=\ref[src];operation=supplies'>Supply Drop Control</a><BR>"
					dat += "<A href='?src=\ref[src];operation=bombs'>Orbital Bombardment Control</a><BR>"
					dat += "<A href='?src=\ref[src];operation=monitor'>Squad Monitor</a><BR>"
					dat += "<BR><BR>----------------------<BR></Body>"
					dat += "<BR><BR><A href='?src=\ref[src];operation=refresh'>{Refresh}</a></Body>"

			if(1)//Info screen.
				if(!current_squad)
					dat += "No Squad selected!<BR>"
				else

					var/leader_text = ""
					var/leader_count = 0
					var/spec_text = ""
					var/spec_count = 0
					var/medic_text = ""
					var/medic_count = 0
					var/engi_text = ""
					var/engi_count = 0
					var/smart_text = ""
					var/smart_count = 0
					var/marine_text = ""
					var/marine_count = 0
					var/misc_text = ""
					var/living_count = 0

					var/conscious_text = ""
					var/unconscious_text = ""
					var/dead_text = ""

					var/SL_z //z level of the Squad Leader
					if(current_squad.squad_leader)
						var/turf/SL_turf = get_turf(current_squad.squad_leader)
						SL_z = SL_turf.z


					for(var/X in current_squad.marines_list)
						if(!X) continue //just to be safe
						var/mob_name = "unknown"
						var/mob_state = ""
						var/role = "unknown"
						var/act_sl = ""
						var/fteam = ""
						var/dist = "<b>???</b>"
						var/area_name = "<b>???</b>"
						var/mob/living/carbon/human/H
						if(ishuman(X))
							H = X
							mob_name = H.real_name
							var/area/A = get_area(H)
							var/turf/M_turf = get_turf(H)
							if(A)
								area_name = sanitize(A.name)

							if(z_hidden && M_turf && (z_hidden == M_turf.z))
								continue

							if(H.mind && H.mind.assigned_role)
								role = H.mind.assigned_role
							else if(istype(H.wear_id, /obj/item/card/id)) //decapitated marine is mindless,
								var/obj/item/card/id/ID = H.wear_id		//we use their ID to get their role.
								if(ID.rank) role = ID.rank

							if(current_squad.squad_leader)
								if(H == current_squad.squad_leader)
									dist = "<b>N/A</b>"
									if(H.mind && H.mind.assigned_role != "Squad Leader")
										act_sl = " (acting SL)"
								else if(M_turf && (M_turf.z == SL_z))
									dist = "[get_dist(H, current_squad.squad_leader)] ([dir2text_short(get_dir(current_squad.squad_leader, H))])"

							switch(H.stat)
								if(CONSCIOUS)
									mob_state = "Conscious"
									living_count++
									conscious_text += "<tr><td><A href='?src=\ref[src];operation=use_cam;cam_target=\ref[H]'>[mob_name]</a></td><td>[role][act_sl]</td><td>[mob_state]</td><td>[area_name]</td><td>[dist]</td></tr>"

								if(UNCONSCIOUS)
									mob_state = "<b>Unconscious</b>"
									living_count++
									unconscious_text += "<tr><td><A href='?src=\ref[src];operation=use_cam;cam_target=\ref[H]'>[mob_name]</a></td><td>[role][act_sl]</td><td>[mob_state]</td><td>[area_name]</td><td>[dist]</td></tr>"

								if(DEAD)
									if(dead_hidden)
										continue
									mob_state = "<font color='red'>DEAD</font>"
									dead_text += "<tr><td><A href='?src=\ref[src];operation=use_cam;cam_target=\ref[H]'>[mob_name]</a></td><td>[role][act_sl]</td><td>[mob_state]</td><td>[area_name]</td><td>[dist]</td></tr>"


							if(!H.key || !H.client)
								if(H.stat != DEAD)
									mob_state += " (SSD)"


							if(istype(H.wear_id, /obj/item/card/id))
								var/obj/item/card/id/ID = H.wear_id
								if(ID.assigned_fireteam)
									fteam = " \[[ID.assigned_fireteam]\]"

						else //listed marine was deleted or gibbed, all we have is their name
							if(dead_hidden)
								continue
							if(z_hidden) //gibbed marines are neither on the colony nor on the almayer
								continue
							for(var/datum/data/record/t in data_core.general)
								if(t.fields["name"] == X)
									role = t.fields["real_rank"]
									break
							mob_state = "<font color='red'>DEAD</font>"
							mob_name = X
							dead_text += "<tr><td><A href='?src=\ref[src];operation=use_cam;cam_target=\ref[H]'>[mob_name]</a></td><td>[role][act_sl]</td><td>[mob_state]</td><td>[area_name]</td><td>[dist]</td></tr>"


						var/marine_infos = "<tr><td><A href='?src=\ref[src];operation=use_cam;cam_target=\ref[H]'>[mob_name]</a></td><td>[role][act_sl][fteam]</td><td>[mob_state]</td><td>[area_name]</td><td>[dist]</td></tr>"
						switch(role)
							if("Squad Leader")
								leader_text += marine_infos
								leader_count++
							if("Squad Specialist")
								spec_text += marine_infos
								spec_count++
							if("Squad Medic")
								medic_text += marine_infos
								medic_count++
							if("Squad Engineer")
								engi_text += marine_infos
								engi_count++
							if("Squad Smartgunner")
								smart_text += marine_infos
								smart_count++
							if("Squad Marine")
								marine_text += marine_infos
								marine_count++
							else
								misc_text += marine_infos

					dat += "<b>[leader_count ? "Squad Leader Deployed":"<font color='red'>No Squad Leader Deployed!</font>"]</b><BR>"
					dat += "<b>[spec_count ? "Squad Specialist Deployed":"<font color='red'>No Specialist Deployed!</font>"]</b><BR>"
					dat += "<b>[smart_count ? "Squad Smartgunner Deployed":"<font color='red'>No Smartgunner Deployed!</font>"]</b><BR>"
					dat += "<b>Squad Medics: [medic_count] Deployed | Squad Engineers: [engi_count] Deployed</b><BR>"
					dat += "<b>Squad Marines: [marine_count] Deployed</b><BR>"
					dat += "<b>Total: [current_squad.marines_list.len] Deployed</b><BR>"
					dat += "<b>Marines alive: [living_count]</b><BR><BR>"
					dat += "<table border='1' style='width:100%' align='center'><tr>"
					dat += "<th>Name</th><th>Role</th><th>State</th><th>Location</th><th>SL Distance</th></tr>"
					if(!living_marines_sorting)
						dat += leader_text + spec_text + medic_text + engi_text + smart_text + marine_text + misc_text
					else
						dat += conscious_text + unconscious_text + dead_text
					dat += "</table>"
				dat += "<BR><BR>----------------------<br>"
				dat += "<A href='?src=\ref[src];operation=refresh'>{Refresh}</a><br>"
				dat += "<A href='?src=\ref[src];operation=change_sort'>{Change Sorting Method}</a><br>"
				dat += "<A href='?src=\ref[src];operation=hide_dead'>{[dead_hidden ? "Show Dead Marines" : "Hide Dead Marines" ]}</a><br>"
				dat += "<A href='?src=\ref[src];operation=choose_z'>{Change Locations Ignored}</a><br>"
				dat += "<br><A href='?src=\ref[src];operation=back'>{Back}</a></body>"
			if(2)
				dat += "<BR><B>Supply Drop Control</B><BR><BR>"
				if(!current_squad)
					dat += "No squad selected!"
				else
					dat += "<B>Current Supply Drop Status:</B> "
					var/cooldown_left = (current_squad.supply_cooldown + 5000) - world.time
					if(cooldown_left > 0)
						dat += "Launch tubes resetting ([round(cooldown_left/10)] seconds)<br>"
					else
						dat += "<font color='green'>Ready!</font><br>"
					dat += "<B>Launch Pad Status:</b> "
					var/obj/structure/closet/crate/C = locate() in current_squad.drop_pad.loc
					if(C)
						dat += "<font color='green'>Supply crate loaded</font><BR>"
					else
						dat += "Empty<BR>"
					dat += "<B>Longitude:</B> [x_supply] <A href='?src=\ref[src];operation=supply_x'>\[Change\]</a><BR>"
					dat += "<B>Latitude:</B> [y_supply] <A href='?src=\ref[src];operation=supply_y'>\[Change\]</a><BR><BR>"
					dat += "<A href='?src=\ref[src];operation=dropsupply'>\[LAUNCH!\]</a>"
				dat += "<BR><BR>----------------------<br>"
				dat += "<A href='?src=\ref[src];operation=refresh'>{Refresh}</a><br>"
				dat += "<A href='?src=\ref[src];operation=back'>{Back}</a></body>"
			if(3)
				dat += "<BR><B>Orbital Bombardment Control</B><BR><BR>"
				if(!current_squad)
					dat += "No squad selected!"
				else
					dat += "<B>Current Cannon Status:</B> "
					var/cooldown_left = (almayer_orbital_cannon.last_orbital_firing + 5000) - world.time
					if(cooldown_left > 0)
						dat += "Cannon on cooldown ([round(cooldown_left/10)] seconds)<br>"
					else if(!almayer_orbital_cannon.chambered_tray)
						dat += "<font color='red'>No ammo chambered in the cannon.</font><br>"
					else
						dat += "<font color='green'>Ready!</font><br>"
					dat += "<B>Longitude:</B> [x_bomb] <A href='?src=\ref[src];operation=bomb_x'>\[Change\]</a><BR>"
					dat += "<B>Latitude:</B> [y_bomb] <A href='?src=\ref[src];operation=bomb_y'>\[Change\]</a><BR><BR>"
					dat += "<A href='?src=\ref[src];operation=dropbomb'>\[FIRE!\]</a>"
				dat += "<BR><BR>----------------------<br>"
				dat += "<A href='?src=\ref[src];operation=refresh'>{Refresh}</a><br>"
				dat += "<A href='?src=\ref[src];operation=back'>{Back}</a></body>"

	user << browse(dat, "window=overwatch;size=550x550")
	onclose(user, "overwatch")
	return

/obj/machinery/computer/overwatch/proc/update_mapview(var/close = 0)
	if(close || !current_squad || (current_mapviewer && !Adjacent(current_mapviewer)))
		if(current_mapviewer)
			current_mapviewer << browse(null, "window=marineminimap")
			current_mapviewer = null
		return
	var/icon/O
	switch(current_squad.color)
		if(1)
			if(!istype(marine_mapview_overlay_1))
				overlay_marine_mapview(current_squad)
			O = marine_mapview_overlay_1
		if(2)
			if(!istype(marine_mapview_overlay_2))
				overlay_marine_mapview(current_squad)
			O = marine_mapview_overlay_2
		if(3)
			if(!istype(marine_mapview_overlay_3))
				overlay_marine_mapview(current_squad)
			O = marine_mapview_overlay_3
		if(4)
			if(!istype(marine_mapview_overlay_4))
				overlay_marine_mapview(current_squad)
			O = marine_mapview_overlay_4
	if(O)
		current_mapviewer << browse_rsc(O, "marine_minimap.png")
		current_mapviewer << browse("<html><head><script type=\"text/javascript\">function ref() { document.body.innerHTML = '<img src=\"marine_minimap.png?'+Math.random()+'\">'; } setInterval('ref()',1000);</script></head><body><img src=marine_minimap.png></body></html>","window=marineminimap;size=[(map_sizes[1][1]*2)+50]x[(map_sizes[1][2]*2)+50]")

/obj/machinery/computer/overwatch/Topic(href, href_list)
	if(..())
		return

	if(!href_list["operation"])
		return

	if((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (ishighersilicon(usr)))
		usr.set_interaction(src)

	switch(href_list["operation"])
		// main interface
		if("mapview")
			if(current_mapviewer)
				update_mapview(1)
				return
			current_mapviewer = usr
			update_mapview()
			return
		if("back")
			state = 0
		if("monitor")
			state = 1
		if("supplies")
			state = 2
		if("bombs")
			state = 3
		if("change_operator")
			if(operator != usr)
				if(ishighersilicon(operator))
					visible_message("\icon[src] <span class='boldnotice'>AI override in progress. Access denied.</span>")
				if(current_squad)
					current_squad.overwatch_officer = usr
				operator = usr
				if(ishighersilicon(usr))
					to_chat(usr, "\icon[src] <span class='boldnotice'>Overwatch system AI override protocol successful.</span>")
					send_to_squad("Attention. [operator.name] has engaged overwatch system control override.")
				else
					var/mob/living/carbon/human/H = operator
					var/obj/item/card/id/ID = H.get_idcard()
					visible_message("\icon[src] <span class='boldnotice'>Basic overwatch systems initialized. Welcome, [ID ? "[ID.rank] ":""][operator.name]. Please select a squad.</span>")
					send_to_squad("Attention. Your Overwatch officer is now [ID ? "[ID.rank] ":""][operator.name].") //This checks for squad, so we don't need to.
		if("logout")
			if(current_squad)
				current_squad.overwatch_officer = null //Reset the squad's officer.
			if(ishighersilicon(usr))
				send_to_squad("Attention. [operator.name] has released overwatch system control. Overwatch functions deactivated.")
				to_chat(usr, "\icon[src] <span class='boldnotice'>Overwatch system control override disengaged.</span>")
			else
				var/mob/living/carbon/human/H = operator
				var/obj/item/card/id/ID = H.get_idcard()
				send_to_squad("Attention. [ID ? "[ID.rank] ":""][operator ? "[operator.name]":"sysadmin"] is no longer your Overwatch officer. Overwatch functions deactivated.")
				visible_message("\icon[src] <span class='boldnotice'>Overwatch systems deactivated. Goodbye, [ID ? "[ID.rank] ":""][operator ? "[operator.name]":"sysadmin"].</span>")
			operator = null
			current_squad = null
			if(cam && !ishighersilicon(usr))
				usr.reset_view(null)
			cam = null
			state = 0
		if("pick_squad")
			if(operator == usr)
				if(current_squad)
					to_chat(usr, SPAN_WARNING("\icon[src] You are already selecting a squad."))
				else
					var/list/squad_list = list()
					for(var/datum/squad/S in RoleAuthority.squads)
						if(S.usable && !S.overwatch_officer)
							squad_list += S.name

					var/name_sel = input("Which squad would you like to claim for Overwatch?") as null|anything in squad_list
					if(!name_sel) return
					if(operator != usr)
						return
					if(current_squad)
						to_chat(usr, SPAN_WARNING("\icon[src] You are already selecting a squad."))
						return
					var/datum/squad/selected = get_squad_by_name(name_sel)
					if(selected)
						selected.overwatch_officer = usr //Link everything together, squad, console, and officer
						current_squad = selected
						send_to_squad("Attention - Your squad has been selected for Overwatch. Check your Status pane for objectives.")
						send_to_squad("Your Overwatch officer is: [operator.name].")
						visible_message("\icon[src] <span class='boldnotice'>Tactical data for squad '[current_squad]' loaded. All tactical functions initialized.</span>")
						attack_hand(usr)
						if(!current_squad.drop_pad) //Why the hell did this not link?
							for(var/obj/structure/supply_drop/S in item_list)
								S.force_link() //LINK THEM ALL!

					else
						to_chat(usr, "\icon[src] <span class='warning'>Invalid input. Aborting.</span>")
		if("message")
			if(current_squad && operator == usr)
				var/input = stripped_input(usr, "Please write a message to announce to the squad:", "Squad Message")
				if(input)
					send_to_squad(input, 1) //message, adds username
					visible_message("\icon[src] <span class='boldnotice'>Message sent to all Marines of squad '[current_squad]'.</span>")
		if("sl_message")
			if(current_squad && operator == usr)
				var/input = stripped_input(usr, "Please write a message to announce to the squad leader:", "SL Message")
				if(input)
					send_to_squad(input, 1, 1) //message, adds usrname, only to leader
					visible_message("\icon[src] <span class='boldnotice'>Message sent to Squad Leader [current_squad.squad_leader] of squad '[current_squad]'.</span>")
		if("check_primary")
			if(current_squad) //This is already checked, but ehh.
				if(current_squad.primary_objective)
					visible_message("\icon[src] <span class='boldnotice'>Reminding primary objectives of squad '[current_squad]'.</span>")
					to_chat(usr, "\icon[src] <b>Primary Objective:</b> [current_squad.primary_objective]")
		if("check_secondary")
			if(current_squad) //This is already checked, but ehh.
				if(current_squad.secondary_objective)
					visible_message("\icon[src] <span class='boldnotice'>Reminding secondary objectives of squad '[current_squad]'.</span>")
					to_chat(usr, "\icon[src] <b>Secondary Objective:</b> [current_squad.secondary_objective]")
		if("set_primary")
			var/input = stripped_input(usr, "What will be the squad's primary objective?", "Primary Objective")
			if(input)
				current_squad.primary_objective = "[input] ([worldtime2text()])"
				send_to_squad("Your primary objective has changed. See Status pane for details.")
				visible_message("\icon[src] <span class='boldnotice'>Primary objective of squad '[current_squad]' set.</span>")
		if("set_secondary")
			var/input = stripped_input(usr, "What will be the squad's secondary objective?", "Secondary Objective")
			if(input)
				current_squad.secondary_objective = input + " ([worldtime2text()])"
				send_to_squad("Your secondary objective has changed. See Status pane for details.")
				visible_message("\icon[src] <span class='boldnotice'>Secondary objective of squad '[current_squad]' set.</span>")
		if("supply_x")
			var/input = input(usr,"What longitude should be targetted? (Increments towards the east)", "X Coordinate", 0) as num
			to_chat(usr, "\icon[src] <span class='notice'>Longitude is now [input].</span>")
			x_supply = input
		if("supply_y")
			var/input = input(usr,"What latitude should be targetted? (Increments towards the north)", "Y Coordinate", 0) as num
			to_chat(usr, "\icon[src] <span class='notice'>Latitude is now [input].</span>")
			y_supply = input
		if("bomb_x")
			var/input = input(usr,"What longitude should be targetted? (Increments towards the east)", "X Coordinate", 0) as num
			to_chat(usr, "\icon[src] <span class='notice'>Longitude is now [input].</span>")
			x_bomb = input
		if("bomb_y")
			var/input = input(usr,"What latitude should be targetted? (Increments towards the north)", "Y Coordinate", 0) as num
			to_chat(usr, "\icon[src] <span class='notice'>Latitude is now [input].</span>")
			y_bomb = input
		if("refresh")
			src.attack_hand(usr)
		if("change_sort")
			living_marines_sorting = !living_marines_sorting
			if(living_marines_sorting)
				to_chat(usr, "\icon[src] <span class='notice'>Marines are now sorted by health status.</span>")
			else
				to_chat(usr, "\icon[src] <span class='notice'>Marines are now sorted by rank.</span>")
		if("hide_dead")
			dead_hidden = !dead_hidden
			if(dead_hidden)
				to_chat(usr, "\icon[src] <span class='notice'>Dead marines are now not shown.</span>")
			else
				to_chat(usr, "\icon[src] <span class='notice'>Dead marines are now shown again.</span>")
		if("choose_z")
			switch(z_hidden)
				if(0)
					z_hidden = MAIN_SHIP_Z_LEVEL
					to_chat(usr, "\icon[src] <span class='notice'>Marines on the Almayer are now hidden.</span>")
				if(MAIN_SHIP_Z_LEVEL)
					z_hidden = 1
					to_chat(usr, "\icon[src] <span class='notice'>Marines on the ground are now hidden.</span>")
				else
					z_hidden = 0
					to_chat(usr, "\icon[src] <span class='notice'>No location is ignored anymore.</span>")

		if("change_lead")
			change_lead()
		if("insubordination")
			mark_insubordination()
		if("squad_transfer")
			transfer_squad()
		if("dropsupply")
			if(current_squad)
				if((current_squad.supply_cooldown + 5000) > world.time)
					to_chat(usr, "\icon[src] <span class='warning'>Supply drop not yet available!</span>")
				else
					handle_supplydrop()
		if("dropbomb")
			if((almayer_orbital_cannon.last_orbital_firing + 5000) > world.time)
				to_chat(usr, "\icon[src] <span class='warning'>Orbital bombardment not yet available!</span>")
			else
				handle_bombard()
		if("back")
			state = 0
		if("use_cam")
			if(isAI(usr))
				to_chat(usr, "\icon[src] <span class='warning'>Unable to override console camera viewer. Track with camera instead. </span>")
				return
			if(current_squad)
				var/mob/cam_target = locate(href_list["cam_target"])
				var/obj/machinery/camera/new_cam = get_camera_from_target(cam_target)
				if(!new_cam || !new_cam.can_use())
					to_chat(usr, "\icon[src] <span class='warning'>Searching for helmet cam. No helmet cam found for this marine! Tell your squad to put their helmets on!</span>")
				else if(cam && cam == new_cam)//click the camera you're watching a second time to stop watching.
					visible_message("\icon[src] <span class='boldnotice'>Stopping helmet cam view of [cam_target].</span>")
					cam = null
					usr.reset_view(null)
				else if(usr.client.view != world.view)
					to_chat(usr, SPAN_WARNING("You're too busy peering through binoculars."))
				else
					cam = new_cam
					usr.reset_view(cam)
	attack_hand(usr) //The above doesn't ever seem to work.

/obj/machinery/computer/overwatch/check_eye(mob/user)
	if(user.is_mob_incapacitated(TRUE) || get_dist(user, src) > 1 || user.blinded) //user can't see - not sure why canmove is here.
		user.unset_interaction()
	else if(!cam || !cam.can_use()) //camera doesn't work, is no longer selected or is gone
		user.unset_interaction()


/obj/machinery/computer/overwatch/on_unset_interaction(mob/user)
	..()
	if(!isAI(user))
		cam = null
		user.reset_view(null)

//returns the helmet camera the human is wearing
/obj/machinery/computer/overwatch/proc/get_camera_from_target(mob/living/carbon/human/H)
	if (current_squad)
		if (H && istype(H) && istype(H.head, /obj/item/clothing/head/helmet/marine))
			var/obj/item/clothing/head/helmet/marine/helm = H.head
			return helm.camera

//Sends a string to our currently selected squad.
/obj/machinery/computer/overwatch/proc/send_to_squad(var/txt = "", var/plus_name = 0, var/only_leader = 0)
	if(txt == "" || !current_squad || !operator) return //Logic

	var/text = copytext(sanitize(txt), 1, MAX_MESSAGE_LEN)
	var/nametext = ""
	if(plus_name)
		nametext = "[usr.name] transmits: "
		text = "<font size='3'><b>[text]<b></font>"

	for(var/mob/living/carbon/human/M in current_squad.marines_list)
		if(!M.stat && M.client) //Only living and connected people in our squad
			if(!only_leader)
				if(plus_name)
					M << sound('sound/effects/radiostatic.ogg')
				to_chat(M, "\icon[src] <font color='blue'><B>\[Overwatch\]:</b> [nametext][text]</font>")
			else
				if(current_squad.squad_leader == M)
					if(plus_name)
						M << sound('sound/effects/radiostatic.ogg')
					to_chat(M, "\icon[src] <font color='blue'><B>\[SL Overwatch\]:</b> [nametext][text]</font>")
					return

/obj/machinery/computer/overwatch/proc/change_lead()
	if(!usr || usr != operator)
		return
	if(!current_squad)
		to_chat(usr, "\icon[src] <span class='warning'>No squad selected!</span>")
		return
	var/sl_candidates = list()
	for(var/mob/living/carbon/human/H in current_squad.marines_list)
		if(istype(H) && H.stat != DEAD && H.mind && !jobban_isbanned(H, "Squad Leader"))
			sl_candidates += H
	var/new_lead = input(usr, "Choose a new Squad Leader") as null|anything in sl_candidates
	if(!new_lead || new_lead == "Cancel") return
	var/mob/living/carbon/human/H = new_lead
	if(!istype(H) || !H.mind || H.stat == DEAD) //marines_list replaces mob refs of gibbed marines with just a name string
		to_chat(usr, "\icon[src] <span class='warning'>[H] is KIA!</span>")
		return
	if(H == current_squad.squad_leader)
		to_chat(usr, "\icon[src] <span class='warning'>[H] is already the Squad Leader!</span>")
		return
	if(jobban_isbanned(H, "Squad Leader"))
		to_chat(usr, "\icon[src] <span class='warning'>[H] is unfit to lead!</span>")
		return
	if(current_squad.squad_leader)
		send_to_squad("Attention: [current_squad.squad_leader] is [current_squad.squad_leader.stat == DEAD ? "stepping down" : "demoted"]. A new Squad Leader has been set: [H.real_name].")
		visible_message("\icon[src] <span class='boldnotice'>Squad Leader [current_squad.squad_leader] of squad '[current_squad]' has been [current_squad.squad_leader.stat == DEAD ? "replaced" : "demoted and replaced"] by [H.real_name]! Logging to enlistment files.</span>")
		var/old_lead = current_squad.squad_leader
		current_squad.demote_squad_leader(current_squad.squad_leader.stat != DEAD)
		SStracking.start_tracking(current_squad.tracking_id, old_lead)
	else
		send_to_squad("Attention: A new Squad Leader has been set: [H.real_name].")
		visible_message("\icon[src] <span class='boldnotice'>[H.real_name] is the new Squad Leader of squad '[current_squad]'! Logging to enlistment file.</span>")

	to_chat(H, "\icon[src] <font size='3' color='blue'><B>\[Overwatch\]: You've been promoted to \'[H.mind.assigned_role == "Squad Leader" ? "SQUAD LEADER" : "ACTING SQUAD LEADER"]\' for [current_squad.name]. Your headset has access to the command channel (:v).</B></font>")
	to_chat(usr, "\icon[src] [H.real_name] is [current_squad]'s new leader!")

	current_squad.squad_leader = H

	SStracking.set_leader(current_squad.tracking_id, H)
	SStracking.start_tracking("marine_sl", H)

	if(H.mind.assigned_role == "Squad Leader")//a real SL
		H.mind.role_comm_title = "SL"
	else //an acting SL
		H.mind.role_comm_title = "aSL"
	if(H.mind.cm_skills)
		H.mind.cm_skills.leadership = max(SKILL_LEAD_TRAINED, H.mind.cm_skills.leadership)

	if(istype(H.wear_ear, /obj/item/device/radio/headset/almayer/marine))
		var/obj/item/device/radio/headset/almayer/marine/R = H.wear_ear
		if(!R.keyslot1)
			R.keyslot1 = new /obj/item/device/encryptionkey/squadlead (src)
		else if(!R.keyslot2)
			R.keyslot2 = new /obj/item/device/encryptionkey/squadlead (src)
		else if(!R.keyslot3)
			R.keyslot3 = new /obj/item/device/encryptionkey/squadlead (src)
		R.recalculateChannels()
	if(istype(H.wear_id, /obj/item/card/id))
		var/obj/item/card/id/ID = H.wear_id
		ID.access += ACCESS_MARINE_LEADER
	H.hud_set_squad()
	H.update_inv_head() //updating marine helmet leader overlays
	H.update_inv_wear_suit()

/obj/machinery/computer/overwatch/proc/mark_insubordination()
	if(!usr || usr != operator)
		return
	if(!current_squad)
		to_chat(usr, "\icon[src] <span class='warning'>No squad selected!</span>")
		return
	var/mob/living/carbon/human/wanted_marine = input(usr, "Report a marine for insubordination") as null|anything in current_squad.marines_list
	if(!wanted_marine) return
	if(!istype(wanted_marine))//gibbed/deleted, all we have is a name.
		to_chat(usr, "\icon[src] <span class='warning'>[wanted_marine] is missing in action.</span>")
		return

	for (var/datum/data/record/E in data_core.general)
		if(E.fields["name"] == wanted_marine.real_name)
			for (var/datum/data/record/R in data_core.security)
				if (R.fields["id"] == E.fields["id"])
					if(!findtext(R.fields["ma_crim"],"Insubordination."))
						R.fields["criminal"] = "*Arrest*"
						if(R.fields["ma_crim"] == "None")
							R.fields["ma_crim"]	= "Insubordination."
						else
							R.fields["ma_crim"] += "Insubordination."

						var/insub = "\icon[src] <span class='boldnotice'>[wanted_marine] has been reported for insubordination. Logging to enlistment file.</span>"
						if(isAI(usr))
							usr << insub
						else
							visible_message(insub)
						to_chat(wanted_marine, "\icon[src] <font size='3' color='blue'><B>\[Overwatch\]:</b> You've been reported for insubordination by your overwatch officer.</font>")
						wanted_marine.sec_hud_set_security_status()
					return

/obj/machinery/computer/overwatch/proc/transfer_squad()
	if(!usr || usr != operator)
		return
	if(!current_squad)
		to_chat(usr, "\icon[src] <span class='warning'>No squad selected!</span>")
		return
	var/datum/squad/S = current_squad
	var/mob/living/carbon/human/transfer_marine = input(usr, "Choose marine to transfer") as null|anything in current_squad.marines_list
	if(!transfer_marine) return
	if(S != current_squad) return //don't change overwatched squad, idiot.

	if(!istype(transfer_marine) || !transfer_marine.mind || transfer_marine.stat == DEAD) //gibbed, decapitated, dead
		to_chat(usr, "\icon[src] <span class='warning'>[transfer_marine] is KIA.</span>")
		return

	if(!istype(transfer_marine.wear_id, /obj/item/card/id))
		to_chat(usr, "\icon[src] <span class='warning'>Transfer aborted. [transfer_marine] isn't wearing an ID.</span>")
		return

	var/datum/squad/new_squad = input(usr, "Choose the marine's new squad") as null|anything in RoleAuthority.squads
	if(!new_squad) return
	if(S != current_squad) return

	if(!istype(transfer_marine) || !transfer_marine.mind || transfer_marine.stat == DEAD)
		to_chat(usr, "\icon[src] <span class='warning'>[transfer_marine] is KIA.</span>")
		return

	if(!istype(transfer_marine.wear_id, /obj/item/card/id))
		to_chat(usr, "\icon[src] <span class='warning'>Transfer aborted. [transfer_marine] isn't wearing an ID.</span>")
		return

	var/datum/squad/old_squad = transfer_marine.assigned_squad
	if(new_squad == old_squad)
		to_chat(usr, "\icon[src] <span class='warning'>[transfer_marine] is already in [new_squad]!</span>")
		return


	var/no_place = FALSE
	switch(transfer_marine.mind.assigned_role)
		if("Squad Leader")
			if(new_squad.num_leaders == new_squad.max_leaders)
				no_place = TRUE
		if("Squad Specialist")
			if(new_squad.num_specialists == new_squad.max_specialists)
				no_place = TRUE
		if("Squad Engineer")
			if(new_squad.num_engineers >= new_squad.max_engineers)
				no_place = TRUE
		if("Squad Medic")
			if(new_squad.num_medics >= new_squad.max_medics)
				no_place = TRUE
		if("Squad Smartgunner")
			if(new_squad.num_smartgun == new_squad.max_smartgun)
				no_place = TRUE

	if(no_place)
		to_chat(usr, "\icon[src] <span class='warning'>Transfer aborted. [new_squad] can't have another [transfer_marine.mind.assigned_role].</span>")
		return

	old_squad.remove_marine_from_squad(transfer_marine)
	new_squad.put_marine_in_squad(transfer_marine)

	for(var/datum/data/record/t in data_core.general) //we update the crew manifest
		if(t.fields["name"] == transfer_marine.real_name)
			t.fields["squad"] = new_squad.name
			break

	var/obj/item/card/id/ID = transfer_marine.wear_id
	ID.assigned_fireteam = 0 //reset fireteam assignment

	transfer_marine.hud_set_squad()
	visible_message("\icon[src] <span class='boldnotice'>[transfer_marine] has been transfered from squad '[old_squad]' to squad '[new_squad]'. Logging to enlistment file.</span>")
	to_chat(transfer_marine, "\icon[src] <font size='3' color='blue'><B>\[Overwatch\]:</b> You've been transfered to [new_squad]!</font>")

/obj/machinery/computer/overwatch/proc/handle_bombard()
	if(!usr) return

	if(busy)
		to_chat(usr, "\icon[src] <span class='warning'>The [name] is busy processing another action!</span>")
		return

	if(!current_squad)
		to_chat(usr, "\icon[src] <span class='warning'>No squad selected!</span>")
		return

	if(!almayer_orbital_cannon.chambered_tray)
		to_chat(usr, "\icon[src] <span class='warning'>The orbital cannon has no ammo chambered.</span>")
		return

	var/x_coord = deobfuscate_x(x_bomb)
	var/y_coord = deobfuscate_y(y_bomb)

	var/turf/T = locate(x_coord, y_coord, 1)

	var/area/A = get_area(T)
	if(istype(A) && A.ceiling >= CEILING_DEEP_UNDERGROUND)
		to_chat(usr, "\icon[src] <span class='warning'>The target zone is deep underground. The orbital strike cannot reach here.</span>")
		return

	if(istype(T, /turf/open/space))
		to_chat(usr, "\icon[src] <span class='warning'>The target zone appears to be out of bounds. Please check coordinates.</span>")
		return

	//All set, let's do this.
	busy = 1
	visible_message("\icon[src] <span class='boldnotice'>Orbital bombardment request for squad '[current_squad]' accepted. Orbital cannons are now calibrating.</span>")
	send_to_squad("Initializing fire coordinates.")
	playsound(T,'sound/effects/alert.ogg', 25, 1)  //Placeholder
	sleep(20)
	send_to_squad("Transmitting beacon feed.")
	sleep(20)
	send_to_squad("Calibrating trajectory window.")
	sleep(20)
	for(var/mob/living/carbon/H in living_mob_list)
		if(H.z == MAIN_SHIP_Z_LEVEL && !H.stat) //USS Almayer decks.
			to_chat(H, SPAN_WARNING("The deck of the USS Almayer shudders as the orbital cannons open fire on the colony."))
			if(H.client)
				shake_camera(H, 10, 1)
	visible_message("\icon[src] <span class='boldnotice'>Orbital bombardment for squad '[current_squad]' has fired! Impact imminent!</span>")
	send_to_squad("WARNING! Ballistic trans-atmospheric launch detected! Get outside of Danger Close!")
	spawn(6)
		if(A)
			message_mods("<font size=4>ALERT: [usr] ([usr.key]) fired an orbital bombardment in [A.name] for squad '[current_squad]' (<A HREF='?_src_=admin_holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</a>)</font>")
			log_attack("[usr.name] ([usr.ckey]) fired an orbital bombardment in [A.name] for squad '[current_squad]'")
		busy = 0
		var/turf/target = locate(T.x + rand(-3, 3), T.y + rand(-3, 3), T.z)
		if(target && istype(target))
			almayer_orbital_cannon.fire_ob_cannon(target, usr)

/obj/machinery/computer/overwatch/proc/handle_supplydrop()

	if(!usr || usr != operator)
		return

	if(busy)
		to_chat(usr, "\icon[src] <span class='warning'>The [name] is busy processing another action!</span>")
		return

	var/obj/structure/closet/crate/C = locate() in current_squad.drop_pad.loc //This thing should ALWAYS exist.
	if(!istype(C))
		to_chat(usr, "\icon[src] <span class='warning'>No crate was detected on the drop pad. Get Requisitions on the line!</span>")
		return

	var/x_coord = deobfuscate_x(x_supply)
	var/y_coord = deobfuscate_y(y_supply)

	var/turf/T = locate(x_coord, y_coord, 1)
	if(!T)
		to_chat(usr, "\icon[src] <span class='warning'>Error, invalid coordinates.</span>")
		return

	var/area/A = get_area(T)
	if(A && A.ceiling >= CEILING_UNDERGROUND)
		to_chat(usr, "\icon[src] <span class='warning'>The landing zone is underground. The supply drop cannot reach here.</span>")
		return

	if(istype(T, /turf/open/space) || T.density)
		to_chat(usr, "\icon[src] <span class='warning'>The landing zone appears to be obstructed or out of bounds. Package would be lost on drop.</span>")
		return

	busy = 1

	visible_message("\icon[src] <span class='boldnotice'>'[C.name]' supply drop is now loading into the launch tube! Stand by!</span>")
	C.visible_message(SPAN_WARNING("\The [C] begins to load into a launch tube. Stand clear!"))
	C.anchored = TRUE //To avoid accidental pushes
	send_to_squad("'[C.name]' supply drop incoming. Heads up!")
	var/datum/squad/S = current_squad //in case the operator changes the overwatched squad mid-drop
	spawn(100)
		if(!C || C.loc != S.drop_pad.loc) //Crate no longer on pad somehow, abort.
			if(C) C.anchored = FALSE
			to_chat(usr, "\icon[src] <span class='warning'>Launch aborted! No crate detected on the drop pad.</span>")
			return
		S.supply_cooldown = world.time

		playsound(C.loc,'sound/effects/bamf.ogg', 50, 1)  //Ehh
		C.anchored = FALSE
		C.z = T.z
		C.x = T.x
		C.y = T.y
		var/turf/TC = get_turf(C)
		TC.ceiling_debris_check(3)
		playsound(C.loc,'sound/effects/bamf.ogg', 50, 1)  //Ehhhhhhhhh.
		C.visible_message("\icon[C] <span class='boldnotice'>The '[C.name]' supply drop falls from the sky!</span>")
		visible_message("\icon[src] <span class='boldnotice'>'[C.name]' supply drop launched! Another launch will be available in five minutes.</span>")
		busy = 0

/obj/machinery/computer/overwatch/almayer
	density = 0
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "overwatch"

/obj/structure/supply_drop
	name = "Supply Drop Pad"
	desc = "Place a crate on here to allow bridge Overwatch officers to drop them on people's heads."
	icon = 'icons/effects/warning_stripes.dmi'
	anchored = 1
	density = 0
	unacidable = 1
	layer = 2.1 //It's the floor, man
	var/squad = "Alpha"
	var/sending_package = 0

	New() //Link a squad to a drop pad
		..()
		spawn(10)
			force_link()

	proc/force_link() //Somehow, it didn't get set properly on the new proc. Force it again,
		var/datum/squad/S = get_squad_by_name(squad)
		if(S)
			S.drop_pad = src
		else
			to_world("Alert! Supply drop pads did not initialize properly.")

/obj/structure/supply_drop/alpha
	icon_state = "alphadrop"
	squad = "Alpha"

/obj/structure/supply_drop/bravo
	icon_state = "bravodrop"
	squad = "Bravo"

/obj/structure/supply_drop/charlie
	icon_state = "charliedrop"
	squad = "Charlie"

/obj/structure/supply_drop/delta
	icon_state = "deltadrop"
	squad = "Delta"

/obj/structure/supply_drop/echo //extra supply drop pad
	icon_state = "echodrop"
	squad = "Echo"

//This is perhaps one of the weirdest places imaginable to put it, but it's a leadership skill, so
/mob/living/carbon/human/verb/issue_order()

	set name = "Issue Order"
	set desc = "Issue an order to nearby humans, using your authority to strengthen their resolve."
	set category = "IC"

	if(!mind.cm_skills || (mind.cm_skills && mind.cm_skills.leadership < SKILL_LEAD_TRAINED))
		to_chat(src, SPAN_WARNING("You are not competent enough in leadership to issue an order."))
		return

	if(stat)
		to_chat(src, SPAN_WARNING("You cannot give an order in your current state."))
		return

	if(command_aura_cooldown > 0)
		to_chat(src, SPAN_WARNING("You have recently given an order. Calm down."))
		return

	var/choice = input(src, "Choose an order") in command_aura_allowed + "help" + "cancel"
	if(choice == "help")
		to_chat(src, SPAN_NOTICE("<br>Orders give a buff to nearby soldiers for a short period of time, followed by a cooldown, as follows:<br><B>Move</B> - Increased mobility and chance to dodge projectiles.<br><B>Hold</B> - Increased resistance to pain and combat wounds.<br><B>Focus</B> - Increased gun accuracy and effective range.<br>"))
		return
	if(choice == "cancel") return

	if(command_aura_cooldown > 0)
		to_chat(src, SPAN_WARNING("You have recently given an order. Calm down."))
		return

	command_aura = choice
	command_aura_cooldown = 45 //45 ticks
	command_aura_tick = 10 //10 ticks
	command_aura_notified = FALSE
	var/message = ""
	switch(command_aura)
		if("move")
			message = pick(";GET MOVING!", ";GO, GO, GO!", ";WE ARE ON THE MOVE!", ";MOVE IT!", ";DOUBLE TIME!")
			say(message)
		if("hold")
			message = pick(";DUCK AND COVER!", ";HOLD THE LINE!", ";HOLD POSITION!", ";STAND YOUR GROUND!", ";STAND AND FIGHT!")
			say(message)
		if("focus")
			message = pick(";FOCUS FIRE!", ";PICK YOUR TARGETS!", ";CENTER MASS!", ";CONTROLLED BURSTS!", ";AIM YOUR SHOTS!")
			say(message)

