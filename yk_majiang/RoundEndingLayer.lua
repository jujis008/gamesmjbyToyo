local Card = require("yk_majiang.card.card")
local sendHandle = require("yk_majiang.handle.YKMJSendHandle")

local RoundEndingLayer = class("RoundEndingLayer")

local CHILD_NAME_FLOOR = "floor"
local CHILD_NAME_TITLE_BG_IMG = "title_bg_img"
local CHILD_NAME_TITLE_IMG = "title_img"
local CHILD_NAME_SHOW_PLANE = "show_plane"
local CHILD_NAME_BIRD_CARD_PLANE = "bird_card_plane"
local CHILD_NAME_START_BT = "start_bt"
local CHILD_NAME_CLOSE_BT = "close_bt"
local CHILD_NAME_ROOM_LB = "room_lb"
local CHILD_NAME_BIRD_LB = "bird_lb"
local CHILD_NAME_TIME_LB = "time_lb"
local CHILD_NAME_JIESAN_BT = "jiesan_bt"
local CHILD_NAME_HUIPAI_BOX = "huipai_bx"

local CHILD_NAME_PLAYER1_PLANE = "player1_plane"
local CHILD_NAME_PLAYER2_PLANE = "player2_plane"
local CHILD_NAME_PLAYER3_PLANE = "player3_plane"
local CHILD_NAME_PLAYER4_PLANE = "player4_plane"

local CHILD_NAME_ZHUANG_SIGNAL = "zhuang_signal"
local CHILD_NAME_NICK_LB = "nick_lb"
local CHILD_NAME_DESC_LB = "desc_lb"
local CHILD_NAME_CARD_PLANE = "card_plane"
local CHILD_NAME_SCORE_LB = "score_lb"
local CHILD_NAME_HU_SIGNAL = "hu_signal"

local TITLE_TYPE_WIN = 1
local TITLE_TYPE_LOSE = 2
local TITLE_TYPE_LIUJU = 3

local win_lose_table = {} -- key = seatId

local isShow = false

function RoundEndingLayer:showZhuaniao(data, isEnd)
	isShow = true

	win_lose_table = {}

	for k,v in pairs(data.players) do
		local player = v
		if player.huTypeCount > 0 then
			--todo
			win_lose_table[k - 1] = "Y"
		else
			win_lose_table[k - 1] = "N"
		end
	end

	local cards_tb1 = {}
	local zhongcard = {}
	local count = table.getn(data.birdCards)
	for i=1,count do
		table.insert(cards_tb1, data.birdCards[i]["card"])
		if data.birdCards[i]["position"] == 1 then
			--todo
			table.insert(zhongcard, data.birdCards[i]["card"])
		end
	end

	local timeDelay = require("yk_majiang.result_effect_layout"):reset_niaocard_data(cards_tb1, zhongcard)
	
	if timeDelay == 0 then
		--todo
		timeDelay = 3
	else
		timeDelay = timeDelay + 3
	end

	local zhuaniaoLayout = SCENENOW["scene"]:getChildByName("zhuaniaoLayout")
	if zhuaniaoLayout then
		--todo
		local callFuncAc = cc.CallFunc:create(function ()
				zhuaniaoLayout:removeFromParent()
				YKMJ_CONTROLLER:clearGameDatas()
				self:show(data, isEnd)
			end)

		zhuaniaoLayout:runAction(cc.Sequence:create(cc.DelayTime:create(timeDelay), callFuncAc))
	end
end

--显示墙头牌
function RoundEndingLayer:HuiPai(qiangtoupai)
    local huipai_box=self.floor:getChildByName(CHILD_NAME_HUIPAI_BOX)

    if qiangtoupai>0 then huipai_box:setVisible(true)   
    else  huipai_box:setVisible(false)   end
    huipai_box:removeAllChildren()
    local value = qiangtoupai
    local card = Card:new(CARD_PLAYERTYPE_MY, CARD_TYPE_INHAND, CARD_DISPLAY_TYPE_OPPOSIVE, value)
	local size = card:getSize()
	local scale = (huipai_box:getSize().height - 20) / size.height
	card:setScale(scale)
	card:setColor(cc.c3b(250,250,0))
	card:setPosition(cc.p(huipai_box:getSize().width / 2, huipai_box:getSize().height / 2))
    huipai_box:addChild(card)
end

function RoundEndingLayer:show(data, isEnd)
   
	isShow = true
	local isEndT = isEnd or false

	win_lose_table = {}

	self._scene = cc.CSLoader:createNode("yk_majiang/roundEndingLayer.csb")
	self.floor = self._scene:getChildByName(CHILD_NAME_FLOOR)
	self.showPlane = self.floor:getChildByName(CHILD_NAME_SHOW_PLANE)

    --先隐藏所有 再根据需要打开
	for  index=1,4 do 
	local playerPlaneName = "player" .. index .. "_plane"
	local playerPlane = self.showPlane:getChildByName(playerPlaneName)
	playerPlane:setVisible(false)
	end


	--显示墙头牌
	--dump(data.Qiangtoupai, "data.Qiangtoupai")
	if  data.Qiangtoupai then
		--dump(data.Qiangtoupai, "data.Qiangtoupai2")
	self:HuiPai(data.Qiangtoupai)
	end
	--

	local endType = data.type
	local uid = data.uid

	local players = data.players

	local me = nil
	for i=1,table.getn(players) do

		local isZhuang = false
		
		if YKMJ_ZHUANG_UID == players[i].uid then  --此玩家为庄家的情况下
			--todo
			isZhuang = true
			    ----------------解决四人营口连庄最后一局连庄的代码----------
				if PLAYERNUM == 4 then
				if players[i].huTypeCount > 0 then  --此玩家为庄家且胡了的情况下
					 isEndT = false
				end
				end
				--------------------------------------------------------------
		end
		    
        --流局屏蔽后台发来的huTypeCount
		if  endType == 0 then
			players[i].huTypeCount=0
		end

		self:dealPlayerCards(players[i].remainCards, data.huCard, players[i].huTypeCount)
		self:showPlayerPlane(players[i], i, isZhuang, data.huCard)

		if tonumber(players[i].uid) == tonumber(USER_INFO["uid"]) then
			--todo
			me = players[i]
		end
	end

	local titleType = TITLE_TYPE_LIUJU
	if endType ~= 0 then
		--todo
		if me.changeCoins > 0 then
			--todo
			titleType = TITLE_TYPE_WIN
		else
			titleType = TITLE_TYPE_LOSE
		end
	end

	self:showTitle(titleType)

	self:showBirdCards(data.birdCards)

	for i=1,table.getn(players) do

		self:showEndingInfo(players[i], i)
	end


	local timeStr = os.date("%Y-%m-%d %H:%M:%S",data["time"])
	self:showGameRemark(timeStr)

	local start_bt = self.floor:getChildByName(CHILD_NAME_START_BT)

	if start_bt then
		--todo
		local function bt_callback(sender, event)
			if event == TOUCH_EVENT_ENDED then
				--todo
				sendHandle:readyNow()

				self._scene:removeFromParent()
				isShow = false
			end
		end

		start_bt:addTouchEventListener(bt_callback)

		if isEndT then
			--todo
			start_bt:setVisible(false)
		else
			start_bt:setVisible(true)
		end
	end

	local close_bt = self.floor:getChildByName(CHILD_NAME_CLOSE_BT)

	if close_bt then
		--todo
		local function bt_callback(sender, event)
			if event == TOUCH_EVENT_ENDED then
				--todo
				self._scene:removeFromParent()

				if YKMJ_GROUP_ENDING_DATA then
					--todo
					require("yk_majiang.GroupEndingLayer"):showGroupResult(YKMJ_GROUP_ENDING_DATA)
				end

				isShow = false

			end
		end

		close_bt:addTouchEventListener(bt_callback)

		if isEndT then
			--todo
			close_bt:setVisible(true)
		else
			close_bt:setVisible(false)
		end
	end

	local jiesan_bt = self.floor:getChildByName(CHILD_NAME_JIESAN_BT)

	if jiesan_bt then
		--todo
		local function bt_callback(sender, event)
			if event == TOUCH_EVENT_ENDED then
				--todo
				SCENENOW["scene"]:disbandGroup()

			end
		end

		jiesan_bt:addTouchEventListener(bt_callback)

		if isEndT then
			--todo
			jiesan_bt:setVisible(false)
		else
			jiesan_bt:setVisible(true)
		end
	end

	self._scene:setName("roundEndingLayer")
	SCENENOW["scene"]:addChild(self._scene)
end

function RoundEndingLayer:hide()
	local layer = SCENENOW["scene"]:getChildByName("roundEndingLayer")

	if layer then
		--todo
		layer:removeFromParent()
	end
end

function RoundEndingLayer:isShow()
	return isShow
end

function RoundEndingLayer:setIsShow(param)
	isShow = param
end

function RoundEndingLayer:showPlayerPlane(player, index, isZhuang, huCard)
	local playerPlaneName = "player" .. index .. "_plane"
	local playerPlane = self.showPlane:getChildByName(playerPlaneName)
	playerPlane:setVisible(true)

	local zhuang_signal = playerPlane:getChildByName(CHILD_NAME_ZHUANG_SIGNAL)
	zhuang_signal:setVisible(isZhuang)

	local hu_signal = playerPlane:getChildByName(CHILD_NAME_HU_SIGNAL)
	if player.changeCoins > 0 then
		--todo
		win_lose_table[index - 1] = "Y"
	elseif player.changeCoins == 0 then
		win_lose_table[index - 1] = "N"
	else
		win_lose_table[index - 1] = "Y"
	end

	if player.huTypeCount > 0 then
		--todo
		hu_signal:setVisible(true)
	else
		hu_signal:setVisible(false)
	end

	local score_lb = playerPlane:getChildByName(CHILD_NAME_SCORE_LB)
	score_lb:setString("" .. player.changeCoins)

	local seatId = index - 1

	local nickname = YKMJ_USERINFO_TABLE[seatId .. ""].nick

	local nick_lb = playerPlane:getChildByName(CHILD_NAME_NICK_LB)

	nick_lb:setString(nickname)

	local card_plane = playerPlane:getChildByName(CHILD_NAME_CARD_PLANE)

	local progCards = {}

	for i=1,player.agCount do
		local p = {}
		p.type = "ag"

		local cs = {player.agCards[i], player.agCards[i], player.agCards[i], player.agCards[i]}

		p.cards = cs

		table.insert(progCards, p)
	end

	for i=1,player.gCount do
		local p = {}
		p.type = "g"

		local cs = {player.gCards[i], player.gCards[i], player.gCards[i], player.gCards[i]}

		p.cards = cs

		table.insert(progCards, p)
	end

    for i=1,player.xfgFengCount do
		local p = {}
		p.type = "xfgFeng"

		local cs = {49, 50, 51, 52}

		p.cards = cs

		table.insert(progCards, p)
	end

	for i=1,player.xfgJianCount do
		local p = {}
		p.type = "xfgJian"

		local cs = {65, 66, 67}

		p.cards = cs

		table.insert(progCards, p)
	end

	for i=1,player.pCount do
		local p = {}
		p.type = "p"

		local cs = {player.pCards[i], player.pCards[i], player.pCards[i]}

		p.cards = cs

		table.insert(progCards, p)
	end

	local p = nil
	local cs = nil
	for i=1,player.cCount do
		if i % 3 == 1 then
			--todo
			p = {}
			p.type = "c"
			cs = {}
			p.cards = cs
			table.insert(cs, player.cCards[i])
		elseif i % 3 == 0 then
			table.insert(cs, player.cCards[i])

			table.insert(progCards, p)
		else
			table.insert(cs, player.cCards[i])
		end
	end

	if player.huTypeCount > 0 and player.isQishou == 0 then
		--todo
		self:showPlayerCards(progCards, player.remainCards, card_plane, huCard)
	else
		self:showPlayerCards(progCards, player.remainCards, card_plane, nil)
	end

	
end

function RoundEndingLayer:showEndingInfo(player, index)
	local playerPlaneName = "player" .. index .. "_plane"
	local playerPlane = self.showPlane:getChildByName(playerPlaneName)

	local desc_lb = playerPlane:getChildByName(CHILD_NAME_DESC_LB)

	local endingInfo = ""

	if player.winLoseType == -1 then
		--todo
		endingInfo = endingInfo .. "点炮 "
	elseif player.winLoseType == 1 then
		endingInfo = endingInfo .. "接炮 "
	elseif player.winLoseType == 2 then
		endingInfo = endingInfo .. "自摸 "
	end

	for i=1,player.huTypeCount do
		endingInfo = endingInfo .. YKMJ_HU_TYPE_TABLE[player.huTypes[i] + 1] .. " "
	end

	local birdCount = win_lose_table[(index - 1) .. "birdCount"]
	if not birdCount then
		--todo
		birdCount = 0
	end

	-- endingInfo = endingInfo .. "中" .. birdCount .. "鸟"

	if player.huTypeCount > 0 and player.kanCount > 0 then
		--todo
		endingInfo = endingInfo .. player.kanCount .. "坎 "
	end
	
	if player.dgCount > 0 then
		--todo
		endingInfo = endingInfo .. "点杠x" .. player.dgCount .. " "
	end
	if player.pgCount > 0 then
		--todo
		endingInfo = endingInfo .. "直杠x" .. player.pgCount .. " "
	end
	if player.bgCount > 0 then
		--todo
		endingInfo = endingInfo .. "补杠x" .. player.bgCount .. " "
	end
	if player.agCount > 0 then
		--todo
		endingInfo = endingInfo .. "暗杠x" .. player.agCount .. " "
	end
	if (player.xfgFengCount + player.xfgJianCount) > 0 then
		--todo
		endingInfo = endingInfo .. "旋风杠x" .. (player.xfgFengCount + player.xfgJianCount) .. " "
	end

	desc_lb:setString(endingInfo)
end

function RoundEndingLayer:showTitle(titleType)
	local title_bg_img = self.floor:getChildByName(CHILD_NAME_TITLE_BG_IMG)
	local title_img = self.floor:getChildByName(CHILD_NAME_TITLE_IMG)

	if titleType == TITLE_TYPE_WIN then
		--todo
		title_bg_img:loadTexture("yk_majiang/image/red_button_p.png")
		title_img:loadTexture("yk_majiang/image/mahjong_win.png")
	elseif titleType == TITLE_TYPE_LOSE then
		title_bg_img:loadTexture("yk_majiang/image/mahjong_lose_bt.png")
		title_img:loadTexture("yk_majiang/image/mahjong_lose.png")
	else
		title_bg_img:loadTexture("yk_majiang/image/grey_button.png")
		title_img:loadTexture("yk_majiang/image/text_liuju.png")
	end
end

function RoundEndingLayer:showGameRemark(timeStr)
	local room_lb = self.floor:getChildByName(CHILD_NAME_ROOM_LB)
	local bird_lb = self.floor:getChildByName(CHILD_NAME_BIRD_LB)
	local time_lb = self.floor:getChildByName(CHILD_NAME_TIME_LB)

	room_lb:setString("房号" .. USER_INFO["invote_code"])
	-- bird_lb:setString("抓2鸟")
	if USER_INFO["gameConfig"] then
		--todo
		bird_lb:setString("营口麻将：" .. USER_INFO["gameConfig"])
	else
		bird_lb:setString("正在读取组局信息")
	end
	time_lb:setString(timeStr)
end

function RoundEndingLayer:showBirdCards(cards)
	if not cards then
		--todo
		return
	end

	local bird_card_plane = self.floor:getChildByName(CHILD_NAME_BIRD_CARD_PLANE)

	local height = bird_card_plane:getSize().height

	local count = table.getn(cards)
	for i=1,count do
		local card = Card:new(CARD_PLAYERTYPE_MY, CARD_TYPE_OUTHAND, CARD_DISPLAY_TYPE_SHOW, cards[i]["card"])

		local scale = height / card:getSize().height

		if cards[i]["position"] == 1 then
			--todo
			card:setColor(cc.c3b(200, 200, 50))

			local countKey = cards[i]["position"] .. "birdCount"

			if win_lose_table[countKey] then
				--todo
				local count = win_lose_table[countKey] + 1

				win_lose_table[countKey] = count
			else
				local count = 1
				win_lose_table[countKey] = count
			end
		end

		card:setScale(scale)

		card:setPosition(cc.p(card:getSize().width * scale * (i - 1) + card:getSize().width * scale / 2, height / 2))

		bird_card_plane:addChild(card)
	end
end

function RoundEndingLayer:showPlayerCards(progCards, handCards, cardPlane, huCard)
	if not cardPlane then
		--todo
		return
	end

	local progCount = table.getn(progCards)
	local handCount = table.getn(handCards)

	local oriX = 0

	for i=1,progCount do
		local cType = progCards[i].type
		local cards = progCards[i]["cards"]

		for j=1,table.getn(cards) do
			local card

			if cType == "ag" and j == 1 then
				--todo
				card = Card:new(CARD_PLAYERTYPE_MY, CARD_TYPE_OUTHAND, CARD_DISPLAY_TYPE_HIDE, cards[j])
			else
				card = Card:new(CARD_PLAYERTYPE_MY, CARD_TYPE_OUTHAND, CARD_DISPLAY_TYPE_SHOW, cards[j])
			end

			local size = card:getSize()

			card:setPosition(cc.p(oriX + size.width / 2, size.height / 2))

			cardPlane:addChild(card)

			oriX = oriX + size.width
		end

		oriX = oriX + 20
	end

	for i=1,handCount do

		local if_huipai = false
		for k,v in pairs(HUIPAI) do
			if handCards[i] == v then
				if_huipai = true
				break
			end
		end

		local card = Card:new(CARD_PLAYERTYPE_MY, CARD_TYPE_OUTHAND, CARD_DISPLAY_TYPE_SHOW, handCards[i],if_huipai)

		local size = card:getSize()
        
        if  if_huipai == true then
            card:setColor(cc.c3b(140, 140, 140))
       	end
       	
		card:setPosition(cc.p(oriX + size.width / 2, size.height / 2))

		cardPlane:addChild(card)

		oriX = oriX + size.width
	end

	if huCard then
		--todo
		oriX = oriX + 20

		local card = Card:new(CARD_PLAYERTYPE_MY, CARD_TYPE_OUTHAND, CARD_DISPLAY_TYPE_SHOW, huCard)

		local size = card:getSize()

		card:setPosition(cc.p(oriX + size.width / 2, size.height / 2))

		cardPlane:addChild(card)
	end
end

function RoundEndingLayer:dealPlayerCards(cards, huCard, huTypeCount)
	if huTypeCount <= 0 then
		--todo
		return
	end
	
	if huCard and huCard > 0 then
		--todo
		for i=1,table.getn(cards) do
			if cards[i] == huCard then
				--todo
				table.remove(cards, i)

				break
			end
		end
	end
	
end

return RoundEndingLayer