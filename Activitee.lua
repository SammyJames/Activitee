--
-- @Author: Pawkette
-- @Date: 9/14/13
--
require "table"
require "lib/lib_Debug"
require "lib/lib_Vector"
require "./ActivityEntry"
require "./ObjectiveEntry"

local skMainFrameId         = "Main"
local skActivitiesId        = "Activities"
local skActivityMainGroupId = "ActivityMainGroup"
local skGoalIconId          = "GoalIcon"
local skGoalLabelId         = "GoalLabel"
local skGoalMainGroupId     = "GoalMainGroup"
local skGoalDetailGroupId   = "GoalDetailGroup"
local skShoppingItemNameId  = "ShoppingItemName"
local skGoalListId          = "GoalList"
local skDistanceUpdateRate  = 0.1
local skMinDistance         = 5
local skMaxDistance         = 10

local kSinView
local kShoppingItemName
local kGoalDetailGroup
local kGoalIcon
local kGoalList
local kGoalMainGroup
local kGoalLabel
local kComponentFrame
local kActivityMainGroup
local kActivitiesWidget
local kShoppingList
local kActivityData         = {}
local kActivityDisplay      = {}
local fnDistanceCheck
local kGoalWidth
local kPlayerPosition       = { x = 0, y = 0, z = 0 }

function Initialize()
    Debug.EnableLogging( true )
    kComponentFrame         = Component.GetFrame( skMainFrameId )
    kActivityMainGroup      = Component.GetWidget( skActivityMainGroupId )
    kActivitiesWidget       = Component.GetWidget( skActivitiesId )

    kGoalMainGroup          = Component.GetWidget( skGoalMainGroupId )
    kGoalIcon               = Component.GetWidget( skGoalIconId )
    kGoalLabel              = Component.GetWidget( skGoalLabelId )

    kGoalDetailGroup        = Component.GetWidget( skGoalDetailGroupId )
    kGoalList               = Component.GetWidget( skGoalListId )
    kShoppingItemName       = Component.GetWidget( skShoppingItemNameId )
end

--- Unique ID for actitivies
-- Combines the typename of the activity with the id
-- @param pActivity
--
function UID( pActivity )
    return ( pActivity.typeName .. "#" .. tostring( pActivity.id ) )
end

--- Determines if an activity has no objectives
-- @param pActivity
--
function NoObjectives( pActivity )
    return ( ( not pActivity.objectives ) or ( #pActivity.objectives == 0 ) )
end

--- Determines if an activity is already active
-- @param pActivity
--
function AlreadyActive( pActivity )
    local result = false
    for _,objective in ipairs( pActivity.objectives ) do
        result = ActiveObjective( objective )
        if result then break end
    end

    return result
end

--- Determines if an objective is active
-- @param pObjective
--
function ActiveObjective( pObjective )
    return ( ( pObjective.description ) and ( pObjective.description ~= "" )
            and ( pObjective.active ) and ( not pObjective.completed ) )
end

--- Remove an activity
-- really just does what the function says
-- @param pActivity
--
function RemoveActivity( pActivity )
    local key = UID( pActivity )

    if ( kActivityDisplay[ key ] ) then
        Component.RemoveWidget( kActivityDisplay[ key ].mGroup )
        kActivityDisplay[ key ] = nil
    end

    kActivityData[ key ] = nil
    if ( kActivitiesWidget:GetChildCount() == 0 ) then
        kActivityMainGroup:Hide()
    end

    RearrangeActivites()
end

--- Add or Updates an activity
-- if no entry exists, will create a new one or update existing
-- @param pActivity
--
function UpdateActivity( pActivity )
    local key = UID( pActivity )
    kActivityData[ key ] = pActivity

    if ( NoObjectives( pActivity ) or AlreadyActive( pActivity ) ) then
        local activity_display = kActivityDisplay[ key ]

        if ( not activity_display ) then
            activity_display = ActivityEntry( pActivity, key, kActivitiesWidget )
            kActivityDisplay[ key ] = activity_display
        else
            activity_display:RemoveAllMarkers()
            activity_display:RemoveAllObjectives()
        end

        for _,objective in ipairs( pActivity.objectives ) do
            local active = ActiveObjective( objective )

            if ( active ) then
                local obj       = ObjectiveEntry( objective, activity_display:GetObjectives() )
                local count     = activity_display:NumObjectives()
                local height    = obj:GetBounds().height

                obj:SetDims( "height:_; center-y:" .. count * height * 2 )

                activity_display:SetFullHeight( ( count * height * 2 ) + 54 )
                activity_display:SetDims( "top:_; height:" .. activity_display:GetFullHeight() )
                activity_display:Show()
            end

            if ( ( active ) and ( objective.waypoint ) ) then
                activity_display:CreateMarker( objective.waypoint )
            end
        end

        if ( ( pActivity.waypoint ) and ( activity_display:NumMarkers() == 0 ) ) then
            activity_display:CreateMarker( pActivity.waypoint )
        end

        kActivityMainGroup:Show()
    else
        local activity_display = kActivityDisplay[ key ]
        if ( activity_display ) then
            activity_display:Hide()
        end
    end

    RearrangeActivites()
end

--- Rearranges activities based on their priorityOrder
--
function RearrangeActivites()
    local tbl = {}
    for key,activity in pairs( kActivityData ) do
        if ( kActivityDisplay[ key ] ) then
            table.insert( tbl, { key = key, order = activity.priorityOrder } )
        end
    end

    table.sort( tbl, function( lhs, rhs ) return lhs.order < rhs.order end )

    local top = 0
    for _,v in ipairs( tbl ) do
        local key = v.key
        local activity_display = kActivityDisplay[ key ]

        activity_display:MoveTo( "height:_; top:" .. top, 0.1 )
        top = top + activity_display:GetFullHeight() + 1
    end
end

--- Removes all activities
--
function RemoveAllActivities()
    for _,v in pairs( kActivityDisplay ) do
        RemoveActivity( v:GetActivityData() )
    end

    kActivityDisplay    = {}
    kActivityData       = {}
    kActivityMainGroup:Hide()
end


--- Called when Addon is loaded
--
function OnComponentLoad()
    Initialize()
end

---
-- @param pArgs
--
function OnSinView( pArgs )
    kSinView = pArgs.sinView
    AdjustWidth()
end

---
-- @param pArgs
--
function OnHudShow( pArgs )
    kComponentFrame:ParamTo( "alpha", tonumber( pArgs.show ), pArgs.dur )
end

---
-- @param pArgs
--
function OnEnterZone( pArgs )
   kComponentFrame:Hide( Game.IsInPvP() )
end

---
-- @param pArgs
--
function OnPlayerReady( pArgs )
    OnEnterZone()
    RunDistanceCheck()
    OnShoppingListUpdated( pArgs )
end

---
-- @param pArgs
--
function OnTrackerUpdateMission( pArgs )
    UpdateActivity( jsontotable( pArgs.json ) )
end

---
-- @param pArgs
--
function OnTrackerDeleteMission( pArgs )
    RemoveActivity( jsontotable( pArgs.json ) )
end

---
-- @param pArgs
--
function OnTrackerDelete( pArgs )
    RemoveActivity( jsontotable( pArgs.json ) )
end

---
-- @param pArgs
--
function OnTrackerUpdate( pArgs )
    UpdateActivity( jsontotable( pArgs.json ) )
end

---
-- @param pArgs
--
function OnTrackerClear( pArgs )
    RemoveAllActivities()
end

---
-- @param pArgs
--
function OnShoppingListUpdated( pArgs )
    kShoppingList   = Player.GetShoppingList()
    kGoalWidth      = 150 --TODO: make this tweakable?

    if ( kShoppingList and kShoppingList[1] ) then
        local item_info = Game.GetItemInfoByType( kShoppingList[1].item_id )
        kGoalIcon:SetUrl( item_info.web_icon )
        kShoppingItemName:SetText( item_info.name )

        kGoalWidth = math.max( kGoalWidth, kShoppingItemName:GetTextDims().width )

        --CreateShoppingList()
        kGoalMainGroup:Show()
    else
        kShoppingList = nil

        kGoalMainGroup:Hide()
    end
end

---
--
function RunDistanceCheck()
     if ( not fnDistanceCheck ) then
        DistanceCheck()
     end
end

---
--
function DistanceCheck()
    fnDistanceCheck = nil

    local player_position = Player.GetPosition()

    if ( Vec3.Distance( player_position, kPlayerPosition ) > 1 ) then
        Debug.Log( "Running Distance Check" )
        for _,activity_display in pairs( kActivityDisplay ) do
            if ( activity_display.mGroup ) then
                local min_distance = 9999  --TODO: make this tweakable?

                for _, tbl in ipairs( activity_display.mMarkers ) do
                    if ( tbl.marker ) then
                        local distance  = Vec3.Distance( player_position, tbl.waypoint )
                        min_distance    = math.min( min_distance, distance )
                        local alpha     = math.min( 1, math.max( 0, ( distance - skMinDistance ) / ( skMaxDistance - skMinDistance ) ) )

                        tbl.marker:ParamTo( "alpha", alpha, skDistanceUpdateRate )
                    end
                end

                if ( min_distance < 9999 ) then
                    activity_display:SetDistance( math.floor( min_distance ) )
                else
                    activity_display:SetDistance( 0 )
                end
            end
        end

        kPlayerPosition = player_position
    end

    fnDistanceCheck = callback( DistanceCheck, nil, skDistanceUpdateRate )
end

---
--
function AdjustWidth()
    local duration = 0.2 --TODO: make this tweakable?

    if ( kSinView ) then
        if ( kShoppingList ) then
            kComponentFrame:MoveTo( "right:_; width:" .. kGoalWidth + 230, duration, 0, "ease-in" )
        end
    else
        kComponentFrame:MoveTo( "right:_; width:200", duration, duration, "ease-out" )
    end
end