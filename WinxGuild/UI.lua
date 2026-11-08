local M,A=WinxGuildModel,WinxGuildClient
local U={tab='overview',query='',online=false,sort='name',descending=false,page=1,fonts={},surfaces={},buttons={}}
WinxGuildUI=U
local stockLauncherIcon=M.Logos[1][3]
local palettes={
 fairy={bg={0.055,0.035,0.10},panel={0.105,0.065,0.17},accent={0.81,0.49,0.98},muted={0.68,0.62,0.78}},
 dark={bg={0.035,0.045,0.065},panel={0.065,0.08,0.11},accent={0.32,0.77,0.87},muted={0.60,0.67,0.74}},
 azeroth={bg={0.075,0.06,0.04},panel={0.13,0.105,0.065},accent={0.91,0.72,0.34},muted={0.72,0.67,0.56}},
 forever={bg={0.045,0.04,0.035},panel={0.055,0.075,0.10},accent={1,0.82,0.23},muted={0.73,0.69,0.54}},
}
local function text(parent,value,x,y,size,width)
 local f=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
 f:SetPoint('TOPLEFT',x,y);f:SetJustifyH('LEFT');f:SetJustifyV('TOP')
 if width then f:SetWidth(width) end
 f:SetText(value or '');f.baseSize=size or 14
 U.fonts[#U.fonts+1]=f
 return f
end
local function surface(parent)
 local t=parent:CreateTexture(nil,'BACKGROUND');t:SetAllPoints();U.surfaces[#U.surfaces+1]=t;return t
end
local function button(parent,label,x,y,w,callback)
 local b=CreateFrame('Button',nil,parent);b:SetSize(w,32);b:SetPoint('TOPLEFT',x,y)
 b.bg=b:CreateTexture(nil,'BACKGROUND');b.bg:SetAllPoints()
 b.label=text(b,label,12,-8,13,w-24)
 b:SetScript('OnClick',callback)
 b:SetScript('OnEnter',function(self)
  if U.settings.theme=='forever' then self.bg:SetAlpha(0.8)
  else self.bg:SetColorTexture(0.4,0.3,0.6,0.65) end
 end)
 b:SetScript('OnLeave',function() U.Paint() end)
 U.buttons[#U.buttons+1]=b
 return b
end
local function paintForeverButton(b,active)
 if not b.foreverBorder then
  b.foreverBorder=b:CreateTexture(nil,'BACKGROUND',nil,-1)
  b.foreverBorder:SetAllPoints()
  b.foreverBorder:Hide()
 end
 if not b.foreverBorder:IsShown() then
  b.bg:ClearAllPoints()
  b.bg:SetPoint('TOPLEFT',1,-1);b.bg:SetPoint('BOTTOMRIGHT',-1,1)
  b.label:ClearAllPoints()
  b.label:SetPoint('CENTER',b,'CENTER')
  b.label:SetWidth(b:GetWidth()-12)
  b.label:SetJustifyH('CENTER');b.label:SetJustifyV('MIDDLE')
  b.foreverBorder:Show()
 end
 if active then
  b.foreverBorder:SetColorTexture(0.82,0.58,0.28,1)
  b.bg:SetColorTexture(0.40,0.095,0.065,1)
 else
  b.foreverBorder:SetColorTexture(0.47,0.32,0.20,1)
  b.bg:SetColorTexture(0.25,0.052,0.038,1)
 end
end
function U.ShowAnnouncement(message,sender)
 if not U.announcement then
  local popup=CreateFrame('Frame',nil,UIParent,'BackdropTemplate')
  popup:SetSize(420,170)
  popup:SetPoint('TOP',UIParent,'TOP',0,-100)
  popup:SetClampedToScreen(true)
  popup:SetFrameStrata('FULLSCREEN_DIALOG')
  popup:SetBackdrop({edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=15})
  local bg=popup:CreateTexture(nil,'BACKGROUND')
  bg:SetPoint('TOPLEFT',4,-4);bg:SetPoint('BOTTOMRIGHT',-4,4)
  bg:SetColorTexture(0.07,0.045,0.12,1)
  U.announcementTitle=text(popup,'',16,-15,16,346)
  U.announcementTitle:SetTextColor(1,0.82,0.32)
  U.announcementSender=text(popup,'',16,-41,12,385)
  U.announcementText=text(popup,'',16,-64,14,388)
  U.announcementText:SetWordWrap(true)
  local close=button(popup,'X',0,0,32,function() popup:Hide() end)
  close:ClearAllPoints();close:SetPoint('TOPRIGHT',-7,-7)
  U.announcement=popup
  U.Paint()
 end
 U.announcementTitle:SetText(sender and 'Важное сообщение гильдии' or 'Тест оповещения')
 U.announcementSender:SetText(M.Plain(sender or 'Guild Panel'))
 U.announcementText:SetText(M.Plain(message))
 U.announcement:Show()
 local play=C_Sound and C_Sound.PlaySound or PlaySound
 local sound=SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959
 if play then return play(sound) end
end
local function edit(parent,x,y,width,placeholder,onChange)
 local e=CreateFrame('EditBox',nil,parent,'InputBoxTemplate');e:SetSize(width,30);e:SetPoint('TOPLEFT',x,y)
 e:SetAutoFocus(false);e:SetMaxLetters(100);e:SetText('')
 e:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 e:SetScript('OnTextChanged',function(self,user) if user and onChange then onChange(self:GetText()) end end)
 e:SetScript('OnEnter',function() GameTooltip:SetOwner(e,'ANCHOR_TOP');GameTooltip:SetText(placeholder);GameTooltip:Show() end)
 e:SetScript('OnLeave',function() GameTooltip:Hide() end)
 return e
end
function U.Paint()
 if not U.window then return end
 local s=U.settings;local p=palettes[s.theme]
 local stockTheme=s.theme=='forever'
 U.background:SetColorTexture(p.bg[1],p.bg[2],p.bg[3],s.opacity)
 U.background:SetAlpha(1)
 if stockTheme then
  U.stockChrome:Show()
  U.stockTexture:SetAlpha(0.4*s.opacity)
  if U.window.SetBackdrop then
   U.window:SetBackdrop({edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24,insets={left=6,right=6,top=6,bottom=6}})
   U.window:SetBackdropBorderColor(0.85,0.67,0.31,1)
  end
 else
  U.stockChrome:Hide()
  if U.window.SetBackdrop then U.window:SetBackdrop(nil) end
 end
 for _,t in ipairs(U.surfaces) do t:SetColorTexture(p.panel[1],p.panel[2],p.panel[3],0.98) end
 for _,b in ipairs(U.buttons) do
  local active=b.tab==U.tab or b.theme==s.theme
  b.bg:SetAlpha(1)
  b.bg:SetTexCoord(0,1,0,1)
  if stockTheme and b.tab then
   if active then b.bg:SetColorTexture(0.09,0.32,0.08,1)
   else b.bg:SetColorTexture(0.10,0.13,0.17,1) end
  elseif stockTheme and not b.listRow and b~=U.launcher then
   paintForeverButton(b,active)
  else
   if b.foreverBorder and b.foreverBorder:IsShown() then
    b.foreverBorder:Hide()
    b.bg:ClearAllPoints();b.bg:SetAllPoints()
    b.label:ClearAllPoints();b.label:SetPoint('TOPLEFT',12,-8)
    b.label:SetWidth(b:GetWidth()-24)
    b.label:SetJustifyH('LEFT');b.label:SetJustifyV('TOP')
   end
   b.bg:SetColorTexture(p.accent[1],p.accent[2],p.accent[3],active and 0.27 or 0.09)
  end
 end
 local font=STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF'
 for _,f in ipairs(U.fonts) do f:SetFont(font,f.baseSize+s.font-14,'');f:SetTextColor(A.Color(f.classToken)) end
 if stockTheme then
  for _,b in ipairs(U.buttons) do
   if not b.listRow and b~=U.launcher then b.label:SetTextColor(unpack(p.accent)) end
  end
 end
 U.guildName:SetTextColor(unpack(p.accent));U.section:SetTextColor(unpack(p.accent))
 U.motdTitle:SetTextColor(unpack(p.accent))
 U.motdAccent:SetColorTexture(p.accent[1],p.accent[2],p.accent[3],0.9)
 local crest=M.Logos[M.LogoIndex(s.logo)]
 local wings=crest[1]=='fairy'
 U.fairyCrest:SetTexture(crest[3])
 U.fairyCrest:SetSize(wings and 116 or 56,wings and 116 or 56)
 U.fairyCrest:ClearAllPoints()
 U.fairyCrest:SetPoint('TOP',0,wings and 15 or -16)
 if s.decor then U.fairyCrest:Show() else U.fairyCrest:Hide() end
 U.window:SetScale(s.scale)
 U.chatFrame:SetFont(font,s.font,'')
 if U.launcher then
  U.launcher.icon:SetTexture(s.decor and crest[3] or stockLauncherIcon)
  local size=s.decor and wings and 42 or 34
  U.launcher.icon:SetSize(size,size)
  U.launcher.bg:SetColorTexture(0,0,0,0)
 end
 for _,line in ipairs(U.closeLines) do line:SetColorTexture(p.accent[1],p.accent[2],p.accent[3],1) end
 for _,line in ipairs(U.resizeLines) do line:SetColorTexture(p.accent[1],p.accent[2],p.accent[3],0.95) end
end
function U.Status(message) if U.footer then U.footer:SetText(M.Plain(message or A.status)) end end
local function handoff()
 local ok,msg=A.Stock()
 if ok then U.window:Hide() else U.Status(msg) end
end
function U.ShowTab(key)
 U.tab=key
 for name,p in pairs(U.pages) do if name==key then p:Show() else p:Hide() end end
 local titles={overview='Дом гильдии',roster='Участники',chat='Гильдейский чат',news='Новости гильдии',info='Информация о гильдии',manage='Управление',settings='Настройки',about='Об аддоне'}
 U.section:SetText(titles[key]);U.Refresh();U.Paint()
 if key=='chat' then U.LoadHistory() end
 if key=='news' then A.RequestNews() end
end
function U.LoadHistory()
 U.followChat=true
 U.historyPreview=true
 U.chatQuery='';U.chatSearch:SetText('')
 local _,msg=A.History(true,true)
 U.Refresh();U.Status(msg)
end
local function heading(page,label,subtitle)
 text(page,label,0,0,22,700)
 return text(page,subtitle,0,-38,13,700)
end
local overviewRowTop,overviewRowStep,overviewFooterHeight=146,33,116
local maxOverviewRows=17
local function overviewPageSize(height)
 return math.max(1,math.min(maxOverviewRows,1+math.floor((height-overviewFooterHeight-overviewRowTop-24)/overviewRowStep)))
end
local function overview(page)
 heading(page,'Сводка по онлайну','Зоны игроков по списку гильдии')
 U.stats=text(page,'',0,-65,14,740)
 U.overviewFilters={}
 for index,filter in ipairs({{'all','Все онлайн'},{'nearby','В моей зоне'},{'dungeon','Подземелья'},{'raid','Рейды'}}) do
  local key=filter[1]
  local control=button(page,filter[2],(index-1)*187,-93,180,function()
   U.overviewFilter=key;U.overviewPage=1;U.Refresh()
  end)
  U.overviewFilters[key]={control=control,title=filter[2]}
 end
 U.overviewRows={}
 for index=1,maxOverviewRows do
  local y=-overviewRowTop-(index-1)*overviewRowStep
  local name=text(page,'',0,y,14,230)
  local location=text(page,'',248,y,13,490)
  name:SetWordWrap(false);location:SetWordWrap(false)
  U.overviewRows[index]={name=name,location=location}
 end
 local function footerButton(label,x,y,width,action)
  local b=button(page,label,0,0,width,action)
  b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',x,y)
 end
 footerButton('Назад',0,84,95,function() U.overviewPage=U.overviewPage-1;U.Refresh() end)
 U.overviewPageLabel=text(page,'',0,0,13,280)
 U.overviewPageLabel:ClearAllPoints();U.overviewPageLabel:SetPoint('BOTTOMLEFT',110,92)
 footerButton('Далее',395,84,95,function() U.overviewPage=U.overviewPage+1;U.Refresh() end)
 footerButton('Информация гильдии',0,34,225,function() U.ShowTab('info') end)
 footerButton('Полный состав',240,34,180,function() U.ShowTab('roster') end)
 footerButton('Чат',435,34,100,function() U.ShowTab('chat') end)
 page:SetScript('OnSizeChanged',function(_,_,height)
  if page:IsVisible() and overviewPageSize(height)~=U.overviewPageSize then U.RefreshOverview() end
 end)
end
function U.RefreshOverview()
 local summary,zone=A.OnlineSummary()
 U.stats:SetText(#summary.all..' в сети / '..#A.rows..' участников - '..M.Plain(zone and zone~='' and zone or 'Текущая зона неизвестна'))
 local key=U.overviewFilter or 'all'
 for filter,entry in pairs(U.overviewFilters) do
  entry.control.label:SetText((filter==key and '> ' or '')..entry.title..' ('..#summary[filter]..')')
 end
 local size=overviewPageSize(U.pages.overview:GetHeight())
 local page=U.overviewPage or 1
 if U.overviewPageSize and U.overviewPageSize~=size then
  page=math.floor((page-1)*U.overviewPageSize/size)+1
 end
 U.overviewPageSize=size
 local rows,total,index=M.Page(summary[key],page,size)
 U.overviewPage=index
 U.overviewPageLabel:SetText(#summary[key]>0 and ('Страница '..index..' / '..total) or 'Нет совпадений')
 for position,widgets in ipairs(U.overviewRows) do
  local entry=rows[position]
  local member=entry and entry.member
  widgets.name:SetText(member and M.Plain(member.name) or '')
  widgets.name.classToken=member and member.class
  widgets.name:SetTextColor(A.Color(widgets.name.classToken))
  local activity=entry and (entry.kind=='raid' and 'Рейд' or entry.kind=='dungeon' and 'Подземелье' or nil)
  local location=member and (member.zone~='' and member.zone or 'Зона неизвестна') or ''
  if activity then location=activity..' - '..location end
  if entry and entry.nearby then location='В моей зоне - '..location end
  widgets.location:SetText(M.Plain(location))
 end
end
local rosterRowTop,rosterRowHeight,rosterFooterHeight=160,30,74
local maxRosterRows=19
local function rosterPageSize(height)
 local gap=U.settings.density=='compact' and 31 or 34
 local size=1+math.floor((height-rosterFooterHeight-rosterRowTop-rosterRowHeight)/gap)
 return math.max(1,math.min(maxRosterRows,size)),gap
end
local function roster(page)
 U.rosterHint=heading(page,'Найдите своих','Поиск по имени, классу, званию и зоне')
 U.search=edit(page,6,-78,410,'Введите имя, класс, звание или зону',function(q) U.query=q;U.page=1;U.Refresh() end)
 U.onlineButton=button(page,'Только онлайн: нет',440,-78,235,function() U.online=not U.online;U.page=1;U.Refresh() end)
 U.columns={}
 local cols={{'Имя','name',0,200},{'Класс','className',206,96},{'Ур.','level',308,45},{'Звание','rank',359,112},{'Зона','zone',477,124},{'Примечание','note',607,143}}
 for _,c in ipairs(cols) do
  local key=c[2]
  local b=button(page,c[1],c[3],-126,c[4],function() if U.sort==key then U.descending=not U.descending else U.sort=key;U.descending=false end;U.Refresh() end)
  U.columns[#U.columns+1]=b
 end
 U.rowButtons={}
 for i=1,maxRosterRows do
  local b=button(page,'',0,-rosterRowTop-(i-1)*34,750,function(self)
   if not self.member then return end
   U.selected=self.member.name;U.Refresh()
  end)
  b.listRow=true;b:SetHeight(rosterRowHeight)
  b.label:SetWidth(184)
  b.classLabel=text(b,'',212,-8,13,86)
  b.level=text(b,'',314,-8,13,35);b.rank=text(b,'',365,-8,13,102);b.zone=text(b,'',483,-8,13,114);b.note=text(b,'',613,-8,13,131)
  for _,cell in ipairs({b.label,b.classLabel,b.level,b.rank,b.zone,b.note}) do cell:SetWordWrap(false) end
  b:SetScript('OnEnter',function(self)
   if not self.member then return end
   GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(M.Plain(self.member.name))
   GameTooltip:AddLine(M.Plain(self.member.className..' / '..self.member.rank),0.8,0.75,0.9,true)
   if self.member.note and self.member.note~='' then GameTooltip:AddLine(M.Plain(self.member.note),0.9,0.9,0.9,true) end
   GameTooltip:Show()
  end)
  b:SetScript('OnLeave',function() GameTooltip:Hide() end)
  U.rowButtons[i]=b
 end
 local prev=button(page,'Назад',0,0,100,function() U.page=U.page-1;U.Refresh() end)
 prev:ClearAllPoints();prev:SetPoint('BOTTOMLEFT',0,42)
 U.pageLabel=text(page,'',0,0,13,270)
 U.pageLabel:ClearAllPoints();U.pageLabel:SetPoint('BOTTOMLEFT',115,50)
 local next=button(page,'Далее',0,0,100,function() U.page=U.page+1;U.Refresh() end)
 next:ClearAllPoints();next:SetPoint('BOTTOMLEFT',390,42)
 U.detail=text(page,'Выберите участника — полное имя появится здесь.',0,0,13,740)
 U.detail:ClearAllPoints();U.detail:SetPoint('BOTTOMLEFT',0,0);U.detail:SetHeight(40)
 page:SetScript('OnSizeChanged',function(_,_,height)
  if page:IsVisible() and rosterPageSize(height)~=U.rosterPageSize then U.RefreshRoster() end
 end)
end
local function chat(page)
 U.BuildChat(page,{text=text,button=button,edit=edit,surface=surface,heading=heading,handoff=handoff})
end
local function guildNews(page)
 heading(page,'Сводка гильдии','Сообщение дня, игровые новости и оповещения администрации')
 local function feed(x,y,width,height)
  local f=CreateFrame('ScrollingMessageFrame',nil,page)
  f:SetPoint('TOPLEFT',x,y);f:SetSize(width,height)
  f:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',14,'')
  f:SetJustifyH('LEFT');f:SetFading(false);f:SetMaxLines(64);f:SetSpacing(8)
  if f.SetJustifyV then f:SetJustifyV('TOP') end
  f:EnableMouseWheel(true)
  f:SetScript('OnMouseWheel',function(self,delta) if delta>0 then self:ScrollUp() else self:ScrollDown() end end)
  return f
 end
 local motdPanel=CreateFrame('Frame',nil,page)
 motdPanel:SetPoint('TOPLEFT',0,-70);motdPanel:SetPoint('TOPRIGHT',0,-70);motdPanel:SetHeight(128)
 surface(motdPanel)
 U.motdAccent=motdPanel:CreateTexture(nil,'ARTWORK')
 U.motdAccent:SetPoint('TOPLEFT');U.motdAccent:SetPoint('BOTTOMLEFT');U.motdAccent:SetWidth(3)
 U.motdTitle=text(motdPanel,'Сообщение дня',16,-10,16,700)
 U.motdText=text(motdPanel,'',16,-37,14)
 U.motdText:SetPoint('BOTTOMRIGHT',-16,10)
 U.motdText:SetWordWrap(true)
 text(page,'Новости гильдии',0,-213,16,355)
 button(page,'Открыть новости в WoW',0,-239,290,handoff)
 local news=CreateFrame('ScrollFrame',nil,page)
 news:SetPoint('TOPLEFT',0,-279);news:SetPoint('BOTTOMLEFT',0,8);news:SetWidth(355)
 local content=CreateFrame('Frame',nil,news);content:SetSize(355,1);content:SetPoint('TOPLEFT')
 news:SetScrollChild(content)
 news:EnableMouseWheel(true)
 news:SetScript('OnMouseWheel',function(self,delta)
  self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-delta*42)))
 end)
 U.newsFeed=news;U.newsContent=content;U.newsRows={}
 for i=1,37 do
  local row=CreateFrame('Button',nil,content)
  row:SetWidth(355);row:EnableMouse(true)
  row.label=text(row,'',8,-6,14,339);row.label:SetWordWrap(true)
  local highlight=row:CreateTexture(nil,'BACKGROUND')
  highlight:SetAllPoints();highlight:Hide()
  row:SetScript('OnEnter',function()
   local accent=palettes[U.settings.theme].accent
   highlight:SetColorTexture(accent[1],accent[2],accent[3],0.20);highlight:Show()
  end)
  row:SetScript('OnLeave',function() highlight:Hide() end)
  U.newsRows[i]=row
 end
 text(page,'История оповещений',380,-213,16,350)
 text(page,'Здесь только оповещения, полученные, пока этот персонаж был онлайн.',380,-240,12,350)
 U.alertFeed=feed(380,-285,350,225)
end
function U.RefreshNews()
 local function fill(frame,rows,empty)
  frame:Clear()
  for i=#rows,1,-1 do frame:AddMessage(M.Plain(rows[i]),0.91,0.89,0.96) end
  if #rows==0 then frame:AddMessage(empty,0.72,0.68,0.78) end
  frame:ScrollToBottom()
 end
 local motd,cached=A.MessageOfTheDay()
 local news=A.News()
 local events=A.GuildEvents()
 for i=#events,1,-1 do news[#news+1]=events[i] end
 if motd=='' then motd='Сообщение дня не задано.' end
 if cached then motd='Последнее полученное:\n'..motd end
 U.motdText:SetText(M.Plain(motd or 'Ждём сообщение дня от WoW. После /reload может понадобиться повторный вход персонажем.'))
 local y=0
 for i,row in ipairs(U.newsRows) do
  if news[i] then
   row.label:SetText(M.Plain(news[i]))
   row:ClearAllPoints();row:SetPoint('TOPLEFT',0,-y)
   local height=math.max(30,row.label:GetStringHeight()+12)
   row:SetHeight(height);row:Show()
   y=y+height
  else row:Hide() end
 end
 U.newsContent:SetHeight(math.max(1,y))
 U.newsFeed:SetVerticalScroll(math.min(U.newsFeed:GetVerticalScroll(),math.max(0,y-U.newsFeed:GetHeight())))
 local alerts={}
 for _,row in ipairs(A.AnnouncementHistory()) do
  if type(row)=='table' and type(row.message)=='string' and type(row.sender)=='string' and type(row.time)=='string' then
   alerts[#alerts+1]=row.time..'  '..row.sender..'\n'..row.message
  end
 end
 fill(U.alertFeed,alerts,'Полученных оповещений пока нет.')
end
local function guildInfo(page)
 heading(page,'Информация о гильдии','Связь, офицеры и памятка для участников')
 text(page,'Описание гильдии',0,-78,18,720)
 U.guildDescription=text(page,'',0,-107,14,720)
 U.guildDescription:SetHeight(66)
 local sections={
  {'Discord','Здесь будет ссылка на сервер гильдии.'},
  {'Офицеры','Здесь появятся имена офицеров и их обязанности.'},
  {'Памятка','Место для правил, расписания сборов и полезных ссылок.'},
 }
 for i,section in ipairs(sections) do
  local y=-180-(i-1)*72
  text(page,section[1],0,y,18,720)
  text(page,section[2],0,y-30,14,720)
 end
 button(page,'Сведения в окне Blizzard',0,-402,300,handoff)
end
local function about(page)
 local version=C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata('WinxGuild','Version')
 heading(page,'Guild Panel','Окно гильдии для WoW Forever'..(version and '  /  '..version or ''))
 text(page,'Краткая инструкция',0,-82,18,720)
 local tips={
  '/guildpanel, /winx или щелчок по эмблеме у миникарты открывает окно.',
  'В «Обзоре» и «Участниках» можно найти согильдийцев и посмотреть, кто онлайн.',
  'В чате Enter отправляет сообщение, @ помогает выбрать имя, Shift-клик вставляет предмет.',
  'В «Новостях» есть сообщение дня и переход в штатное окно WoW.',
  'В «Настройках» можно выбрать тему, размер текста и прозрачность.',
 }
 for i,tip in ipairs(tips) do text(page,tip,0,-117-(i-1)*32,14,730) end
 local jeweler=text(page,'ЮВЕЛИРКА',21,-315,18)
 for _,side in ipairs({'LEFT','RIGHT'}) do
  local diamond=page:CreateTexture(nil,'ARTWORK')
  diamond:SetSize(9,9)
  diamond:SetPoint('CENTER',jeweler,side,side=='LEFT' and -13 or 13,0)
  diamond:SetColorTexture(0.48,0.85,1,1)
  diamond:SetRotation(math.pi/4)
 end
 local invite='https://discord.gg/uGGYWqZsxc'
 local link=edit(page,6,-345,350,'Приглашение в Discord «ЮВЕЛИРКА»')
 link:SetScript('OnTextChanged',function(box,user) if user then box:SetText(invite) end end)
 link:SetText(invite)
 button(page,'Выделить ссылку',375,-345,190,function() link:SetFocus();link:HighlightText() end)
 text(page,'Выделите ссылку и нажмите Ctrl+C, чтобы скопировать.',0,-387,13,720)
 text(page,'В Discord «ЮВЕЛИРКА» можно задать вопрос по аддону Guild Panel.',0,-413,13,720)
end
local function manage(page)
 heading(page,'Инструменты гильдии','Для главы и офицеров • действуют настоящие права вашего ранга')
 local entries={
  {'Приглашения и состав','Приглашение, повышение, понижение и исключение участников.'},
  {'Звания и разрешения','Настройка рангов, офицерские и публичные заметки.'},
  {'Объявления и информация','Сообщение дня, описание гильдии и доступный журнал.'},
 }
 for i,v in ipairs(entries) do
  local y=-95-(i-1)*127
  text(page,v[1],0,y,18,700);text(page,v[2],0,y-31,13,700)
  button(page,'Продолжить в окне Blizzard',0,y-62,320,handoff)
 end
 U.announceLabel=text(page,'Важное сообщение',0,-461,13,155)
 U.announceDraft=edit(page,163,-453,410,'Оповещение гильдии, до 220 байт')
 U.announceDraft:SetMaxLetters(220)
 local function send()
  local ok,msg=A.SendAnnouncement(U.announceDraft:GetText())
  if ok then U.announceDraft:SetText('');U.announceDraft:ClearFocus() end
  U.Status(msg)
 end
 U.announceSend=button(page,'Отправить',588,-453,145,send)
 U.announceDraft:SetScript('OnEnterPressed',send)
 text(page,'Приглашения, звания и настройки гильдии открываются в окне Blizzard.',0,-503,13,730)
end
local function settings(page)
 heading(page,'Оформление под настроение','Личные настройки • не меняют оформление у других участников')
 local names={{'fairy','Феечки Винкс'},{'dark','Тёмная'},{'azeroth','Азерот'},{'forever','Forever / стандартная'}}
 for i,v in ipairs(names) do
  local key=v[1]
  local b=button(page,v[2],((i-1)%2)*370,-78-math.floor((i-1)/2)*40,350,function() U.settings.theme=key;U.Paint() end)
  b.theme=key
 end
 U.settingsLabels={}
 local function adjust(label,key,y,step,low,high)
  local f=text(page,'',0,y-9,15,425);U.settingsLabels[key]={font=f,label=label}
  button(page,'-',455,y,54,function() U.settings[key]=math.max(low,U.settings[key]-step);U.Refresh();U.Paint() end)
  button(page,'+',523,y,54,function() U.settings[key]=math.min(high,U.settings[key]+step);U.Refresh();U.Paint() end)
 end
 adjust('Размер текста','font',-159,1,12,20)
 adjust('Масштаб окна','scale',-214,0.05,0.75,1.25)
 adjust('Непрозрачность фона','opacity',-269,0.05,0.65,1)
 button(page,'100%',590,-269,110,function()
  U.settings.opacity=1;U.Refresh();U.Paint()
 end)
 U.densityButton=button(page,'',0,-336,350,function() U.settings.density=U.settings.density=='compact' and 'comfortable' or 'compact';U.Refresh() end)
 U.decorButton=button(page,'',370,-336,350,function() U.settings.decor=not U.settings.decor;U.Refresh();U.Paint() end)
 button(page,'Сбросить оформление',0,-403,300,function()
  local fresh=M.Settings(nil)
  for k,v in pairs(fresh) do U.settings[k]=v end
  U.displayNameInput:SetText('')
  U.Refresh();U.Paint()
 end)
 button(page,'Вернуть значок аддона',320,-403,300,function() U.ResetLauncher() end)
 U.announcementTest=button(page,'Тест оповещения',0,-446,220,function()
  local played=U.ShowAnnouncement('Так выглядит важное сообщение от администрации гильдии.')
  U.Status(played and 'Тест оповещения' or 'Звук не запустился. Проверьте настройки звука WoW.')
 end)
 U.logoButton=button(page,'',320,-446,300,function()
  local index=M.LogoIndex(U.settings.logo)
  U.settings.logo=M.Logos[index%#M.Logos+1][1]
  U.Refresh();U.Paint()
 end)
 text(page,'Название в окне (пустое поле — имя из WoW)',0,-484,13,710)
 U.displayNameInput=edit(page,6,-503,300,'Название видно только в вашем окне')
 U.displayNameInput:SetText(U.settings.displayName)
 local function saveName()
  U.settings.displayName=M.DisplayName(U.displayNameInput:GetText())
  U.displayNameInput:SetText(U.settings.displayName)
  U.displayNameInput:ClearFocus()
  U.Refresh()
 end
 U.displayNameInput:SetScript('OnEnterPressed',saveName)
 button(page,'Сохранить название',320,-503,220,saveName)
 U.saveNotice=text(page,'',0,-379,12,730)
end
function U.Refresh()
 if not U.window then return end
 local name=U.settings.displayName~='' and U.settings.displayName or A.guild or 'Гильдейский дом'
 if U.lastGuild~=A.guild then
  U.selected=nil;U.lastGuild=A.guild;U.page=1;U.overviewPage=1;U.overviewFilter='all'
  if U.composer then U.composer:SetText('') end
  U.announceDraft:SetText('')
  if U.mentionPopup then U.mentionPopup:Hide() end
  U.sentHistory={};U.sentPosition=nil;U.replyTargets={};U.unread=0;U.followChat=true
 end
 U.guildName:SetText(M.Plain(name));U.Status()
 if A.CanAnnounce() then
  U.announceLabel:Show();U.announceDraft:Show();U.announceSend:Show()
 else
  U.announceLabel:Hide();U.announceDraft:Hide();U.announceSend:Hide()
 end
 if U.tab=='overview' then U.RefreshOverview() end
 if U.tab=='news' then U.RefreshNews() end
 if U.tab=='info' then
  local description=A.GuildDescription()
  U.guildDescription:SetText(M.Plain(description=='' and 'Описание не задано.' or description or 'WoW пока не передал описание гильдии.'))
 end
 U.RefreshRoster()
 U.RefreshChat()
 for key,v in pairs(U.settingsLabels) do
  local value=key=='font' and tostring(U.settings[key]) or math.floor(U.settings[key]*100+0.5)..'%'
  v.font:SetText(v.label..': '..value)
 end
 U.densityButton.label:SetText('Строки: '..(U.settings.density=='compact' and 'компактные' or 'свободные'))
 U.decorButton.label:SetText('Эмблема гильдии: '..(U.settings.decor and 'вкл.' or 'выкл.'))
 U.logoButton.label:SetText('Логотип: '..M.Logos[M.LogoIndex(U.settings.logo)][2]..'  >')
 U.saveNotice:SetText(U.writable and '' or 'Настройки более новой версии сохранены без изменений. Этот сеанс не сохраняется.')
end
function U.RefreshRoster()
 U.onlineButton.label:SetText('Только онлайн: '..(U.online and 'да' or 'нет'))
 local filtered=M.Filter(A.rows,U.query,U.online,U.sort,U.descending)
 local size,gap=rosterPageSize(U.pages.roster:GetHeight())
 if U.rosterPageSize and U.rosterPageSize~=size then
  U.page=math.floor((U.page-1)*U.rosterPageSize/size)+1
 end
 U.rosterPageSize=size
 local rows,total,index=M.Page(filtered,U.page,size);U.page=index
 U.pageLabel:SetText(index..' / '..total..'   •   найдено: '..#filtered)
 local selected
 for _,r in ipairs(A.rows) do if r.name==U.selected then selected=r end end
 if selected then
  U.detail:SetText(M.Plain(selected.name..' / '..selected.className..' / '..selected.rank)..'\n'..M.Plain(selected.note or ''))
 else U.selected=nil end
 for i,b in ipairs(U.rowButtons) do
  local r=rows[i];b.member=r;b:ClearAllPoints();b:SetPoint('TOPLEFT',0,-rosterRowTop-(i-1)*gap)
  if r then
   b:Show();b.label:SetText((r.online and '|cff74d6a5•|r ' or '|cff888888•|r ')..M.Plain(r.name))
   b.level:SetText(r.level);b.rank:SetText(M.Plain(r.rank));b.zone:SetText(r.online and M.Plain(r.zone) or 'Не в сети')
   b.note:SetText(M.Plain(r.note or ''))
   b.classLabel:SetText(M.Plain(r.className or ''))
   b.label.classToken=r.class;b.classLabel.classToken=r.class
   b.label:SetTextColor(A.Color(r.class));b.classLabel:SetTextColor(A.Color(r.class))
  else b:Hide() end
 end
 if not U.selected then U.detail:SetText('Выберите участника — полное имя появится здесь.') end
end
function U.Create(settingsValue,writable)
 U.settings=settingsValue;U.writable=writable
 local f=CreateFrame('Frame','WinxGuildWindow',UIParent,'BackdropTemplate');U.window=f
 f:SetSize(settingsValue.width or 1060,settingsValue.height or 700)
 f:SetPoint('CENTER',UIParent,'CENTER',settingsValue.x or 0,settingsValue.y or 0)
 f:SetClampedToScreen(true);f:SetMovable(true);f:SetResizable(true)
 if f.SetResizeBounds then f:SetResizeBounds(1020,700,1500,1000) end
 f:EnableMouse(true);f:SetFrameStrata('DIALOG')
 U.background=f:CreateTexture(nil,'BACKGROUND');U.background:SetAllPoints()
 local chrome=CreateFrame('Frame',nil,f,'BackdropTemplate')
 chrome:SetAllPoints();chrome:SetFrameLevel(f:GetFrameLevel())
 U.stockChrome=chrome
 local texture=chrome:CreateTexture(nil,'BACKGROUND',nil,1)
 texture:SetPoint('TOPLEFT',8,-8);texture:SetPoint('BOTTOMRIGHT',-8,8)
 texture:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Background')
 U.stockTexture=texture
 local header=chrome:CreateTexture(nil,'BORDER')
 header:SetPoint('TOPLEFT',200,-12);header:SetPoint('BOTTOMRIGHT',f,'TOPRIGHT',-12,-51)
 header:SetColorTexture(0.19,0.105,0.045,0.98)
 local rule=chrome:CreateTexture(nil,'ARTWORK')
 rule:SetPoint('TOPLEFT',header,'BOTTOMLEFT');rule:SetPoint('TOPRIGHT',header,'BOTTOMRIGHT')
 rule:SetHeight(2);rule:SetColorTexture(0.58,0.40,0.17,1)
 local inset=CreateFrame('Frame',nil,chrome,'BackdropTemplate')
 inset:SetPoint('TOPLEFT',208,-91);inset:SetPoint('BOTTOMRIGHT',-12,50)
 if inset.SetBackdrop then
  inset:SetBackdrop({edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=13})
  inset:SetBackdropBorderColor(0.45,0.39,0.30,1)
 end
 chrome:Hide()
 local side=CreateFrame('Frame',nil,f);side:SetPoint('TOPLEFT',12,-12);side:SetPoint('BOTTOMLEFT',12,12);side:SetWidth(184);surface(side)
 U.fairyCrest=side:CreateTexture(nil,'ARTWORK')
 text(side,'GUILD PANEL',12,-86,16,160):SetJustifyH('CENTER')
 text(side,'Ваш гильдейский дом',12,-111,11,160):SetJustifyH('CENTER')
 local tabs={{'overview','Обзор'},{'roster','Участники'},{'chat','Чат гильдии'},{'news','Новости'},{'info','Информация'},{'manage','Управление'},{'settings','Настройки'},{'about','Об аддоне'}}
 for i,v in ipairs(tabs) do
  local key=v[1]
  local b=button(side,v[2],10,-158-(i-1)*48,164,function() U.ShowTab(key) end)
  b.tab=key
  if key=='about' then b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',10,14) end
 end
 local sideNote=text(side,'0.3 / FOREVER\nНастройки только у вас',0,0,11,160)
 sideNote:ClearAllPoints();sideNote:SetPoint('BOTTOMLEFT',15,60)
 local drag=CreateFrame('Frame',nil,f);drag:SetPoint('TOPLEFT',210,-6);drag:SetPoint('TOPRIGHT',-60,-6);drag:SetHeight(80)
 drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() f:StartMoving() end)
 drag:SetScript('OnDragStop',function()
  f:StopMovingOrSizing();local x,y=f:GetCenter();local px,py=UIParent:GetCenter()
  U.settings.x=x-px/U.settings.scale;U.settings.y=y-py/U.settings.scale
 end)
 U.guildName=text(f,'Гильдейский дом',222,-22,23,650)
 U.section=text(f,'Дом гильдии',223,-59,13,600)
 local close=button(f,'',0,0,32,function() f:Hide() end)
 close:ClearAllPoints();close:SetPoint('TOPRIGHT',-10,-12)
 close.bg:Hide()
 U.closeLines={}
 for i=1,2 do
  local line=close:CreateTexture(nil,'ARTWORK');line:SetSize(16,2)
  line:SetPoint('CENTER');line:SetRotation(i==1 and math.pi/4 or -math.pi/4)
  U.closeLines[i]=line
 end
 U.pages={}
 for _,v in ipairs(tabs) do
  local p=CreateFrame('Frame',nil,f);p:SetPoint('TOPLEFT',222,-112);p:SetPoint('BOTTOMRIGHT',-20,52);U.pages[v[1]]=p
 end
 overview(U.pages.overview);roster(U.pages.roster);chat(U.pages.chat)
 guildNews(U.pages.news);guildInfo(U.pages.info);manage(U.pages.manage);settings(U.pages.settings);about(U.pages.about)
 U.footer=text(f,'',224,-658,11,590)
 U.footer:ClearAllPoints();U.footer:SetPoint('BOTTOMLEFT',224,20)
 local refresh=button(f,'Обновить',0,0,120,function()
  A.Refresh()
  if U.tab=='chat' then U.LoadHistory() else U.Refresh() end
  if U.tab=='news' then A.RequestNews() end
 end)
 refresh:ClearAllPoints();refresh:SetPoint('BOTTOMRIGHT',-155,14)
 local stock=button(f,'Blizzard',0,0,120,handoff)
 stock:ClearAllPoints();stock:SetPoint('BOTTOMRIGHT',-25,14)
 local resize=CreateFrame('Button',nil,f);resize:SetSize(24,24);resize:SetPoint('BOTTOMRIGHT',-1,1);resize:EnableMouse(true)
 U.resizeLines={}
 for i=1,3 do
  local line=resize:CreateTexture(nil,'OVERLAY');line:SetSize(4+i*4,2)
  line:SetPoint('CENTER',resize,'BOTTOMRIGHT',-5-i*3,5+i*3)
  line:SetRotation(math.pi/4);U.resizeLines[i]=line
 end
 resize:SetScript('OnMouseDown',function() f:StartSizing('BOTTOMRIGHT') end)
 resize:SetScript('OnMouseUp',function() f:StopMovingOrSizing();U.settings.width=f:GetWidth();U.settings.height=f:GetHeight() end)
 if UISpecialFrames then table.insert(UISpecialFrames,'WinxGuildWindow') end
 local launcher=button(UIParent,'',0,0,44,function(_,mouse)
  if mouse=='RightButton' then
   A.Refresh();f:Show();U.ShowTab('settings')
  else U.Toggle() end
 end)
 U.launcher=launcher;launcher:SetHeight(44);launcher:ClearAllPoints()
 launcher:SetFrameStrata('HIGH');launcher:SetFrameLevel(100);launcher:SetMovable(true);launcher:SetClampedToScreen(true)
 launcher.icon=launcher:CreateTexture(nil,'ARTWORK');launcher.icon:SetPoint('CENTER')
 U.unreadBadge=CreateFrame('Frame',nil,launcher)
 U.unreadBadge:SetSize(24,16);U.unreadBadge:SetPoint('TOPRIGHT',0,0)
 local badgeBg=U.unreadBadge:CreateTexture(nil,'BACKGROUND')
 badgeBg:SetAllPoints();badgeBg:SetColorTexture(0.61,0.13,0.24,1)
 U.unreadBadgeText=U.unreadBadge:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 U.unreadBadgeText:SetPoint('CENTER')
 U.unreadBadge:Hide()
 launcher:RegisterForClicks('LeftButtonUp','RightButtonUp');launcher:RegisterForDrag('LeftButton')
 if settingsValue.launcherX and settingsValue.launcherY then
  launcher:SetPoint('CENTER',UIParent,'CENTER',settingsValue.launcherX,settingsValue.launcherY)
 elseif Minimap then launcher:SetPoint('TOPRIGHT',Minimap,'TOPLEFT',-8,0)
 else launcher:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-28,-210) end
 launcher:SetScript('OnDragStart',function(self) self:StartMoving() end)
 launcher:SetScript('OnDragStop',function(self)
  self:StopMovingOrSizing();local x,y=self:GetCenter();local px,py=UIParent:GetCenter()
  U.settings.launcherX=x-px;U.settings.launcherY=y-py
 end)
 launcher:SetScript('OnEnter',function(self)
  GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText('Guild Panel')
  GameTooltip:AddLine('ЛКМ — открыть / закрыть\nПКМ — настройки\nПеретащите кнопку в удобное место',0.85,0.75,0.95,true);GameTooltip:Show()
 end)
 launcher:SetScript('OnLeave',function() GameTooltip:Hide();U.Paint() end)
 U.ShowTab('overview');f:Hide()
end
function U.ResetLauncher()
 U.settings.launcherX=nil;U.settings.launcherY=nil
 U.launcher:ClearAllPoints();U.launcher:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-240,-170)
 U.launcher:Show();U.Paint()
end
function U.Toggle()
 if not U.window then return end
 if U.window:IsShown() then U.window:Hide();return end
 A.Refresh();U.window:Show()
 if U.tab=='chat' then U.LoadHistory() else U.Refresh() end
 if U.tab=='news' then A.RequestNews() end
end
