--
-- @Author: Pawkette
-- @Date: 9/16/13
--

require "lib/lib_InterfaceOptions"

local skLoadedUID           = "__LOADED"
local skDefaultUID          = "__DEFAULT"
local skDisplayUID          = "__DISPLAY"
local skVersionId           = 1

Options             = {}
Options.__index     = Options

setmetatable( Options, { __call = function( cls, ... ) return cls.new( ... ) end, } )

---
-- @param pFrame the frame to which these options belong
-- @param pLabel the label to show for these options
-- @param pMovable should the frame be movable in the ui?
-- @param pScalable should the frame be scalable in the ui?
-- @param pNotifyOnDefaults
-- @param pNotifyOnLoaded
-- @param pNotifyOnDisplay
--
function Options.new( pFrame, pLabel, pCallback, pMovable --[[ = true]], pScalable --[[ = true]] )
    local self      = setmetatable( { }, Options )

    if ( pMovable == nil )          then pMovable           = true  end
    if ( pScalable == nil )         then pScalable          = true  end

    InterfaceOptions.SetCallbackFunc( pCallback, pLabel )

    if ( pMovable ) then
        InterfaceOptions.AddMovableFrame( { frame = pFrame, label = pLabel, scalable = pScalable } )
    end

    self.mOptions   = {}
    self.mCallbacks = {}
    self.mFrame     = pFrame

    return self
end

--- Called by InterfaceOptions
-- @param pUID
-- @param pValue
--
function Options:HandleInterfaceCallback( pUID, pValue )
    if ( self.mCallbacks[ pUID ] ) then
       self.mCallbacks[ pUID ]( pValue )
    end

    if ( self.mOptions[ pUID ] ) then
        self.mOptions[ pUID ] = pValue
    end
end

--- Register a callback
-- @param pUID
-- @param pFn
--
function Options:AddCallback( pUID, pFn )
    if ( not self.mCallbacks[ pUID ] ) then
        self.mCallbacks[ pUID ] = pFn
    end
end

--- Remove a callback
-- @param pUID
--
function Options:RemoveCallback( pUID )
    if ( self.mCallbacks[ pUID ] ) then
        self.mCallbacks[ pUID ] = nil
    end
end

--- Get an option value by UID
-- @param pUID
--
function Options:GetValue( pUID )
    local result = nil
    if ( self.mOptions[ pUID ] ) then
        result = self.mOptions[ pUID ]
    end

    return result
end

---
-- @param ...
--
function Options:HandleRestoreDefaults( ... )

end

---
-- @param ...
--
function Options:HandleOptionsLoaded( ... )

end

---
-- @param ...
--
function Options:HandleDisplay( ... )

end

---
-- @param pUID
-- @param pLabel
--
function Options:StartGroup( pUID, pLabel )
    InterfaceOptions.StartGroup( { id = pUID, label = pLabel } )
end

---
--
function Options:StopGroup()
    InterfaceOptions.StopGroup()
end

---
-- @param pUID
-- @param pLabel
-- @param pOptions
-- @param pDefault = false
--
function Options:AddDropDown( pUID, pLabel, pOptions, pDefault --[[= false]], pCB --[[= nil]] )
    if ( #pOptions ~= 0 ) then
        if ( pDefault == nil )  then pDefault = false end

        InterfaceOptions.AddChoiceMenu( { id = pUID, label = pLabel, default = pDefault })

        for _,v in ipairs( pOptions ) do
            InterfaceOptions.AddChoiceEntry( { menuId = pUID, val = v.value, label = v.label } )
        end

        self.mOptions[ pUID ] = pDefault
        if ( pCB ~= nil ) then
            self:AddCallback( pUID, pCB )
        end
    end
end

---
-- @param pUID
-- @param pLabel
-- @param pDefault = false
--
function Options:AddCheckBox( pUID, pLabel, pDefault --[[= false]], pCB --[[= nil]] )
    if ( pDefault == nil )  then pDefault = false end

    InterfaceOptions.AddCheckBox( { id = pUID, label = pLabel, default = pDefault } )

    self.mOptions[ pUID ] = pDefault
    if ( pCB ~= nil ) then
        self:AddCallback( pUID, pCB )
    end
end

---
-- @param pUID
-- @param pLabel
-- @param pMin
-- @param pMax
-- @param pIncrement
-- @param pSuffix
-- @param pDefault = pMin
--
function Options:AddSlider( pUID, pLabel, pMin, pMax, pIncrement --[[ = 1]], pSuffix --[[ = "%"]], pDefault --[[ = pMin]], pCB --[[= nil]] )
    if ( pDefault == nil )      then pDefault   = pMin  end
    if ( pSuffix == nil )       then pSuffix    = "%"   end
    if ( pIncrement == nil )    then pIncrement = 1     end

    InterfaceOptions.AddSlider( { id = pUID, label = pLabel, tooltip = "", default = pDefault, min = pMin, max = pMax, inc = pIncrement, suffix = pSuffix } )

    self.mOptions[ pUID ] = pDefault
    if ( pCB ~= nil ) then
        self:AddCallback( pUID, pCB )
    end
end

---
-- @param pUID
-- @param pLabel
-- @param pDefault = #FFFFFF
--
function Options:AddColorPicker( pUID, pLabel, pDefault --[[ = #FFFFFF]], pCB --[[= nil]] )
    if ( pDefault == nil ) then pDefault = "#FFFFFF" end

    InterfaceOptions.AddColorPicker( { id = pUID, label = pLabel, default = pDefault } )

    self.mOptions[ pUID ] = pDefault
    if ( pCB ~= nil ) then
        self:AddCallback( pUID, pCB )
    end
end

---
-- @param pUID
-- @param pLabel
-- @param pCallback
--
function Options:AddButton( pUID, pLabel, pCallback )
    InterfaceOptions.AddButton( { id = pUID, label = pLabel } )
    self.mCallbacks[ pUID ] = pCallback
end

---
-- @param pUID
-- @param pLabel
-- @param pMax
-- @param pDefault = ""
-- @param pNumeric
-- @param pPassword
-- @param pWhitespace
--
function Options:AddTextInput( pUID, pLabel, pMax, pDefault --[[ = ""]], pNumeric --[[ = false]], pPassword --[[ = false]], pWhitespace --[[ = true]], pCB --[[= nil]] )
    if ( pDefault == nil )      then pDefault       = ""    end
    if ( pNumeric == nil )      then pNumeric       = false end
    if ( pPassword == nil )     then pPassword      = false end
    if ( pWhitespace == nil )   then pWhitespace    = true  end

    InterfaceOptions.AddTextInput( { id = pUID, label = pLabel, max = pMax, default = pDefault, numeric = pNumeric, masked = pPassword, whitespace = pWhitespace } )

    self.mOptions[ pUID ] = pDefault
    if ( pCB ~= nil ) then
        self:AddCallback( pUID, pCB )
    end
end

--- This is literally a wrapper
-- @param pUID
-- @param pWidth
-- @param pHeight
-- @param pTint
-- @param pTexture
-- @param pRegion
-- @param pURL
-- @param pIcon
-- @param pAspect
-- @param pPadding
-- @param pYOffset
-- @param pXOffset
-- @param pOnClick
--
function Options:AddMultiArt( pUID, pWidth, pHeight, pTint, pTexture, pRegion, pURL, pIcon, pAspect, pPadding, pYOffset, pXOffset, pOnClick )
    InterfaceOptions.AddMultiArt( {
            id          = pUID,
            url         = pURL,
            icon        = pIcon,
            texture     = pTexture,
            region      = pRegion,
            tint        = pTint,
            width       = pWidth,
            height      = pHeight,
            padding     = pPadding,
            aspect      = pAspect,
            y_offset    = pYOffset,
            x_offset    = pXOffset,
            OnClickUrl  = pOnClick
    } )
end

---
-- @param pUID
-- @param pEnabled
--
function Options:SetEnabled( pUID, pEnabled )
    InterfaceOptions.EnableOption( pUID, pEnabled )
end

---
-- @param pUID
-- @param pLabel
--
function Options:UpdateLabel( pUID, pLabel )
    InterfaceOptions.UpdateLabel( pUID, pLabel )
end

---
-- @param pFrame = nil
--
function Options:UpdateFrame( pFrame --[[ = nil]] )
    if ( pFrame == nil ) then pFrame = self.mFrame end

    InterfaceOptions.UpdateFrame( pFrame )
end