-- Adds date after the first H1

local i = 0
local envvars = pandoc.system.environment()

pandoc.log.info("Append date called, with DATE = " .. tostring(envvars['DATE']))

function Meta (m)
    pandoc.log.info("Meta called!")
    date = m.date
    return m
end

function Header (h)
    pandoc.log.info("Header called, with date " .. tostring(envvars["date"]) .. " and i = " .. i)
    i = i + 1
    if i == 1 then
        return {
            h,
            pandoc.Para(pandoc.Str("Published on " .. envvars['DATE']))
        }
    end
    
    return h
  end
