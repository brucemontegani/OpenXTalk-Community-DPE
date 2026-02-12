on mouseUp
    put "hello" into x
    put " world" after x
    add 5 to y
end mouseUp

on mouseUp param1, param2
    put param1 into x
end mouseUp

function myFunc arg1
    return arg1 + 1
end myFunc

on testIf
    if x > 0 then put "positive" into result
    if x > 10 then
        put "big" into result
    else
        put "small" into result
    end if
end testIf

on testRepeat
    repeat with i = 1 to 10
        put i into x
    end repeat
    repeat
        put "forever" into x
    end repeat
end testRepeat

on testNested
    repeat with i = 1 to 10
        if i > 5 then
            put i into x
        else
            put 0 into x
        end if
    end repeat
end testNested

function bareReturn
    return
end bareReturn
