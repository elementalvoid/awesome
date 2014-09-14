-- Standard amesome library
require("awful")
require("awful.autofocus")
require("awful.rules")

-- Theme handling library
require("beautiful")

-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")

-- Teardrop terminal
require("lib/teardrop")

-- run_once function - place calls at the bottom of rc..
require("lib/run_once")

-- pulse audio from https://github.com/orofarne/pulseaudio-awesome
require("pulseaudio-awesome/pulseaudio")

-- Obvious widgets
require("obvious.popup_run_prompt")
require("obvious.battery")
require("obvious.clock")

-- {{{ Variable definitions
awesome_config = awful.util.getdir("config")

-- This is used later as the default terminal and editor to run.
terminal = "terminator -b"
editor = "urxvt -e vim"
editor_cmd = terminal .. " -e " .. editor
lockscreen = "xscreensaver-command -lock"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
}
-- }}}

-- Set the theme
beautiful.init(awesome_config .. "/themes/solarized/solarized/theme.lua")

-- Configure notifications
naughty.config.default_preset.position = "bottom_right"

-- Configure the popup command prompt
--- Spawn a program using a login shell -- for custom PATH support
function spawn_with_login_shell(cmd, screen)
    if cmd and cmd ~= "" then
        cmd = "/bin/bash -l -c \"" .. cmd .. "\""
        return awesome.spawn(cmd, false, screen or mouse.screen)
    end
end
obvious.popup_run_prompt.set_opacity( 0.7 )
obvious.popup_run_prompt.set_prompt_string( " $> " )
obvious.popup_run_prompt.set_slide( true )
obvious.popup_run_prompt.set_width( 0.5 )
obvious.popup_run_prompt.set_height( 18 )
obvious.popup_run_prompt.set_border_width( 1 )
obvious.popup_run_prompt.set_run_function( spawn_with_login_shell )

-- Configure the clock
obvious.clock.set_editor(editor)
obvious.clock.set_shortformat(function ()
    local week = tonumber(os.date("%W"))
    return "%H:%M %a %m/%d "
end)
obvious.clock.set_longformat(function ()
    local week = tonumber(os.date("%W"))
    return "%H:%M %a %m/%d "
end)

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}


-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4}, s, awful.layout.suit.tile)
end
--for s = 1, screen.count() do
--   -- Each screen has its own tag table.
--   tags[s] = awful.tag({ "⌨", "☠", "☕", "✍", "☻", "♬" }, s, awful.layout.suit.tile)
--end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "man page", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox

-- A simple separator
separator = widget({ type = "textbox" })
separator.text  = " :: "
space_separator = widget({ type = "textbox" })
space_separator.text = " "
gear_separator = widget({ type = "textbox" })
gear_separator.text = obvious.lib.markup.fg.color("#009000", " ⚙ ")

-- Configure the PulseAudio widget
volumewidget = widget({
    type = "textbox",
    name = "volumewidget",
    align = "right"
})

volumewidget:buttons(awful.util.table.join(
  awful.button({ }, 4, function() pulseaudio.volumeUp(); volumewidget.text = pulseaudio.volumeInfo() end),
  awful.button({ }, 5, function() pulseaudio.volumeDown(); volumewidget.text = pulseaudio.volumeInfo() end)
))

volumewidget.text = pulseaudio.volumeInfo()
volumetimer = timer({ timeout = 30 })
volumetimer:add_signal("timeout", function() volumewidget.text = pulseaudio.volumeInfo() end)
volumetimer:start()

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        obvious.clock(),
        gear_separator,
        volumewidget,
        space_separator,
        obvious.battery(),
        separator,
        s == 1 and mysystray or nil, -- systray on screen 1 only
        --s == 1 and separator or nil, -- systray on screen 1 only
        mytasklist[s],
        separator,
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey, "Mod1"    }, "j",  awful.tag.viewprev       ),
    awful.key({ modkey, "Mod1"    }, "k",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    -- awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     obvious.popup_run_prompt.run_prompt),

    -- teardrop
    awful.key({ modkey }, "`",
              function ()
                  teardrop(terminal, "top", "middle", .8, .4, true, 1)
              end),

    awful.key({ modkey }, "BackSpace", function () awful.util.spawn(lockscreen) end),

    -- media keys
    --awful.key({ }, "XF86MonBrightnessUp",   brightness.increase),
    --awful.key({ }, "XF86MonBrightnessDown", brightness.decrease),
    --awful.key({ }, "XF86AudioRaiseVolume", volume.increase),
    --awful.key({ }, "XF86AudioLowerVolume", volume.decrease),
    --awful.key({ }, "XF86AudioMute",        volume.toggle),
    awful.key({}, "XF86AudioMute",
      function() pulseaudio.volumeMute(); volumewidget.text = pulseaudio.volumeInfo() end),
    awful.key({}, "XF86AudioLowerVolume",
      function() pulseaudio.volumeDown(); volumewidget.text = pulseaudio.volumeInfo() end),
    awful.key({}, "XF86AudioRaiseVolume",
      function() pulseaudio.volumeUp(); volumewidget.text = pulseaudio.volumeInfo() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
    awful.key({ }, "XF86MonBrightnessDown",
      function ()
        awful.util.spawn("xbacklight -time 0 -steps 1 -dec 20")
      end),
    awful.key({ }, "XF86MonBrightnessUp",
      function ()
        awful.util.spawn("xbacklight -time 0 -steps 1 -inc 20")
      end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  -- switch to the given screen
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  -- "join" two screens without moving windows
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  -- move current window to given screen
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewonly(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  -- display current window on current screen *and* given screen
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
  -- Use xwininfo to get the properties for windows
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },

    -- Pidgin always on tag 2 of screen 1
    { rule = { class = "Pidgin" },
      properties = { tag = tags[1][2] } },

    -- Chrome alwas on tag 1 of screen 4
    {rule = { class = "Google-chrome" },
      properties = { tag = tags[1][4] } },
    -- Chrome popups should float
    {rule = { class = "Google-chrome", role = "pop-up" },
      properties = { floating = true } },

    -- Icedove/Thunderbird always on tag 2 of screen 2
    {rule = { class = "Icedove" },
      properties = { tag = tags[1][2] } },

    -- ReadyTalk Conference Controls
    {rule = { class = "Conference Controls" },
      properties = { floating = true } },

    -- Meld should always be full screen
    {rule = { class = "Meld" },
      properties = { floating = true, maximized_vertical = true, maximized_horizontal = true } },

    -- Cisco AnyConnect
    {rule = { class = "Vpnui" },
      properties = { floating = true } },

    -- ECUxPlot
    {rule = { class = "ECUxPlot" },
      properties = { floating = true } },

    -- GitG
    {rule = { class = "gitg" },
      properties = { floating = true } },

    {rule = { class = "rdesktop" },
      properties = {floating = true } },

    {rule = { class = "vncviewer" },
      properties = {floating = true } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- xsetroot every 10 seconds
mytimer = timer({ timeout = 10 })
mytimer:add_signal("timeout", function() awful.util.spawn_with_shell("xsetroot -cursor_name left_ptr") end)
mytimer:start()
awful.util.spawn_with_shell("xsetroot -cursor_name left_ptr")

-- Run these apps once
run_once ("gnome-keyring-daemon", "gnome-keyring-daemon --start --components=pkcs11")
run_once ("xscreensaver")
run_once ("pidgin", "pidgin -f")
run_once ("parcellite")
run_once ("nm-applet")
run_once ("chrome", "google-chrome")
