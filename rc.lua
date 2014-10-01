-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
awful.widget = require("awful.widget")
local wibox = require("wibox")

-- Override awful.completion
local completion = require("lib/completion")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- Load Debian menu entries
require("debian.menu")

-- Teardrop terminal
local teardrop = require("lib/teardrop")

-- run_once function - place calls at the bottom of rc..
require("lib/run_once")

-- pulse audio from https://github.com/orofarne/pulseaudio-awesome
require("pulseaudio-awesome/pulseaudio")

-- Obvious widgets
require("obvious.battery")
require("obvious.clock")

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
    awesome.connect_signal("debug::error", function (err)
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

-- {{{ Variable definitions
awesome_config = awful.util.getdir("config")
-- Themes define colours, icons, font and wallpapers.
beautiful.init(awesome_config .. "/themes/solarized/solarized/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "terminator -b"
editor = terminal .. " -e vim"
lockscreen = "xscreensaver-command -lock"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Configure notifications
naughty.config.defaults.position = "bottom_right"

--- Spawn a program using a login shell -- for custom PATH support
function spawn_with_login_shell(cmd, screen)
    if cmd and cmd ~= "" then
        cmd = "/bin/bash -l -c \"" .. cmd .. "\""
        return awesome.spawn(cmd, false, screen or mouse.screen)
    end
end

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


-- {{{ Define a tag table which hold all screen tags.
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

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

tags = {
  settings = {
    { names  = { 1, 2, 3, 4 },
      layout = { layouts[2], layouts[3], layouts[2], layouts[2] }
    },
    { names  = { 1, 2, 3, 4 },
      layout = { layouts[2], layouts[2], layouts[2], layouts[2] }
    }
  }
}

for s = 1, screen.count() do
    tags[s] = awful.tag(tags.settings[s].names, s, tags.settings[s].layout)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox

-- A simple separator
separator = wibox.widget.textbox()
separator:set_markup(" :: ")
space_separator = wibox.widget.textbox()
space_separator:set_markup(" ")
gear_separator = wibox.widget.textbox()
gear_separator:set_markup(obvious.lib.markup.fg.color("#009000", " ⚙ "))

-- Configure the PulseAudio widget
--volumewidget = wibox.widget.textbox({ name = "volumewidget", align = "right" })
volumewidget = wibox.widget.textbox("volumewidget")
volumewidget:set_align("right")

volumewidget:buttons(awful.util.table.join(
  awful.button({ }, 4, function() pulseaudio.volumeUp(); volumewidget:set_markup(pulseaudio.volumeInfo()) end),
  awful.button({ }, 5, function() pulseaudio.volumeDown(); volumewidget:set_markup(pulseaudio.volumeInfo()) end)
))

volumewidget:set_markup(pulseaudio.volumeInfo())
volumetimer = timer({ timeout = 30 })
volumetimer:connect_signal("timeout", function() volumewidget:set_markup(pulseaudio.volumeInfo()) end)
volumetimer:start()

-- Create a systray
mysystray = wibox.widget.systray()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
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
  -- Create a promptbox for each screen
  mypromptbox[s] = awful.widget.prompt()
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s })
          -- Widgets that are aligned to the left
          local left_layout = wibox.layout.fixed.horizontal()
          left_layout:add(mylauncher)
          left_layout:add(mytaglist[s])
          left_layout:add(mypromptbox[s])

          -- Widgets that are aligned to the right
          local right_layout = wibox.layout.fixed.horizontal()
          if s == 1 then right_layout:add(space_separator) end
          if s == 1 then right_layout:add(wibox.widget.systray()) end
          right_layout:add(space_separator)
          right_layout:add(obvious.battery())
          right_layout:add(space_separator)
          right_layout:add(volumewidget)
          right_layout:add(gear_separator)
          right_layout:add(obvious.clock())
          right_layout:add(mylayoutbox[s])

          -- Now bring it all together (with the tasklist in the middle)
          local layout = wibox.layout.align.horizontal()
          layout:set_left(left_layout)
          layout:set_middle(mytasklist[s])
          layout:set_right(right_layout)

          mywibox[s]:set_widget(layout)
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
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

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

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    --awful.key({ modkey }, "r", function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey }, "r",
              function ()
                  awful.prompt.run({ prompt = " Run: "},
                      mypromptbox[mouse.screen].widget,
                      function (...) spawn_with_login_shell(...) end,
                      completion.shell,
                      awful.util.getdir("cache") .. "/history"
                  )
              end
             ),


    -- teardrop
    awful.key({ modkey }, "`",
              function ()
                  teardrop(terminal, "top", "middle", .8, .4, true, 1)
              end),

    awful.key({ modkey }, "BackSpace", function () awful.util.spawn(lockscreen) end),

    awful.key({}, "XF86AudioMute",
      function() pulseaudio.volumeMute(); volumewidget:set_markup(pulseaudio.volumeInfo()) end),
    awful.key({}, "XF86AudioLowerVolume",
      function() pulseaudio.volumeDown(); volumewidget:set_markup(pulseaudio.volumeInfo()) end),
    awful.key({}, "XF86AudioRaiseVolume",
      function() pulseaudio.volumeUp(); volumewidget:set_markup(pulseaudio.volumeInfo()) end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
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

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
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
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
  -- Use xwininfo/xprop to get the properties for windows
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
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

    {rule = { class = "hipchat" },
      properties = { tag = tags[1][2], } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Why do I ever want clients offscreen?
        awful.placement.no_offscreen(c)
        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- xsetroot every 10 seconds
mytimer = timer({ timeout = 10 })
mytimer:connect_signal("timeout", function() awful.util.spawn_with_shell("xsetroot -cursor_name left_ptr") end)
mytimer:start()
awful.util.spawn_with_shell("xsetroot -cursor_name left_ptr")

-- Run these apps once
run_once ("gnome-keyring-daemon", "gnome-keyring-daemon --start --components=pkcs11")
run_once ("xscreensaver")
run_once ("pidgin", "pidgin -f")
run_once ("parcellite")
run_once ("nm-applet")
run_once ("chrome", "google-chrome")
