--
-- @Author: Pawkette
-- @Date: 9/15/13
--

local skObjectiveId = "ObjectiveLabel"
local skLabelId     = "Label"

GoalEntry           = {}
GoalEntry.__index   = GoalEntry

setmetatable( GoalEntry, { __call = function( cls, ... ) return cls.new( ... ) end, } )

function GoalEntry.new( pLabel, pComplete, pParent )
    local self      = setmetatable( { }, GoalEntry )
    self.mParent    = pParent
    self.mComplete  = false
    self.mWidget    = Component.CreateWidget( skObjectiveId, pParent )
    self.mLabel     = self.mWidget:GetChild( skLabelId )

    self.mLabel:SetFont( "UbuntuRegular_10" )

    self:SetLabel( pLabel )
    self:SetComplete( pComplete )

    return self
end

--- Changes text color based on status
-- @param pComplete
--
function GoalEntry:SetComplete( pComplete )
    if ( self.mComplete ~= pComplete ) then
        if ( pComplete ) then
            self.mLabel:SetTextColor( "#888888" ) --TODO: make tweakable?
        else
            self.mLabel:SetTextColor( "#FFFFFF" )
        end

        self.mComplete = pComplete
    end
end

--- Sets label text
-- @param pText
--
function GoalEntry:SetLabel( pText )
    self.mLabel:SetText( tostring( pText ) )

    local dimensions    = self.mLabel:GetTextDims()
    self.mWidget:SetDims( "right:_; width:" .. dimensions.width .. "; center-y:_; height:" .. dimensions.height )
end

--- Wrapper
--
function GoalEntry:GetTextDims()
    return self.mLabel:GetTextDims()
end

--- Wrapper
--
function GoalEntry:GetBounds()
    return self.mWidget:GetBounds()
end

--- Wrapper
-- @param ...
--
function GoalEntry:SetDims( ... )
    self.mWidget:SetDims( ... )
end