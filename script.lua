local _={"\x50\x6c\x61\x79\x65\x72\x73","\x4c\x6f\x63\x61\x6c\x50\x6c\x61\x79\x65\x72","\x47\x65\x74\x53\x65\x72\x76\x69\x63\x65","\x50\x6c\x61\x79\x65\x72\x47\x75\x69"}
local function __(_)local __=""for i=1,#_ do __=__..string.char(_.byte(_,i))end return __ end

local a=game[__(_[3])]( __(_[1]) )
local b=a[ __(_[2]) ]

local c,d=nil,""

local function e(f,g)
	if not f or not g then return f end
	return (f:gsub(g.Name,d):gsub(g.DisplayName,d))
end

local function h(i,j)
	if i:IsA("TextLabel") or i:IsA("TextButton") or i:IsA("TextBox") then
		i.Text=e(i.Text,j)
		i:GetPropertyChangedSignal("Text"):Connect(function()
			i.Text=e(i.Text,j)
		end)
	end
end

local function k()
	return c and a:GetPlayerByUserId(c) or nil
end

local function l()
	local m=k()
	if not m then return end
	for _,n in ipairs(game:GetDescendants()) do
		h(n,m)
	end
end

-- gui escondida em função
(function()
	local o=Instance.new("ScreenGui")
	o.Parent=b:WaitForChild(__(_[4]))

	local p=Instance.new("Frame")
	p.Size=UDim2.new(0,260,0,160)
	p.Position=UDim2.new(0,50,0,120)
	p.BackgroundColor3=Color3.fromRGB(25,25,25)
	p.Parent=o
	p.Active=true
	p.Draggable=true

	local q=Instance.new("TextBox")
	q.PlaceholderText="UserId"
	q.Size=UDim2.new(1,-20,0,30)
	q.Position=UDim2.new(0,10,0,35)
	q.Parent=p

	local r=Instance.new("TextBox")
	r.PlaceholderText="Nome"
	r.Size=UDim2.new(1,-20,0,30)
	r.Position=UDim2.new(0,10,0,75)
	r.Parent=p

	local s=Instance.new("TextButton")
	s.Text="OK"
	s.Size=UDim2.new(1,-20,0,30)
	s.Position=UDim2.new(0,10,0,115)
	s.Parent=p

	s.MouseButton1Click:Connect(function()
		c=tonumber(q.Text)
		d=r.Text
		l()
	end)
end)()

game.DescendantAdded:Connect(function(t)
	local u=k()
	if u then
		h(t,u)
	end
end)
