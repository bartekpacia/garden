-- Adds date after the first H1

local i = 0
local envvars = pandoc.system.environment()

-- Adapted from https://stackoverflow.com/a/72762025/7009800
local function custompara (para)
    return pandoc.Plain(
      {pandoc.RawInline('html', '<p class="published-date">')} ..
      para.content ..
      {pandoc.RawInline('html', '</p>')}
    )
  end

function Header (h)
    i = i + 1
    if i == 1 then
        local updated_date = envvars['UPDATED_DATE']

        local text = envvars['PUBLISHED_DATE']
        if updated_date then
            text = text .. ' / last updated: ' .. updated_date
        end
        local para = pandoc.Para(pandoc.Str(text))
        local newpara = custompara(para)

        return {h, newpara}
    end
    
    return h
  end

