-- data.lua (mod root, alongside control.lua)
data:extend({
  {
    type = "custom-input",
    name = "factorio-narrator-read-hovered",
    key_sequence = "1",
    action = "lua",
    include_selected_prototype = true,
    order = "a[narrator]-a[read-hovered]",
  },
})
