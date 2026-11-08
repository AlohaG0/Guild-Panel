local M,A,U=WinxGuildModel,WinxGuildClient,WinxGuildUI
local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(_,event,...)
 if event=='ADDON_LOADED' then
  if (...)~='WinxGuild' then return end
  local settings,writable=M.Settings(WinxGuildSettings)
  if writable then WinxGuildSettings=settings end
  U.Create(settings,writable)
  events:UnregisterEvent('ADDON_LOADED')
  events:RegisterEvent('PLAYER_GUILD_UPDATE');events:RegisterEvent('GUILD_ROSTER_UPDATE')
  events:RegisterEvent('PLAYER_ENTERING_WORLD');events:RegisterEvent('CHAT_MSG_GUILD')
  events:RegisterEvent('GUILD_MOTD');events:RegisterEvent('GUILD_NEWS_UPDATE')
  events:RegisterEvent('CALENDAR_UPDATE_EVENT_LIST')
  events:RegisterEvent('INITIAL_CLUBS_LOADED');events:RegisterEvent('CLUB_UPDATED')
  if A.RegisterAnnouncements() then events:RegisterEvent('CHAT_MSG_ADDON_LOGGED') end
  events:RegisterEvent('CLUB_MESSAGE_HISTORY_RECEIVED');events:RegisterEvent('CLUB_MESSAGE_UPDATED')
  events:RegisterEvent('CLUB_STREAMS_LOADED')
  events:RegisterEvent('ZONE_CHANGED_NEW_AREA')
 elseif event=='ZONE_CHANGED_NEW_AREA' then
  if U.window:IsShown() and U.tab=='overview' then U.Refresh() end
 elseif event=='CHAT_MSG_GUILD' then
  local message,author=...;local row=A.Receive(message,author)
  if row then U.NewMessage(A.IsOwnChatMessage(author,select(12,...))) end
 elseif event=='CHAT_MSG_ADDON_LOGGED' then
  local message,sender=A.ReceiveAnnouncement(...)
  if message then
   U.ShowAnnouncement(message,sender)
   if U.window:IsShown() and U.tab=='news' then U.RefreshNews() end
  end
 elseif event=='GUILD_MOTD' or event=='GUILD_NEWS_UPDATE' or event=='CALENDAR_UPDATE_EVENT_LIST'
  or event=='INITIAL_CLUBS_LOADED' or event=='CLUB_UPDATED' then
  if event=='GUILD_MOTD' then A.ReceiveMOTD(...) end
  if U.window:IsShown() and U.tab=='news' then U.RefreshNews() end
  if U.window:IsShown() and U.tab=='info' and (event=='INITIAL_CLUBS_LOADED' or event=='CLUB_UPDATED') then U.Refresh() end
  if event=='INITIAL_CLUBS_LOADED' and U.window:IsShown() and U.tab=='chat' then
   local _,msg=A.History(true,U.historyPreview)
   U.Refresh();U.Status(msg)
  end
 elseif event=='CLUB_MESSAGE_HISTORY_RECEIVED' or event=='CLUB_MESSAGE_UPDATED' or event=='CLUB_STREAMS_LOADED' then
  if U.window:IsShown() and U.tab=='chat' then
   local _,msg=A.History(event=='CLUB_STREAMS_LOADED',U.historyPreview)
   U.Refresh();U.Status(msg)
  end
 else
  A.Read()
  if U.window:IsShown() then U.Refresh() end
 end
end)
SLASH_WINXGUILD1='/winx'
SLASH_WINXGUILD2='/guildpanel'
SlashCmdList.WINXGUILD=function(command)
 local action,message=(command or ''):match('^(%S+)%s*(.-)%s*$')
 if action=='announce' then
  local _,status=A.SendAnnouncement(message)
  print('Guild Panel: '..status)
  return
 end
 if command=='motdstatus' then
  print('Guild Panel: '..A.MOTDStatus())
 elseif command=='chatstatus' then
  print('Guild Panel: '..(A.liveChatStatus or 'событий чата пока не было')
   ..' / новые: '..#A.chat..' / история: '..#(A.history or {})
   ..' / поиск: '..(U.chatQuery and U.chatQuery~='' and 'включён' or 'выключен')
   ..' / прокрутка: '..(U.followChat and 'внизу' or 'пауза'))
 elseif command=='button' then U.ResetLauncher() else U.Toggle() end
end
