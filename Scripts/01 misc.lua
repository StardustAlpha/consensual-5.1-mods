-- For when you need a noop function to pass to something that requires a callback.
function noop_false() return false end
function noop_true() return true end
function noop_blank() return "" end
function noop_nil() end
function noop_retarg(...) return ... end
-- For all those actors that need this for various things.
function play_set(self) self:playcommand("Set") end

-- ApplyGameCommand has no place in modern Stepmania lua.
GameState.ApplyGameCommand= nil

function gameplay_back_gives_up()
	if ScreenGameplay.begin_backing_out then return false end
	return true
end

function gte_nil(value, min)
	if min then
		return value >= min
	else
		return true
	end
end

function lte_nil(value, max)
	if max then
		return value <= max
	else
		return true
	end
end

function min_nil(a, b)
	return (lte_nil(a, b) and a) or b
end

function max_nil(a, b)
	return (gte_nil(a, b) and a) or b
end

function less_cmp(a, b)
	return a < b
end

function grt_cmp(a, b)
	return a > b
end

function lesseq_cmp(a, b)
	return a <= b
end

function grteq_cmp(a, b)
	return a >= b
end

function str_cmp(a, b)
	return a:lower() < b:lower()
end

function update_min_table(tab, new_tab, cmp)
	for min_name, min_value in pairs(tab) do
		tab[min_name]= cmp(new_tab[min_name], min_value)
	end
end

function update_totals_table(tab, new_tab)
	for tot_name, tot_value in pairs(new_tab) do
		tab[tot_name]= (tab[tot_name] or 0) + tot_value
	end
end

function newskin_available()
	if NewField then return true end
	return false
end

function not_newskin_available()
	return not newskin_available()
end

-- Fun fact:  Because this file is in consensual/Scripts, while it is being
-- loaded, THEME:GetCurrentThemeDirectory returns "Themes/consensual".
-- So this table exists to allow things that run after script loading is
-- finished to look inside the consensual theme dir when they run for a
-- theme that uses consensual as a fallback theme.
-- Themes using consensual as a fallback should have a file in Scripts that
-- adds their theme dir to this list.
cons_theme_dir_list= {THEME:GetCurrentThemeDirectory()}

all_player_indices= {PLAYER_1, PLAYER_2}
other_player= { [PLAYER_1]= PLAYER_2, [PLAYER_2]= PLAYER_1}

-- this has to be a function instead of a constant because the game can change.
function lowered_game_name()
	return GAMESTATE:GetCurrentGame():GetName():lower()
end

function math.round_to_zero(n)
	if n > 0 then
		return math.floor(n)
	else
		return math.ceil(n)
	end
end

function force_to_range(min, number, max)
	return math.min(max, math.max(min, number))
end

function pow_ten_force(val)
	return 10^math.round(math.log10(val))
end

function shuffle(tab)
	for i= 1, #tab do
		local a= math.random(1, #tab)
		local b= math.random(1, #tab)
		tab[a], tab[b]= tab[b], tab[a]
	end
end

-- Usage:  Pass in an ActorFrame to print all the children of.
function print_children(a)
	local aname= a:GetName()
	Trace("Printing child list for " .. aname)
	if a.GetChildren then
		local children= a:GetChildren()
		for k, v in pairs(children) do
			Trace("  " .. v:GetName())
		end
	else
		Trace("Not an ActorFrame or other thing with children.")
	end
	Trace("Done.")
end

-- Usage:  Pass in an ActorFrame and a string to put in front of every line.
-- indent will be appended to at each level of the recursion, to indent each
-- generation further.

function rec_print_children(parent, indent)
	if not indent then indent= "" end
	if #parent > 0 and type(parent) == "table" then
		for i, c in ipairs(parent) do
			rec_print_children(c, indent .. i .. "->")
		end
	elseif parent.GetChildren then
		local pname= (parent.GetName and parent:GetName()) or ""
		local children= parent:GetChildren()
		Trace(indent .. pname .. " children:")
		for k, v in pairs(children) do
			if #v > 0 then
				Trace(indent .. pname .. "->" .. k .. " shared name:")
				rec_print_children(v, indent .. pname .. "->")
				Trace(indent .. pname .. "->" .. k .. " shared name over.")
			else
				rec_print_children(v, indent .. pname .. "->")
			end
		end
		Trace(indent .. pname .. " children over.")
	else
		local pname= (parent.GetName and parent:GetName()) or ""
		Trace(indent .. pname .. "(" .. tostring(parent) .. ")")
	end
end

function rec_count_children(parent)
	local total= 1
	if #parent > 0 and type(parent) == "table" then
		for i, c in ipairs(parent) do
			total= total + rec_count_children(c)
		end
	elseif parent.GetChildren then
		local pname= (parent.GetName and parent:GetName()) or ""
		local children= parent:GetChildren()
		for k, v in pairs(children) do
			if #v > 0 then
				total= total + rec_count_children(v)
			else
				total= total + rec_count_children(v)
			end
		end
	end
	return total
end


function rec_find_child(parent, name)
	if parent:GetName() == name then
		--Trace("Found matching child: " .. parent:GetName())
		return parent
	end
	if parent.GetChildren then
		for k, v in pairs(parent:GetChildren()) do
			local res= rec_find_child(v, name)
			if res then
				--Trace("Recursively returning match: " .. res:GetName())
				return res
			end
		end
	end
	return nil
end

local function rand_bezin()
	return math.random()
end

function rand_bezier1(actor, time)
	actor:tween(time, "TweenType_Bezier", {0, rand_bezin(), rand_bezin(), 1})
end

function rand_bezier2(actor, time)
	actor:tween(time, "TweenType_Bezier", {0, 0, rand_bezin(), rand_bezin(), rand_bezin(), rand_bezin(), 1, 1})
end

local possible_tweens= {
	noop_nil, Actor.april_linear, Actor.accelerate, Actor.decelerate, Actor.spring,
	rand_bezier1, rand_bezier2,
}
local tween_sets= {
	[0]= {2, 5},
	{1, 1}, {1, 1}, {1, 1}, {2, 2}, {2, 2},
	{1, 5}, {2, 5}, {3, 5}, {5, 5},
	{5, #possible_tweens},
	{#possible_tweens, #possible_tweens},
}
local tween_times= {
	[0]= {1, 8}, {1, 1}, {1, 1}, {1, 1}, {1, 4}, {1, 4}, {1, 8}, {1, 8}, {1, 16}, {1, 32},
}

function rand_choice(level, sets)
	if level then
		level= force_to_range(1, level, #sets)
	else
		level= 0
	end
	local min, max= sets[level][1], sets[level][2]
	if min == max then return min end
	return math.random(min, max)
end

function rand_tween(child, level)
	local choice= rand_choice(level, tween_sets)
	local time= rand_choice(level, tween_times)
	possible_tweens[choice](child, time)
end

function for_all_children(parent, func)
	local children= parent:GetChildren()
	for name, child in pairs(children) do
		if #child > 0 then
			for si, sc in ipairs(child) do
				func(sc)
			end
		else
			func(child)
		end
	end
end

function rec_convert_strings_to_numbers(t)
	for k, v in pairs(t) do
		if tonumber(v) then
			t[k]= tonumber(v)
		elseif type(v) == "table" then
			rec_convert_strings_to_numbers(v)
		end
	end
end

-- Usage:  Pass in a table and a string to indent each line with.
function print_table(t, indent)
	if not indent then indent= "" end
	for k, v in pairs(t) do
		Trace(indent .. k .. ": " .. tostring(v))
	end
	Trace(indent .. "end")
end

-- Usage:  Pass in a table and a string to indent each line with.
-- indent will be appended to at each level of the recursion, to indent each
-- generation further.
-- DO NOT pass in a table that contains a reference loop.
-- A reference loop is a case where a table contains a member that is a
-- reference to itself, or contains a table that contains a reference to
-- itself.
-- Short reference loop example:  a= {}   a[1]= a
-- Longer reference loop example:  a= {b= {c= {}}}   a.b.c[1]= a
function rec_print_table(t, indent, depth_remaining)
	if not indent then indent= "" end
	if type(t) ~= "table" then
		Trace(indent .. "rec_print_table passed a " .. type(t))
		return
	end
	depth_remaining= depth_remaining or -1
	if depth_remaining == 0 then return end
	for k, v in pairs(t) do
		if type(v) == "table" then
			Trace(indent .. tostring(k) .. ": table")
			rec_print_table(v, indent .. "  ", depth_remaining - 1)
		else
			Trace(indent .. "(" .. type(k) .. ")" .. tostring(k) .. ": " ..
							"(" .. type(v) .. ")" .. tostring(v))
		end
	end
	Trace(indent .. "end")
end

function rec_print_table_to_str(t, indent, depth_remaining)
	if not indent then indent= "" end
	if type(t) ~= "table" then
		return indent .. "rec_print_table passed a " .. type(t)
	end
	depth_remaining= depth_remaining or -1
	if depth_remaining == 0 then return "" end
	local lines= {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			table.insert(lines, indent .. k .. ": table")
			table.insert(lines, rec_print_table_to_str(
										 v, indent .. "  ", depth_remaining - 1))
		else
			table.insert(lines, indent .. "(" .. type(k) .. ")" .. k .. ": " ..
							"(" .. type(v) .. ")" .. tostring(v) .. "")
		end
	end
	table.insert(lines, indent .. "end")
	return table.concat(lines, "\n")
end

function string_needs_escape(str)
	if str:match("^[a-zA-Z_][a-zA-Z_0-9]*$") then
		return false
	else
		return true
	end
end

function lua_table_to_string(t, indent, line_pos)
	indent= indent or ""
	line_pos= (line_pos or #indent) + 1
	local internal_indent= indent .. "  "
	local ret= "{"
	local has_table= false
	for k, v in pairs(t) do if type(v) == "table" then has_table= true end
	end
	if has_table then
		ret= "{\n" .. internal_indent
		line_pos= #internal_indent
	end
	local separator= ""
	local function do_value_for_key(k, v, need_key_str)
		if type(v) == "nil" then return end
		local k_str= k
		if type(k) == "number" then
			k_str= "[" .. k .. "]"
		elseif type(k) == "boolean" then
			k_str= "[" .. tostring(k) .. "]"
		else
			if string_needs_escape(k) then
				k_str= "[" .. ("%q"):format(k) .. "]"
			else
				k_str= k
			end
		end
		if need_key_str then
			k_str= k_str .. "= "
		else
			k_str= ""
		end
		local v_str= ""
		if type(v) == "table" then
			v_str= lua_table_to_string(v, internal_indent, line_pos + #k_str)
		elseif type(v) == "string" then
			v_str= ("%q"):format(v)
		elseif type(v) == "number" then
			if v ~= math.floor(v) then
				v_str= ("%.6f"):format(v)
				local last_nonz= v_str:reverse():find("[^0]")
				if last_nonz then
					v_str= v_str:sub(1, -last_nonz)
				end
			else
				v_str= tostring(v)
			end
		else
			v_str= tostring(v)
		end
		local to_add= k_str .. v_str
		if type(v) == "table" then
			if separator == "" then
				to_add= separator .. to_add
			else
				to_add= separator .."\n" .. internal_indent .. to_add
			end
		else
			if line_pos + #separator + #to_add > 80 then
				line_pos= #internal_indent + #to_add
				to_add= separator .. "\n" .. internal_indent .. to_add
			else
				to_add= separator .. to_add
				line_pos= line_pos + #to_add
			end
		end
		ret= ret .. to_add
		separator= ", "
	end
	-- do the integer indices from 0 to n first, in order.
	do_value_for_key(0, t[0], true)
	for n= 1, #t do
		do_value_for_key(n, t[n], false)
	end
	for k, v in pairs(t) do
		local is_integer_key= (type(k) == "number") and (k == math.floor(k)) and k >= 0 and k <= #t
		if not is_integer_key then
			do_value_for_key(k, v, true)
		end
	end
	ret= ret .. "}"
	return ret
end

function wrapped_index(start, offset, set_size)
	return ((start - 1 + offset) % set_size) + 1
end

do
	local zoomed_width= SCREEN_BOTTOM / 32
	local zoomed_height= 24
	local spacing_y= zoomed_width
	local start_y= 0
	function life_pill_transform(self,offsetFromCenter,itemIndex,numItems)
		--Trace("life_pill_transform: " .. self:GetName() .. ": " .. offsetFromCenter .. ", " .. itemIndex .. ", " .. numItems)
		--local parent= self:GetParent()
		--if parent then
		--   Trace("Parent: " .. parent:GetName())
		--end
		self:zoomtoheight(zoomed_height)
		self:zoomtowidth(zoomed_width)
		self:rotationz(-90)
		self:y(start_y - (itemIndex * spacing_y))
	end
end

local unlower= {"ABCDEFGHIJKLMNOPQRSTUVWXYZ"}
for i= 1, #unlower[1] do
	local l= math.random(1, #unlower[1])
	unlower[unlower[1]:sub(i, i)]= unlower[1]:sub(l, l):lower()
end
local prev_month= -1
local prev_day= -1
function aprf_check()
	local month= MonthOfYear()
	local day= DayOfMonth()
	if day ~= prev_day then
		activate_confetti("day", false)
	end
	if month == 3 and day == 1 and PREFSMAN:GetPreference("EasterEggs") then
		april_fools= true
		scrambler_mode= true
		tilt_mode= true
		activate_confetti("day", true)
	else
		april_fools= false
		scrambler_mode= false
		tilt_mode= false
	end
	if month == 10 and day == 7 and PREFSMAN:GetPreference("EasterEggs") then
		kyzentun_birthday= true
	else
		kyzentun_birthday= false
	end
	if GAMESTATE:GetCurrentGame():GetName() == "kickbox" then
		-- Not going to bother porting the doubles-only easter egg to kickbox.
		kyzentun_birthday= false
	end
	special_day= kyzentun_birthday or april_fools
	prev_month= month
	prev_day= day
end

global_distortion_mode= april_fools
function maybe_distort_text(text_actor)
	if global_distortion_mode and text_actor.distort then
		if april_fools then
			if GetTimeSinceStart() > 2048 then
				-- This should cause the distortion to start appearing 2048 seconds
				-- after sm starts.  Then the distortion will take 612 seconds to go
				-- through a full cycle.
				local dist= 2 * math.sin((GetTimeSinceStart() - 2048) / 100)
				if math.abs(dist) > 1 then
					if dist > 0 then
						dist= dist - 1
					else
						dist= dist + 1
					end
					text_actor:distort(dist)
				end
			end
		else
			text_actor:distort(.75)
		end
	end
end

local next_yield_time= 0
local yield_gap= .05
function maybe_yield(...)
	local curr_time= GetTimeSinceStart()
	if curr_time > next_yield_time then
		next_yield_time= curr_time + yield_gap
		coroutine.yield(...)
	end
end

function fracstr(a, b)
	return a .. "/" .. b
end

-- Possibilities: (0+n, 1-n)
local sub_makes= {
	function(bez, yc)
		bez[4]= 0 + yc
		bez[6]= 1 - yc
		return bez
	end,
	function(bez, yc)
		bez[4]= 0 - yc
		bez[6]= 1 + yc
		return bez
	end,
	function(bez, yc)
		bez[4]= 1 + yc
		bez[6]= 0 - yc
		return bez
	end,
	function(bez, yc)
		bez[4]= 1 - yc
		bez[6]= 0 + yc
		return bez
	end,
}

local function make_april_bezier()
	local ret= {0, 0, math.random(), .5, math.random(), .5, 1, 1}
	return sub_makes[math.random(#sub_makes)](ret, math.random() * 2)
end

local normal_beziers= {
	{0, 0, 1, 2, 0, .5, 1, 1},
	{0, 0, .5, 2, 0, .5, 1, 1},
	{0, 0, .5, 2, .5, .5, 1, 1},
	{0, 0, .5, 2, 1, .5, 1, 1},
	{0, 0, .5, 2, 0, .5, 1, 1},
	{0, 0, .25, 2, .25, .5, 1, 1},
	{0, 0, .5, 2, -.25, .5, 1, 1},
}

local function normal_bezier()
	return normal_beziers[math.random(#normal_beziers)]
end

Actor.april_linear= function(self, time)
	if april_fools then
		return self:tween(time*5, "TweenType_Bezier", make_april_bezier())
	else
		return self:tween(time*4, "TweenType_Bezier", normal_bezier())
	end
end

local function april_spin_dir()
	if math.random(2) == 1 then
		return .05
	else
		return -.05
	end
end

function april_spin(self)
	if april_fools then
		self:xy(-_screen.cx, -_screen.cy)
			:AddWrapperState():xy(_screen.cx, _screen.cy)
			:spin():effectmagnitude(0, 0, april_spin_dir())
	end
end

local get_all_steps= "GetAllSteps"
local get_main_title= "GetDisplayMainTitle"
local set_curr_song= noop_nil
local get_curr_song= noop_nil
local get_curr_steps= noop_nil
local set_curr_steps= noop_nil
local does_group_exist= noop_false
local get_group_banner_path= noop_blank
function song_get_length() return 0 end
function song_get_dir(song)
	return (song.GetSongDir and song:GetSongDir()) or
		(song.GetCourseDir and song:GetCourseDir())
end

function set_course_mode()
	get_all_steps= "GetAllTrails"
	get_main_title= "GetDisplayFullTitle"
	set_curr_song= GAMESTATE.SetCurrentCourse
	get_curr_song= GAMESTATE.GetCurrentCourse
	get_curr_steps= GAMESTATE.GetCurrentTrail
	set_curr_steps= GAMESTATE.SetCurrentTrail
	does_group_exist= SONGMAN.DoesCourseGroupExist
	get_group_banner_path= SONGMAN.GetCourseGroupBannerPath
	song_get_length=
		function(song)
--			return 0
			local steps_type= GAMESTATE:GetCurrentStyle():GetStepsType()
			return (song.GetTotalSeconds and song:GetTotalSeconds(steps_type)) or 0
		end
end

function  set_song_mode()
	get_all_steps= "GetAllSteps"
	get_main_title= "GetDisplayMainTitle"
	set_curr_song= GAMESTATE.SetCurrentSong
	get_curr_song= GAMESTATE.GetCurrentSong
	get_curr_steps= GAMESTATE.GetCurrentSteps
	set_curr_steps= GAMESTATE.SetCurrentSteps
	does_group_exist= SONGMAN.DoesSongGroupExist
	get_group_banner_path= SONGMAN.GetSongGroupBannerPath
	song_get_length=
		function(song)
			return (song.GetFirstSecond and
							math.round(song:GetLastSecond() - song:GetFirstSecond())) or 0
		end
end

function sourse_get_all_steps(sourse)
	if sourse.GetAllSteps then
		return sourse:GetAllSteps()
	end
	return sourse:GetAllTrails()
end

function song_get_all_steps(song)
	return song[get_all_steps](song)
end

function song_get_main_title(song)
	return song[get_main_title](song)
end

function put_bpm_in_disp_pair(disp_pair, bpm)
	if lte_nil(bpm, disp_pair[1]) then
		disp_pair[1]= bpm
	end
	if gte_nil(bpm, disp_pair[2]) then
		disp_pair[2]= bpm
	end
end

function get_timing_bpms(steps, song)
	local bpms= {}
	local timing_data= steps:GetTimingData()
	local bpmsand= timing_data:GetBPMsAndTimes(true)
	local totals= {}
	local num_beats= timing_data:GetBeatFromElapsedTime(song:GetLastSecond())
	local highest_sustained= 0
	local sustain_limit= 8
	local max_bpm= false
	for i, s in ipairs(bpmsand) do
		local start_beat= s[1]
		local bpm= s[2]
		if gte_nil(bpm, max_bpm) then
			max_bpm= bpm
		end
		local end_beat= 0
		if bpmsand[i+1] then
			end_beat= bpmsand[i+1][1]
		else
			end_beat= num_beats
		end
		local len= (end_beat - start_beat)
		local seconds= len / bpm * 60
		if bpm > highest_sustained and seconds > sustain_limit then
			highest_sustained= bpm
		end
		totals[bpm]= len + (totals[bpm] or 0)
	end
	local tot= 0
	local most_common= false
	for k, v in pairs(totals) do
		local minutes_duration= v / k
		if not most_common or minutes_duration > most_common[2] then
			most_common= {k, minutes_duration}
		end
		tot= tot + (k * v)
	end
	local average= tot / num_beats
	put_bpm_in_disp_pair(bpms, math.max(most_common[1], highest_sustained))
	return bpms
end

function get_display_bpms(steps, song)
	local display_bpms= steps:GetDisplayBpms()
	local timing_bpms= get_timing_bpms(steps, song)
	if steps:GetDisplayBPMType() ~= "DisplayBPM_Specified" or
		display_bpms[2] < 1 or display_bpms[2] > 1000
	-- DDR worshippers like to give DDR simfiles Konami's false display bpms.
	or steps_are_konami_trash(steps) then
		return timing_bpms
	end
	return display_bpms
end

function steps_get_bpms(strail, song)
	local bpms= {}
	if GAMESTATE:IsCourseMode() then
		for i, entry in ipairs(strail:GetTrailEntries()) do
			local ebpms= get_display_bpms(entry:GetSteps(), entry:GetSong())
			put_bpm_in_disp_pair(bpms, ebpms[1])
			put_bpm_in_disp_pair(bpms, ebpms[2])
		end
	else
		bpms= get_display_bpms(strail, song)
	end
	return bpms
end

function format_bpm(bpm)
	return ("%.0f"):format(bpm)
end

function format_xmod(xmod)
	return ("%.2f"):format(xmod)
end

function steps_are_konami_trash(steps)
	local fname= steps:GetFilename()
	return fname and fname:find("DDR") and not fname:find("Encore")
end

function steps_get_author(steps, song)
	local author= ""
	if not steps then
		if not song then return "" end
		return song:GetGroupName()
	end
	if steps.IsAutogen and steps:IsAutogen() then
		return "Autogen"
	end
	if steps.GetAuthorCredit then
		-- All three of these are plausible places for the author name.
		-- The correct place.
		author= steps:GetAuthorCredit()
		if not author or author == "" then
			-- The wrong place.
			author= steps:GetChartName()
		end
		if not author or author == "" then
			-- The place that exists in .sm files.
			author= steps:GetDescription()
		end
		if steps_are_konami_trash(steps) then
			author = "Konami Shuffle"
		end
	else
		author= song:GetScripter()
	end
	if author == "" or author:lower():find("copied from") then
		author= song:GetGroupName()
	end
	if author:lower() == "c. grab" then
		author= "( ͡° ͜ʖ ͡°)"
	end
	return author
end

function gamestate_get_curr_song()
	return get_curr_song(GAMESTATE)
end

function gamestate_set_curr_song(song)
	return set_curr_song(GAMESTATE, song)
end

function gamestate_get_curr_steps(pn)
	return get_curr_steps(GAMESTATE, pn)
end

function gamestate_set_curr_steps(pn, steps)
	return set_curr_steps(GAMESTATE, pn, steps)
end

function songman_does_group_exist(name)
	return does_group_exist(SONGMAN, name)
end

function songman_get_group_banner_path(name)
	return get_group_banner_path(SONGMAN, name)
end

playmode_to_command= {
	PlayMode_Regular= "regular",
	PlayMode_Nonstop= "nonstop",
	PlayMode_Oni= "oni",
	PlayMode_Endless= "endless",
	PlayMode_Battle= "battle",
	PlayMode_Rave= "rave"
}

function get_current_song_length()
	local song= gamestate_get_curr_song()
	if song then
		return song_get_length(song)
	else
		return 0
	end
end

function get_rate_from_songopts()
	return GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate()
end

function trans_new_screen(name)
	SCREENMAN:GetTopScreen():SetNextScreenName(name)
		:StartTransitioningScreen("SM_GoToNextScreen")
end

function prompt_text_entry(settings)
	SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
	SCREENMAN:GetTopScreen():Load(settings)
end

function set_current_style(style, pn)
	GAMESTATE:SetCurrentStyle(style, pn)
end

function set_current_playmode(playmode)
	GAMESTATE:SetCurrentPlayMode(playmode)
end

-- An object to handle coordination of rate changes between things on a screen.
local rate_coordinator_interface= {}
rate_coordinator_interface_mt= { __index= rate_coordinator_interface }
function rate_coordinator_interface:initialize()
	self.notify_list= {}
	self.current_rate= get_rate_from_songopts()
end

function rate_coordinator_interface:add_to_notify(sub)
	self.notify_list[#self.notify_list+1]= sub
end

function rate_coordinator_interface:remove_from_notify(sub)
	local index= 0
	for i, s in ipairs(self.notify_list) do
		if s == sub then
			index= i
		end
	end
	if index ~= 0 then
		table.remove(self.notify_list, index)
	end
end

function rate_coordinator_interface:notify(new_rate, play_new_sample)
	MESSAGEMAN:Broadcast("rate_changed")
	if tonumber(new_rate) then
		self.current_rate= new_rate
		for v in ivalues(self.notify_list) do
			v:notify_of_rate_change()
		end
		if play_new_sample then
			play_sample_music()
		end
	else
		error("Someone notified of a bad new rate: \"" .. tostring(new_rate)
				.. '"')
	end
end

function rate_coordinator_interface:get_current_rate()
	return self.current_rate
end

function steps_to_string(steps)
	return get_string_wrapper("DifficultyNames", steps:GetStepsType()) .. "-"
	.. get_string_wrapper("DifficultyNames", steps:GetDifficulty())
end

local cached_steps_list= false
local cached_steps_song= false
local cached_steps_players= false
local cached_list_is_sorted= false
function get_filtered_steps_list(song)
	song= song or gamestate_get_curr_song()
	local num_players= GAMESTATE:GetNumPlayersEnabled()
	if song == cached_steps_song and num_players == cached_steps_players then
		return cached_steps_list
	end
	local ret= {}
	local filter_types= cons_get_steps_types_to_show()
	if song then
		local all_steps= song_get_all_steps(song)
		for i, v in ipairs(all_steps) do
			if filter_types[v:GetStepsType()] then
				ret[#ret+1]= v
			end
		end
	end
	cached_steps_players= num_players
	cached_steps_song= song
	cached_steps_list= ret
	cached_list_is_sorted= false
	return ret
end

local steps_compare_fields= {
	"GetMeter", "GetChartStyle", "GetDescription", "GetFilename",
	"GetAuthorCredit", "GetChartName"}

function sort_steps_list(list)
	if cached_list_is_sorted and list == cached_steps_list then
		return cached_steps_list
	end
	local function compare(ela, elb)
		if not ela then return true end
		if not elb then return false end
		local type_diff= StepsType:Compare(ela:GetStepsType(), elb:GetStepsType())
		if type_diff == 0 then
			local diff_diff= Difficulty:Compare(ela:GetDifficulty(), elb:GetDifficulty())
			if diff_diff == 0 then
				for i, comp in ipairs(steps_compare_fields) do
					local ac= ela[comp](ela)
					local bc= elb[comp](elb)
					if ac ~= bc then
						return ac < bc
					end
				end
				return false
			else
				return diff_diff < 0
			end
		else
			return type_diff < 0
		end
	end
	table.sort(list, compare)
	cached_list_is_sorted= true
	return list
end

convert_code_name_to_display_text= {
	noob_mode="noob",
	simple_options_mode="simple options",
	all_options_mode="all options",
	excessive_options_mode="excessive options",
	kyzentun_mode="Kyzentun",
	unjoin="Unjoin Other",
}

function ymd_timestamp()
	local y= Year()
	local m= MonthOfYear() + 1
	local d= DayOfMonth()
	if m < 10 then m = "0" .. m end
	if d < 10 then d = "0" .. d end
	return y.."-"..m.."-"..d
end

function hms_timestamp()
	local h= Hour()
	local m= Minute()
	local s= Second()
	if h < 10 then h= "0" .. h end
	if m < 10 then m= "0" .. m end
	if s < 10 then s= "0" .. s end
	return h..":"..m..":"..s
end

function ymdhms_timestamp()
	return ymd_timestamp() .. " " .. hms_timestamp()
end

local slot_conversion= {
	[PLAYER_1]= "ProfileSlot_Player1", [PLAYER_2]= "ProfileSlot_Player2",}
function pn_to_profile_slot(pn)
	return slot_conversion[pn] or "ProfileSlot_Invalid"
end

function secs_to_str(secs, precise)
	local minutes= math.abs(math.round_to_zero(secs / 60))
	local seconds= math.round_to_zero(secs % 60)
	if precise and precise > 0 then
		seconds= secs % 60
	end
	if secs < 0 then
		if precise and precise > 0 then
			seconds= math.abs(secs % -60)
		else
			seconds= math.abs(math.round_to_zero(secs % -60))
		end
	end
	local neg= (secs < 0) and "-" or ""
	local lead= (seconds < 10) and "0" or ""
	if precise and precise > 0 then
		return neg..minutes..":"..lead..("%."..(precise+1).."g"):format(seconds)
	else
		return neg..minutes..":"..lead..seconds
	end
end

function toggle_int_as_bool(b)
	if b and b ~= 0 then
		return 0
	end
	return 1
end

function int_to_bool(i)
	if i ~= 0 then return true end
	return false
end

function insert_into_sorted_table(tab, value)
	local lower= 1
	local upper= #tab
	if not tab[lower] then
		table.insert(tab, lower, value)
		return
	end
	if tab[lower] == value or tab[upper] == value then return end
	if value < tab[lower] then
		table.insert(tab, 1, value)
		return
	end
	if tab[upper] < value then
		table.insert(tab, upper+1, value)
		return
	end
	while upper - lower > 1 do
		local new_lower= math.ceil((lower + upper) * .5)
		if tab[new_lower] == value then
			return
		elseif tab[new_lower] < value then
			lower= new_lower
			last_compare_result= new_compare_result
		else
			upper= new_lower
		end
	end
	table.insert(tab, upper, value)
end

function table_remove_range(tab, first, last)
	local original_size= #tab
	local diff= last - first
	for i= 0, diff-1 do
		tab[first+i]= tab[last+i]
	end
	for i= last, original_size do
		tab[i]= nil
	end
end

function end_credit_now()
	local next_screen= "ScreenInitialMenu"
	for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		if cons_players[pn].play_history[1] then
			next_screen= "ScreenConsNameEntry"
			break
		end
	end
	trans_new_screen(next_screen)
end

function life_on(self)
	if misc_config:get_data().disable_extra_processing then
		self:hibernate(math.huge)
	end
end

function screen_pixels(pix)
	return pix * (DISPLAY:GetDisplayHeight() / _screen.h)
end

local number_names= {
	[0]= "zero", "one", "two", "three", "four", "five", "six", "seven",
	"eight", "nine"
}
local teen_names= {
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
	"seventeen", "eighteen", "nineteen"
}
local tens_names= {
	"ten", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty",
	"ninety"
}
local thousand_names= {
	"thousand", "million", "billion", "trillion", "quadrillion", "pentillion",
	"sexillion", "hepatitisillion", "octillion", "nonallion", "decillion"
}
function wordify_subk_number(number, result)
	local hundreds= math.floor(number * .01)
	local tens= math.floor((number * .1) % 10)
	local ones= number % 10
	if hundreds > 0 then
		table.insert(result, number_names[hundreds])
		table.insert(result, "hundred")
	end
	local is_teen= false
	if tens > 0 then
		if tens == 1 and ones ~= 0 then
			is_teen= true
			table.insert(result, teen_names[ones])
		else
			table.insert(result, tens_names[tens])
		end
	end
	if not is_teen and (ones > 0 or number == 0) then
		table.insert(result, number_names[ones])
	end
	return result
end
function wordify_number_internal(number, result)
	if number < 0 then
		table.insert(result, "negative")
		return wordify_number_internal(-number, result)
	end
	if number < 1000 then
		return wordify_subk_number(number, result)
	end
	local curr_number= number
	local subk_parts= {}
	while curr_number > 0 do
		local subk= curr_number % 1000
		table.insert(subk_parts, wordify_subk_number(subk, {}))
		curr_number= math.floor(curr_number / 1000)
	end
	local worded_subk_parts= {}
	for sk= #subk_parts, 1, -1 do
		if sk > 1 then
			table.insert(subk_parts[sk], thousand_names[sk-1])
		end
		if subk_parts[sk][1] ~= "zero" then
			table.insert(worded_subk_parts, table.concat(subk_parts[sk], " "))
		end
	end
	return worded_subk_parts
end

function wordify_number(number)
	local result= wordify_number_internal(math.round(number), {})
	return table.concat(result, " ")
end

function wordify_num_test()
	Trace(wordify_number(123456789012345))
	Trace(wordify_number(12345678901234))
	Trace(wordify_number(1234567890123))
	Trace(wordify_number(123456789012))
	Trace(wordify_number(12345678901))
	Trace(wordify_number(1234567890))
	Trace(wordify_number(123456789))
	Trace(wordify_number(12345678))
	Trace(wordify_number(1234567))
	Trace(wordify_number(123456))
	Trace(wordify_number(12345))
	Trace(wordify_number(1234))
	Trace(wordify_number(123))
	Trace(wordify_number(12))
	Trace(wordify_number(1))
	Trace(wordify_number(0))
	Trace(wordify_number(-1))
	Trace(wordify_number(10))
	Trace(wordify_number(20))
	Trace(wordify_number(30))
	Trace(wordify_number(32))
	Trace(wordify_number(333))
	Trace(wordify_number(315))
	lua.ReportScriptError("wordify_num_test done")
end

music_wheel_width= SCREEN_WIDTH*.3125
mini_menu_width= math.min(_screen.w*.9, 480*.9)
