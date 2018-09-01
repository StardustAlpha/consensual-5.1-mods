local timer_text

local function timer_update(self)
	local time= math.floor((self:GetSecsIntoEffect() % 60) * 10) / 10
	if time < 10 then
		timer_text:settext(("0%.1f"):format(time))
	else
		timer_text:settext(("%.1f"):format(time))
	end
end

local button_list= {{"left", "MenuLeft"}, {"right", "MenuRight"}}
if ud_menus() then
	button_list[#button_list+1]= {"top", "MenuUp"}
	button_list[#button_list+1]= {"bottom", "MenuDown"}
end
reverse_button_list(button_list)

local heart_entry_mt= {
	__index= {
		create_actors= function(self, name, x, y, pn)
			self.name= name
			local args= {
				Name= name,
				InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.cursor:refit(nil, nil, 16, 24)
					self.rate= subself:GetChild("rate")
				end
			}
			args[#args+1]= normal_text(
				"rate_label", get_string_wrapper("ScreenHeartEntry", "Heart Rate"),
				nil, fetch_color("stroke"), 0, -72)
			args[#args+1]= normal_text("rate", "0", pn_to_color(pn), fetch_color("stroke"), 0, -48)
			self.value= 0
			self.numpad_poses= {
				-- Do not modify without updating interpret_code.
				{-24, -24}, {0, -24}, {24, -24},
				{-24, 0},   {0, 0},   {24, 0},
				{-24, 24}, {0, 24},   {24, 24},
				{-24, 48}, {0, 48},   {24, 48}}
			self.done_text= "&start;"
			self.back_text= "&leftarrow;"
			self.numpad_nums= {7, 8, 9, 4, 5, 6, 1, 2, 3, 0,
												 self.done_text, self.back_text}
			if april_fools then
				shuffle(self.numpad_nums)
			end
			for i, num in ipairs(self.numpad_nums) do
				args[#args+1]= normal_text(
					"num" .. i, num, nil, fetch_color("stroke"), self.numpad_poses[i][1],
					self.numpad_poses[i][2])
			end
			self.cursor= setmetatable({}, cursor_mt)
			args[#args+1]= self.cursor:create_actors(
				"cursor", 0, 0, 1, pn_to_color(pn), fetch_color("player.hilight"),
				button_list)
			self.cursor_pos= 5
			return Def.ActorFrame(args)
		end,
		interpret_code= function(self, code, menu_code)
			if code == "Start" then
				local num= self.numpad_nums[self.cursor_pos]
				local as_num= tonumber(num)
				local auto_end_num= 10
				if as_num then
					local new_value= (self.value * 10) + as_num
					if new_value < 300 then
						self.value= new_value
						if new_value > auto_end_num then
							self.cursor_pos= 11
							self:update_cursor()
						end
					else
						SOUND:PlayOnce(THEME:GetPathS("Common", "invalid"))
					end
					self.rate:settext(self.value)
					return true, false
				else
					if num == self.done_text then
						self.entry_done= true
						return true, true
					elseif num == self.back_text then
						self.value= math.floor(self.value/10)
						self.rate:settext(self.value)
						return true, false
					end
				end
			else
				local adds= {
					Left= {2, -1, -1},
					Right= {1, 1, -2},
					MenuLeft= {-1, -1, -1},
					MenuRight= {1, 1, 1},
					Up= {9, -3, -3, -3},
					Down= {3, 3, 3, -9},
				}
				adds.MenuUp= adds.Up
				adds.MenuDown= adds.Down
				adds.UpLeftFist= adds.Left
				adds.UpRightFist= adds.Right
				adds.DownLeftFist= adds.Up
				adds.DownRightFist= adds.Down
				local lr_buttons= {
					Left= true, Right= true, UpLeftFist= true, UpRightFist= true, MenuLeft= true, MenuRight= true}
				local adhd= adds[code] or adds[menu_code]
				if adhd then
					local ind= 0
					if lr_buttons[code] then
						ind= ((self.cursor_pos-1)%3)+1
					else
						ind= math.ceil(self.cursor_pos / 3)
					end
					local new_pos= self.cursor_pos + adhd[ind]
					if new_pos < 1 then new_pos= #self.numpad_nums end
					if new_pos > #self.numpad_nums then new_pos= 1 end
					self.cursor_pos= new_pos
					self:update_cursor()
					return true, false
				end
			end
			return false, false
		end,
		update_cursor= function(self)
			local pos= self.numpad_poses[self.cursor_pos]
			self.cursor:refit(pos[1], pos[2])
		end
}}

local heart_entries= {}

local heart_xs= {
	[PLAYER_1]= SCREEN_WIDTH * .25,
	[PLAYER_2]= SCREEN_WIDTH * .75,
}
local function input(event)
	local pn= event.PlayerNumber
	if not pn then return false end
	if event.type == "InputEventType_Release" then return false end
	if not heart_entries[pn] then return false end
	local handled, done= heart_entries[pn]:interpret_code(event.button, event.GameButton)
	if handled and done then
		local all_done= true
		for i, en in pairs(heart_entries) do
			if not en.entry_done then all_done= false break end
		end
		if all_done then
			for pn, en in pairs(heart_entries) do
				local profile= PROFILEMAN:GetProfile(pn)
				if profile and profile:GetIgnoreStepCountCalories() then
					local heart_rate= en.value*6
					local calories= profile:CalculateCaloriesFromHeartRate(
						heart_rate, get_last_song_time())
					profile:AddCaloriesToDailyTotal(calories)
					cons_players[pn].last_song_calories= calories
					cons_players[pn].last_song_heart_rate= heart_rate
				end
			end
			SOUND:PlayOnce(THEME:GetPathS("Common", "Start"))
			trans_new_screen(cons_branches.after_heart())
		end
	end
end

local args= {
	Def.ActorFrame{
		Name= "timer", InitCommand= function(self)
			hms_unfade()
			hms_join()
			self:effectperiod(2^16)
			timer_text= self:GetChild("timer_text")
			self:SetUpdateFunction(timer_update)
		end,
		OnCommand= function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(input)
		end,
		normal_text("timer_text", "00", nil, fetch_color("stroke"), SCREEN_CENTER_X, SCREEN_CENTER_Y)
	},
	normal_text("explanation",
							get_string_wrapper("ScreenHeartEntry", "heart_prompt"),
							nil, fetch_color("stroke"), SCREEN_CENTER_X, SCREEN_CENTER_Y - 120),
	normal_text("song_len_label",
							get_string_wrapper("ScreenHeartEntry", "Song Length"),
							nil, fetch_color("stroke"), SCREEN_CENTER_X, SCREEN_CENTER_Y - 72),
	normal_text("song_len", secs_to_str(get_last_song_time()), nil, fetch_color("stroke"),
							SCREEN_CENTER_X, SCREEN_CENTER_Y - 48),
}

for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
	local profile= PROFILEMAN:GetProfile(pn)
	if profile and profile:GetIgnoreStepCountCalories() then
		heart_entries[pn]= setmetatable({}, heart_entry_mt)
		args[#args+1]= heart_entries[pn]:create_actors(
			pn, heart_xs[pn], SCREEN_CENTER_Y, pn)
	end
end

return Def.ActorFrame(args)
