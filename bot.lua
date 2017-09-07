redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)
apiBots = {
    [0]={ChatId = "409295312", Username = "@ads_fwd_nabot"}
}
function vardump(value, depth, key)
    local linePrefix = ""
    local spaces = ""

    if key ~= nil then
        linePrefix = "[" .. key .. "] = "
    end

    if depth == nil then
        depth = 0
    else
        depth = depth + 1
        for i = 1, depth do spaces = spaces .. "  " end
    end

    if type(value) == 'table' then
        mTable = getmetatable(value)
        if mTable == nil then
            print(spaces .. linePrefix .. "(table) ")
        else
            print(spaces .. "(metatable) ")
            value = mTable
        end
        for tableKey, tableValue in pairs(value) do
            vardump(tableValue, depth, tableKey)
        end
    elseif type(value) == 'function' or
            type(value) == 'thread' or
            type(value) == 'userdata' or
            value == nil then
        print(spaces .. tostring(value))
    else
        print(spaces .. linePrefix .. "(" .. type(value) .. ") " .. tostring(value))
    end
end

function fwd_bac(arg, data)
    vardump( data, 10)
end

function dl_cb(arg, data)
end

function get_admin()
    if redis:get('botsadminset') then
        return true
    else
        print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
        local admin = io.read()
        redis:del("botsadmin")
        redis:sadd("botsadmin", admin)
        redis:set('botsadminset', true)
        return print("\n\27[36m     ADMIN ID |\27[32m " .. admin .. " \27[36m| شناسه ادمین")
    end
end

function get_bot(i, naji)
    function bot_info(i, naji)
        redis:set("botBOT-IDid", naji.id_)
        if naji.first_name_ then
            redis:set("botBOT-IDfname", naji.first_name_)
        end
        if naji.last_name_ then
            redis:set("botBOT-IDlanme", naji.last_name_)
        end
        redis:set("botBOT-IDnum", naji.phone_number_)
        return naji.id_
    end

    tdcli_function({ ID = "GetMe", }, bot_info, nil)
end

function is_admin(msg)
    local var = false
    local hash = 'botsadmin'
    local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
    if Naji then
        var = true
    end
    return var
end

function process_join(i, naji)
    if naji.code_ == 429 then
        local message = tostring(naji.message_)
        local Time = message:match('%d+') + 85
        redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
    else
        redis:srem("botBOT-IDgoodlinks", i.link)
        redis:sadd("botBOT-IDsavedlinks", i.link)
    end
end

function process_link(i, naji)
    if (naji.is_group_ or naji.is_supergroup_channel_) then
        redis:srem("botswaitelinks", i.link)
        redis:sadd("botBOT-IDgoodlinks", i.link)
    elseif naji.code_ == 429 then
        local message = tostring(naji.message_)
        local Time = message:match('%d+') + 85
        redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
    else
        redis:srem("botswaitelinks", i.link)
    end
end

function find_link(text)
    if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
        local text = text:gsub("t.me", "telegram.me")
        local text = text:gsub("telegram.dog", "telegram.me")
        for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
            if not redis:sismember("botBOT-IDalllinks", link) then
                redis:sadd("botswaitelinks", link)
                redis:sadd("botBOT-IDalllinks", link)
            end
        end
    end
end

function add(id)
    local Id = tostring(id)
    if not redis:sismember("botBOT-IDall", id) then
        if Id:match("^(%d+)$") then
            redis:sadd("botBOT-IDusers", id)
            redis:sadd("botBOT-IDall", id)
        elseif Id:match("^-100") then
            redis:sadd("botBOT-IDsupergroups", id)
            redis:sadd("botBOT-IDall", id)
        else
            redis:sadd("botBOT-IDgroups", id)
            redis:sadd("botBOT-IDall", id)
        end
    end
    return true
end

function rem(id)
    local Id = tostring(id)
    if redis:sismember("botBOT-IDall", id) then
        if Id:match("^(%d+)$") then
            redis:srem("botBOT-IDusers", id)
            redis:srem("botBOT-IDall", id)
        elseif Id:match("^-100") then
            redis:srem("botBOT-IDsupergroups", id)
            redis:srem("botBOT-IDall", id)
        else
            redis:srem("botBOT-IDgroups", id)
            redis:srem("botBOT-IDall", id)
        end
    end
    return true
end

function sendtobot()
    local Botscount = tablelength(apiBots)
    local i = 0
    while i < Botscount do
        local user_id = apiBots[i]["Username"]
        local cid = apiBots[i]["ChatId"]
        tdcli_function({
            ID = "SearchPublicChat",
            username_ = user_id
        }, fwd_bac, nil)

        tdcli_function({
            ID = "SendMessage",
            chat_id_ = cid,
            reply_to_message_id_ = 0,
            disable_notification_ = 1,
            from_background_ = 1,
            reply_markup_ = nil,
            input_message_content_ = {
                ID = "InputMessageText",
                text_ = "/start",
                disable_web_page_preview_ = 1,
                clear_draft_ = 0,
                entities_ = {},
                parse_mode_ = { ID = "TextParseModeHTML" }
            }
        }, fwd_bac, nil)

        i = i + 1
    end
end

function addBots(chat_id)
    local Botscount = tablelength(apiBots)
    local i = 0
    while i < Botscount do
        tdcli_function ({
            ID = "AddChatMember",
            chat_id_ = chat_id,
            user_id_ = apiBots[i]["ChatId"],
            forward_limit_ =  50
        }, fwd_bac, nil)

        i = i + 1
    end
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function send(chat_id, msg_id, text)
    tdcli_function ({
        ID = "SendChatAction",
        chat_id_ = chat_id,
        action_ = {
            ID = "SendMessageTypingAction",
            progress_ = 100
        }
    }, cb or dl_cb, cmd)
    tdcli_function ({
        ID = "SendMessage",
        chat_id_ = chat_id,
        reply_to_message_id_ = msg_id,
        disable_notification_ = 1,
        from_background_ = 1,
        reply_markup_ = nil,
        input_message_content_ = {
            ID = "InputMessageText",
            text_ = text,
            disable_web_page_preview_ = 1,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {ID = "TextParseModeHTML"},
        },
    }, fwd_bac, nil)
end
get_admin()
redis:set("botBOT-IDstart", true)
function tdcli_update_callback(data)
    if data.ID == "UpdateNewMessage" then
        if redis:get("botBOT-IDaddbots") then
            if not redis:get("botBOT-IDapiadding") then
                local groups = redis:smembers("botBOT-IDsupergroups")
                local added = tonumber(redis:get("botBOT-IDapiadded")) or 0
                local gpCount = redis:scard("botBOT-IDsupergroups")
                for x,y in ipairs(groups) do
                    if added == 0 or x > added then
                        addBots(y)
                        redis:set("botBOT-IDapiadded", x)
                        redis:setex("botBOT-IDapiadding", 300, true)
                        if x == gpCount then
                            redis:del("botBOT-IDaddbots")
                            redis:del("botBOT-IDapiadded")
                        end
                        return
                    end
                end
            end
        end
        local maxfwd = redis:get("botBOT-IDmaxfwd") or 'false'
        local isfwd = redis:get("botBOT-IDisfwd") or 'false'
        print('maxfwd '.. maxfwd)
        print('isfwd '.. isfwd)
        if not redis:get("botBOT-IDmaxfwd") then
            if redis:get("botBOT-IDisfwd") then
                local naji = "botBOT-IDsupergroups"
                local list = redis:smembers(naji)
                local listcnt = redis:scard(naji)
                local msg_id = redis:get("botBOT-IDfwdmsg_id")
                local from_chat_id_ = redis:get("botBOT-IDfwdfrom_chat_id_")
                local sended = tonumber(redis:get("botBOT-IDfwdsended")) or 0
                print('msg_id '.. msg_id)
                print('from_chat_id_ '.. from_chat_id_)
                print('sended '.. sended)

                --send('-1001143653541', 0, "salam")
                tdcli_function({
                    ID = "ForwardMessages",
                    chat_id_ = '-1001143653541',
                    from_chat_id_ = '93077939',
                    message_ids_ = {[0] = 102760448},
                    disable_notification_ = 1,
                    from_background_ = 1
                }, fwd_bac, nil)

                for i, v in pairs(list) do
                    print('index '.. i)
                    if sended == 0 or i > sended then
                        print('chat id=> '.. v)
                        tdcli_function({
                            ID = "ForwardMessages",
                            chat_id_ = v,
                            from_chat_id_ = from_chat_id_,
                            message_ids_ = {[0] = msg_id},
                            disable_notification_ = 1,
                            from_background_ = 1
                        }, fwd_bac, nil)
                        print('sended')
                        sended = sended + 1
                        redis:set("botBOT-IDfwdsended", sended)
                        redis:setex("botBOT-IDmaxfwd", 7, true)

                        if i == listcnt then
                            redis:del("botBOT-IDisfwd")
                            redis:set("botBOT-IDfwdsended", 0)
                        end
                        return
                    end
                end
            end
        end
        if not redis:get("botBOT-IDmaxlink") then
            if redis:scard("botswaitelinks") ~= 0 then
                local links = redis:smembers("botswaitelinks")
                for x,y in ipairs(links) do
                    if x == 3 then redis:setex("botBOT-IDmaxlink", 200, true) return end
                    tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
                end
            end
        end
        if not redis:get("botBOT-IDmaxjoin") then
            if redis:scard("botBOT-IDgoodlinks") ~= 0 then
                local links = redis:smembers("botBOT-IDgoodlinks")
                for x,y in ipairs(links) do
                    tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
                    if x == 1 then redis:setex("botBOT-IDmaxjoin", 300, true) return end
                end
            end
        end
        local msg = data.message_
        local bot_id = redis:get("botBOT-IDid") or get_bot()
        if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
            local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "4", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
            local txt = os.date("پیام ارسال شده از تلگرام")
            for k,v in ipairs(redis:smembers('botsadmin')) do
                send(v, 0, txt.."\n\n"..c)
            end
        end
        if tostring(msg.chat_id_):match("^(%d+)") then
            if not redis:sismember("botBOT-IDall", msg.chat_id_) then
                redis:sadd("botBOT-IDusers", msg.chat_id_)
                redis:sadd("botBOT-IDall", msg.chat_id_)
            end
        end
        add(msg.chat_id_)
        if msg.date_ < os.time() - 150 then
            return false
        end
        if msg.content_.ID == "MessageText" then
            local text = msg.content_.text_
            local matches
            if redis:get("botBOT-IDlink") then
                find_link(text)
            end
            if is_admin(msg) then
                find_link(text)

                if text:match("^(stop) (.*)$") then
                    local matches = text:match("^stop (.*)$")
                    if matches == "join" then
                        redis:set("botBOT-IDmaxjoin", true)
                        redis:set("botBOT-IDoffjoin", true)
                        return send(msg.chat_id_, msg.id_, "auto join stoped")
                    elseif matches == "check link" then
                        redis:set("botBOT-IDmaxlink", true)
                        redis:set("botBOT-IDofflink", true)
                        return send(msg.chat_id_, msg.id_, "check link process stoped")
                    elseif matches == "find link" then
                        redis:del("botBOT-IDlink")
                        return send(msg.chat_id_, msg.id_, "find link process stoped")
                    elseif matches == "add contact" then
                        redis:del("botBOT-IDsavecontacts")
                        return send(msg.chat_id_, msg.id_, "auto add contact process stoped")
                    end
                elseif text:match("^(start) (.*)$") then
                    local matches = text:match("^start (.*)$")
                    if matches == "join" then
                        redis:del("botBOT-IDmaxjoin")
                        redis:del("botBOT-IDoffjoin")
                        return send(msg.chat_id_, msg.id_, "auto join started")
                    elseif matches == "check link" then
                        redis:del("botBOT-IDmaxlink")
                        redis:del("botBOT-IDofflink")
                        return send(msg.chat_id_, msg.id_, "check link process started")
                    elseif matches == "find link" then
                        redis:set("botBOT-IDlink", true)
                        return send(msg.chat_id_, msg.id_, "find link process started")
                    elseif matches == "add contact" then
                        redis:set("botBOT-IDsavecontacts", true)
                        return send(msg.chat_id_, msg.id_, "auto add contact process started")
                    end
					elseif text:match("^(حداکثر گروه) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgroups', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>تعداد حداکثر سوپرگروه های تبلیغ‌گر تنظیم شد به : </i><b> "..matches.." </b>")
				elseif text:match("^(حداقل اعضا) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgpmmbr', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>عضویت در گروه های با حداقل</i><b> "..matches.." </b> عضو تنظیم شد.")
				elseif text:match("^(حذف حداکثر گروه)$") then
					redis:del('botBOT-IDmaxgroups')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز گروه نادیده گرفته شد.")
				elseif text:match("^(حذف حداقل اعضا)$") then
					redis:del('botBOT-IDmaxgpmmbr')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز اعضای گروه نادیده گرفته شد.")
                elseif text:match("^(add admin) (%d+)$") then
                    local matches = text:match("%d+")
                    if redis:sismember('botBOT-IDmod',msg.sender_user_id_) then
                        return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
                    end
                    if redis:sismember('botBOT-IDmod', matches) then
                        redis:srem("botBOT-IDmod",matches)
                        redis:sadd('botsadmin'..tostring(matches),msg.sender_user_id_)
                        return send(msg.chat_id_, msg.id_, "user is now admin")
                    elseif redis:sismember('botsadmin',matches) then
                        return send(msg.chat_id_, msg.id_, 'user was admin')
                    else
                        redis:sadd('botsadmin', matches)
                        redis:sadd('botsadmin'..tostring(matches),msg.sender_user_id_)
                        return send(msg.chat_id_, msg.id_, "user is now admin")
                    end
                elseif text:match("^(rem admin) (%d+)$") then
                    local matches = text:match("%d+")
                    if redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
                        if tonumber(matches) == msg.sender_user_id_ then
                            redis:srem('botsadmin', msg.sender_user_id_)
                            redis:srem('botBOT-IDmod', msg.sender_user_id_)
                            return send(msg.chat_id_, msg.id_, "شما دیگر مدیر نیستید.")
                        end
                        return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
                    end
                    if redis:sismember('botsadmin', matches) then
                        if  redis:sismember('botsadmin'..msg.sender_user_id_ ,matches) then
                            return send(msg.chat_id_, msg.id_, "شما نمی توانید مدیری که به شما مقام داده را عزل کنید.")
                        end
                        redis:srem('botsadmin', matches)
                        redis:srem('botBOT-IDmod', matches)
                        return send(msg.chat_id_, msg.id_, "user remove from admins list")
                    end
                    return send(msg.chat_id_, msg.id_, "user is'nt a admin")
                elseif text:match("^(seen) (.*)$") then
                    local matches = text:match("^seen (.*)$")
                    if matches == "on" then
                        redis:set("botBOT-IDmarkread", true)
                        return send(msg.chat_id_, msg.id_, "<i>auto seen enabled</i>")
                    elseif matches == "off" then
                        redis:del("botBOT-IDmarkread")
                        return send(msg.chat_id_, msg.id_, "<i>auto seen disabled</i>")
                    end
                elseif text:match("^(set contact msg) (.*)") then
                    local matches = text:match("^add contact msg (.*)")
                    redis:set("botBOT-IDaddmsgtext", matches)
                elseif text:match('^(set answer) "(.*)" (.*)') then
                    local txt, answer = text:match('^set answer "(.*)" (.*)')
                    redis:hset("botBOT-IDanswers", txt, answer)
                    redis:sadd("botBOT-IDanswerslist", txt)
                    return send(msg.chat_id_, msg.id_, "<i>answer to | </i>" .. tostring(txt) .. "<i> | is set to :</i>\n" .. tostring(answer))
                elseif text:match("^(rem answer) (.*)") then
                    local matches = text:match("^rem answer (.*)")
                    redis:hdel("botBOT-IDanswers", matches)
                    redis:srem("botBOT-IDanswerslist", matches)
                    return send(msg.chat_id_, msg.id_, "<i>answer to | </i>" .. tostring(matches) .. "<i> | removed from auto answer list.</i>")
                elseif text:match("^(auto answer) (.*)$") then
                    local matches = text:match("^auto answer (.*)$")
                    if matches == "on" then
                        redis:set("botBOT-IDautoanswer", true)
                        return send(msg.chat_id_, 0, "<i>auto answer is enabled</i>")
                    elseif matches == "off" then
                        redis:del("botBOT-IDautoanswer")
                        return send(msg.chat_id_, 0, "<i>auto answer is disabled</i>")
                    end
                elseif text:match("^(reload)$")then
                    local list = {redis:smembers("botBOT-IDsupergroups"),redis:smembers("botBOT-IDgroups")}
                    tdcli_function({
                        ID = "SearchContacts",
                        query_ = nil,
                        limit_ = 999999999
                    }, function (i, naji)
                        redis:set("botBOT-IDcontacts", naji.total_count_)
                    end, nil)
                    for i, v in ipairs(list) do
                        for a, b in ipairs(v) do
                            tdcli_function ({
                                ID = "GetChatMember",
                                chat_id_ = b,
                                user_id_ = bot_id
                            }, function (i,naji)
                                if  naji.ID == "Error" then
                                    rem(i.id)
                                end
                            end, {id=b})
                        end
                    end
                    return send(msg.chat_id_,msg.id_,"<i>bot with bot id: </i><code> BOT-ID </code> reloaded.")
                elseif text:match("^(state)$") then
                    local s =  redis:get("botBOT-IDoffjoin") and 0 or redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
                    local ss = redis:get("botBOT-IDofflink") and 0 or redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
                    local msgadd = redis:get("botBOT-IDaddmsg") and "✅️" or "⛔️"
                    --                local numadd = redis:get("botBOT-IDaddcontact") and "✅️" or "⛔️"
                    local txtadd = redis:get("botBOT-IDaddmsgtext") or  "addi, bia pv"
                    local autoanswer = redis:get("botBOT-IDautoanswer") and "✅️" or "⛔️"
                    local wlinks = redis:scard("botswaitelinks")
                    local glinks = redis:scard("botBOT-IDgoodlinks")
                    local links = redis:scard("botBOT-IDsavedlinks")
                    local offjoin = redis:get("botBOT-IDoffjoin") and "⛔️" or "✅️"
                    local offlink = redis:get("botBOT-IDofflink") and "⛔️" or "✅️"
                    local nlink = redis:get("botBOT-IDlink") and "✅️" or "⛔️"
                    local contacts = redis:get("botBOT-IDsavecontacts") and "✅️" or "⛔️"
                    local txt = "<i>state of bot</i><code> BOT-ID</code>\n\n"..
                            tostring(offjoin).."<code> auto join </code>\n"..
                            tostring(offlink).."<code> auto check link </code>\n"..
                            tostring(nlink).."<code> find join links </code>\n"..
                            tostring(contacts).."<code> auto add contact </code>\n" ..
                            tostring(autoanswer) .."<code> auto answer </code>\n" ..
                            tostring(msgadd) .. "<code>auto add contact msg on or off</code>\n<code> auto add contact msg :</code>" .. tostring(txtadd) ..
                            "\n\n<code>saved links : </code><b>" .. tostring(links) .. "</b>"..
                            "\n<code>wait to join links : </code><b>" .. tostring(glinks) .. "</b>"..
                            "\n<b>" .. tostring(s) .. " </b><code>second to join again</code>"..
                            "\n<code>wait to check links : </code><b>" .. tostring(wlinks) .. "</b>"..
                            "\n<b>" .. tostring(ss) .. " </b><code>second to check again</code>"
                    return send(msg.chat_id_, 0, txt)
                elseif text:match("^(panel)$") or text:match("^(Panel)$") then
                    local gps = redis:scard("botBOT-IDgroups")
                    local sgps = redis:scard("botBOT-IDsupergroups")
                    local usrs = redis:scard("botBOT-IDusers")
                    local links = redis:scard("botBOT-IDsavedlinks")
                    local glinks = redis:scard("botBOT-IDgoodlinks")
                    local wlinks = redis:scard("botswaitelinks")
                    tdcli_function({
                        ID = "SearchContacts",
                        query_ = nil,
                        limit_ = 999999999
                    }, function (i, naji)
                        redis:set("botBOT-IDcontacts", naji.total_count_)
                    end, nil)
                    local contacts = redis:get("botBOT-IDcontacts")
                    local text = [[
    <i> panel of bot </i>
    <code> pv : </code>
    <b>]] .. tostring(usrs) .. [[</b>
    <code> groups : </code>
    <b>]] .. tostring(gps) .. [[</b>
    <code> super groups : </code>
    <b>]] .. tostring(sgps) .. [[</b>
    <code> saved contacts : </code>
    <b>]] .. tostring(contacts)..[[</b>
    <code> saved links : </code>
    <b>]] .. tostring(links)..[[</b>]]
                    return send(msg.chat_id_, 0, text)

                elseif (text:match("^fwdsuper$") and msg.reply_to_message_id_ ~= 0) then
                    redis:del("botBOT-IDmaxfwd")
                    redis:set("botBOT-IDfwdsended", 0)
                    redis:set("botBOT-IDisfwd", true)
                    redis:set("botBOT-IDfwdmsg_id", msg.reply_to_message_id_)
                    redis:set("botBOT-IDfwdfrom_chat_id_", msg.chat_id_)
                    return send(msg.chat_id_, msg.id_, "<i>fwd with time limit started</i>")
                elseif (text:match("^fwd panel$")) then
                    local msg1 = 'there is not any process'
                    if redis:get("botBOT-IDfwdsended") then
                        msg1 = 'sended: '..redis:get("botBOT-IDfwdsended").."\n all: "..redis:scard("botBOT-IDsupergroups")
                    end
                    return send(msg.chat_id_, msg.id_, msg1 )
                elseif (text:match("^(send to) (.*)$") and msg.reply_to_message_id_ ~= 0) then
                    local matches = text:match("^send to (.*)$")
                    local naji
                    if matches:match("^(pv)") then
                        naji = "botBOT-IDusers"
                    elseif matches:match("^(gp)$") then
                        naji = "botBOT-IDgroups"
                    elseif matches:match("^(sgp)$") then
                        naji = "botBOT-IDsupergroups"
                    else
                        return true
                    end
                    local list = redis:smembers(naji)
                    local id = msg.reply_to_message_id_
                    print("chat id => ".. msg.chat_id_)
                    print("message_ids_ => ".. id)
                    print("chat id => ".. type(msg.chat_id_))
                    print("message_ids_ => ".. type(id))
                    for i, v in pairs(list) do
                        tdcli_function({
                            ID = "ForwardMessages",
                            chat_id_ = v,
                            from_chat_id_ = msg.chat_id_,
                            message_ids_ = {[0] = id},
                            disable_notification_ = 1,
                            from_background_ = 1
                        }, fwd_bac, nil)
                    end
                    return send(msg.chat_id_, msg.id_, "<i>sended</i>")
                elseif text:match("^(send to sgp) (.*)") then
                    local matches = text:match("^send to sgp (.*)")
                    local dir = redis:smembers("botBOT-IDsupergroups")
                    for i, v in pairs(dir) do
                        tdcli_function ({
                            ID = "SendMessage",
                            chat_id_ = v,
                            reply_to_message_id_ = 0,
                            disable_notification_ = 0,
                            from_background_ = 1,
                            reply_markup_ = nil,
                            input_message_content_ = {
                                ID = "InputMessageText",
                                text_ = matches,
                                disable_web_page_preview_ = 1,
                                clear_draft_ = 0,
                                entities_ = {},
                                parse_mode_ = nil
                            },
                        }, dl_cb, nil)
                    end
                    return send(msg.chat_id_, msg.id_, "<i>sended</i>")
                elseif text:match('^(set name) "(.*)" (.*)') then
                    local fname, lname = text:match('^set name "(.*)" (.*)')
                    tdcli_function ({
                        ID = "ChangeName",
                        first_name_ = fname,
                        last_name_ = lname
                    }, dl_cb, nil)
                    return send(msg.chat_id_, msg.id_, "<i>set new name success.</i>")
                elseif text:match("^(add to all) (%d+)$") then
                    local matches = text:match("%d+")
                    local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
                    for a, b in pairs(list) do
                        for i, v in pairs(b) do
                            tdcli_function ({
                                ID = "AddChatMember",
                                chat_id_ = v,
                                user_id_ = matches,
                                forward_limit_ =  50
                            }, dl_cb, nil)
                        end
                    end
                    return send(msg.chat_id_, msg.id_, "<i>added</i>")
                elseif text:match('^(startbots)') then
                    sendtobot()
                    return send(msg.chat_id_, msg.id_, "<i>bots started</i>")
                elseif text:match('^(addbots)') then
                    redis:setex("botBOT-IDapiadding", 300, true)
                    redis:set("botBOT-IDaddbots", true)
                    redis:del("botBOT-IDapiadded")
                    return send(msg.chat_id_, msg.id_, "<i>adding bots process started</i>")
                elseif text:match("^(help)$") then
                    local txt ='help: \n\n'..
                            'reload\n'..
                            '<i>reload bot panel</i>\n'..
                            '\n\nadd admin chatid\n<i>add chatid to admins list</i>'..
                            '\n\nrem admin chatid\n<i>remove chatid from admins list</i>'..
                            '\n\nset name "name" family\n<i>set bot name</i>'..
                            '\n\nstop join|check link|find link|add contact\n<i>stop a process</i> '..
                            '◼️\n\nstart join|check link|find link|add contact\n<i>start a process</i>'..
                            '\n\nset contact msg text\n<i>set (text) to answer to shared contact</i>'..
                            '\n\nseen on | off 👁\n<i>on or of auto seen</i>'..
                            '\n\npanel\n<i>get bot panel</i>'..
                            '\n\nstate\n<i>get bot state</i>'..
                            '\n\nstartbots\n<i>start api bots</i>'..
                            '\n\naddbots\n<i>add api bots to super groups</i>'..
                            '\n\nsend to pv|gp|sgp\n<i>send reply message</i>'..
                            '\n\nsend to sgp text\n<i>send text to all sgp</i>'..
                            '\n\nset answer "text" answer\n<i>add a asnwer to auto answer list</i>'..
                            '\n\nrem answer text\n<i>remove answer to text</i>'..
                            '\n\nauto answer on|off\n<i>turn on|off auto answer</i>'..
                            '\n\nadd to all chatid\n<i>add chatid to all gp and sgp</i>'..
                            '\n\nhelp\n<i>get this message</i>'
                    return send(msg.chat_id_,msg.id_, txt)


                end
            end
            if redis:sismember("botBOT-IDanswerslist", text) then
                if redis:get("botBOT-IDautoanswer") then
                    if msg.sender_user_id_ ~= bot_id then
                        local answer = redis:hget("botBOT-IDanswers", text)
                        send(msg.chat_id_, 0, answer)
                    end
                end
            end
        elseif (msg.content_.ID == "MessageContact" and redis:get("botBOT-IDsavecontacts")) then
            local id = msg.content_.contact_.user_id_
            if not redis:sismember("botBOT-IDaddedcontacts",id) then
                redis:sadd("botBOT-IDaddedcontacts",id)
                local first = msg.content_.contact_.first_name_ or "-"
                local last = msg.content_.contact_.last_name_ or "-"
                local phone = msg.content_.contact_.phone_number_
                local id = msg.content_.contact_.user_id_
                tdcli_function ({
                    ID = "ImportContacts",
                    contacts_ = {[0] = {
                        phone_number_ = tostring(phone),
                        first_name_ = tostring(first),
                        last_name_ = tostring(last),
                        user_id_ = id
                    },
                    },
                }, dl_cb, nil)
                if redis:get("botBOT-IDaddcontact") and msg.sender_user_id_ ~= bot_id then
                    local fname = redis:get("botBOT-IDfname")
                    local lnasme = redis:get("botBOT-IDlname") or ""
                    local num = redis:get("botBOT-IDnum")
                    tdcli_function ({
                        ID = "SendMessage",
                        chat_id_ = msg.chat_id_,
                        reply_to_message_id_ = msg.id_,
                        disable_notification_ = 1,
                        from_background_ = 1,
                        reply_markup_ = nil,
                        input_message_content_ = {
                            ID = "InputMessageContact",
                            contact_ = {
                                ID = "Contact",
                                phone_number_ = num,
                                first_name_ = fname,
                                last_name_ = lname,
                                user_id_ = bot_id
                            },
                        },
                    }, dl_cb, nil)
                end
            end
            if redis:get("botBOT-IDaddmsg") then
                local answer = redis:get("botBOT-IDaddmsgtext") or "addi, bia pv"
                send(msg.chat_id_, msg.id_, answer)
            end
        elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
            return rem(msg.chat_id_)
        elseif (msg.content_.caption_ and redis:get("botBOT-IDlink"))then
            find_link(msg.content_.caption_)
        end
        if redis:get("botBOT-IDmarkread") then
            tdcli_function ({
                ID = "ViewMessages",
                chat_id_ = msg.chat_id_,
                message_ids_ = {[0] = msg.id_}
            }, dl_cb, nil)
        end
    elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
        tdcli_function ({
            ID = "GetChats",
            offset_order_ = 9223372036854775807,
            offset_chat_id_ = 0,
            limit_ = 1000
        }, dl_cb, nil)
    end
end
