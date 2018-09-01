function Def.AutoHider(params)
	if not params.HideTime then params.HideTime= 5 end
	local args= {
		InitCommand= function(self)
			if params.HideTime < 0 then params.HideTime= 2^16 end
			self:hibernate(params.HideTime)
			if params.InitCommand then params.InitCommand(self) end
		end,
		OnCommand= function(self)
			local function input(event)
				if event.PlayerNumber then
					if params.HideTime < 0 then params.HideTime= 2^16 end
					self:hibernate(params.HideTime)
				end
			end
			SCREENMAN:GetTopScreen():AddInputCallback(input)
			if params.OnCommand then params.OnCommand(self) end
		end
	}
	for k, v in ipairs(params) do
		if k ~= "InitCommand" and k ~= "OnCommand" then
			args[k]= v
		end
	end
	return Def.ActorFrame(args)
end

updatable_help_mt= {
	__index= {
		create_actors= function(self, name, hide_time, translation_section, default_help)
			self.name= name
			self.frame= setmetatable({}, frame_helper_mt)
			self.translation_section= translation_section
			self.default_help= get_string_wrapper(translation_section,default_help)
			self.hide_time= hide_time
			return Def.ActorFrame{
				Name= name, InitCommand= function(subself)
					self.container= subself
					subself:xy(_screen.cx, _screen.cy)
					self.text= subself:GetChild("text")
					self.text:wrapwidthpixels(SCREEN_WIDTH-20):vertspacing(-8)
					if self.hide_time < 0 then self.hide_time= 2^16 end
					subself:hibernate(self.hide_time)
				end,
				OnCommand= function(subself)
					local function input(event)
						if event.PlayerNumber then
							if self.hide_time < 0 then self.hide_time= 2^16 end
							subself:hibernate(self.hide_time)
						end
					end
					SCREENMAN:GetTopScreen():AddInputCallback(input)
				end,
				self.frame:create_actors(
					"frame", 1, 0, 0, fetch_color("rev_bg"), fetch_color("help.bg"),
					0, 0),
				normal_text(
					"text", "", fetch_color("help.text"), fetch_color("help.stroke"),
					0, 0, 1, center),
			}
		end,
		update_text= function(self, text, alt_text)
			local match= get_string_wrapper(self.translation_section, text)
			if match == text and alt_text then
				match= get_string_wrapper(self.translation_section, alt_text)
			end
			if match == alt_text then
				match= self.default_help
			end
			self.text:settext(match)
			local xmn, xmx, ymn, ymx= rec_calc_actor_extent(self.text)
			self.frame:resize(xmx-xmn+20, ymx-ymn+20)
			if match == "" then
				self.container:visible(false)
			else
				self.container:visible(true)
			end
		end,
		update_hide_time= function(self, time)
			self.hide_time= time
		end
}}
