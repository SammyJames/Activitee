--
-- @Author: Pawkette
-- @Date: 9/15/13
--

local bpGoalEntry   = [=[<Text dimensions="left:0; right:100%; top:0; height:18" style="font:UbuntuMedium_9; valign:center"/>]=]

GoalEntry           = {}
GoalEntry.__index   = GoalEntry

setmetatable( GoalEntry, { __call = function( cls, ... ) return cls.new( ... ) end, } )

function GoalEntry.new( pLabel, pComplete, pParent )
    local self      = setmetatable( { }, GoalEntry )
    self.mParent    = pParent
    self.mComplete  = false
    self.mWidget    = Component.CreateWidget( bpGoalEntry, pParent )

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
            self.mWidget:SetTextColor( "#888888" ) --TODO: make tweakable?
        else
            self.mWidget:SetTextColor( "#FFFFFF" )
        end

        self.mComplete = pComplete
    end
end

--- Sets label text
-- @param pText
--
function GoalEntry:SetLabel( pText )
    self.mWidget:SetText( tostring( pText ) )
end

--- Wrapper
--
function GoalEntry:GetTextDims()
    return self.mWidget:GetTextDims()
end