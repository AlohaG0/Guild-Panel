local A={rows={},chat={},status='Ожидаем данные гильдии',guild=nil}
WinxGuildClient=A
local M=WinxGuildModel
local function public(v)
 return not (issecretvalue and issecretvalue(v))
end
function A.ClassFor(name)
 for _,r in ipairs(A.rows) do if r.name==name then return r.class end end
 -- Live chat may include the realm while the local roster omits it. Only use
 -- a shortened public name when it identifies exactly one roster member.
 if type(name)~='string' then return end
 local short=name:match('^([^%-]+)')
 local result,count=nil,0
 for _,r in ipairs(A.rows) do if r.name:match('^([^%-]+)')==short then result=r.class;count=count+1 end end
 if count==1 then return result end
end
function A.Color(token)
 local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[token or '']
 if c then return c.r,c.g,c.b end
 return 0.91,0.89,0.96
end
function A.Clear()
 A.rows={};A.chat={};A.history={};A.guild=nil
 A.motd=nil;A.sessionAlerts={}
end
local function readGuild()
 local inGuild=IsInGuild and IsInGuild()
 if public(inGuild) and inGuild==false then A.Clear();A.status='Вы пока не состоите в гильдии';return false end
 if not public(inGuild) or inGuild~=true then return false end
 local name=GetGuildInfo and GetGuildInfo('player')
 if not public(name) or type(name)~='string' or name=='' then
  A.status='Название гильдии пока недоступно'
  return false
 end
 if A.guild~=name then A.Clear();A.guild=name end
 return true
end
function A.Read()
 if not readGuild() then return end
 if not GetNumGuildMembers or not GetGuildRosterInfo then
  A.rows={};A.status='API состава недоступен. Откройте стандартное окно.';return
 end
 local count=GetNumGuildMembers()
 if not public(count) or type(count)~='number' then A.rows={};A.status='Состав пока недоступен';return end
 local rows={}
 for i=1,math.min(count,1000) do
  -- Deliberately do not inspect, save, render or reconstruct officer notes / GUIDs.
  local n,rank,rankIndex,level,className,zone,note,_,online,_,class=GetGuildRosterInfo(i)
  if public(n) and public(rank) and public(level) and public(className) and public(zone) and public(online) and public(class) then
   if type(n)=='string' and type(level)=='number' then
    rows[#rows+1]={name=n,rank=type(rank)=='string' and rank or '',level=level,
     rankIndex=public(rankIndex) and type(rankIndex)=='number' and rankIndex or nil,
     className=type(className)=='string' and className or '',class=type(class)=='string' and class or '',
     zone=type(zone)=='string' and zone or '',online=online==true,
     note=public(note) and type(note)=='string' and note or ''}
   end
  end
 end
 A.rows=rows;A.status=#rows>0 and 'Данные текущей сессии' or 'Состав загружается или недоступен'
 return true
end
function A.Refresh()
 A.Read()
 if not A.guild then return end
 local now=GetTime and GetTime() or 0
 if A.lastRequest and now-A.lastRequest<10 then return end
 if C_GuildInfo and C_GuildInfo.GuildRoster then A.lastRequest=now;C_GuildInfo.GuildRoster() end
end
local function playerName()
 local name,realm
 if UnitFullName then name,realm=UnitFullName('player') end
 if not public(name) or type(name)~='string' then name=nil end
 if not public(realm) or type(realm)~='string' then realm=nil end
 if name and (not realm or realm=='') and GetNormalizedRealmName then
  local currentRealm=GetNormalizedRealmName()
  if public(currentRealm) and type(currentRealm)=='string' then realm=currentRealm end
 end
 return name,realm
end
function A.IsOwnChatMessage(author,guid)
 if public(guid) and type(guid)=='string' and guid~='' and UnitGUID then
  local player=UnitGUID('player')
  if public(player) and type(player)=='string' and player~='' then return player==guid end
 end
 if not public(author) or type(author)~='string' then return false end
 local name,realm=playerName()
 return name~=nil and (author==name or (realm~=nil and realm~='' and author==name..'-'..realm))
end
-- Roster zones can differ from journal titles, and the journal may only expose
-- one tier. Match whole names so outdoor entrance zones do not count.
local instanceAliases={
 dungeon={
  'Ragefire Chasm','Огненная Пропасть',
  'The Deadmines','Deadmines','Мертвые копи','Мёртвые копи',
  'Wailing Caverns','Пещеры Стенаний',
  'Shadowfang Keep','Крепость Темного Клыка','Крепость Тёмного Клыка',
  'Blackfathom Deeps','Непроглядная Пучина',
  'The Stockade','Stormwind Stockade','Тюрьма','Тюрьма Штормграда',
  'Razorfen Kraul','Лабиринты Иглошкурых',
  'Gnomeregan','Гномреган',
  'Scarlet Monastery','Монастырь Алого ордена',
  'Scarlet Monastery: Graveyard','Scarlet Monastery: Library','Scarlet Monastery: Armory','Scarlet Monastery: Cathedral',
  'Монастырь Алого ордена: кладбище','Монастырь Алого ордена: библиотека',
  'Монастырь Алого ордена: оружейная','Монастырь Алого ордена: собор',
  'Razorfen Downs','Курганы Иглошкурых',
  'Uldaman','Ульдаман',
  'Maraudon','Мародон',
  "Zul'Farrak","Зул'Фаррак",
  'Sunken Temple',"The Temple of Atal'Hakkar",'Затонувший храм',"Храм Атал'Хаккара",
  'Blackrock Depths','Глубины Черной горы','Глубины Чёрной горы',
  'Blackrock Spire','Lower Blackrock Spire','Upper Blackrock Spire','Пик Черной горы','Пик Чёрной горы',
  'Нижняя часть пика Черной горы','Верхняя часть пика Черной горы',
  'Dire Maul','Забытый Город',
  'Dire Maul: East','Dire Maul: West','Dire Maul: North',
  'Забытый Город: восток','Забытый Город: запад','Забытый Город: север',
  'Stratholme','Стратхольм',
  'Scholomance','Некроситет',
  'Hall of Thanes','The Hall of Thanes','Чертоги танов',
  'Ruins of Lordaeron','Руины Лордерона',
  'Excavation Site','Excavation Site: Wetlands','Раскопки: Болотина',
  'City of Dalaran','Город Даларан','Даларан',
  'The Drowned City','Drowned City','Затонувший город',
  "Krol'dok Stronghold","Крепость Крол'док",
  'Alcaz Prison','Тюрьма Алькац',
  'Blackmaw Hold','Крепость Черночрева',
  "Shaper's Terrace",'Терраса Создателя',
 },
 raid={
  'The Barrow Deeps','Barrow Deeps','Глубины Обители',
  'Hyjal Summit','Вершина Хиджала',
  "Onyxia's Lair",'Логово Ониксии',
  'Molten Core','Огненные Недра',
  'Blackwing Lair','Логово Крыла Тьмы',
  "Zul'Gurub","Зул'Гуруб",
  "Ruins of Ahn'Qiraj","Руины Ан'Киража",
  "Temple of Ahn'Qiraj","Ahn'Qiraj","Храм Ан'Киража","Ан'Кираж",
  'Naxxramas','Наксрамас',
 },
}
local function instanceKey(title)
 return M.Fold(title):gsub('’',"'"):match('^%s*(.-)%s*$')
end
local fallbackInstances={}
for kind,aliases in pairs(instanceAliases) do
 for _,alias in ipairs(aliases) do fallbackInstances[instanceKey(alias)]=kind end
end
function A.OnlineSummary()
 local zone=GetRealZoneText and GetRealZoneText()
 if not public(zone) or type(zone)~='string' then zone=nil end
 local name,realm=playerName()
 local instances={}
 if #A.rows>0 and EJ_GetInstanceByIndex then
  for _,raid in ipairs({false,true}) do
   local kind=raid and 'raid' or 'dungeon'
   for index=1,200 do
    local id,title=EJ_GetInstanceByIndex(index,raid)
    if not public(id) or not id then break end
    if public(title) and type(title)=='string' and title~='' then
     local key=instanceKey(title)
     local previous=instances[key]
     if previous==nil then instances[key]=kind
     elseif previous~=kind then instances[key]=false end
    end
   end
  end
 end
 local rosterInstances={}
 for _,member in ipairs(A.rows) do
  local key=instanceKey(member.zone)
  local kind=instances[key]
  if kind==nil then kind=fallbackInstances[key] end
  if kind then rosterInstances[member.zone]=kind end
 end
 return M.OnlineSummary(A.rows,zone,name,realm,rosterInstances),zone
end
function A.Receive(text,author)
 -- Verify membership without refreshing or depending on the roster.
 if not public(text) or not public(author) then
  A.liveChatStatus='WoW ограничил доступ к сообщению'
  return
 end
 if not readGuild() then A.liveChatStatus='данные гильдии недоступны';return end
 local stamp=GetServerTime and GetServerTime() or nil
 local timeLabel=date and (stamp and date('%d.%m %H:%M',stamp) or date('%d.%m %H:%M')) or ''
 local row=M.Message(A.chat,author,text,timeLabel,stamp)
 A.liveChatStatus=row and 'сообщение принято' or 'формат сообщения недоступен'
 return row
end
-- No restricted calls are attempted unless the client's documented security gate
-- explicitly reports false. No taint clearing, unwrapping or alternate read path.
local function unlocked()
 if not C_ChatInfo or type(C_ChatInfo.InChatMessagingLockdown)~='function' then return false end
 local locked=C_ChatInfo.InChatMessagingLockdown()
 return public(locked) and locked==false
end
function A.RequestNews()
 if not A.guild or not QueryGuildNews then return end
 local now=GetTime()
 if A.lastNewsRequest and now-A.lastNewsRequest<30 then return end
 A.lastNewsRequest=now
 QueryGuildNews()
 -- The stock news tab applies the normal sort after the request.
 if GuildNewsSort then GuildNewsSort(0) end
end
function A.News()
 local rows={}
 if not A.guild or not GetNumGuildNews or not C_GuildInfo or not C_GuildInfo.GetGuildNewsInfo then return rows end
 local count=GetNumGuildNews()
 if not public(count) or type(count)~='number' then return rows end
 for i=1,math.min(count,100) do
  local info=C_GuildInfo.GetGuildNewsInfo(i)
  if public(info) and type(info)=='table' and public(info.isHeader) and info.isHeader==false
   and public(info.newsType) and (not NEWS_MOTD or info.newsType~=NEWS_MOTD) then
   local who=public(info.whoText) and type(info.whoText)=='string' and info.whoText or ''
   local what=public(info.whatText) and type(info.whatText)=='string' and info.whatText or ''
   if NEWS_GUILD_CREATE and info.newsType==NEWS_GUILD_CREATE and what=='' then what='Создание гильдии' end
   if who~='' or what~='' then
    local subject=what:match('|h(%b[])|h') or what
    local separator=who~='' and subject~='' and ' - ' or ''
    local prefix=public(info.isSticky) and info.isSticky==true and 'Закреплено: ' or ''
    rows[#rows+1]=prefix..who..separator..subject
    if #rows==30 then break end
   end
  end
 end
 return rows
end
function A.GuildEvents()
 local rows={}
 local c=C_Calendar
 if not A.guild or not c or not c.GetNumGuildEvents or not c.GetGuildEventInfo then return rows end
 local count=c.GetNumGuildEvents()
 if not public(count) or type(count)~='number' then return rows end
 for i=1,math.min(count,7) do
  local info=c.GetGuildEventInfo(i)
  if public(info) and type(info)=='table' and public(info.title) and type(info.title)=='string' and info.title~='' then
   local day,month=info.monthDay,info.month
   local dateLabel=''
   if public(day) and type(day)=='number' and public(month) and type(month)=='number' then
    dateLabel=string.format('%02d.%02d - ',day,month)
   end
   rows[#rows+1]='Календарь: '..dateLabel..info.title
  end
 end
 return rows
end
local announcementPrefix='WinxGuildAlert1'
local function validAnnouncement(message)
 return public(message) and type(message)=='string' and #message<=220
  and message:match('%S') and not message:find('[%c|]')
end
local function allowed(value)
 return public(value) and value==true
end
function A.GuildRole(rankIndex)
 if rankIndex==0 then return 'leader' end
 if rankIndex and rankIndex>0 and C_GuildInfo and C_GuildInfo.GuildControlGetRankFlags then
  local ok,flags=pcall(C_GuildInfo.GuildControlGetRankFlags,rankIndex+1)
  -- Forever's Guild Control UI binds “Has Officer Privileges” to flag 22.
  if ok and public(flags) and type(flags)=='table' and allowed(flags[22]) then return 'officer' end
 end
 return 'member'
end
local function announcementClub()
 if not IsInGuild or not allowed(IsInGuild()) or not unlocked() or not C_Club or not C_Club.GetGuildClubId then return end
 local club=C_Club.GetGuildClubId()
 if public(club) and type(club)=='number' then return club end
end
local function announcementRows(club)
 local archive=WinxGuildAlertArchive
 if club and type(archive)=='table' and archive.club==club and type(archive.rows)=='table' then return archive.rows end
 return A.sessionAlerts or {}
end
local function cacheMOTD(club,message)
 local archive=WinxGuildAlertArchive
 if type(archive)=='table' and archive.club==club and archive.motd==message then return end
 WinxGuildAlertArchive={club=club,rows=announcementRows(club),motd=message}
end
function A.ReceiveMOTD(message)
 A.motdEvent='получено'
 if not unlocked() or not public(message) or type(message)~='string' then
  A.motdEvent='текст недоступен'
  return
 end
 A.motd=readGuild() and message or nil
 local club=announcementClub()
 if club then cacheMOTD(club,message) end
end
local function guildClubInfo(club)
 local c=C_Club
 if club and c.GetClubInfo and c.IsEnabled and c.IsRestricted and Enum and Enum.ClubRestrictionReason then
  local enabled,restriction=c.IsEnabled(),c.IsRestricted()
  if allowed(enabled) and public(restriction) and restriction==Enum.ClubRestrictionReason.None then
   local info=c.GetClubInfo(club)
   if public(info) and type(info)=='table' then return info end
  end
 end
end
function A.GuildDescription()
 local info=guildClubInfo(announcementClub())
 if info and public(info.description) and type(info.description)=='string' then return info.description end
end
function A.MessageOfTheDay()
 if A.motd~=nil then return A.motd,false,'событие WoW' end
 local club=announcementClub()
 local info=guildClubInfo(club)
 if info and public(info.broadcast) and type(info.broadcast)=='string' and info.broadcast~='' then
  cacheMOTD(club,info.broadcast)
  return info.broadcast,false,'объявление сообщества'
 end
 local archive=WinxGuildAlertArchive
 if club and type(archive)=='table' and archive.club==club and type(archive.motd)=='string' then
  return archive.motd,true,'локальный кэш'
 end
end
function A.MOTDStatus()
 A.Read()
 local _,_,source=A.MessageOfTheDay()
 return 'Сообщение дня: '..(source or 'источник недоступен')
  ..'; событие: '..(A.motdEvent or 'не было в этом сеансе')
  ..'; чат: '..(unlocked() and 'доступен' or 'ограничен')
  ..'; канал гильдии: '..(announcementClub() and 'найден' or 'недоступен')
end
function A.AnnouncementHistory()
 return announcementRows(announcementClub())
end
local function rememberAnnouncement(message,sender)
 local club=announcementClub()
 local rows=announcementRows(club)
 if club then WinxGuildAlertArchive={club=club,rows=rows,motd=A.MessageOfTheDay()} end
 A.sessionAlerts=club and {} or rows
 table.insert(rows,1,{message=message,sender=sender,time=date and date('%d.%m %H:%M') or ''})
 while #rows>30 do table.remove(rows) end
end
function A.RegisterAnnouncements()
 local c=C_ChatInfo
 if c and c.RegisterAddonMessagePrefix and c.IsAddonMessagePrefixRegistered then
  c.RegisterAddonMessagePrefix(announcementPrefix)
  A.announcementsReady=allowed(c.IsAddonMessagePrefixRegistered(announcementPrefix))
 end
 return A.announcementsReady
end
function A.CanAnnounce()
 local guild=C_GuildInfo
 return (IsGuildLeader and allowed(IsGuildLeader()))
  or (guild and guild.IsGuildOfficer and allowed(guild.IsGuildOfficer()))
end
function A.SendAnnouncement(message)
 if not A.CanAnnounce() then return false,'Команда доступна главе и офицерам гильдии.' end
 if not validAnnouncement(message) then
  return false,'Введите одну строку до 220 байт без игровой разметки.'
 end
 local c=C_ChatInfo
 if not unlocked() or not c.AreOutgoingAddonChatMessagesRestricted then
  return false,'Клиент ограничивает рассылку оповещений.'
 end
 local restricted=c.AreOutgoingAddonChatMessagesRestricted()
 if not public(restricted) or restricted~=false then
  return false,'На этом сервере ограничена рассылка между аддонами.'
 end
 local resultEnum=Enum and Enum.SendAddonMessageResult
 if not A.announcementsReady or not c.SendAddonMessageLogged or not resultEnum or resultEnum.Success==nil then
  return false,'Рассылка оповещений недоступна.'
 end
 local now=GetTime()
 if A.lastAnnouncementSend and now-A.lastAnnouncementSend<30 then
  return false,'Между оповещениями должно пройти 30 секунд.'
 end
 local ok,result=pcall(c.SendAddonMessageLogged,announcementPrefix,message,'GUILD')
 if not ok or not public(result) or result~=resultEnum.Success then
  return false,'Клиент не подтвердил отправку оповещения.'
 end
 A.lastAnnouncementSend=now
 return true,'Оповещение передано клиенту.'
end
function A.ReceiveAnnouncement(prefix,message,channel,sender)
 if not A.announcementsReady or not public(prefix) or prefix~=announcementPrefix
  or not public(channel) or channel~='GUILD' or not unlocked()
  or not public(sender) or type(sender)~='string' or not validAnnouncement(message) then return end
 local now=GetTime()
 if A.lastAnnouncementReceive and now-A.lastAnnouncementReceive<30 then return end
 if not A.Read() then return end
 for _,row in ipairs(A.rows) do
  -- Use the server-supplied sender exactly, never a name embedded in the payload.
  if row.name==sender then
   if A.GuildRole(row.rankIndex)~='member' then
    A.lastAnnouncementReceive=now
    rememberAnnouncement(message,sender)
    return message,sender
   end
   return
  end
 end
end
function A.History(requestInitial,preview)
 if not readGuild() then return false,'Данные гильдии пока недоступны' end
 A.history={}
 if not unlocked() then return false,'Клиент ограничивает историю чата. Используйте окно Blizzard.' end
 local c=C_Club
 if not c or not Enum or not Enum.ClubStreamType or not Enum.ClubRestrictionReason then return false,'API истории недоступен' end
 for _,key in ipairs({'IsEnabled','IsRestricted','GetGuildClubId','GetStreams','IsSubscribedToStream','GetMessageRanges','GetMessagesBefore'}) do
  if type(c[key])~='function' then return false,'API истории недоступен: '..key end
 end
 local enabled,restriction=c.IsEnabled(),c.IsRestricted()
 if not public(enabled) or enabled~=true or not public(restriction) or restriction~=Enum.ClubRestrictionReason.None then return false,'Сервис истории недоступен' end
 local club=c.GetGuildClubId()
 if not public(club) or club==nil then return false,'История ещё не готова. Повторите чуть позже.' end
 local streams=c.GetStreams(club)
 if not public(streams) or type(streams)~='table' then return false,'Канал гильдии недоступен' end
 local stream
 for _,s in ipairs(streams) do
  if public(s) and type(s)=='table' and public(s.streamType) and s.streamType==Enum.ClubStreamType.Guild and public(s.streamId) then stream=s.streamId;break end
 end
 if stream==nil then return false,'Канал гильдии ещё не загружен' end
 local subscribed=c.IsSubscribedToStream(club,stream)
 if not public(subscribed) or subscribed~=true then return false,'Нет подписки на гильдейский канал' end
 local ranges=c.GetMessageRanges(club,stream)
 if not public(ranges) or (ranges~=nil and type(ranges)~='table') then return false,'История недоступна' end
 local newest
 if ranges and #ranges>0 then
  local range=ranges[#ranges]
  if not public(range) or type(range)~='table' then return false,'История недоступна' end
  newest=range.newestMessageId
  local oldest=range.oldestMessageId
  if not public(newest) or not public(oldest) or type(newest)~='table' or type(oldest)~='table'
   or not public(newest.epoch) or not public(newest.position) or not public(oldest.epoch) or not public(oldest.position)
   or type(newest.epoch)~='number' or type(newest.position)~='number'
   or type(oldest.epoch)~='number' or type(oldest.position)~='number' then return false,'История недоступна' end
  if newest.epoch<oldest.epoch or (newest.epoch==oldest.epoch and newest.position<oldest.position) then newest=nil end
 end
 if not newest then
  local now=GetTime()
  if A.lastHistoryRequest and now-A.lastHistoryRequest<15 then return false,'Ожидаем историю от WoW…' end
  if not requestInitial then return false,'История пока не загружена' end
  if type(c.RequestMoreMessagesBefore)~='function' then return false,'Клиент не поддерживает загрузку истории здесь' end
  A.lastHistoryRequest=now
  local ok,cached=pcall(c.RequestMoreMessagesBefore,club,stream,nil)
  if not ok then return false,'Клиент не принял запрос истории' end
  if allowed(cached) then return A.History(false,preview) end
  return false,'Ожидаем историю от WoW…'
 end
 local messages=c.GetMessagesBefore(club,stream,newest,200)
 if not public(messages) or type(messages)~='table' then return false,'История недоступна' end
 local hidden,temporary=0,0
 for _,msg in ipairs(messages) do
  if public(msg) and type(msg)=='table' and public(msg.destroyed) and msg.destroyed==false
   and public(msg.content) and type(msg.content)=='string' and public(msg.author) and type(msg.author)=='table'
   and public(msg.author.name) and type(msg.author.name)=='string' then
   local opaque=msg.content:find('|K%a%d+|k') or msg.author.name:find('|K%a%d+|k')
   if opaque and not preview then
    hidden=hidden+1
   else
    local time,stamp='',nil
    if public(msg.messageId) and type(msg.messageId)=='table' and public(msg.messageId.epoch) and type(msg.messageId.epoch)=='number' and date then
     stamp=math.floor(msg.messageId.epoch/1000000)
     time=date('%d.%m %H:%M',stamp)
    end
    if not stamp and public(msg.messageId) and type(msg.messageId)=='table' and public(msg.messageId.epoch) and type(msg.messageId.epoch)=='number' then stamp=math.floor(msg.messageId.epoch/1000000) end
    local row=M.Message(A.history,msg.author.name,msg.content,time,stamp)
    if row then
     row.historical=true
     if opaque then row.temporary=true;temporary=temporary+1 end
     if public(msg.author.classID) and type(msg.author.classID)=='number' and C_CreatureInfo and C_CreatureInfo.GetClassInfo then
      local info=C_CreatureInfo.GetClassInfo(msg.author.classID)
      if public(info) and type(info)=='table' and public(info.classFile) and type(info.classFile)=='string' then row.class=info.classFile end
     end
    end
   end
  end
 end
 local status='Загружено сообщений: '..#A.history
 if hidden>0 then status=status..' / Временная история: '..hidden..'. Нажмите «Загрузить историю».' end
 if temporary>0 then status=status..' / Временный текст может исчезнуть, если WoW его скроет.' end
 return true,status
end
function A.EndHistoryPreview()
 for i=#(A.history or {}),1,-1 do
  if A.history[i].temporary then table.remove(A.history,i) end
 end
end
function A.Messages()
 if #(A.history or {})>0 and not unlocked() then A.history={} end
 local out,order={},{}
 for _,v in ipairs(A.history or {}) do out[#out+1]=v end
 -- CHAT_MSG_GUILD has no ClubMessageIdentifier. Do not guess that matching
 -- text/time identifies the same message: two real identical messages can occur.
 for _,v in ipairs(A.chat) do out[#out+1]=v end
 for i,v in ipairs(out) do order[v]=i end
 table.sort(out,function(a,b)
  local x,y=a.stamp or math.huge,b.stamp or math.huge
  if x==y then return order[a]<order[b] end
  return x<y
 end)
 return out
end
function A.Send(value)
 if not readGuild() then return false,'Данные гильдии пока недоступны' end
 if type(value)~='string' or not value:match('%S') then return false,'Введите сообщение' end
 if #value>255 then return false,'Сообщение слишком длинное: максимум 255 байт' end
 if value:find('[%z\1-\31]') then return false,'Сообщение должно быть одной строкой' end
 if not unlocked() then return false,'Клиент ограничивает отправку. Текст оставлен в поле.' end
 if type(C_ChatInfo.SendChatMessage)~='function' then return false,'API отправки недоступен' end
 -- Called once, directly from a click/Enter handler, never a timer or login event.
 local accepted=pcall(C_ChatInfo.SendChatMessage,value,'GUILD')
 if not accepted then return false,'Клиент отклонил отправку. Текст сохранён в поле.' end
 return true,'Сообщение передано клиенту'
end
function A.Stock()
 if InCombatLockdown and InCombatLockdown() then return false,'Откройте стандартное окно после боя' end
 if ToggleGuildFrame then ToggleGuildFrame();return true end
 return false,'Откройте «Гильдия и сообщества» через меню игры'
end
function A.Compose()
 if not A.guild then return false,'Сначала вступите в гильдию' end
 if InCombatLockdown and InCombatLockdown() then return false,'Откройте чат после боя' end
 if ChatFrame_OpenChat then ChatFrame_OpenChat('/g ',DEFAULT_CHAT_FRAME);return true end
 return false,'Нажмите Enter и введите /g для гильдейского чата'
end
