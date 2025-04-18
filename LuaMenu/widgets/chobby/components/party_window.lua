PartyWindow = LCS.class{}

PartyWindow.RIGHT_MARGIN = 20
PartyWindow.LEFT_MARGIN = 20
PartyWindow.TOP_MARGIN = 17
PartyWindow.BOTTOM_MARGIN = 0

PartyWindow.TITLE_HEIGHT = 20
PartyWindow.SECTION_HEADER_HEIGHT = 15 -- font1 size

PartyWindow.MINOR_SPACING = 5
PartyWindow.MAJOR_SPACING = 20

PartyWindow.BUTTON_WIDTH = 100

PartyWindow.CONTENT_Y_OFFSET = PartyWindow.TITLE_HEIGHT + PartyWindow.MINOR_SPACING

function PartyWindow:init(parent)
    self.window = Window:New{
        x = 0,
        right = 0,
        y = 0,
        bottom = 0,
        padding = { PartyWindow.LEFT_MARGIN, PartyWindow.TOP_MARGIN, PartyWindow.RIGHT_MARGIN, PartyWindow.BOTTOM_MARGIN },
        parent = parent,
        resizable = false,
        draggable = false,
        classname = "PartyWindow"
    }

    Label:New {
        parent = self.window,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(3),
        caption = i18n("parties"),
    }

    self.requiresLoginLabel = Label:New {
        y = PartyWindow.CONTENT_Y_OFFSET,
        objectOverrideFont = WG.Chobby.Configuration:GetFont(1, "parties_require_login", { color = { 0.5, 0.5, 0.5, 1 } }),
        parent = self.window,
        caption = i18n("parties_require_login")
    }

    self.createPartyButton = Button:New {
        caption = i18n("create_new_party"),
        parent = self.window,
        right = 0,
        width = PartyWindow.BUTTON_WIDTH,
        classname = "option_button",
        visible = false,
        OnClick = {
            function()
                if lobby.myPartyID then
                    self:LeaveMyCurrentParty()
                end
                lobby:CreateParty(
                    nil,
                    function(errorMessage)
                        ErrorPopup(i18n("error_party_create_failed", { error_message = errorMessage }))
                    end
                )
            end
        },
    }
    self.createPartyButton:Hide()

    -- In a party

    self.yourPartyLabel = Label:New {
        y = PartyWindow.CONTENT_Y_OFFSET,
        caption = i18n("your_party_title"),
        parent = self.window
    }
    self.yourPartyLabel:Hide()

    self.invitesLabel = Label:New {
        caption = i18n("your_party_invites"),
        parent = self.window
    }
    self.invitesLabel:Hide()

    self.partyWrappers = {}

    lobby:AddListener("OnAccepted", function()
        self.requiresLoginLabel:Hide()
        self.createPartyButton:Show()
    end)

    lobby:AddListener("OnDisconnected", function()
        self.requiresLoginLabel:Show()
        self.createPartyButton:Hide()
        self.invitesLabel:Hide()
        self.yourPartyLabel:Hide()

        for partyID, partyWrapper in pairs(self.partyWrappers) do
            partyWrapper.wrapper:Dispose()
            self.partyWrappers[partyID] = nil
        end
    end)

    lobby:AddListener("OnRemoveUser", function(_, username)
        for partyID, partyWrapper in pairs(self.partyWrappers) do
            if partyWrapper.inviteRows[username] then
                partyWrapper:RemoveInvite(username)
            end
        end
    end)

    lobby:AddListener("OnJoinedParty", function(_, ...)
        self:JoinedParty(...)
    end)

    lobby:AddListener("OnLeftParty", function(_, ...)
        self:LeftParty(...)
    end)

    lobby:AddListener("OnInvitedToParty", function(_, ...)
        self:InvitedToParty(...)
    end)

    lobby:AddListener("OnPartyInviteCancelled", function(_, ...)
        self:InviteToPartyCancelled(...)
    end)
end

function PartyWindow:UpdateLayout()
    local offset = PartyWindow.CONTENT_Y_OFFSET

    if lobby.myPartyID then
        local myPartyWrapper = self.partyWrappers[lobby.myPartyID]
        offset = myPartyWrapper.wrapper.y +
                 myPartyWrapper:TotalHeight() +
                 PartyWindow.MINOR_SPACING
    end

    self.invitesLabel:SetPos(0, offset)
    self.invitesLabel:Hide()

    offset = offset + PartyWindow.SECTION_HEADER_HEIGHT + PartyWindow.MINOR_SPACING

    for partyID, partyWrapper in pairs(self.partyWrappers) do
        if partyID ~= lobby.myPartyID then
            self.invitesLabel:Show()
            partyWrapper.wrapper:SetPos(0, offset)
            offset = offset + partyWrapper:TotalHeight() + PartyWindow.MINOR_SPACING
        end
    end
end

function PartyWindow:LeaveMyCurrentParty()
    local myPartyID = lobby.myPartyID
    lobby:LeaveMyCurrentParty(nil, 
    function(errorMessage)
        ErrorPopup(i18n("error_party_leave_failed", { error_message = errorMessage }))
    end)
end

function PartyWindow:LeftParty(partyID, username, partyDestroyed)
    if partyDestroyed then
        self.partyWrappers[partyID].wrapper:Dispose()
        self.partyWrappers[partyID] = nil
        if username == lobby.myUserName then
            self.yourPartyLabel:Hide()
        end
    else
        self.partyWrappers[partyID]:RemoveMember(username)
    end

    self:UpdateLayout()
end
function PartyWindow:JoinedParty(partyID, username)
    local partyWrapper = self.partyWrappers[partyID] or PartyWrapper(self.window, partyID)

    if username == lobby.myUserName then
        partyWrapper:ClearActionButtons()
        partyWrapper:AddActionButton(i18n("leave_my_party"), "negative_button", function() self:LeaveMyCurrentParty() end)

        partyWrapper.wrapper:SetPos(0, PartyWindow.CONTENT_Y_OFFSET + PartyWindow.SECTION_HEADER_HEIGHT + PartyWindow.MINOR_SPACING)
        partyWrapper.wrapper:Show()
        self.yourPartyLabel:Show()
    end
    
    partyWrapper:RemoveInvite(username)
    partyWrapper:AddMember(username)
    
    self.partyWrappers[partyID] = partyWrapper
    self:UpdateLayout()
end
function PartyWindow:InvitedToParty(partyID, username)
    if username == lobby.myUserName then
        self.partyWrappers[partyID] = PartyWrapper(self.window, partyID)
        self.partyWrappers[partyID]:AddActionButton(i18n("accept_party_invite"), "positive_button", function() 
            if lobby.myPartyID then
                self:LeaveMyCurrentParty()
            end
            lobby:AcceptInviteToParty(
                partyID,
                nil, 
                function(errorMessage)
                    ErrorPopup(i18n("error_party_accept_invite_failed", { error_message = errorMessage }))
                end
            )
        end)

        self.partyWrappers[partyID]:AddActionButton(i18n("decline_party_invite"), "negative_button",
            function() 
                lobby:DeclineInviteToParty(
                    partyID,
                    nil, 
                    function(errorMessage)
                        ErrorPopup(i18n("error_party_decline_invite_failed", { error_message = errorMessage }))
                    end
                )
            end
        )

        self.partyWrappers[partyID].wrapper:Show()
        self.invitesLabel:Show()
    else
        self.partyWrappers[partyID]:AddInvite(username)
    end

    self:UpdateLayout()
end
function PartyWindow:InviteToPartyCancelled(partyID, username)
    self.partyWrappers[partyID]:RemoveInvite(username)

    if username == lobby.myUserName then
        self.partyWrappers[partyID].wrapper:Dispose()
        self.partyWrappers[partyID] = nil
    end

    self:UpdateLayout()
end