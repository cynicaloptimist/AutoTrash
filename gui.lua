local lib_control = require '__AutoTrash__.lib_control'
local saveVar = lib_control.saveVar --luacheck: ignore
local display_message = lib_control.display_message
local format_number = lib_control.format_number
local format_request = lib_control.format_request
local format_trash = lib_control.format_trash
local convert_to_slider = lib_control.convert_to_slider
local mod_gui = require '__core__/lualib/mod-gui'

local function show_yarm(index)
    if remote.interfaces.YARM and global.settings[index].YARM_old_expando then
        remote.call("YARM", "show_expando", index)
    end
end

local function hide_yarm(index)
    if remote.interfaces.YARM then
        global.settings[index].YARM_old_expando = remote.call("YARM", "hide_expando", index)
    end
end

local GUI = {
    defines = {
        --DONT RENAME, ELSE GUI WONT CLOSE
        mainButton = "at-config-button",
        storage_frame = "at-logistics-storage-frame",
        config_frame = "at-config-frame",


        trash_above_requested = "autotrash_above_requested",
        trash_unrequested = "autotrash_unrequested",
        trash_in_main_network = "autotrash_in_main_network",
        save_button = "autotrash_logistics_apply",
        clear_button = "autotrash_clear",
        clear_option = "autotrash_clear_option",
        set_main_network = "autotrash_set_main_network",
        trash_options = "autotrash_trash_options",
        pause_trash = "autotrash_pause_trash",
        pause_requests = "autotrash_pause_requests",
        store_button = "autotrash_preset_save",
        config_request = "at_config_request",
        config_trash = "at_config_trash",
        config_slider = "at_config_slider",
        config_slider_text = "at_config_slider_text",

        choose_button = "autotrash_item_",
        load_preset = "autotrash_preset_load_",
        delete_preset = "autotrash_preset_delete_"
    },
    on_gui_click = {

    }
}

function GUI.index_from_name(name)
    return tonumber(string.match(name, GUI.defines.choose_button .. "(%d+)"))
end

function GUI.init(player)
    local button_flow = mod_gui.get_button_flow(player)
    if button_flow[GUI.defines.mainButton] then
        return
    end
    if player.force.technologies["character-logistic-slots-1"].researched
    or player.force.technologies["character-logistic-trash-slots-1"].researched then
        local button = button_flow.add{
            type = "sprite-button",
            name = GUI.defines.mainButton,
            style = "auto-trash-sprite-button"
        }
        button.sprite = "autotrash_trash"
    end
end

function GUI.update(player)
    local mainButton = mod_gui.get_button_flow(player)[GUI.defines.mainButton]
    if not mainButton then
        return
    end
    --TODO come up with a graphic that represents trash AND requests being paused
    --mainButton.sprite = "autotrash_logistics_paused"
    if global.settings[player.index].pause_trash then
        mainButton.sprite = "autotrash_trash_paused"
    else
        mainButton.sprite = "autotrash_trash"
    end
    GUI.update_settings(player)
end

function GUI.update_settings(player)
    local frame = mod_gui.get_frame_flow(player)[GUI.defines.config_frame]
    if not frame or not frame.valid then
        return
    end
    frame = frame[GUI.defines.trash_options]
    if not frame or not frame.valid then return end
    local index = player.index
    frame[GUI.defines.trash_unrequested].state = global.settings[index].auto_trash_unrequested
    frame[GUI.defines.trash_above_requested].state = global.settings[index].auto_trash_above_requested
    frame[GUI.defines.trash_in_main_network].state = global.settings[index].auto_trash_in_main_network
    frame[GUI.defines.pause_trash].state = global.settings[index].pause_trash
    frame[GUI.defines.pause_requests].state = global.settings[index].pause_requests
end

function GUI.destroy(player)
    local button_flow = mod_gui.get_button_flow(player)
    if button_flow[GUI.defines.mainButton] then
        button_flow[GUI.defines.mainButton].destroy()
    end
end

function GUI.update_sliders(player_index)
    local left = mod_gui.get_frame_flow(game.get_player(player_index))[GUI.defines.config_frame]
    local slider_flow = left and left.valid and left["at_slider_flow_vertical"]
    if not slider_flow or not slider_flow.valid then
        return
    end
    local visible = global.selected[player_index] or false
    for _, child in pairs(slider_flow.children) do
        child.visible = visible
    end
    if global.selected[player_index] then
        local req = global.config_tmp[player_index].config[global.selected[player_index]]
        slider_flow[GUI.defines.config_request][GUI.defines.config_slider].slider_value = convert_to_slider(req.request)
        slider_flow[GUI.defines.config_request][GUI.defines.config_slider_text].text = format_request(req) or 0
        slider_flow[GUI.defines.config_trash][GUI.defines.config_slider].slider_value = req.trash and convert_to_slider(req.trash) or 42
        slider_flow[GUI.defines.config_trash][GUI.defines.config_slider_text].text = format_trash(req) or "∞"
    end
end

function GUI.create_buttons(player)
    local left = mod_gui.get_frame_flow(player)
    local frame = (left and left.valid) and left[GUI.defines.config_frame]
    if not frame or not frame.valid then
        return
    end

    local scroll_pane = frame["at_config_scroll"]
    scroll_pane = scroll_pane or frame.add{
        type = "scroll-pane",
        name = "at_config_scroll",
    }
    local mod_settings = player.mod_settings
    local display_rows = mod_settings["autotrash_gui_max_rows"].value
    scroll_pane.style.maximal_height = 38 * display_rows + 6

    local ruleset_grid = scroll_pane["at_ruleset_grid"]
    if ruleset_grid and ruleset_grid.valid then
        ruleset_grid.destroy()
    end

    ruleset_grid = frame["at_config_scroll"].add{
        type = "table",
        column_count = mod_settings["autotrash_gui_columns"].value,
        name = "at_ruleset_grid",
        style = "slot_table"
    }

    local player_index = player.index
    local slots = mod_settings["autotrash_slots"].value or player.character.request_slot_count
    for i = 1, slots-1 do
        local req = global["config_tmp"][player_index].config[i]
        local elem_value = req and req.name or nil
        local button_name = GUI.defines.choose_button .. i
        local choose_button = ruleset_grid.add{
            type = "choose-elem-button",
            name = button_name,
            style = "logistic_button_slot",
            elem_type = "item"
        }
        choose_button.elem_value = elem_value
        if global.selected[player_index] == i then
            choose_button.style = "logistic_button_selected_slot"
        end

        local lbl_top = choose_button.add{
            type = "label",
            style = "auto-trash-request-label-top",
            ignored_by_interaction = true,
            caption = " "
        }

        local lbl_bottom = choose_button.add{
            type = "label",
            style = "auto-trash-request-label-bottom",
            ignored_by_interaction = true,
            caption = " "
        }

        if elem_value then
            lbl_top.caption = format_number(format_request(req), true)
            lbl_bottom.caption = format_number(format_trash(req), true)
            --disable popup gui, keeps on_click active
            choose_button.locked = choose_button.name ~=  GUI.defines.choose_button .. tostring(global.selected[player_index])
        end
    end

    local extend_button_flow = ruleset_grid.add{
        type = "flow",
        name = "autotrash-extend-flow",
        direction = "vertical",
        style = "autotrash-extend-flow"
    }
    extend_button_flow.style.left_padding = 0
    extend_button_flow.style.right_padding = 0
    extend_button_flow.style.top_padding = 0
    extend_button_flow.style.bottom_padding = 0
    extend_button_flow.style.vertical_spacing = 0

    local minus = extend_button_flow.add{
        type = "button",
        name = "autotrash-extend-less",
        caption = "-",
        --sprite = "utility/dropdown",
        style = "auto-trash-sprite-button"
    }
    local plus = extend_button_flow.add{
        type = "sprite-button",
        name = "autotrash-extend-more",
        caption = "+",
        --sprite = "utility/add",
        style = "auto-trash-sprite-button"
    }
    minus.style.maximal_height = 16
    minus.style.minimal_width = 16
    minus.style.font = "default-bold"
    plus.style.maximal_height = 16
    plus.style.minimal_width = 16
    plus.style.font = "default-bold"
end

function GUI.open_logistics_frame(player, redraw)
    local left = mod_gui.get_frame_flow(player)
    local frame = left[GUI.defines.config_frame]
    local player_index = player.index
    local storage_frame = left[GUI.defines.storage_frame]

    if frame then
        frame.destroy()
        if storage_frame then
            storage_frame.destroy()
        end
        if not redraw then
            global.selected[player_index] = false
            show_yarm(player_index)
            return
        end
    end

    hide_yarm(player_index)

    log("Selected: " .. serpent.line(global.selected[player_index]))
    frame = left.add{
        type = "frame",
        caption = {"gui-logistic.title"},
        name = GUI.defines.config_frame,
        direction = "vertical"
    }

    GUI.create_buttons(player)

    local slider_vertical_flow = frame.add{
        type = "table",
        name = "at_slider_flow_vertical",
        column_count = 2
    }
    slider_vertical_flow.style.minimal_height = 60
    slider_vertical_flow.add{
        type = "label",
        caption = {"gui-logistic.title-request-short"}
    }
    local slider_flow_request = slider_vertical_flow.add{
        type = "flow",
        name = GUI.defines.config_request,
        direction = "horizontal",
        caption = "TEST"
    }
    slider_flow_request.style.vertical_align = "center"

    slider_flow_request.add{
        type = "slider",
        name = GUI.defines.config_slider,
        minimum_value = 0,
        maximum_value = 41,
    }
    slider_flow_request.add{
        type = "textfield",
        name = GUI.defines.config_slider_text,
        style = "slider_value_textfield",
    }

    slider_vertical_flow.add{
        type = "label",
        caption = {"auto-trash-trash"}
    }
    local slider_flow_trash = slider_vertical_flow.add{
        type = "flow",
        name = GUI.defines.config_trash,
        direction = "horizontal",
    }
    slider_flow_trash.style.vertical_align = "center"

    slider_flow_trash.add{
        type = "slider",
        name = GUI.defines.config_slider,
        minimum_value = 0,
        maximum_value = 42,
    }
    slider_flow_trash.add{
        type = "textfield",
        name = GUI.defines.config_slider_text,
        style = "slider_value_textfield",
    }

    GUI.update_sliders(player_index)

    --TODO add a dropdown for quick actions, that apply to each item e.g.
    --Set trash to requested amount
    --Set trash to stack size
    --Set requests to stack size
    --in/decrease by 1 stack size

    local trash_options = frame.add{
        type = "frame",
        name = GUI.defines.trash_options,
        style = "bordered_frame",
        direction = "vertical",
    }
    trash_options.style.use_header_filler = false
    trash_options.style.horizontally_stretchable = true
    trash_options.style.font = "default-bold"

    trash_options.add{
        type = "checkbox",
        name = GUI.defines.trash_above_requested,
        caption = {"auto-trash-above-requested"},
        state = global.settings[player_index].auto_trash_above_requested
    }

    trash_options.add{
        type = "checkbox",
        name = GUI.defines.trash_unrequested,
        caption = {"auto-trash-unrequested"},
        state = global.settings[player_index].auto_trash_unrequested,
    }

    trash_options.add{
        type = "checkbox",
        name = GUI.defines.trash_in_main_network,
        caption = {"auto-trash-in-main-network"},
        state = global.settings[player_index].auto_trash_in_main_network,
    }

    trash_options.add{
        type = "checkbox",
        name = GUI.defines.pause_trash,
        caption = {"auto-trash-config-button-pause"},
        tooltip = {"auto-trash-tooltip-pause"},
        state = global.settings[player_index].pause_trash
    }

    trash_options.add{
        type = "checkbox",
        name = GUI.defines.pause_requests,
        caption = {"auto-trash-config-button-pause-requests"},
        tooltip = {"auto-trash-tooltip-pause-requests"},
        state = global.settings[player_index].pause_requests
    }

    trash_options.add{
        type = "button",
        name = GUI.defines.set_main_network,
        caption = global.mainNetwork[player_index] and {"auto-trash-unset-main-network"} or {"auto-trash-set-main-network"}
    }

    local button_grid = frame.add{
        type = "table",
        column_count = 2,
        name = "auto-trash-button-grid"
    }
    button_grid.add{
        type = "button",
        name = GUI.defines.save_button,
        caption = {"gui.save"}
    }
    button_grid.add{
        type = "textfield",
        name = GUI.defines.save_name,
    }
    button_grid.add{
        type = "button",
        name = GUI.defines.clear_button,
        caption = {"gui.clear"}
    }
    button_grid.add{
        type = "drop-down",
        name = GUI.defines.clear_option,
        items = {
            [1] = "Both",
            [2] = "Requests",
            [3] = "Trash"
        },
        selected_index = 1
    }

    storage_frame = left.add{
        type = "frame",
        name = GUI.defines.storage_frame,
        caption = {"auto-trash-storage-frame-title"},
        direction = "vertical"
    }
    storage_frame.style.minimal_width = 200

    local storage_frame_buttons = storage_frame.add{
        type = "table",
        column_count = 2,
        name = "auto-trash-logistics-storage-buttons"
    }
    storage_frame_buttons.add{
        type = "textfield",
        text = "",
        name = "auto-trash-logistics-storage-name"
    }
    storage_frame_buttons.add{
        type = "button",
        caption = {"gui-save-game.save-as"},
        name = GUI.defines.store_button,
        style = "auto-trash-small-button"
    }
    local storage_scroll = storage_frame.add{
        type = "scroll-pane",
    }

    storage_scroll.style.maximal_height = math.ceil(38*10+4)
    local storage_grid = storage_scroll.add{
        type = "table",
        column_count = 2,
    }

    if global.storage_new[player_index] then
        local i = 1
        for key, _ in pairs(global.storage_new[player_index]) do
            storage_grid.add{
                type = "button",
                caption = key,
                name = GUI.defines.load_preset .. i,
            }
            local remove = storage_grid.add{
                type = "sprite-button",
                name = GUI.defines.delete_preset .. i,
                style = "red_icon_button",
                sprite = "utility/remove"
            }
            remove.style.left_padding = 0
            remove.style.right_padding = 0
            remove.style.top_padding = 0
            remove.style.bottom_padding = 0
            i = i + 1
        end
    end
end

function GUI.close(player)
    local left = mod_gui.get_frame_flow(player)
    local storage_frame = left[GUI.defines.storage_frame]
    local frame = left[GUI.defines.config_frame]

    if storage_frame then
        storage_frame.destroy()
    end
    if frame then
        frame.destroy()
    end
end

function GUI.save_changes(player)
    local player_index = player.index
    global.config_new[player_index] = util.table.deepcopy(global.config_tmp[player_index])

    show_yarm(player_index)
    GUI.close(player)
end

function GUI.clear_all(player, element)
    local player_index = player.index
    local mode = element.parent[GUI.defines.clear_option].selected_index
    if mode == 1 then
        global.config_tmp[player_index].config = {}
        global.config_tmp[player_index].config_by_name = {}
        global.selected[player_index] = false
    elseif mode == 2 then
        for _, config in pairs(global.config_tmp[player_index].config_by_name) do
            config.request = 0
        end
    elseif mode == 3 then
        for _, config in pairs(global.config_tmp[player_index].config_by_name) do
            config.trash = false
        end
    end
    GUI.open_logistics_frame(player, true)
end

function GUI.set_item(player, index, element)
    local player_index = player.index
    if not index then
        return
    end

    local elem_value = element.elem_value
    if elem_value then
        if global.config_tmp[player_index].config_by_name[elem_value] then
            display_message(player, {"", {"cant-set-duplicate-request", game.item_prototypes[elem_value].localised_name}}, true)
            element.elem_value = nil
            return global.config_tmp[player_index].config_by_name[elem_value].slot
        end
        global.config_tmp[player_index].config[index] = {name = elem_value, request = game.item_prototypes[elem_value].default_request_amount, trash = false, slot = index}
        global.config_tmp[player_index].config_by_name[elem_value] = global.config_tmp[player_index].config[index]
    end
    return true
end

function GUI.store(player, element)
    local player_index = player.index

    local textfield = element.parent["auto-trash-logistics-storage-name"]
    local name = textfield.text
    name = string.match(name, "^%s*(.-)%s*$")

    if not name or name == "" then
        display_message(player, {"auto-trash-storage-name-not-set"}, true)
        return
    end
    if global.storage_new[player_index][name] then
        display_message(player, {"auto-trash-storage-name-in-use"}, true)
        return
    end

    global.storage_new[player_index][name] = util.table.deepcopy(global.config_tmp[player_index])
    GUI.open_logistics_frame(player,true)
end

function GUI.restore(player, name)
    local player_index = player.index
    assert(global.storage_new[player_index] and global.storage_new[player_index][name]) --TODO remove

    global.config_tmp[player_index] = util.table.deepcopy(global.storage_new[player_index][name])
    global.selected[player_index] = false
    GUI.open_logistics_frame(player, true)
end

function GUI.remove(player, element, index)
    local storage_grid = element.parent
    assert(storage_grid and storage_grid.valid) --TODO remove
    local btn1 = storage_grid[GUI.defines.load_preset .. index]
    local btn2 = storage_grid[GUI.defines.delete_preset .. index]

    if not btn1 or not btn2 then return end
    assert(global.storage_new[player.index] and global.storage_new[player.index][btn1.caption]) --TODO remove
    global["storage_new"][player.index][btn1.caption] = nil
    saveVar(global, "delete")
    btn1.destroy()
    btn2.destroy()
end

return GUI
