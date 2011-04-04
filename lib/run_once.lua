function run_once(prg,arg_string,screen)
    if not prg then
        do return nil end
    end
    if not arg_string then 
        awful.util.spawn_with_shell("pgrep -f -u $USER -x " .. prg .. " || (" .. prg .. ")",screen)
    else
        awful.util.spawn_with_shell("pgrep -f -u $USER -x " .. prg .. " || (" .. prg .. " " .. arg_string .. ")",screen)
    end
end
