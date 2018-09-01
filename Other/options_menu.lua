-- Usage:
-- Use the following two lines to load this file on some screen.
--   local menu_path= THEME:GetPathO("", "options_menu.lua")
--   dofile(menu_path)
-- Then declare whatever special menus you need inside the options_sets table
-- options_sets.menu and options_sets.special_functions are provided as
--   examples and for general use.
-- After declaring the specialized menus, call set_option_set_metatables().
-- Create a table with option_display_mt as the metatable.
-- option_display_mt follows my convention for actor wrappers of having
--   create_actors, and name.
-- After the display's Initcommand runs, call
--   option_display_mt.set_underline_color if you are going to use the
--   underline feature.
-- option_display_mt is not meant to be controlled directly, instead it is
--   meant to be given to a menu to control.  Control commands should be sent
--   to the menu, and the menu will take care of manipulating the display.
-- See ScreenSickPlayerOptions for a complicated example.

local move_time= 0.1
local line_height= get_line_height()

local option_item_mt= {
	__index= {
		create_actors= function(self, name)
			self.name= name
			self.zoom= 1
			self.width= SCREEN_WIDTH
			self.prev_index= 1
			self.translation_section= "OptionNames"
			return Def.ActorFrame{
				Name= name,
				InitCommand= function(subself)
					self.container= subself
					self.text= subself:GetChild("text")
					self:lose_focus()
				end,
				Def.Quad{
					Name= "underline", InitCommand= function(q) self.underline= q end},
				normal_text("text", "", nil, fetch_color("stroke"), nil, nil, self.zoom),
			}
		end,
		set_geo= function(self, width, height, zoom)
			self.width= width
			self.zoom= zoom
			self.height= height
			self.text:zoom(zoom)
			self.underline:SetHeight(height/2):vertalign(top)
		end,
		set_underline_color= function(self, color)
			self.underline:diffuse(color)
		end,
		set_text_colors= function(self, main, stroke)
			self.text:diffuse(main):strokecolor(stroke)
		end,
		transform= function(self, item_index, num_items, is_focus)
			local changing_edge= math.abs(item_index-self.prev_index)>num_items/2
			if changing_edge then
				self.container:diffusealpha(0)
			end
			self.container:finishtweening():april_linear(move_time)
				:xy(0, (item_index-1) * (self.height or self.text:GetZoomedHeight()))
				:april_linear(move_time):diffusealpha(1)
			self.prev_index= item_index
		end,
		set= function(self, info)
			self.info= info
			if info then
				self:set_text(info.text)
				self:set_underline(info.underline)
			else
				self.text:settext("")
				self:set_underline(false)
			end
		end,
		set_underline= function(self, u)
			if u then
				self.underline:stoptweening():accelerate(0.25):zoom(1)
			else
				self.underline:stoptweening():decelerate(0.25):zoom(0)
			end
		end,
		set_text= function(self, t)
			self.text:settext(get_string_wrapper(self.translation_section, t))
			width_limit_text(self.text, self.width, self.zoom)
			self.underline:SetWidth(self.text:GetZoomedWidth())
		end,
		get_cursor_fit= function(self)
			local ret= {0, 0, 0, self.height + 4}
			if self.text:GetText() ~= "" then
				ret[3]= self.text:GetWidth() + 4
			end
			return ret
		end,
		gain_focus= noop_nil,
		lose_focus= noop_nil,
}}

local option_item_value_mt= {
	__index= {
		create_actors= function(self, name, height)
			self.name= name
			self.zoom= 1
			self.width= SCREEN_WIDTH
			self.prev_index= 1
			self.translation_section= "OptionNames"
			return Def.ActorFrame{
				Name= name, InitCommand= function(subself)
					self.container= subself
					self.text= subself:GetChild("text")
					self.value= subself:GetChild("value")
					self:lose_focus()
				end,
				Def.Quad{
					Name= "example", InitCommand= function(subself)
						self.value_example= subself
						subself:visible(false):horizalign(left)
					end
				},
				normal_text("text", "", nil, nil, nil, nil, nil, left),
				normal_text("value", "", nil, nil, nil, nil, nil, right),
			}
		end,
		set_geo= function(self, width, height, zoom)
			self.width= width
			self.height= height
			self.zoom= zoom
			self.text:zoom(zoom):x(-width/2)
			self.value:zoom(zoom):x(width/2)
			self.value_example:x(width/2 + 4):setsize(height * 2, height)
		end,
		set_text_colors= function(self, main, stroke)
			self.text:diffuse(main):strokecolor(stroke)
			self.value:diffuse(main):strokecolor(stroke)
		end,
		transform= option_item_mt.__index.transform,
		set= function(self, info)
			self.info= info
			if info then
				self.text:zoom(self.zoom)
					:settext(get_string_wrapper(self.translation_section, info.text))
				self.value:zoom(self.zoom)
					:settext(get_string_wrapper(self.translation_section, info.value))
				local ex_color= is_color_string(info.value)
				if ex_color then
					self.value_example:diffuse(ex_color):visible(true)
				else
					self.value_example:visible(false)
				end
				local twidth= self.text:GetZoomedWidth()
				local vwidth= self.value:GetZoomedWidth()
				if twidth + vwidth + 16 > self.width then
					if vwidth > 0 then
						-- w1 * z1 + w2 * z2 + 16 = w3
						-- z1 = z2
						-- z1 * (w1 + w2) + 16 = w3
						-- z1 * (w1 + w2) = w3 - 16
						-- z1 = (w3 - 16) / (w1 + w2)
						local z= (self.width - 16) / (twidth + vwidth)
						self.text:zoomx(z)
						self.value:zoomx(z)
					else
						width_limit_text(self.text, self.width, self.zoom)
					end
				end
			else
				self.text:settext("")
				self.value:settext("")
				self.value_example:visible(false)
			end
		end,
		get_cursor_fit= function(self)
			local ret= {0, 0, 0, self.height + 4}
			if self.text:GetText() ~= "" then
				ret[1]= self.text:GetX()
				ret[3]= self.text:GetWidth()
			end
			if self.value:GetText() ~= "" then
				if ret[3] > 0 then
					ret[3]= self.value:GetX() - self.text:GetX()
				else
					ret[1]= -self.value:GetWidth()
					ret[3]= self.value:GetX()
				end
			end
			if ret[1] ~= 0 then ret[1]= ret[1] - 2 end
			ret[3]= ret[3] + 4
			return ret
		end,
		set_underline_color= noop_nil,
		set_underline= noop_nil,
		gain_focus= noop_nil,
		lose_focus= noop_nil,
}}

option_item_sector_mt= {
	__index= {
		create_actors= function(self, name)
			self.name= name
			self.zoom= 1
			self.prev_index= 1
			self.translation_section= "OptionNames"
			local frame_parts= {
				InitCommand= function(subself)
					self.frame_cont= subself
				end,
			}
			local colors= {
				{1, 1, 1, 1},
				{1, 0, 1, 1},
				{1, 1, 0, 1},
				{0, 1, 1, 1},
			}
			for qi, part_name in ipairs{"top_quad", "bottom_quad", "left_quad", "right_quad"} do
				frame_parts[#frame_parts+1]= Def.Quad{
					InitCommand= function(subself)
						subself:diffuse(colors[qi])
						self[part_name]= subself
					end
				}
			end
			local parts= {
				Name= name, InitCommand= function(subself)
					self.container= subself
					self:lose_focus()
				end,
				Def.ActorFrame(frame_parts)
			}
			parts[#parts+1]= Def.BitmapText{
				Font= FontChoiceBig, InitCommand= function(subself)
					subself:diffuse{1, 1, 1, 1}
					self.text= subself
				end
			}
			return Def.ActorFrame(parts)
		end,
		set_geo= function(self, width, height, zoom, square_size)
			local thick= 2
			local hthick= thick / 2
			self.width= width
			self.height= height
			self.square_size= square_size
			self.top_quad:setsize(width-thick, thick):xy(0, -height/2 + thick)
			self.bottom_quad:setsize(width-thick, thick):xy(0, height/2 - thick)
			self.left_quad:setsize(thick, height-thick):xy(-width/2 + thick, 0)
			self.right_quad:setsize(thick, height-thick):xy(width/2 - thick, 0)
		end,
		set_underline_color= noop_nil,
		set_text_colors= function(self, main, stroke)
			self.text:diffuse(main):strokecolor(stroke)
		end,
		transform= function(self, item_index, num_items, is_focus)
			local x_items= self.square_size
			local pos= item_index - 1
			local xpos= pos % x_items
			local ypos= math.floor(pos / x_items)
			self.container:stoptweening():linear(.1)
				:xy((xpos+.5) * self.width, (ypos+.5) * self.height)
		end,
		set= function(self, info)
			self.info = info
			if info then
				self.container:hibernate(0)
				self:set_text(info.text)
			else
				self.container:hibernate(math.huge)
			end
		end,
		set_underline= noop_nil,
		set_text= function(self, t)
			self.text:settext(get_string_wrapper(self.translation_section, t))
			width_limit_text(self.text, self.width, self.zoom)
		end,
		get_cursor_fit= function(self)
			return {0, 0, self.width, self.height}
		end,
		set_frame_color= function(self, color)
			for quad in ivalues{self.top_quad, self.bottom_quad, self.left_quad, self.right_quad} do
				quad:diffuse(color)
			end
		end,
		gain_focus= function(self)
			self.frame_cont:stoptweening():linear(.1):zoom(1)
		end,
		lose_focus= function(self)
			self.frame_cont:stoptweening():linear(.1):zoom(1)
		end,
}}

option_display_mt= {
	__index= {
		create_actors= function(
				self, name, x, y, display_height, el_width, el_height, el_zoom,
				no_heading, no_display, style)
			if type(style) == "boolean" then
				lua.ReportScriptError("Menu on this screen needs to be updated, it is sending the option_display_mt a bool style.")
			end
			local el_count= 1
			if not no_heading then
				display_height= display_height - el_height
			end
			if not no_display then
				display_height= display_height - el_height
			end
			if not no_heading or not no_display then
				display_height= display_height - (el_height * .5)
			end
			el_count= math.floor(display_height / el_height)
			self.name= name
			self.el_width= el_width or SCREEN_WIDTH
			self.el_height= el_height or line_height
			self.el_zoom= el_zoom or 1
			self.no_heading= no_heading
			self.no_display= no_display
			self.translation_section= "OptionNames"
			self.style= style
			local args= {
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					if not self.no_heading then
						self.heading= subself:GetChild("heading")
					end
					if not self.no_display then
						self.display= subself:GetChild("display")
					end
					self:regeo_items()
				end,
			}
			local next_y= 0
			if not no_heading then
				args[#args+1]= normal_text("heading", "", nil, fetch_color("stroke"), 0, 0, self.el_zoom)
				next_y= next_y + self.el_height
			end
			if not no_display then
				args[#args+1]= normal_text("display", "", nil, fetch_color("stroke"), 0, next_y, self.el_zoom)
				next_y= next_y + self.el_height
			end
			if (not no_heading) or (not no_display) then
				next_y= next_y + self.el_height * .5
			end
			self.sick_wheel= setmetatable({disable_wrapping= true}, sick_wheel_mt)
			if style == "value" then
				args[#args+1]= self.sick_wheel:create_actors(
					"wheel", el_count, option_item_value_mt, 0, next_y)
			elseif style == "sector" then
				self.height= display_height
				self.width= el_width
				args[#args+1]= self.sick_wheel:create_actors(
					"wheel", el_count, option_item_sector_mt, 0, next_y)
			else
				args[#args+1]= self.sick_wheel:create_actors(
					"wheel", el_count, option_item_mt, 0, next_y)
			end
			return Def.ActorFrame(args)
		end,
		set_underline_color= function(self, color)
			for i, item in ipairs(self.sick_wheel.items) do
				item:set_underline_color(color)
			end
		end,
		set_text_colors= function(self, main, stroke)
			local function set_one(one)
				one:diffuse(main):strokecolor(stroke)
			end
			if not self.no_heading then
				set_one(self.heading)
			end
			if not self.no_display then
				set_one(self.display)
			end
			for i, item in ipairs(self.sick_wheel.items) do
				item:set_text_colors(main, stroke)
			end
		end,
		set_translation_section= function(self, section)
			self.translation_section= section
			for i= 1, #self.sick_wheel.items do
				self.sick_wheel.items[i].translation_section= section
			end
		end,
		set_el_geo= function(self, width, height, zoom)
			self.el_width= width or self.el_width
			self.el_height= height or self.el_height
			self.el_zoom= zoom or self.el_zoom
			self:regeo_items()
		end,
		regeo_items= function(self)
			for i, item in ipairs(self.sick_wheel.items) do
				item:set_geo(self.el_width, self.el_height, self.el_zoom, self.square_size)
			end
		end,
		set_heading= function(self, h)
			if not self.no_heading then
				self.heading:settext(get_string_wrapper(self.translation_section, h))
				width_limit_text(self.heading, self.el_width, self.el_zoom)
			end
		end,
		set_display= function(self, d)
			if not self.no_display then
				self.display:settext(d)
				width_limit_text(self.display, self.el_width, self.el_zoom)
			end
		end,
		set_info_set= function(self, info, pos)
			if self.style == "sector" then
				local num_items= math.min(#self.sick_wheel.items, #info)
				self.sick_wheel.fake_num_items= num_items
				self.square_size= math.ceil(math.sqrt(num_items))
				self.rows= math.ceil(num_items / self.square_size)
				self.el_width= self.width / self.square_size
				self.el_height= self.height / self.rows
				self:regeo_items()
			end
			self.sick_wheel:set_info_set(info, pos or 1)
			self:unhide()
		end,
		set_element_info= function(self, element, info)
			self.sick_wheel:set_element_info(element, info)
		end,
		get_element= function(self, element)
			return self.sick_wheel:get_items_by_info_index(element)[1]
		end,
		scroll= function(self, pos)
			self.sick_wheel:scroll_to_pos(pos)
		end,
		hide= function(self) self.hidden= true self.container:diffusealpha(0) end,
		unhide= function(self) self.hidden= false self.container:diffusealpha(1) end,
		lose_focus_items= function(self)
			for i, item in ipairs(self.sick_wheel.items) do
				item:lose_focus()
			end
		end,
}}

function up_element()
	return {text= "&leftarrow;"}
end

function persist_element()
	return {text= "Set Persistent"}
end

function unpersist_element()
	return {text= "Unset Persistent"}
end

function persist_value_text(value)
	return get_string_wrapper("OptionNames", "persist_value") .. tostring(value)
end
function persist_value_element(value)
	return {text= persist_value_text(value)}
end

option_set_general_mt= {
	__index= {
		set_player_info= function(self, player_number)
			self.player_number= player_number
		end,
		set_display= function(self, display)
			self.display= display
			display:set_info_set(self.info_set, self.cursor_pos)
			self:set_status()
		end,
		set_status= function() end, -- This is meant to be overridden.
		can_exit= function(self)
			return self.cursor_pos == 1
		end,
		get_cursor_element= function(self)
			if self.display then
				return self.display:get_element(self.cursor_pos)
			else
				lua.ReportScriptError("menu has no display to fetch cursor element from.")
				return nil
			end
		end,
		update_el_text= function(self, pos, text)
			self.info_set[pos].text= text
			if self.display then
				self.display:set_element_info(pos, self.info_set[pos])
			end
		end,
		update_el_underline= function(self, pos, underline)
			self.info_set[pos].underline= underline
			if self.display then
				self.display:set_element_info(pos, self.info_set[pos])
			end
		end,
		scroll_to_pos= function(self, pos)
			self.cursor_pos= ((pos-1) % #self.info_set) + 1
			self.display:scroll(self.cursor_pos)
		end,
		interpret_code= function(self, code)
			-- Protect against other code changing cursor_pos to an element that
			-- isn't visible.
			local function unfocus_cursor(self)
				local prev_el= self:get_cursor_element()
				if prev_el then
					prev_el:lose_focus()
				end
			end
			local funs= {
				MenuLeft= function(self)
					unfocus_cursor(self)
					if self.cursor_pos > 1 then
						self.cursor_pos= self.cursor_pos - 1
					else
						self.cursor_pos= #self.info_set
					end
					self.display:scroll(self.cursor_pos)
					self:get_cursor_element():gain_focus()
					return true
				end,
				MenuRight= function(self)
					unfocus_cursor(self)
					if self.cursor_pos < #self.info_set then
						self.cursor_pos= self.cursor_pos + 1
					else
						self.cursor_pos= 1
					end
					self.display:scroll(self.cursor_pos)
					self:get_cursor_element():gain_focus()
					return true
				end,
				Start= function(self)
					if self.info_set[self.cursor_pos].text == up_element().text then
						-- This position is the "up" element that moves the
						-- cursor back up the options tree.
						return false
					end
					if self.interpret_start then
						local menu_ret= {self:interpret_start()}
						if self.scroll_to_move_on_start then
							local pos_diff= 1 - self.cursor_pos
							self.cursor_pos= 1
							self.display:scroll(self.cursor_pos)
						end
						return unpack(menu_ret)
					else
						return false
					end
				end,
				Select= function(self)
					self.cursor_pos= 1
					self.display:scroll(self.cursor_pos)
					return true
				end
			}
			local function square_adjust_pos(pos)
				if pos > 0 and pos <= #self.info_set then return pos end
				local rect_size= self.display.rows * self.display.square_size
				if pos > #self.info_set then
					pos= pos - rect_size
					if pos <= 0 then
						pos= pos + self.display.square_size
					end
					return pos
				end
				pos= pos + rect_size
				if pos > #self.info_set then
					return pos - self.display.square_size
				end
				return pos
			end
			if self.display.style == "sector" then
				funs.MenuUp= function(self)
					self:get_cursor_element():lose_focus()
					self.cursor_pos= square_adjust_pos(self.cursor_pos - self.display.square_size)
					self:get_cursor_element():gain_focus()
				end
				funs.MenuDown= function(self)
					self:get_cursor_element():lose_focus()
					self.cursor_pos= square_adjust_pos(self.cursor_pos + self.display.square_size)
					self:get_cursor_element():gain_focus()
				end
			else
				funs.MenuUp= funs.MenuLeft
				funs.MenuDown= funs.MenuRight
			end
			if funs[code] then return funs[code](self) end
			return false
		end
}}

options_sets= {}

-- MENU ENTRIES STRUCTURE
-- {}
--   name= string -- Name for the entry
--   args= {} -- Args to return to options_menu_mt to construct the new menu
--     meta= {} -- metatable for the submenu
--     args= {} -- extra args for the initialize function of the metatable
options_sets.menu= {
	__index= {
		initialize= function(self, player_number, initializer_args, no_up, up_text)
			self.init_args= initializer_args
			self.player_number= player_number
			self.no_up= no_up
			self.up_text= up_text
			self:recall_init()
		end,
		recall_init= function(self)
			self.menu_data= self.init_args
			if type(self.init_args) == "function" then
				self.menu_data= self.init_args(self.player_number)
			end
			self.name= self.menu_data.name or ""
			self.recall_init_on_pop= self.menu_data.recall_init_on_pop
			self.special_handler= self.menu_data.special_handler
			self.destructor= self.menu_data.destructor
			self:set_status()
			self:reset_info()
		end,
		reset_info= function(self)
			local old_option_name= ""
			if self.cursor_pos then
				old_option_name= self.info_set[self.cursor_pos].text
			end
			self.info_set= {}
			self.shown_data= {}
			if not self.no_up then
				if self.up_text then
					self.info_set[#self.info_set+1]= {text= self.up_text}
				else
					self.info_set[#self.info_set+1]= up_element()
				end
			end
			self.cursor_pos= 1
			if self.player_number then
				self.curr_level= ops_level(self.player_number)
			end
			self:update_info(self.menu_data)
			if old_option_name ~= "" then
				for pos= 1, #self.info_set do
					if self.info_set[pos].text == old_option_name then
						self.cursor_pos= pos
					end
				end
			end
			if self.display then
				self.display:set_info_set(self.info_set)
				self:scroll_to_pos(self.cursor_pos)
				for i, item in ipairs(self.display.sick_wheel.items) do
					item.container:finishtweening()
				end
			end
		end,
		id_plus_up= function(self, id)
			if self.no_up then return id end
			return id + 1
		end,
		id_minus_up= function(self, id)
			if self.no_up then return id end
			return id - 1
		end,
		update_info= function(self, new_menu_data)
			local next_shown= 1
			for i, data in ipairs(new_menu_data) do
				local show= true
				if self.player_number and data.level then
					if data.level > 0 then
						show= data.level <= self.curr_level
					else
						show= -data.level == self.curr_level
					end
				end
				if data.req_func then
					show= show and data.req_func(self.player_number)
				end
				if show then
					local disp_slot= self:id_plus_up(next_shown)
					self.shown_data[next_shown]= data
					local disp_text= data.text or data.name
					local underline= data.underline
					if type(underline) == "function" then
						underline= underline(self.player_number)
					end
					if self.info_set[disp_slot] then
						self.info_set[disp_slot].text= disp_text
						self.info_set[disp_slot].underline= underline
						self.info_set[disp_slot].value= data.value
					else
						self.info_set[disp_slot]= {text= disp_text, underline= underline, value= data.value}
					end
					if data.args and type(data.args) == "table" then
						data.args.name= data.name
					end
					if self.display then
						self.display:set_element_info(
							disp_slot, self.info_set[disp_slot])
					end
					next_shown= next_shown + 1
				end
			end
			while #self.shown_data >= next_shown do
				local index= #self.shown_data
				self.shown_data[index]= nil
				self.info_set[self:id_plus_up(index)]= nil
				if self.display then
					self.display:set_element_info(self:id_plus_up(index), nil)
				end
			end
			self.menu_data= new_menu_data
		end,
		recheck_levels= function(self)
			self:reset_info()
		end,
		set_status= function(self)
			if self.display then
				self.display:set_heading(self.name or "")
				self.display:set_display(self.menu_data.status or "")
			end
		end,
		update= function(self)
			if GAMESTATE:IsPlayerEnabled(self.player_number) then
				self.display:unhide()
			else
				self.display:hide()
			end
		end,
		interpret_start= function(self)
			local data= self.shown_data[self:id_minus_up(self.cursor_pos)]
			if self.special_handler then
				local handler_ret= self.special_handler(self, data)
				if handler_ret.recall_init then
					self:recall_init()
					return true
				elseif handler_ret.ret_data then
					return unpack(handler_ret.ret_data)
				else
					return false
				end
			else
				if data then
					return true, data
				else
					return false
				end
			end
		end,
		get_item_name= function(self, pos)
			pos= self:id_minus_up(pos or self.cursor_pos)
			if self.shown_data[pos] then
				return self.shown_data[pos].name
			end
			return ""
		end
}}

options_sets.special_functions= {
	-- element_set structure:
	-- element_set= {}
	--   {} -- info for one element
	--     name -- string for naming the element.
	--     init(player_number) -- called to init the element, returns bool.
	--     set(player_number) -- called when the element is set.
	--     unset(player_number) -- called when the element is unset.
	__index= {
		-- shared_display special cases added so this can be reused on evaluation
		-- for editing flags
		initialize= function(self, player_number, extra, shared_display)
			self.name= extra.name
			self.cursor_pos= 1
			self.player_number= player_number
			self.element_set= extra.eles
			self.shared_display= shared_display
			self.disallow_unset= extra.disallow_unset
			self.reeval_init_on_change= extra.reeval_init_on_change
			if shared_display then
				self:reset_info()
			else
				self.info_set= {up_element()}
				for i, el in ipairs(self.element_set) do
					self.info_set[#self.info_set+1]= {
						text= el.name, underline= el.init(player_number)}
				end
			end
		end,
		get_item_name= function(self, pos)
			pos= pos or self.cursor_pos-1
			if self.element_set[pos] then
				return self.element_set[pos].name
			end
			return ""
		end,
		reset_info= function(self)
			self.cursor_pos= 1
			self.real_info_set= {{text= "Exit Menu"}}
			for i, el in ipairs(self.element_set) do
				self.real_info_set[#self.real_info_set+1]= {
					text= el.name, underline= el.init(self.player_number)}
			end
			self.info_set= DeepCopy(self.real_info_set)
			if self.display then
				self.display:set_info_set(self.info_set)
			end
		end,
		update= function(self)
			if GAMESTATE:IsPlayerEnabled(self.player_number) then
				self.display:unhide()
			else
				self.display:hide()
			end
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display("")
		end,
		interpret_start= function(self)
			if self.shared_display and self.cursor_pos == 1 then
				return true, true
			end
			local ele_pos= self.cursor_pos - 1
			local ele_info= self.element_set[ele_pos]
			if ele_info then
				local is_info= self.info_set[self.cursor_pos]
				if is_info.underline and not self.disallow_unset then
					ele_info.unset(self.player_number)
					self:update_el_underline(self.cursor_pos, false)
				else
					ele_info.set(self.player_number)
					self:update_el_underline(self.cursor_pos, true)
				end
				if self.reeval_init_on_change then
					for i, el in ipairs(self.element_set) do
						local info= self.info_set[i+1]
						info.underline= el.init(self.player_number)
						self:update_el_underline(i+1, info.underline)
					end
				end
				return true
			else
				return false
			end
		end
}}

options_sets.mutually_exclusive_special_functions= {
	__index= {
		initialize= options_sets.special_functions.__index.initialize,
		set_status= options_sets.special_functions.__index.set_status,
		interpret_start= function(self)
			local ret= options_sets.special_functions.__index.interpret_start(self)
			if ret then
				for i, info in ipairs(self.info_set) do
					if i ~= self.cursor_pos then
						if info.underline then
							self:update_el_underline(i, false)
						end
					end
				end
			end
			return ret
		end
}}

options_sets.boolean_option= {
	__index= {
		initialize= function(self, pn, extra)
			self.name= extra.name
			self.player_number= pn
			self.cursor_pos= 1
			self.get= extra.get
			self.set= extra.set
			local curr= extra.get(pn)
			self.info_set= {
				up_element(),
				{text= extra.true_text, underline= curr},
				{text= extra.false_text, underline= not curr}}
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display("")
		end,
		interpret_start= function(self)
			if self.cursor_pos == 1 then return false end
			local curr= self.cursor_pos == 2
			self.set(self.player_number, curr)
			self:update_el_underline(2, curr)
			self:update_el_underline(3, not curr)
			return true
		end
}}

local function find_scale_for_number(num, min_scale)
	local cv= math.round(num /10^min_scale) * 10^min_scale
	local prec= math.max(0, -min_scale)
	local cs= ("%." .. prec .. "f"):format(cv)
	local ret_scale= 0
	for n= 1, #cs do
		if cs:sub(-n, -n) ~= "0" then
			ret_scale= math.min(ret_scale, min_scale + (n-1))
		end
	end
	return ret_scale, cv
end

options_sets.adjustable_float= {
	__index= {
		initialize= function(self, player_number, extra)
			local function check_member(member_name)
				assert(self[member_name],
							 "adjustable_float '" .. self.name .. "' warning: " ..
								 member_name .. " not provided.")
			end
			local function to_text_default(player_number, value)
				if value == -0 then return "0" end
				return tostring(value)
			end
			--Trace("adjustable_float extra:")
			--rec_print_table(extra)
			assert(extra, "adjustable_float passed a nil extra table.")
			self.name= extra.name
			self.persist_name= extra.persist_name or self.name
			self.cursor_pos= 1
			self.player_number= player_number
			self.reset_value= extra.reset_value or 0
			self.min_scale= extra.min_scale
			check_member("min_scale")
			self.scale= extra.scale or 0
			self.current_value= extra.initial_value(player_number) or 0
			if self.current_value ~= 0 then
				self.min_scale_used, self.current_value=
					find_scale_for_number(self.current_value, self.min_scale)
			end
			self.min_scale_used= math.min(self.scale, self.min_scale_used or 0)
			self.max_scale= extra.max_scale
			check_member("max_scale")
			self.set= extra.set
			check_member("set")
			self.val_min= extra.val_min
			self.val_max= extra.val_max
			self.val_to_text= extra.val_to_text or to_text_default
			self.scale_to_text= extra.scale_to_text or to_text_default
			local scale_text= get_string_wrapper("OptionNames", "scale")
			self.pi_text= get_string_wrapper("OptionNames", "pi")
			self.info_set= {
				up_element(),
				{text= "+"..self.scale_to_text(self.player_number, 10^self.scale)},
				{text= "-"..self.scale_to_text(self.player_number, 10^self.scale)},
				{text= scale_text.."*10"}, {text= scale_text.."/10"},
				{text= "Round"}, {text= "Reset"}}
			self.menu_functions= {
				function() return false end, -- up element
				function() -- increment
					self:set_new_val(self.current_value + 10^self.scale)
					return true
				end,
				function() -- decrement
					self:set_new_val(self.current_value - 10^self.scale)
					return true
				end,
				function() -- scale up
					self:set_new_scale(self.scale + 1)
					return true
				end,
				function() -- scale down
					self:set_new_scale(self.scale - 1)
					return true
				end,
				function() -- round
					self:set_new_val(math.round(self.current_value))
					return true
				end,
				function() -- reset
					local new_scale, new_value=
						find_scale_for_number(self.reset_value, self.min_scale)
					self:set_new_scale(new_scale)
					self:set_new_val(new_value)
					return true
				end,
			}
			if extra.is_angle then
				-- insert the pi option before the Round option.
				local pi_pos= #self.info_set-1
				local function pi_function()
					self.pi_exp= not self.pi_exp
					if self.pi_exp then
						self:update_el_text(6, "/"..self.pi_text)
					else
						self:update_el_text(6, "*"..self.pi_text)
					end
					self:set_new_val(self.current_value)
					return true
				end
				table.insert(self.info_set, pi_pos, {text= "*"..self.pi_text})
				table.insert(self.menu_functions, pi_pos, pi_function)
			end
			if extra.can_persist and player_using_profile(self.player_number) then
				self.persist_el_pos= #self.info_set+1
				self.info_set[self.persist_el_pos]= persist_element()
				self.menu_functions[#self.menu_functions+1]= function()
					local new_val= self:cooked_val(self.current_value)
					cons_players[self.player_number]:persist_mod(
						self.persist_name, new_val, extra.persist_type)
					self:update_el_text(
						self.persist_val_pos, persist_value_text(new_val))
					return true
				end
				self.info_set[#self.info_set+1]= unpersist_element()
				self.menu_functions[#self.menu_functions+1]= function()
					cons_players[self.player_number]:unpersist_mod(
						self.persist_name, extra.persist_type)
					self:update_el_text(
						self.persist_val_pos, persist_value_text(nil))
					return true
				end
				self.persist_val_pos= #self.info_set+1
				self.info_set[#self.info_set+1]= persist_value_element(
					cons_players[self.player_number]:get_persist_mod_value(
						self.persist_name, extra.persist_type))
				self.menu_functions[#self.menu_functions+1]= noop_true
			end
		end,
		interpret_start= function(self)
			if self.menu_functions[self.cursor_pos] then
				return self.menu_functions[self.cursor_pos]()
			end
			return false
		end,
		set_status= function(self)
			if self.display then
				self.display:set_heading(self.name)
				local val_text=
					self.val_to_text(self.player_number, self.current_value)
				if self.pi_exp then
					val_text= val_text .. "*" .. self.pi_text
				end
				self.display:set_display(val_text)
			end
		end,
		cooked_val= function(self, nval)
			if self.pi_exp then return nval * math.pi end
			return nval
		end,
		set_new_val= function(self, nval)
			local raise= 10^-self.min_scale_used
			local lower= 10^self.min_scale_used
			local rounded_val= math.round(nval * raise) * lower
			if self.val_max and rounded_val > self.val_max then
				rounded_val= self.val_max
			end
			if self.val_min and rounded_val < self.val_min then
				rounded_val= self.val_min
			end
			self.current_value= rounded_val
			rounded_val= self:cooked_val(rounded_val)
			self.set(self.player_number, rounded_val)
			self:set_status()
		end,
		set_new_scale= function(self, nscale)
			if nscale >= self.min_scale and nscale <= self.max_scale then
				self.min_scale_used= math.min(nscale, self.min_scale_used)
				self.scale= nscale
				self:update_el_text(2, "+" .. self.scale_to_text(self.player_number, 10^nscale))
				self:update_el_text(3, "-" .. self.scale_to_text(self.player_number, 10^nscale))
			end
		end
}}

options_sets.enum_option= {
	__index= {
		initialize= function(self, player_number, extra)
			self.name= extra.name
			self.player_number= player_number
			self.enum_vals= {}
			self.info_set= { up_element() }
			self.cursor_pos= 1
			self.get= extra.get
			self.set= extra.set
			self.fake_enum= extra.fake_enum
			self.ops_obj= extra.obj_get(player_number)
			self.can_persist= extra.can_persist
			self.persist_type= extra.persist_type
			self.persist_name= extra.persist_name or self.name
			local cv= self:get_val()
			for i, v in ipairs(extra.enum) do
				self.enum_vals[#self.enum_vals+1]= v
				self.info_set[#self.info_set+1]= {
					text= self:short_string(v), underline= v == cv}
			end
			if self.can_persist then
				self.set_persist_pos= #self.info_set+1
				self.info_set[self.set_persist_pos]= persist_element()
				self.unset_persist_pos= #self.info_set+1
				self.info_set[self.unset_persist_pos]= unpersist_element()
				self.persist_val_pos= #self.info_set+1
				local persist_value= cons_players[self.player_number]:
					get_persist_mod_value(self.persist_name, self.persist_type)
				if persist_value then
					self.info_set[self.persist_val_pos]= persist_value_element(
						ToEnumShortString(persist_value))
				else
					self.info_set[self.persist_val_pos]= persist_value_element(nil)
				end
			end
		end,
		short_string= function(self, val)
			if self.fake_enum then
				return val
			else
				return ToEnumShortString(val)
			end
		end,
		interpret_start= function(self)
			if self.can_persist then
				if self.cursor_pos == self.set_persist_pos then
					local chosen= 0
					for i= 1, #self.info_set do
						if self.info_set[i].underline then
							chosen= i-1
						end
					end
					if self.enum_vals[chosen] then
						cons_players[self.player_number]:persist_mod(
							self.persist_name, self.enum_vals[chosen], self.persist_type)
						self:update_el_text(
							self.persist_val_pos, persist_value_text(
								ToEnumShortString(self.enum_vals[chosen])))
					end
					return true
				elseif self.cursor_pos == self.unset_persist_pos then
						cons_players[self.player_number]:unpersist_mod(
							self.persist_name, self.persist_type)
						self:update_el_text(
							self.persist_val_pos, persist_value_text(nil))
					return true
				elseif self.cursor_pos == #self.info_set then
					return true
				end
			end
			if self.cursor_pos > 1 then
				for i, info in ipairs(self.info_set) do
					if info.underline then
						self:update_el_underline(i, false)
					end
				end
				self:update_el_underline(self.cursor_pos, true)
				if self.ops_obj then
					self.set(self.ops_obj, self.enum_vals[self.cursor_pos-1])
				else
					self.set(self.enum_vals[self.cursor_pos-1])
				end
				self.display:set_display(self:short_string(self:get_val()))
				return true
			else
				return false
			end
		end,
		get_val= function(self)
			if self.ops_obj then
				return self.get(self.ops_obj)
			else
				return self.get()
			end
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display(self:short_string(self:get_val()))
		end
}}

options_sets.extensible_boolean_menu= {
	__index= {
		initialize= function(self, pn, extra)
			self.name= extra.name
			self.player_number= pn
			self.cursor_pos= 1
			self.bool_table= extra.values
			self.true_text= extra.true_text
			self.false_text= extra.false_text
			self.default_for_new= extra.default_for_new
			self.info_set= {
				up_element(), {text= "Add Value"}, {text= "Remove Value"}}
			for i= 1, #self.bool_table do
				table.insert(
					self.info_set, i+1, {text= self:val_text(self.bool_table[i])})
			end
		end,
		val_text= function(self, val)
			if val then return self.true_text end
			return self.false_text
		end,
		add_value= function(self)
			local insert_pos= #self.info_set - 1
			table.insert(self.bool_table, insert_pos-1, self.default_for_new)
			table.insert(self.info_set, insert_pos,
									 {text= self:val_text(self.default_for_new)})
			self.cursor_pos= self.cursor_pos + 1
			self:update_from_pos(insert_pos-1)
		end,
		remove_value= function(self)
			local remove_pos= #self.info_set - 2
			table.remove(self.bool_table, remove_pos-1)
			table.remove(self.info_set, remove_pos)
			self.display:set_element_info(#self.info_set+1, nil)
			self.cursor_pos= self.cursor_pos - 1
			self:update_from_pos(remove_pos-1)
		end,
		update_from_pos= function(self, pos)
			for i= pos, #self.info_set do
				self.display:set_element_info(i, self.info_set[i])
			end
			self:scroll_to_pos(self.cursor_pos)
		end,
		interpret_start= function(self)
			if self.cursor_pos == #self.info_set then
				if #self.bool_table > 1 then
					self:remove_value()
				end
			elseif self.cursor_pos == #self.info_set-1 then
				self:add_value()
			elseif self.cursor_pos > 1 then
				local bi= self.cursor_pos - 1
				self.bool_table[bi]= not self.bool_table[bi]
				self:update_el_text(self.cursor_pos, self:val_text(self.bool_table[bi]))
			else
				return false
			end
			return true
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display("")
		end
}}

options_sets.shown_noteskins= {
	__index= {
		initialize= function(self, pn, extra)
			self.player_number= pn
			self.name= extra.name
			if newskin_available() then
				self.all_noteskin_names= NEWSKIN:get_all_skin_names()
			else
				self.all_noteskin_names= NOTESKIN:GetNoteSkinNames()
			end
			self.config_slot= pn_to_profile_slot(pn)
			self.shown_config= shown_noteskins:get_data(self.config_slot)
			self.info_set= {up_element()}
			for i, skin_name in ipairs(self.all_noteskin_names) do
				local show= not self.shown_config[skin_name]
				self.info_set[#self.info_set+1]= {text= skin_name, underline= show}
			end
			self.cursor_pos= 1
		end,
		destructor= function(self)
			shown_noteskins:save(self.config_slot)
		end,
		set_status= function(self)
			self.display:set_heading(self.name)
			self.display:set_display("")
		end,
		interpret_start= function(self)
			local info= self.info_set[self.cursor_pos]
			if self.cursor_pos == 1 then return false end
			shown_noteskins:set_dirty(self.config_slot)
			local skin_name= info.text
			self.shown_config[skin_name]= not self.shown_config[skin_name]
			info.underline= not self.shown_config[skin_name]
			self:update_el_underline(self.cursor_pos, info.underline)
			return true
		end,
}}

function set_option_set_metatables()
	for k, set in pairs(options_sets) do
		setmetatable(set.__index, option_set_general_mt)
	end
end
set_option_set_metatables()

-- This exists to hand to menus that pass out of view but still exist.
local fake_display= {is_fake= true}
for k, v in pairs(option_display_mt.__index) do
	fake_display[k]= function() end
end

menu_stack_mt= {
	__index= {
		create_actors= function(
				self, name, x, y, width, height, player_number, num_displays,
				el_height, zoom, no_heading, no_display, style)
			num_displays= num_displays or 2
			self.name= name
			self.player_number= player_number
			self.options_set_stack= {}
			self.zoom= zoom or 1
			self.el_height= el_height or line_height
			local pcolor= pn_to_color(player_number)
			local args= {
				Name= name, InitCommand= function(subself)
					subself:xy(x, y)
					self.container= subself
					self.cursor:refit(nil, nil, 20, self.el_height)
					for i, disp in ipairs(self.displays) do
						disp:set_underline_color(pcolor)
					end
				end
			}
			self.displays= {}
			for i= 1, num_displays do
				self.displays[#self.displays+1]= setmetatable({}, option_display_mt)
			end
			local sep= width / #self.displays
			if #self.displays == 1 then sep= 0 end
			local off= sep / 2
			self.cursor= setmetatable({}, cursor_mt)
			local disp_el_width_limit= (width / #self.displays) - 8
			for i, disp in ipairs(self.displays) do
				args[#args+1]= disp:create_actors(
					"disp" .. i, off+sep * (i-1), 0,
					height, disp_el_width_limit, self.el_height, self.zoom, no_heading, no_display, style)
			end
			args[#args+1]= self.cursor:create_actors(
				"cursor", sep, 0, 1, pcolor, fetch_color("player.hilight"),
				button_list_for_menu_cursor())
			return Def.ActorFrame(args)
		end,
		assign_displays= function(self, start)
			local oss= self.options_set_stack
			for i= #oss, 1, -1 do
				oss[i]:set_display(self.displays[start] or fake_display)
				start= start - 1
			end
		end,
		lose_focus_top_display= function(self)
			local top_display= math.min(#self.displays, #self.options_set_stack)
			if self.displays[top_display] then
				self.displays[top_display]:lose_focus_items()
			end
		end,
		push_display_stack= function(self)
			local use_display= math.min(#self.displays, #self.options_set_stack+1)
			self:assign_displays(use_display - 1)
			self:hide_unused_displays(use_display)
			return use_display
		end,
		pop_display_stack= function(self)
			local oss= self.options_set_stack
			local use_display= math.min(#self.displays, #oss)
			self:assign_displays(use_display)
			for i= #oss, 1, -1 do
				local curr_set= oss[i]
				if not curr_set.display.is_fake then
					if curr_set.recall_init_on_pop then
						curr_set:recall_init()
					end
					curr_set:recheck_levels()
				end
			end
			self:hide_unused_displays(use_display)
			return use_display
		end,
		hide_unused_displays= function(self, last_used_display)
			for i= last_used_display+1, #self.displays do
				self.displays[i]:hide()
			end
		end,
		push_options_set_stack= function(
				self, new_set_meta, new_set_initializer_args, base_exit, no_up)
			self:lose_focus_top_display()
			local oss= self.options_set_stack
			local use_display= self:push_display_stack()
			local nos= setmetatable({}, new_set_meta)
			oss[#oss+1]= nos
			nos:set_player_info(self.player_number)
			if #oss == 1 then
				nos:initialize(self.player_number, new_set_initializer_args, no_up, base_exit)
			else
				nos:initialize(self.player_number, new_set_initializer_args)
			end
			nos:set_display(self.displays[use_display])
			self:update_cursor_pos()
		end,
		pop_options_set_stack= function(self)
			self:lose_focus_top_display()
			local oss= self.options_set_stack
			if #oss > 0 then
				local former_top= oss[#oss]
				if former_top.destructor then former_top:destructor(self.player_number) end
				oss[#oss]= nil
				self:pop_display_stack()
			end
			self:update_cursor_pos()
		end,
		clear_options_set_stack= function(self)
			while #self.options_set_stack > 0 do
				self:pop_options_set_stack()
			end
		end,
		enter_external_mode= function(self)
			self:hide_unused_displays(self:push_display_stack() - 1)
			self.external_thing= external_thing
		end,
		exit_external_mode= function(self)
			if self.deextern then
				self:deextern(self.player_number)
				self.deextern= nil
			end
			self.external_thing= nil
			local oss= self.options_set_stack
			if #oss > 0 then
				self:pop_display_stack()
			end
			self:update_cursor_pos()
		end,
		hide_disp= function(self)
			for i, disp in ipairs(self.displays) do
				disp:hide()
			end
		end,
		unhide_disp= function(self)
			for i, disp in ipairs(self.displays) do
				disp:unhide()
			end
		end,
		hide= function(self)
			self.hidden= true
			self:hide_disp()
			self.cursor:hide()
		end,
		unhide= function(self)
			self.hidden= false
			self.cursor:unhide()
		end,
		interpret_code= function(self, code)
			if self.external_thing then
				local handled, close= self.external_thing:interpret_code(code)
				if close then
					self:exit_external_mode()
				end
				return handled
			end
			local oss= self.options_set_stack
			local top_set= oss[#oss]
			local handled, new_set_data= top_set:interpret_code(code)
			if handled then
				if new_set_data then
					if new_set_data.meta == "external_interface" then
						self:enter_external_mode()
						new_set_data.extern(self, new_set_data.args, self.player_number)
						self.deextern= new_set_data.deextern
					elseif new_set_data.meta == "execute" then
						new_set_data.execute(self.player_number)
						top_set:recheck_levels()
					else
						local nargs= new_set_data.args
						if new_set_data.exec_args and type(nargs) == "function" then
							nargs= nargs(self.player_number)
						end
						self:push_options_set_stack(new_set_data.meta, nargs)
					end
				end
			else
				if (code == "Start" or code == "Back") and #oss > 1 then
					handled= true
					self:pop_options_set_stack()
				end
			end
			self:update_cursor_pos()
			return handled
		end,
		update_cursor_pos= function(self)
			local tos= self.options_set_stack[#self.options_set_stack]
			if not tos then return end
			local item= tos:get_cursor_element()
			if item then
				item:gain_focus()
				local xmn, xmx, ymn, ymx= rec_calc_actor_extent(item.container)
				local xp, yp= rec_calc_actor_pos(item.container)
				local xs, ys= rec_calc_actor_pos(self.container)
				xp= xp - xs
				yp= yp - ys
				self.cursor:refit(xp, yp, xmx - xmn + 4, ymx - ymn + 4)
			end
		end,
		refit_cursor= function(self, fit)
			self.cursor:refit(fit[1], fit[2], fit[3], fit[4])
		end,
		can_exit_screen= function(self)
			local oss= self.options_set_stack
			local top_set= oss[#oss]
			return #oss <= 1 and (not top_set or top_set:can_exit())
		end,
		top_menu= function(self)
			return self.options_set_stack[#self.options_set_stack]
		end,
		get_cursor_item_name= function(self)
			local top_set= self.options_set_stack[#self.options_set_stack]
			if top_set.get_item_name then
				return top_set:get_item_name()
			end
			return ""
		end
}}

function float_pref_val(valname, level, min_scale, scale, max_scale)
	return {
		name= valname, meta= options_sets.adjustable_float, level= level,
		args= {
			name= valname, min_scale= min_scale, scale= scale, max_scale= max_scale,
			initial_value= function()
				return PREFSMAN:GetPreference(valname)
			end,
			set= function(pn, value)
				PREFSMAN:SetPreference(valname, value)
			end,
	}}
end
