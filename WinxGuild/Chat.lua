-- Ordinary chat UI. Completion/reply targets come only from public roster/live
-- event names. Opaque historical author/content never become interactive targets.
local U,A,M=WinxGuildUI,WinxGuildClient,WinxGuildModel
U.followChat=true;U.unread=0;U.sentHistory={};U.sentPosition=nil
local onlineRowTop,onlineRowStep,onlineRowHeight=70,30,28
local onlinePagerHeight=32
local maxOnlineRows=15 -- Fits the 1000-high window at its resize limit.
local roleIcons={
 leader='Interface\\GroupFrame\\UI-Group-LeaderIcon',
 officer='Interface\\GroupFrame\\UI-Group-AssistantIcon',
}
local roleTitles={leader='Глава гильдии',officer='Офицер гильдии'}
local function updateChatFollow(frame)
 if not frame.GetScrollOffset then return end
 local wasFollowing=U.followChat
 U.followChat=frame:GetScrollOffset()==0
 if U.followChat and not wasFollowing then U.Refresh() end
end
local function attachChatScrollbar(frame,page)
 if not (frame.GetMaxScrollRange and frame.GetScrollOffset and frame.SetScrollOffset and frame.AddOnDisplayRefreshedCallback) then return end
 local bar=CreateFrame('Slider',nil,page)
 bar:SetOrientation('VERTICAL');bar:SetWidth(14);bar:EnableMouse(true)
 bar:SetPoint('TOPLEFT',frame,'TOPRIGHT',4,0)
 bar:SetPoint('BOTTOMLEFT',frame,'BOTTOMRIGHT',4,0)
 local track=bar:CreateTexture(nil,'BACKGROUND')
 track:SetWidth(4);track:SetPoint('TOP');track:SetPoint('BOTTOM')
 track:SetColorTexture(0.38,0.34,0.45,0.7)
 local thumb=bar:CreateTexture(nil,'ARTWORK')
 thumb:SetSize(12,24);thumb:SetColorTexture(0.82,0.76,0.88,1)
 bar:SetThumbTexture(thumb)
 bar:SetMinMaxValues(0,1);bar:Hide()
 local syncing=false
 local function sync()
  local range=frame:GetMaxScrollRange()
  syncing=true
  bar:SetMinMaxValues(0,math.max(1,range))
  bar:SetValue(range-frame:GetScrollOffset())
  bar:SetShown(range>0)
  syncing=false
 end
 frame:AddOnDisplayRefreshedCallback(sync)
 bar:SetScript('OnValueChanged',function(_,value)
  if syncing then return end
  frame:SetScrollOffset(math.max(0,math.floor(frame:GetMaxScrollRange()-value+0.5)))
  updateChatFollow(frame)
 end)
end
local function onlinePageSize(height)
 return math.max(1,math.min(maxOnlineRows,1+math.floor((height-onlineRowTop-onlinePagerHeight-onlineRowHeight)/onlineRowStep)))
end
function U.InsertMention(name,replaceActive)
 local value,cursor=M.InsertMention(U.composer:GetText(),U.composer:GetCursorPosition(),name,replaceActive==true,A.rows)
 if not value then U.Status(cursor);return end
 U.composer:SetText(value);U.composer:SetCursorPosition(cursor);U.composer:SetFocus()
 U.mentionPopup:Hide();U.mentionIndex=1;U.UpdateDraft()
end
function U.UpdateDraft()
 U.byteCount:SetText(#U.composer:GetText()..' / 255 байт')
end
function U.UpdateMentions()
 U.UpdateDraft()
 local candidates=M.Mentions(A.rows,U.composer:GetText(),U.composer:GetCursorPosition())
 U.mentionIndex=1
 for i,b in ipairs(U.mentionRows) do
  local r=candidates[i];b.member=r
  if r then b.label:SetText(M.Plain(r.name));b.label.classToken=r.class;b.label:SetTextColor(A.Color(r.class));b:Show() else b:Hide() end
 end
 if #candidates>0 then U.mentionPopup:Show() else U.mentionPopup:Hide() end
end
function U.PickMention()
 local b=U.mentionRows[U.mentionIndex or 1]
 if U.mentionPopup:IsShown() and b and b.member then U.InsertMention(b.member.name,true);return true end
 return false
end
function U.UpdateUnread()
 local unread=U.unread or 0
 local suffix=unread>0 and ' ('..unread..')' or ''
 if U.unreadBadge then
  if unread>0 then
   U.unreadBadgeText:SetText(unread>99 and '99+' or tostring(unread))
   U.unreadBadge:Show()
  else
   U.unreadBadge:Hide()
  end
 end
 if U.bottomButton then
  U.bottomButton.label:SetText('Вниз'..suffix)
 end
 for _,b in ipairs(U.buttons) do
  if b.tab=='chat' then
   b.label:SetText('Чат гильдии'..suffix)
  end
 end
end
function U.NewMessage(ownMessage)
 if not ownMessage and (not U.window:IsShown() or U.tab~='chat' or not U.followChat) then U.unread=(U.unread or 0)+1 end
 U.UpdateUnread()
 if U.window:IsShown() and U.tab=='chat' and U.followChat then U.Refresh() end
end
function U.RefreshOnline()
 local groups={leader={},officer={},member={}}
 local roles={}
 for _,member in ipairs(M.Filter(A.rows,U.onlineQuery or '',true,'name',false)) do
  local rank=member.rankIndex
  if rank~=nil and roles[rank]==nil then roles[rank]=A.GuildRole(rank) end
  local group=groups[roles[rank] or 'member']
  group[#group+1]=member
 end
 local online={}
 for _,role in ipairs({'leader','officer','member'}) do
  for _,member in ipairs(groups[role]) do online[#online+1]=member end
 end
 U.onlineTitle:SetText('В сети: '..#online)
 local size=onlinePageSize(U.onlineSide:GetHeight())
 local page=U.onlinePage or 1
 if U.onlinePageSize and U.onlinePageSize~=size then
  local first=(page-1)*U.onlinePageSize
  page=math.floor(first/size)+1
 end
 U.onlinePageSize=size
 local rows,total,current=M.Page(online,page,size);U.onlinePage=current
 U.onlinePageLabel:SetText(current..' / '..total)
 for i,b in ipairs(U.onlineRows) do
  local r=rows[i];b.member=r
  if r then
   b.label:SetText(M.Plain(r.name));b.label.classToken=r.class;b.label:SetTextColor(A.Color(r.class))
   b.level:SetText(tostring(r.level or ''))
   b.role=roles[r.rankIndex]
   local icon=roleIcons[b.role]
   b.rankIcon:SetTexture(icon)
   if icon then b.rankIcon:Show() else b.rankIcon:Hide() end
   b:Show()
  else b:Hide() end
 end
end
function U.RefreshChat()
 U.RefreshOnline();U.UpdateDraft();U.UpdateUnread()
 -- Freeze the displayed scrollback while the user reads it. New messages stay
 -- in the bounded session model and are displayed when the user chooses Down.
 if not U.followChat then return end
 U.chatFrame:Clear();U.replyTargets={}
 local messages=M.Chat(A.Messages(),U.chatQuery or '')
 if #messages==0 then
  local hint=U.chatQuery and U.chatQuery~='' and 'Поиск включён. Очистите поле, чтобы показать чат.' or 'Нет доступных сообщений гильдии.'
  U.chatFrame:AddMessage(hint,0.7,0.65,0.8)
 end
 for _,m in ipairs(messages) do
  local index
  if not m.historical then index=#U.replyTargets+1;U.replyTargets[index]=m.author end
  local class=m.class or (not m.historical and A.ClassFor(m.author) or nil)
  U.chatFrame:AddMessage(M.RenderMessage(m,index,U.showTime~=false),A.Color(class))
 end
 U.chatFrame:ScrollToBottom()
 if U.window:IsShown() and U.tab=='chat' then U.unread=0;U.UpdateUnread() end
end
function U.BuildChat(page,h)
 local text,button,edit=h.text,h.button,h.edit
 h.heading(page,'Разговор у волшебного огня','Клик по имени - ответ. @Имя - быстрый выбор. Справа - кто онлайн.')
 U.chatSearch=edit(page,6,-78,460,'Поиск по текущей сессии. Очистите поле для истории.',function(q) U.chatQuery=q;U.followChat=true;U.Refresh() end)
 button(page,'Загрузить историю',490,-78,250,U.LoadHistory)
 local f=CreateFrame('ScrollingMessageFrame',nil,page);U.chatFrame=f
 f:SetPoint('TOPLEFT',0,-128);f:SetPoint('BOTTOMRIGHT',-230,140)
 page:SetScript('OnHide',function()
  if not U.historyPreview then return end
  U.historyPreview=false
  A.EndHistoryPreview()
  f:Clear()
 end)
 f:SetJustifyH('LEFT');f:SetFading(false);f:SetMaxLines(400);f:SetSpacing(8);f:EnableMouseWheel(true);f:EnableMouse(true)
 attachChatScrollbar(f,page)
 if f.SetHyperlinksEnabled then f:SetHyperlinksEnabled(true) end
 f:SetScript('OnMouseWheel',function(self,delta)
  if delta>0 then self:ScrollUp() else self:ScrollDown() end
  updateChatFollow(self)
 end)
 f:SetScript('OnHyperlinkClick',function(_,link,label,mouse)
  if issecretvalue and issecretvalue(link) then return end
  local index=type(link)=='string' and link:match('^winxreply:(%d+)$')
  local name=index and U.replyTargets[tonumber(index)]
  if name then
   U.InsertMention(name);U.Status('Ответ в общий гильдейский чат: '..M.Plain(name))
  elseif SetItemRef and M.IsChatLink(link)
   and not (issecretvalue and (issecretvalue(label) or issecretvalue(mouse))) then
   SetItemRef(link,label,mouse,nil)
  end
 end)
 local side=CreateFrame('Frame',nil,page);side:SetWidth(190);U.onlineSide=side
 side:SetPoint('TOPRIGHT',-8,-128);side:SetPoint('BOTTOMRIGHT',-8,140);h.surface(side)
 U.onlineTitle=text(side,'В сети',10,-8,13,125)
 text(side,'Ур.',144,-8,12,29):SetJustifyH('RIGHT')
 U.onlineSearch=edit(side,10,-35,168,'Поиск среди участников онлайн',function(q) U.onlineQuery=q;U.onlinePage=1;U.RefreshOnline() end)
 U.onlineRows={}
 for i=1,maxOnlineRows do
  local b=button(side,'',5,-onlineRowTop-(i-1)*onlineRowStep,180,function(self) if self.member then U.InsertMention(self.member.name) end end)
  b.listRow=true;b:SetHeight(onlineRowHeight);b.label:SetWordWrap(false)
  b.label:ClearAllPoints();b.label:SetPoint('TOPLEFT',24,-8);b.label:SetWidth(108)
  b.rankIcon=b:CreateTexture(nil,'ARTWORK')
  b.rankIcon:SetSize(13,13);b.rankIcon:SetPoint('LEFT',6,0);b.rankIcon:Hide()
  b.level=text(b,'',139,-8,12,29)
  b.level:SetJustifyH('RIGHT');b.level:SetWordWrap(false)
  b:SetScript('OnEnter',function(self)
   if not self.member then return end
   GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText(M.Plain(self.member.name))
   if roleTitles[self.role] then GameTooltip:AddLine(roleTitles[self.role],1,0.82,0.3) end
   GameTooltip:AddLine('Клик - подставить упоминание',0.9,0.8,0.6,true);GameTooltip:Show()
  end)
  b:SetScript('OnLeave',function() GameTooltip:Hide() end);U.onlineRows[i]=b
 end
 local prev=button(side,'<',0,0,42,function() U.onlinePage=(U.onlinePage or 1)-1;U.RefreshOnline() end)
 prev:ClearAllPoints();prev:SetPoint('BOTTOMLEFT',5,0)
 U.onlinePageLabel=text(side,'',0,0,12,70);U.onlinePageLabel:ClearAllPoints();U.onlinePageLabel:SetPoint('BOTTOMLEFT',65,8)
 local next=button(side,'>',0,0,42,function() U.onlinePage=(U.onlinePage or 1)+1;U.RefreshOnline() end)
 next:ClearAllPoints();next:SetPoint('BOTTOMRIGHT',-5,0)
 side:SetScript('OnSizeChanged',function(_,_,height)
  if side:IsVisible() and onlinePageSize(height)~=U.onlinePageSize then U.RefreshOnline() end
 end)
 U.composer=edit(page,0,0,560,'Enter - отправить, @ - участник, Shift-клик - ссылка на предмет',function() U.sentPosition=nil;U.UpdateMentions() end)
 U.composer:SetMaxLetters(255);U.composer:ClearAllPoints();U.composer:SetPoint('BOTTOMLEFT',6,82)
 if U.composer.SetAltArrowKeyMode then U.composer:SetAltArrowKeyMode(false) end
 if hooksecurefunc and ChatFrameUtil and type(ChatFrameUtil.InsertLink)=='function' then
  hooksecurefunc(ChatFrameUtil,'InsertLink',function(link)
   local composer=U.composer
   if not composer:IsVisible() or not composer:HasFocus() then return end
   if (issecretvalue and issecretvalue(link)) or type(link)~='string' then return end
   if not M.IsChatLink(link:match('|H([^|]+)|h[^|]+|h')) then return end
   local draft=composer:GetText()
   if issecretvalue and issecretvalue(draft) then return end
   if #draft+#link>255 then U.Status('Ссылка не помещается в сообщение (255 байт).');return end
   composer:Insert(link)
   U.sentPosition=nil;U.UpdateMentions()
  end)
 end
 U.byteCount=text(page,'0 / 255 байт',0,0,11,160);U.byteCount:ClearAllPoints();U.byteCount:SetPoint('BOTTOMRIGHT',-8,120)
 local function send()
  if U.PickMention() then return end
  local value=U.composer:GetText();local ok,msg=A.Send(value);U.Status(msg)
  if ok then
   table.insert(U.sentHistory,1,value);if #U.sentHistory>20 then table.remove(U.sentHistory) end
   U.sentPosition=nil;U.composer:SetText('');U.UpdateDraft()
  end
 end
 U.composer:SetScript('OnEnterPressed',send)
 U.composer:SetScript('OnTabPressed',function() U.PickMention() end)
 U.composer:SetScript('OnEscapePressed',function(self) if U.mentionPopup:IsShown() then U.mentionPopup:Hide() else self:ClearFocus() end end)
 U.composer:SetScript('OnArrowPressed',function(self,key)
  if key~='UP' and key~='DOWN' then return end
  if U.mentionPopup:IsShown() then
   local count=0;for _,b in ipairs(U.mentionRows) do if b.member then count=count+1 end end
   if count>0 then U.mentionIndex=math.max(1,math.min(count,(U.mentionIndex or 1)+(key=='UP' and -1 or 1)));U.Status('Выбор: '..M.Plain(U.mentionRows[U.mentionIndex].member.name)..' / Tab или Enter') end
  elseif key=='UP' and #U.sentHistory>0 then
   if not U.sentPosition then U.beforeRecall=self:GetText() end
   U.sentPosition=math.min(#U.sentHistory,(U.sentPosition or 0)+1);self:SetText(U.sentHistory[U.sentPosition]);self:SetCursorPosition(#self:GetText());U.UpdateDraft()
  elseif key=='DOWN' and U.sentPosition then
   U.sentPosition=U.sentPosition-1
   if U.sentPosition==0 then U.sentPosition=nil;self:SetText(U.beforeRecall or '') else self:SetText(U.sentHistory[U.sentPosition]) end
   self:SetCursorPosition(#self:GetText());U.UpdateDraft()
  end
 end)
 U.sendButton=button(page,'Отправить',0,0,160,send);U.sendButton:ClearAllPoints();U.sendButton:SetPoint('BOTTOMRIGHT',-8,82)
 local popup=CreateFrame('Frame',nil,page);U.mentionPopup=popup
 popup:SetSize(560,194);popup:SetPoint('BOTTOMLEFT',U.composer,'TOPLEFT',0,6);popup:SetFrameLevel(220);h.surface(popup)
 text(popup,'Выберите участника / Tab или Enter / Esc - закрыть',10,-7,11,540)
 U.mentionRows={}
 for i=1,5 do
  local b=button(popup,'',6,-28-(i-1)*32,548,function(self) if self.member then U.InsertMention(self.member.name,true) end end)
  b.listRow=true;U.mentionRows[i]=b
 end
 popup:Hide()
 local stock=button(page,'Blizzard',0,0,105,h.handoff);stock:ClearAllPoints();stock:SetPoint('BOTTOMLEFT',0,35)
 U.bottomButton=button(page,'Вниз',0,0,120,function() U.followChat=true;U.unread=0;U.Refresh() end)
 U.bottomButton:ClearAllPoints();U.bottomButton:SetPoint('BOTTOMLEFT',115,35)
 local times=button(page,'Время: вкл.',0,0,145,function(self) U.showTime=U.showTime==false;self.label:SetText('Время: '..(U.showTime and 'вкл.' or 'выкл.'));U.followChat=true;U.Refresh() end)
 times:ClearAllPoints();times:SetPoint('BOTTOMLEFT',245,35)
 local clear=button(page,'Очистить сеанс',0,0,190,function() A.chat={};U.unread=0;U.followChat=true;U.Refresh();U.Status('Очищена только текущая сессия. История Blizzard сохранена.') end)
 clear:ClearAllPoints();clear:SetPoint('BOTTOMLEFT',400,35)
 local note=text(page,'WoW может передать аддону неполную историю, в том числе без ваших сообщений.\nСверьте историю в окне Blizzard. Поиск и ответы доступны для текущего сеанса.',0,0,11,750)
 note:ClearAllPoints();note:SetPoint('BOTTOMLEFT',0,4)
end
