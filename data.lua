-- data.lua (mod root, alongside control.lua)
data:extend({
  {
    type = "custom-input",
    name = "factorio-narrator-read-hovered",
    key_sequence = "CONTROL", -- default: left ctrl
    action = "lua",
    -- consuming defaults to "none" (valid values: "none" or "game-only")
    include_selected_prototype = true,
    order = "a[narrator]-a[read-hovered]",
  },
})
