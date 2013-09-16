--
-- @Author: Pawkette
-- @Date: 9/15/13
--

local skObjectiveLabelId    = "ObjectiveLabel"
local skLabelId             = "Label"

ObjectiveEntry = {}
ObjectiveEntry.__index = ObjectiveEntry

setmetatable( ObjectiveEntry, { __call = function( cls, ... ) return cls.new( ... ) end, } )

--- Creates a new objective entry
-- @param pObjective
-- @param pParent
--
function ObjectiveEntry.new( pObjective, pParent )
    local self = setmetatable( { }, ObjectiveEntry )
    self.mObjective = pObjective
    self.mParent    = pParent
    self.mWidget    = Component.CreateWidget( skObjectiveLabelId, pParent )
    self.mLabel     = self.mWidget:GetChild( skLabelId )

    self.mLabel:SetFont( "UbuntuRegular_10" )
    self:SetLabel( tostring( pObjective.description ) )

    return self
end

--- Set this objective's text
-- @param pText
--
function ObjectiveEntry:SetLabel( pText )
    self.mLabel:SetText( tostring( pText ) )

    local dimensions    = self.mLabel:GetTextDims()
    self.mWidget:SetDims( "right:_; width:" .. dimensions.width .. "; center-y:_; height:" .. dimensions.height )
end
