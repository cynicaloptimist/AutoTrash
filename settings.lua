local prefix = "autotrash_"
data:extend({
    {
        type = "bool-setting",
        name = prefix .. "pause_on_death",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "b"
    },
    {
        type = "int-setting",
        name = prefix .. "gui_columns",
        setting_type = "runtime-per-user",
        default_value = 6,
        minimum_value = 1,
        order = "c"
    },
    {
        type = "int-setting",
        name = prefix .. "gui_max_rows",
        setting_type = "runtime-per-user",
        default_value = 6,
        minimum_value = 1,
        order = "d"
    },
    {
        type = "int-setting",
        name = prefix .. "slots",
        setting_type = "runtime-per-user",
        default_value = 36,
        minimum_value = 2,
        order = "e"
    },
    {
        type = "int-setting",
        name = prefix .. "trash_above_requested_threshold",
        setting_type = "runtime-per-user",
        default_value = 0,
        minimum_value = 0,
        order = "f"
    },
    {
        type = "bool-setting",
        name = prefix .. "display_messages",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "g"
    }
    -- {
    --     type = "bool-setting",
    --     name = prefix .. "enable_module",
    --     setting_type = "startup",
    --     default_value = true,
    --     order = "a"
    -- },
    -- {
    --     type = "bool-setting",
    --     name = prefix .. "free_wires",
    --     setting_type = "runtime-global",
    --     default_value = false,
    --     order = "a"
    -- }
})