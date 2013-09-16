--
-- @Author: Pawkette
-- @Date: 9/14/13
--
require "table"
require "lib/lib_Debug"
require "lib/lib_Vector"
require "./ActivityEntry"
require "./ObjectiveEntry"
require "./GoalEntry"

local skMainFrameId         = "Main"
local skActivitiesId        = "Activities"
local skActivityMainGroupId = "ActivityMainGroup"
local skGoalIconId          = "GoalIcon"
local skGoalLabelId         = "GoalLabel"
local skGoalMainGroupId     = "GoalMainGroup"
local skGoalListId          = "GoalList"
local skLabelId             = "Label"
local skDistanceUpdateRate  = 0.1
local skMinDistance         = 5
local skMaxDistance         = 10

local kComponentFrame       = Component.GetFrame( skMainFrameId )
local kActivityMainGroup    = Component.GetWidget( skActivityMainGroupId )
local kActivitiesWidget     = Component.GetWidget( skActivitiesId )
local kGoalMainGroup        = Component.GetWidget( skGoalMainGroupId )
local kGoalIcon             = Component.GetWidget( skGoalIconId )
local kGoalList             = Component.GetWidget( skGoalListId )
local kGoalLabel            = Component.GetWidget( skGoalLabelId )
local kShoppingList         = {}
local kActivityData         = {}
local kActivityDisplay      = {}
local kSinView              = false
local fnDistanceCheck
local kGoalIndent           = -1
local kPlayerPosition       = { x = 0, y = 0, z = 0 }

function Initialize()
    Debug.EnableLogging( true )
    Debug.Log( "INITIALIZE" )
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
        Component.RemoveWidget( kActivityDisplay[ key ]:GetWidget() )
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

    if ( kShoppingList and kShoppingList[ 1 ] ) then
        local item_info = Game.GetItemInfoByType( kShoppingList[ 1 ].item_id )
        kGoalIcon:SetUrl( item_info.web_icon )
        SetLabelText( kGoalLabel:GetChild( skLabelId ), item_info.name, "right" )

        CreateShoppingList()
        kGoalMainGroup:Show()

        local dimensions    = kGoalList:GetDims( true )
        kActivityMainGroup:MoveTo( "left:0; width:200; center-y:_; bottom:100%; top:" .. dimensions.bottom.offset, 2, 0, "ease-in" )
    else
        kShoppingList = nil
        RemoveAllChildren( kGoalList )
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
            if ( activity_display:GetWidget() ) then
                local min_distance = 9999  --TODO: make this tweakable?

                for _, tbl in ipairs( activity_display:GetMarkers() ) do
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

--- Removes all childen of parent
-- @param pParent
--
function RemoveAllChildren( pParent )
    for i = pParent:GetChildCount(), 1, -1 do
        Component.RemoveWidget( kGoalList:GetChild( i ) )
    end
end

--- Creates the shopping list for tracked tasks
--
function CreateShoppingList()
    RemoveAllChildren( kGoalList )
    kGoalIndent = -1
    ProcessBluePrint( kShoppingList[ 1 ] )
end

--- Process & Create entries for each item
-- @param pBlueprint
--
function ProcessBluePrint( pBlueprint )
    local item_info
    local done
    local label

    kGoalIndent = kGoalIndent + 1

    if ( pBlueprint.resources ) then
        for _, resource in ipairs( pBlueprint.resources ) do
            done        = resource.quantity_have >= resource.quantity_needed
            label       = resource.loc_resource_name .. ": "
            if ( resource.loc_stat_name ~= "" ) then
                label   = label .. resource.loc_stat_name .. ": "
            end
            label       = label .. resource.quantity_have .. "/" .. resource.quantity_needed

            CreateGoalEntry( label, done )
        end
    end

    if ( pBlueprint.items ) then
        for _, item in ipairs( pBlueprint.items ) do
            item_info   = Game.GetItemInfoByType( item.item_id )
            done        = item.quantity_have >= item.quantity_needed
            label       = item_info.name .. ": " .. item.quantity_have .. "/" .. item.quantity_needed

            CreateGoalEntry( label, done )

            if ( not done ) then
                ProcessBluePrint( item )
            end
        end
    end

    if ( pBlueprint.components ) then
        for _, component in ipairs( pBlueprint.components ) do
            item_info   = Game.GetItemInfoByType( component.item_id )
            done        = component.quantity_have >= component.quantity_needed
            label       = item_info.name .. ": " .. component.quantity_have .. "/" .. component.

            CreateGoalEntry( label, done )

            if ( not done ) then
                ProcessBluePrint( component )
            end
        end
    end

    kGoalIndent = kGoalIndent - 1
end

--- Creates a new goal entry
-- @param pLabel
-- @param pComplete
--
function CreateGoalEntry( pLabel, pComplete )
    for i = 1, kGoalIndent do
        pLabel = " " .. pLabel
    end

    --feels gross to just new this up
    local obj       = GoalEntry( pLabel, pComplete, kGoalList )
    local count     = kGoalList:GetChildCount()
    local height    = obj:GetBounds().height

    obj:SetDims( "height:_; center-y:" .. count * height * 2 )

    kGoalList:SetDims( "top:_; height:" .. ( count * height * 2 ) + 54 )
    kGoalList:Show()
end

--- Sets text and changes parent dims.
-- @param pWidget
-- @param pText
-- @param pAlign
--
function SetLabelText( pWidget, pText, pAlign )
    pWidget:SetText( tostring( pText ) )

    local dimensions = pWidget:GetTextDims()
    pWidget:GetParent():SetDims( pAlign .. ":_; width:" .. dimensions.width .. "; center-y:_; height:" .. dimensions.height )
end