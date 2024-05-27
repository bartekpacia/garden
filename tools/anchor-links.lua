-- Inspired by https://github.com/jgm/pandoc-website/pull/50

-- Adds anchor links to headings with IDs.

local i = 0

function Header (h)
    i = i + 1
    if i == 1 then
      return h
    end

    if h.identifier ~= '' then
      -- an empty link to this header
      local anchor_link = pandoc.Link(
        {},                  -- content
        '#' .. h.identifier, -- href
        '',                  -- title
        {class = 'anchor', ['aria-hidden'] = 'true'} -- attributes
      )
      table.insert(h.content, 1, anchor_link)
      return h
    end
  end
