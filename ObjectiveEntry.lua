--
-- @Author: Pawkette
-- @Date: 9/15/13
--

local skObjectiveLabelId    = "ObjectiveLabel"
local skLabelId             = "Label"

ObjectiveEntry              = {}
ObjectiveEntry.__index      = ObjectiveEntry

setmetatable( ObjectiveEntry, { __call = function( cls, ... ) return cls.new( ... ) end, } )

--- Creates a new objective entry
-- @param pObjective
-- @param pParent
--
function ObjectiveEntry.new( pObjective, pParent, pOptions )
    local self      = setmetatable( { }, ObjectiveEntry )
    self.mObjective = pObjective
    self.mParent    = pParent
    self.mWidget    = Component.CreateWidget( skObjectiveLabelId, pParent )
    self.mLabel     = self.mWidget:GetChild( skLabelId )

    self.mLabel:SetFont( pOptions:GetValue( "#objectivefont" ) )
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

--- Wrapper
--
function ObjectiveEntry:GetBounds()
    return self.mWidget:GetBounds()
end

--- Wrapper
-- @param ...
--
function ObjectiveEntry:SetDims( ... )
    self.mWidget:SetDims( ... )
end

function ObjectiveEntry:SetFont( pFont )
    self.mLabel:SetFont( pFont )
    self:SetLabel( self.mObjective.description )
end