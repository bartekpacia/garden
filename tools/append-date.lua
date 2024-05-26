-- Adds date after the first H1

local i = 0
local envvars = pandoc.system.environment()

-- pandoc.log.info("Append date called, with DATE = " .. tostring(envvars['DATE']))

-- Adapted from https://stackoverflow.com/a/72762025/7009800
local function custompara (para)
    return pandoc.Plain(
      {pandoc.RawInline('html', '<p class="published-date">')} ..
      para.content ..
      {pandoc.RawInline('html', '</p>')}
    )
  end

function Header (h)
    -- pandoc.log.info("Header called, with date " .. tostring(envvars["date"]) .. " and i = " .. i)
    i = i + 1
    if i == 1 then
        local para = pandoc.Para(pandoc.Str("Published on " .. envvars['DATE']))
        local newpara = custompara(para)

        return {h, newpara}
    end
    
    return h
  end

