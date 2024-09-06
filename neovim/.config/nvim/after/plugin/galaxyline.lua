local gl = require('galaxyline')
local condition = require('galaxyline.condition')
local gls = gl.section

local everforest = require("everforest")
local colours = require("everforest.colours")

-- Instead of `everforest.config`, you can add in your own config here by using
-- `everforest.setup({ show_eob = false)` before you generate the palette.
local palette = colours.generate_palette(everforest.config, vim.o.background)

gl.short_line_list = {'NvimTree','vista','dbui','packer'}

gls.left[1] = {
  RainbowRed = {
    provider = function() return '▊ ' end,
    highlight = {palette.blue,palette.bg_visual}
  },
}
gls.left[2] = {
  ViMode = {
    provider = function()
      -- auto change colour according the vim mode
      local mode_colour = {n = palette.red, i = palette.green,v=palette.blue,
                          [''] = palette.blue,V=palette.blue,
                          c = palette.fg,no = palette.red,s = palette.orange,
                          S=palette.orange,[''] = palette.orange,
                          ic = palette.yellow,R = palette.purple,Rv = palette.purple,
                          cv = palette.red,ce=palette.red, r = palette.aqua,
                          rm = palette.aqua, ['r?'] = palette.aqua,
                          ['!']  = palette.red,t = palette.red
                      }
      vim.api.nvim_command('hi GalaxyViMode guifg='..mode_colour[vim.fn.mode()])
      return '  '
    end,
    highlight = {palette.red,palette.bg,'bold'},
  },
}
gls.left[3] = {
  FileSize = {
    provider = 'FileSize',
    condition = condition.buffer_not_empty,
    highlight = {palette.fg,palette.bg}
  }
}
gls.left[4] ={
  FileIcon = {
    provider = 'FileIcon',
    condition = condition.buffer_not_empty,
    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_colour,palette.bg},
  },
}

gls.left[5] = {
  FileName = {
    provider = 'FileName',
    condition = condition.buffer_not_empty,
    highlight = {palette.purple,palette.bg,'bold'}
  }
}

gls.left[6] = {
  LineInfo = {
    provider = 'LineColumn',
    separator = ' ',
    separator_highlight = {'NONE',palette.bg},
    highlight = {palette.fg,palette.bg},
  },
}

gls.left[7] = {
  PerCent = {
    provider = 'LinePercent',
    separator = ' ',
    separator_highlight = {'NONE',palette.bg},
    highlight = {palette.fg,palette.bg,'bold'},
  }
}

gls.left[8] = {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = {palette.red,palette.bg}
  }
}
gls.left[9] = {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {palette.yellow,palette.bg},
  }
}

gls.left[10] = {
  DiagnosticHint = {
    provider = 'DiagnosticHint',
    icon = '  ',
    highlight = {palette.cyan,palette.bg},
  }
}

gls.left[11] = {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = '  ',
    highlight = {palette.blue,palette.bg},
  }
}

gls.mid[1] = {
  ShowLspClient = {
    provider = 'GetLspClient',
    condition = function ()
      local tbl = {['dashboard'] = true,['']=true}
      if tbl[vim.bo.filetype] then
        return false
      end
      return true
    end,
    icon = '   LSP:',
    highlight = {palette.cyan,palette.bg,'bold'}
  }
}

gls.right[1] = {
  FileEncode = {
    provider = 'FileEncode',
    condition = condition.hide_in_width,
    separator = ' ',
    separator_highlight = {'NONE',palette.bg},
    highlight = {palette.green,palette.bg,'bold'}
  }
}

gls.right[2] = {
  FileFormat = {
    provider = 'FileFormat',
    condition = condition.hide_in_width,
    separator = ' ',
    separator_highlight = {'NONE',palette.bg},
    highlight = {palette.green,palette.bg,'bold'}
  }
}

gls.right[3] = {
  GitIcon = {
    provider = function() return '  ' end,
    condition = condition.check_git_workspace,
    separator = ' ',
    separator_highlight = {'NONE',palette.bg},
    highlight = {palette.violet,palette.bg,'bold'},
  }
}

gls.right[4] = {
  GitBranch = {
    provider = 'GitBranch',
    condition = condition.check_git_workspace,
    highlight = {palette.violet,palette.bg,'bold'},
  }
}

gls.right[5] = {
  DiffAdd = {
    provider = 'DiffAdd',
    condition = condition.hide_in_width,
    icon = '  ',
    highlight = {palette.green,palette.bg},
  }
}
gls.right[6] = {
  DiffModified = {
    provider = 'DiffModified',
    condition = condition.hide_in_width,
    icon = ' 柳',
    highlight = {palette.orange,palette.bg},
  }
}
gls.right[7] = {
  DiffRemove = {
    provider = 'DiffRemove',
    condition = condition.hide_in_width,
    icon = '  ',
    highlight = {palette.red,palette.bg},
  }
}

gls.right[8] = {
  RainbowBlue = {
    provider = function() return ' ▊' end,
    highlight = {palette.blue,palette.bg}
  },
}

gls.short_line_left[1] = {
  BufferType = {
    provider = 'FileTypeName',
    separator = ' ',
    separator_highlight = {'NONE',palette.bg},
    highlight = {palette.blue,palette.bg,'bold'}
  }
}

gls.short_line_left[2] = {
  SFileName = {
    provider =  'SFileName',
    condition = condition.buffer_not_empty,
    highlight = {palette.fg,palette.bg,'bold'}
  }
}

gls.short_line_right[1] = {
  BufferIcon = {
    provider= 'BufferIcon',
    highlight = {palette.fg,palette.bg}
  }
}
