function MyColours(colour)
	colour = colour or "everforest"
	vim.cmd.colorscheme(colour)
    vim.o.background=dark
end

MyColours()
