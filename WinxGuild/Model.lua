local M = {}
local defaults = {version=1,theme='fairy',scale=1,opacity=0.96,font=14,density='comfortable',decor=true,logo='shield',displayName=''}
M.Logos={
 {'shield','Щит','Interface\\Icons\\INV_Shield_04'},
 {'fairy','Крылья феи','Interface\\AddOns\\WinxGuild\\FairyCrest.tga'},
 {'diamond','Алмаз','Interface\\Icons\\INV_Misc_Gem_Diamond_01'},
 {'book','Книга','Interface\\Icons\\INV_Misc_Book_09'},
}
function M.LogoIndex(key)
 for i,logo in ipairs(M.Logos) do if logo[1]==key then return i end end
 return 1
end
function M.DisplayName(value)
 if type(value)~='string' or #value>400 then return '' end
 return value:gsub('[%z\1-\31\127]',' '):match('^%s*(.-)%s*$')
end
local themes = {fairy=true,dark=true,azeroth=true,forever=true}
local function clamp(value, fallback, low, high)
 if type(value)~='number' or value~=value then return fallback end
 return math.max(low,math.min(high,value))
end
function M.Settings(saved)
 local result={}
 for k,v in pairs(defaults) do result[k]=v end
 if saved~=nil and (type(saved)~='table' or (saved.version~=nil and saved.version~=1)) then return result,false end
 if type(saved)=='table' then
  for k,v in pairs(saved) do result[k]=v end
  result.version=1
  result.theme=themes[saved.theme] and saved.theme or 'fairy'
  result.scale=clamp(saved.scale,1,0.75,1.25)
  result.opacity=clamp(saved.opacity,0.96,0.65,1)
  result.font=clamp(saved.font,14,12,20)
  result.density=saved.density=='compact' and 'compact' or 'comfortable'
  result.decor=saved.decor~=false
  result.logo=M.Logos[M.LogoIndex(saved.logo)][1]
  result.displayName=M.DisplayName(saved.displayName)
  result.x=clamp(saved.x,0,-10000,10000)
  result.y=clamp(saved.y,0,-10000,10000)
  result.width=clamp(saved.width,1060,1020,1500)
  result.height=clamp(saved.height,700,700,1000)
  if saved.launcherX~=nil and saved.launcherY~=nil then
   result.launcherX=clamp(saved.launcherX,0,-10000,10000)
   result.launcherY=clamp(saved.launcherY,0,-10000,10000)
  end
 end
 return result,true
end
function M.Fold(s)
 -- Windows' C locale can lowercase individual UTF-8 bytes into invalid UTF-8.
 s=tostring(s or ''):gsub('[A-Z]',function(c) return string.char(c:byte()+32) end)
 local upper={'А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'}
 local lower={'а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я'}
 for i,v in ipairs(upper) do s=s:gsub(v,lower[i]) end
 return s
end
function M.Plain(s) return tostring(s or ''):gsub('|','||') end
function M.OnlineSummary(rows, playerZone, playerName, playerRealm, instances)
 local summary={all={},nearby={},dungeon={},raid={}}
 for _,member in ipairs(M.Filter(rows,'',true,'name',false)) do
  local kind=instances[member.zone]
  local isSelf=playerName and (member.name==playerName or
   (playerRealm and member.name==playerName..'-'..playerRealm))
  local nearby=playerZone and playerZone~='' and member.zone==playerZone and not isSelf
  local entry={member=member,kind=kind,nearby=nearby}
  summary.all[#summary.all+1]=entry
  if nearby then summary.nearby[#summary.nearby+1]=entry end
  if kind=='dungeon' or kind=='raid' then summary[kind][#summary[kind]+1]=entry end
 end
 return summary
end
local function mentionStart(value,cursor)
 local left=value:sub(1,cursor)
 local start=left:match('()@[^@]*$')
 if start and (start==1 or left:sub(start-1,start-1):match('%s')) then return start,left:sub(start+1) end
end
function M.Mentions(rows,value,cursor)
 local start,query=mentionStart(value,cursor or #value)
 if not start then return {} end
 local folded=M.Fold(query);local out={}
 for _,r in ipairs(rows) do
  if r.online and type(r.name)=='string' then
   if folded==M.Fold(r.name)..' ' then return {} end
   if M.Fold(r.name):find(folded,1,true)==1 then out[#out+1]=r end
  end
 end
 table.sort(out,function(a,b) return M.Fold(a.name)<M.Fold(b.name) end)
 return out
end
function M.InsertMention(value,cursor,name,replaceActive,rows)
 if type(value)~='string' or type(name)~='string' or name=='' then return nil,'Имя недоступно' end
 cursor=math.max(0,math.min(#value,cursor or #value))
 local start,query=mentionStart(value,cursor)
 if replaceActive==false or (start and M.Fold(name):find(M.Fold(query),1,true)~=1) then start=nil end
 local finish=cursor
 if start then
  -- Forever names can contain spaces. Prefer the full known roster name at
  -- this @ span; do not confuse its suffix with the message after the name.
  local tail=value:sub(start+1)
  for _,r in ipairs(rows or {}) do
   local n=r.name
   if type(n)=='string' and M.Fold(tail:sub(1,#n))==M.Fold(n) then
    local boundary=tail:sub(#n+1,#n+1)
    if boundary=='' or boundary:match('[%s,%p]') then
     local ending=start+#n
     if cursor<=ending then finish=math.max(finish,ending) end
    end
   end
  end
  if finish==cursor then
   local word=value:sub(cursor+1):match('^[^%s%p]+')
   if word then finish=cursor+#word end
  end
 end
 local prefix=value:sub(1,start and start-1 or cursor)
 local suffix=value:sub(finish+1)
 local gap=not start and #prefix>0 and not prefix:sub(-1):match('%s') and ' ' or ''
 local trailing=suffix~='' and suffix:sub(1,1):match('[%s%p]') and '' or ' '
 local insert=gap..'@'..name..trailing
 local result=prefix..insert..suffix
 if #result>255 then return nil,'Для упоминания не хватает места: максимум 255 байт' end
 return result,#prefix+#insert
end
function M.Filter(rows, query, online, key, descending)
 local out={};query=M.Fold(query);key=key or 'name'
 for _,r in ipairs(rows) do
  local text=M.Fold(table.concat({r.name or '',r.className or r.class or '',r.rank or '',r.zone or '',r.note or ''},' '))
  if (not online or r.online) and text:find(query,1,true) then out[#out+1]=r end
 end
 table.sort(out,function(a,b)
  local av,bv=a[key] or '',b[key] or ''
  if key~='level' then av,bv=M.Fold(av),M.Fold(bv) end
  if av==bv then return (a.name or '')<(b.name or '') end
  if descending then return av>bv end
  return av<bv
 end)
 return out
end
function M.Page(rows,page,size)
 local total=math.max(1,math.ceil(#rows/size));page=math.max(1,math.min(total,page or 1))
 local out={};for i=(page-1)*size+1,math.min(page*size,#rows) do out[#out+1]=rows[i] end
 return out,total,page
end
function M.Message(chat,author,text,time,stamp)
 if type(author)~='string' or type(text)~='string' or #text>4096 then return end
 chat[#chat+1]={author=author,text=text,time=time or '',stamp=stamp}
 if #chat>200 then table.remove(chat,1) end
 return chat[#chat]
end
function M.Chat(chat,query)
 local out={};query=M.Fold(query)
 for _,r in ipairs(chat) do
  -- Both historical author and content may be opaque client-rendered Kstrings.
  -- Never parse either; history is shown only with an empty search field.
  if r.historical then
   if query=='' then out[#out+1]=r end
  elseif M.Fold(r.author..' '..r.text):find(query,1,true) then out[#out+1]=r end
 end
 return out
end
local chatLinkTypes={item=true,spell=true,enchant=true,quest=true,achievement=true,trade=true}
function M.IsChatLink(link)
 if type(link)~='string' then return false end
 local kind=link:match('^(%a+):%d[^|%c]*$')
 return chatLinkTypes[kind]==true
end
local function renderChatText(value)
 local output,position={},1
 while true do
  local start=value:find('|',position,true)
  if not start then
   output[#output+1]=value:sub(position)
   return table.concat(output)
  end
  output[#output+1]=value:sub(position,start-1)
  local tail=value:sub(start)
  local color=tail:match('^|c%x%x%x%x%x%x%x%x') or tail:match('^|cn[%w_]+:')
  local body=color and tail:sub(#color+1) or tail
  local link,finish=body:match('^|H([^|]+)|h[^|]*|h()')
  if M.IsChatLink(link) and (not color or body:sub(finish,finish+1)=='|r') then
   position=start+finish-1+(color and #color+2 or 0)
   output[#output+1]=value:sub(start,position-1)
  else
   output[#output+1]='||'
   position=start+1
   if tail:sub(1,2)=='||' then position=position+1 end
  end
 end
end
function M.RenderMessage(message,replyIndex,showTime)
 local prefix=showTime~=false and message.time~='' and message.time..'  ' or ''
 if message.historical then
  -- Same rendering boundary used by Blizzard's CommunitiesChatMixin:
  -- content and display name pass unchanged to the client message widget.
  return M.Plain(prefix)..message.author..': '..message.text
 end
 if type(replyIndex)=='number' then
  return M.Plain(prefix)..'|Hwinxreply:'..replyIndex..'|h'..M.Plain(message.author)..'|h: '..renderChatText(message.text)
 end
 return M.Plain(prefix..message.author..': ')..renderChatText(message.text)
end
WinxGuildModel=M
return M
