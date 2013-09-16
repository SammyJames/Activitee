--
-- @Author: Pawkette
-- @Date: 9/15/13
--

require "table"
require "lib/lib_MultiArt"

local skActivityTypeId  = "Activity"
local skIconGroupId     = "IconGroup"
local skLabelGroupId    = "LabelGroup"
local skLabelId         = "Label"
local skObjectiveLabelId= "ObjectiveLabel"
local skDistanceGroupId = "DistanceGroup"
local skObjectivesId    = "ObjectiveList"

local eMission          = "Mission"
--[[
-- local eEncounter        = "Encounter"
-- local eAchievement      = "Achievement"
-- local eOutpost          = "Outpost"
-- local eResourceNode     = "ResourceNode"
-- local eInstanceStep     = "InstanceStep"
--]]

local bpMarker          = [=[<MapMarker name="Marker" dimensions="center-x:50%; center-y:50%; width:10; height:10" mesh="rotater_reverse" class="Marker"/>]=]
--local bpGoalEntry       = [=[<Text dimensions="left:0; right:100%; top:0; height:18" style="font:UbuntuMedium_9; valign:center"/>]=]

ActivityEntry = {}
ActivityEntry.__index = ActivityEntry

setmetatable( ActivityEntry, { __call = function( cls, ... ) return cls.new( ... ) end, } )

--- Creates a new Activity Entry
-- @param pActivity the activity data table
-- @param pUID the unique id of this entry
--
function ActivityEntry.new( pActivity, pUID, pParent )
    local self = setmetatable( { }, ActivityEntry )
    self.mActivityData  = pActivity
    self.mUID           = pUID
    self.mParent        = pParent
    self.mFullHeight    = 0

    self.mGroup         = Component.CreateWidget( skActivityTypeId, pParent )
    self.mGroup:SetDims( "top:_; height:48" )

    self.mIconGroup     = self.mGroup:GetChild( skIconGroupId )
    self.mLabelGroup    = self.mIconGroup:GetChild( skLabelGroupId )
    self.mLabel         = self.mLabelGroup:GetChild( skLabelId )

    self.mMultiArt      = MultiArt.Create( self.mIconGroup:GetChild( "Icon" ) )
    self.mDistanceGroup = self.mGroup:GetChild( skDistanceGroupId )
    self.mDistance      = self.mDistanceGroup:GetChild( skLabelId )
    self.mObjectives    = self.mGroup:GetChild( skObjectivesId )
    self.mMarkers       = {}

    self.mDistance:SetFont( "UbuntuBold_8" )
    self.mLabel:SetFont( "UbuntuMedium_12" )

    self:SetLabel( pActivity.title )

    if ( pActivity.icon ) then
        self.mMultiArt:SetIcon( pActivity.icon )

        if ( pActivity.iconTint ) then
            self.mMultiArt:SetParam( "tint", pActivity.iconTint )
        end
    elseif ( pActivity.typename == eMission ) then
        self.mMultiArt:SetTexture( "icons", "mission_waypoint" )
    else
        self.mMultiArt:SetTexture( "battleframes", "unknown" )
    end

    return self
end

--- Sets this activities label
-- @param pText
--
function ActivityEntry:SetLabel( pText )
    self.mLabel:SetText( tostring( pText ) )

    local dimensions = self.mLabel:GetTextDims()
    self.mLabelGroup:SetDims( "right:_; width:" .. dimensions.width .. "; center-y:_; height:" .. dimensions.height )
end

--- Sets the distance between player and this activity
-- @param pDistance
--
function ActivityEntry:SetDistance( pDistance )
    if ( pDistance ~= 0 ) then
        self.mDistance:SetText( tostring( Component.LookupText( "DISTANCE_IN_METERS", pDistance ) ) )
        self.mDistanceGroup:Show()
    else
        self.mDistanceGroup:Hide()
    end
end

--- GET UID
--
function ActivityEntry:GetUID()
    return self.mUID
end

--- SET UID
-- @param pUID
--
function ActivityEntry:SetUID( pUID )
    self.mUID = pUID
end

--- GET Activity data
--
function ActivityEntry:GetActivityData()
    return self.mActivityData
end

--- SET Activity data
-- @param pActivity
--
function ActivityEntry:SetActivityData( pActivity )
    self.mActivityData = pActivity
end

--- Get the number of markers
--
function ActivityEntry:NumMarkers()
    return #self.mMarkers
end

--- Creates a map marker
-- @param pWaypoint
--
function ActivityEntry:CreateMarker( pWaypoint )
    local marker = Component.CreateWidget( bpMarker, self.mIconGroup )

    marker:SetAnchorId( Player.GetTargetId() )
    marker:SetMapping( "radial_rotate" )
    marker:SetEdgeTracking( true )
    marker:SetPosition( pWaypoint.x, pWaypoint.y, pWaypoint.z )
    marker:Show()

    table.insert( self.mMarkers, { marker = marker, waypoint = pWaypoint } )
end

--- Removes all markers
--
function ActivityEntry:RemoveAllMarkers()
    for _,v in ipairs( self.mMarkers ) do
       if (  v.mMarker ) then
           Component.RemoveWidget( v.marker )
       end
    end

    self.mMarkers = {}
end

--- Creates an Objective
-- @param pObjective
--
function ActivityEntry:CreateObjective( pObjective )
    local objective         = {}
    objective.mWidget       = Component.CreateWidget( skObjectiveLabelId, self.mObjectives )

    if ( objective.mWidget ) then
        objective.mLabel    = objective.mWidget:GetChild( skLabelId )
        objective.mLabel:SetFont( "UbuntuRegular_10" )

        objective.mLabel:SetText( tostring( pObjective.description ) )

        local dimensions    = objective.mLabel:GetTextDims()
        objective.mWidget:SetDims( "right:_; width:" .. dimensions.width .. "; center-y:_; height:" .. dimensions.height )
    end

    return objective
end

--- Returns the number of objective widgets
--
function ActivityEntry:NumObjectives()
    return self.mObjectives:GetChildCount()
end

--- Removes all objectives
--
function ActivityEntry:RemoveAllObjectives()
    self:RemoveAllChildren( self.mObjectives )
end

--- Removes all children of Parent
-- @param pParent
--
function ActivityEntry:RemoveAllChildren( pParent )
    for i = pParent:GetChildCount(), 1, -1 do
        Component.RemoveWidget( pParent:GetChild( i ) )
    end
end

--- Sets the full height of this activity
-- @param pHeight
--
function ActivityEntry:SetFullHeight( pHeight )
    self.mFullHeight = pHeight
end

--- returns the full height of this activity
--
function ActivityEntry:GetFullHeight()
    return self.mFullHeight
end

--- Wrapper
-- @param ...
--
function ActivityEntry:MoveTo( ... )
    self.mGroup:MoveTo( ... )
end
--- Wrapper
--
function ActivityEntry:Show()
    self.mGroup:Show()
end

--- Wrapper
--
function ActivityEntry:Hide()
    self.mGroup:Hide()
end

--- Wrapper
-- @param ...
--
function ActivityEntry:SetDims( ... )
    self.mGroup:SetDims( ... )
end