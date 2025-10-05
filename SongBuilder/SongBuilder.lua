local pluginName    = select(1, ...)
local componentName = select(2, ...)
local signalTable   = select(3, ...)
local my_handle     = select(4, ...)

-- Todos:
-- - Executor configuration
-- - Rename song
-- - Delete song


-- Parameters (in UI)
local songParameters = {
    name = "MySong",
    short_name = "SG",
    number = 1,
    sequence = 101,
    page = 1,
    timecode = 1,
    macro = 1001,
}

-- Config (in UI)
local applySequences = false
local applySubSequences = false
local applyExecutors = false
local applyTimecode = false
local applyMacro = false
local applyViews = true

-- Parameters (not in UI)
local sequenceMultiplier = 100
local sequencesPerSong = 20
local sequencesPerSongOffset = 9 -- ex: Main seq at 101 and song seq starting at 110
local executorPerRow = 10
local executorUnitStart = 6 -- The unit number on exec 400s and 300s to start assigning sequences to (401 on Compact, 406 on Lite/Full)
local macroOffset = 1000

local viewSequencesOffset = 1000
local viewSequencesTemplate = 999
local viewPresetsOffset = 2000
local viewPresetsTemplate = 1999




function CreateSong(parameters)

  SetVar(GlobalVars(), "Song",          parameters.number)
  SetVar(GlobalVars(), "SongName",      parameters.name)
  SetVar(GlobalVars(), "SongShortName", parameters.short_name)

  -- Sequences
  if applySequences then
    Cmd("Store Sequence " .. parameters.sequence)
    Cmd("Label Sequence " .. parameters.sequence .. " " .. parameters.name)
  end

  if applySubSequences then
    for i = 1,sequencesPerSong do
      local seq = parameters.sequence + sequencesPerSongOffset + i - 1
      Cmd("Store Sequence " .. seq .. " /Overwrite")
      Cmd("Label Sequence " .. seq .. " \"" .. parameters.short_name .. " " .. i .. "\"")
    end
  end

  -- Executors
  if applyExecutors then
    Cmd("Store Page " .. parameters.page)
    Cmd("Label Page " .. parameters.page .. " \"" .. parameters.name .. "\"")
    Cmd("Page " .. parameters.page)
    -- Split the executors between the 400s and 300s going in reverse order of the exec number
    -- As Executor X01 is the furthest left
    -- Executor 400s
    seqStart = parameters.sequence + sequencesPerSongOffset
    seqEnd = seqStart + executorPerRow - 1
    execStart = 400 + executorUnitStart + executorPerRow - 1
    execEnd = 400 + executorUnitStart
    Cmd("Assign Sequence " .. seqStart .. " Thru " .. seqEnd .. " At Page " .. parameters.page .. " Executor " .. execStart .. " Thru " .. execEnd)
    -- Executor 300s
    seqStart = parameters.sequence + sequencesPerSongOffset + executorPerRow
    seqEnd = seqStart + executorPerRow - 1 
    execStart = 300 + executorUnitStart + executorPerRow - 1
    execEnd = 300 + executorUnitStart
    Cmd("Assign Sequence " .. seqStart .. " Thru " .. seqEnd .. " At Page " .. parameters.page .. " Executor " .. execStart .. " Thru " .. execEnd)
    -- Executor 100s: Main Sequence
    execStart = 109 + executorUnitStart
    Cmd("Assign Sequence " .. parameters.sequence .. " At Page " .. parameters.page .. " Executor " .. execStart)
  end

  -- Macro
  if applyMacro then
    Cmd("Copy Macro \"Song\" At " .. parameters.macro .. "/Overwrite")
    Cmd("Label Macro " .. parameters.macro .. " \"" .. parameters.name .. "\"")

    -- edit macro lines
    Cmd("Set Macro " .. parameters.macro .. ".1 Property \"command\" \"SetGlobalVariable Song " .. parameters.name .. "\"")
    Cmd("Set Macro " .. parameters.macro .. ".2 Property \"command\" \"SetGlobalVariable SongShortName " .. parameters.short_name .. "\"")
    Cmd("Set Macro " .. parameters.macro .. ".3 Property \"command\" \"SetGlobalVariable SongNumber " .. parameters.number .. "\"")
  end
  
  -- Timecode
  if applyTimecode then
    Cmd("Store Timecode " .. parameters.timecode .. "/Overwrite")
    Cmd("Label Timecode " .. parameters.timecode .. " " .. parameters.name)
  end

  -- Views
  if applyViews then
    -- Sequences view
    view = viewSequencesOffset + parameters.number
    Cmd("Copy View " .. viewSequencesTemplate .. " At " .. view .. "/Overwrite")
    Cmd("Label View " .. view .. " \"" .. parameters.name .. "_SEQ\"")

    SetViewDataPoolIndex(view, "WindowSequencePool", parameters.sequence - 1)

    -- Presets view
    view = viewPresetsOffset + parameters.number
    Cmd("Copy View " .. viewPresetsTemplate .. " At " .. view .. "/Overwrite")
    Cmd("Label View " .. view .. " \"" .. parameters.name .. "_PRST\"")

    SetViewDataPoolIndex(view, "WindowPresetPool", parameters.sequence - 1)
  end
end


function SetViewDataPoolIndex(view, poolName, index)

  Echo("SetViewDataPoolIndex ".. view .. " " .. poolName .. " at " .. index)

  viewobject = ObjectList("View " .. view)[1]
  -- viewobject:Dump()
  viewItems = viewobject:Children()
  for i = 1, #viewItems do
    pool = viewItems[i]

    if pool.Name == poolName then
      Echo("Found pool " .. pool.Name)

      poolChildren = pool:Children()
      for j = 1, #poolChildren do
        if poolChildren[j].Name == "WindowScrollPositions" then
          Echo("Setting index on pool window settings")
          poolChildren[j].ScrollV = index .. "," .. index
        end
      end
    end
  end
end


function CreateTextInput(grid, num, name, icon, callback)

  local inputTextIcon = grid:Append("Button")
  inputTextIcon.Text = ""
  inputTextIcon.Anchors = {
    left = 0,
    right = 0,
    top = num,
    bottom = num
  }
  inputTextIcon.Icon = icon
  inputTextIcon.Margin = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2    
  }
  inputTextIcon.HasHover = "No";
  
  local inputTextLabel = grid:Append("UIObject")
  inputTextLabel.Text = name
  inputTextLabel.TextalignmentH = "Left"
  inputTextLabel.Anchors = {
    left = 1,
    right = 4,
    top = num,
    bottom = num
  }
  inputTextLabel.Padding = "5,5"
  inputTextLabel.Margin = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2    
  }
  inputTextLabel.HasHover = "No";
  
  local inputTextLineEdit = grid:Append("LineEdit")
  inputTextLineEdit.Anchors = {
    left = 5,
    right = 9,
    top = num,
    bottom = num
  }
  inputTextLineEdit.Padding = "5,5"
  inputTextLineEdit.Margin = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2
  }
  inputTextLineEdit.TextAutoAdjust = "Yes"
  inputTextLineEdit.VkPluginName = "TextInput"
  inputTextLineEdit.Content = ""
  inputTextLineEdit.MaxTextLength = 25
  inputTextLineEdit.HideFocusFrame = "Yes"
  inputTextLineEdit.PluginComponent = my_handle
  inputTextLineEdit.TextChanged = callback

  return inputTextLineEdit

end


function CreateNumInput(grid, num, name, icon, callback)

  local inputNumIcon = grid:Append("Button")
  inputNumIcon.Text = ""
  inputNumIcon.Anchors = {
    left = 0,
    right = 0,
    top = num,
    bottom = num
  }
  inputNumIcon.Icon = icon   
  inputNumIcon.Margin = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2    
  }   
  inputNumIcon.HasHover = "No";  
  -- inputNumIcon.BackColor = colorPartlySelectedPreset
  
  local inputNumLabel = grid:Append("UIObject")
  inputNumLabel.Text = name
  inputNumLabel.TextalignmentH = "Left"
  inputNumLabel.Anchors = {
    left = 1,
    right = 4,
    top = num,
    bottom = num
  }
  inputNumLabel.Padding = "5,5"
  inputNumLabel.Margin = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2    
  }    
  inputNumLabel.HasHover = "No";    
  -- inputNumLabel.BackColor = colorPartlySelectedPreset
  
  local inputNumLineEdit = grid:Append("LineEdit")
  inputNumLineEdit.Anchors = {
    left = 5,
    right = 9,
    top = num,
    bottom = num
  }
  inputNumLineEdit.Padding = "5,5"
  inputNumLineEdit.Margin = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 2
  }
  inputNumLineEdit.TextAutoAdjust = "Yes"
  inputNumLineEdit.Filter = "0123456789"
  inputNumLineEdit.VkPluginName = "TextInputNumOnly"
  inputNumLineEdit.Content = 0
  inputNumLineEdit.MaxTextLength = 10
  inputNumLineEdit.HideFocusFrame = "Yes"
  inputNumLineEdit.PluginComponent = my_handle
  inputNumLineEdit.TextChanged = callback

  return inputNumLineEdit

end


function CreateCheckboxInput(grid, num, name, callback)

  local inputCheckBox = grid:Append("CheckBox")
  inputCheckBox.Anchors = {
    left = num % grid.Columns,
    right = num % grid.Columns,
    top = num // grid.Columns,
    bottom = num // grid.Columns
  }  
  inputCheckBox.Text = name
  inputCheckBox.TextalignmentH = "Left";
  inputCheckBox.State = 0;
  inputCheckBox.PluginComponent = my_handle
  inputCheckBox.Clicked = callback

  return inputCheckBox

end



function Main(displayHandle)  
 
   -- Get the index of the display on which to create the dialog.
  local displayIndex = Obj.Index(GetFocusDisplay())
  if displayIndex > 5 then
    displayIndex = 1
  end
  
  -- Get the colors.
  local colorTransparent = Root().ColorTheme.ColorGroups.Global.Transparent
  local colorBackground = Root().ColorTheme.ColorGroups.Button.Background
  local colorBackgroundPlease = Root().ColorTheme.ColorGroups.Button.BackgroundPlease
  local colorPartlySelected = Root().ColorTheme.ColorGroups.Global.PartlySelected
  local colorPartlySelectedPreset = Root().ColorTheme.ColorGroups.Global.PartlySelectedPreset
  
  -- Get the overlay.
  local display = GetDisplayByIndex(displayIndex)
  local screenOverlay = display.ScreenOverlay
  
  -- Delete any UI elements currently displayed on the overlay.
  screenOverlay:ClearUIChildren()   
  
  -- Create the dialog base.
  local dialogWidth = 700
  local baseInput = screenOverlay:Append("BaseInput")
  baseInput.Name = "DMXTesterWindow"
  baseInput.H = "0"
  baseInput.W = dialogWidth
  baseInput.MaxSize = string.format("%s,%s", display.W * 0.8, display.H)
  baseInput.MinSize = string.format("%s,0", dialogWidth - 100)
  baseInput.Columns = 1  
  baseInput.Rows = 2
  baseInput[1][1].SizePolicy = "Fixed"
  baseInput[1][1].Size = "60"
  baseInput[1][2].SizePolicy = "Stretch"
  baseInput.AutoClose = "No"
  baseInput.CloseOnEscape = "Yes"
  
  -- Create the title bar.
  local titleBar = baseInput:Append("TitleBar")
  titleBar.Columns = 2  
  titleBar.Rows = 1
  titleBar.Anchors = "0,0"
  titleBar[2][2].SizePolicy = "Fixed"
  titleBar[2][2].Size = "50"
  titleBar.Texture = "corner2"
  
  local titleBarIcon = titleBar:Append("TitleButton")
  titleBarIcon.Text = "Song Builder"
  titleBarIcon.Texture = "corner1"
  titleBarIcon.Anchors = "0,0"
  titleBarIcon.Icon = "star"
  
  local titleBarCloseButton = titleBar:Append("CloseButton")
  titleBarCloseButton.Anchors = "1,0"
  titleBarCloseButton.Texture = "corner2"
  
  -- Create the dialog's main frame.
  local dlgFrame = baseInput:Append("DialogFrame")
  dlgFrame.H = "100%"
  dlgFrame.W = "100%"
  dlgFrame.Columns = 1  
  dlgFrame.Rows = 7
  dlgFrame.Anchors = {
    left = 0,
    right = 0,
    top = 1,
    bottom = 1
  }
  dlgFrame[1][1].SizePolicy = "Fixed"
  dlgFrame[1][1].Size = "60"
  dlgFrame[1][2].SizePolicy = "Fixed"
  dlgFrame[1][2].Size = "225"
  dlgFrame[1][3].SizePolicy = "Fixed"
  dlgFrame[1][3].Size = "60"
  dlgFrame[1][4].SizePolicy = "Fixed"
  dlgFrame[1][4].Size = "300"
  dlgFrame[1][5].SizePolicy = "Fixed"  
  dlgFrame[1][5].Size = "60"   
  dlgFrame[1][6].SizePolicy = "Fixed"  
  dlgFrame[1][6].Size = "100"   
  dlgFrame[1][7].SizePolicy = "Fixed"  
  dlgFrame[1][7].Size = "60"    
  

  -- Create the sub title.
  -- This is row 1 of the dlgFrame.
  local subTitle = dlgFrame:Append("UIObject")
  subTitle.Text = "Required fields"
  subTitle.ContentDriven = "Yes"
  subTitle.ContentWidth = "No"
  subTitle.TextAutoAdjust = "No"
  subTitle.Anchors = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }
  subTitle.Padding = {
    left = 20,
    right = 20,
    top = 15,
    bottom = 15
  }
  subTitle.Font = "Medium20"
  subTitle.HasHover = "No"
  subTitle.BackColor = colorTransparent  
  
  -- Create the 1rst inputs grid.
  -- This is row 2 of the dlgFrame.
  local inputsGrid1 = dlgFrame:Append("UILayoutGrid")
  inputsGrid1.Columns = 10
  inputsGrid1.Rows = 3
  inputsGrid1.Anchors = {
    left = 0,
    right = 0,
    top = 1,
    bottom = 1
  }
  inputsGrid1.Margin = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 5    
  }
  
  -- 1rst input: Song Number
  local numberInput = CreateNumInput(inputsGrid1, 0, "Number", "keyboard", "OnNumberChanged")
  numberInput.Content = songParameters.number

  -- 2nd input: Name
  local nameInput = CreateTextInput(inputsGrid1, 1, "Name", "keyboard", "OnNameChanged")
  nameInput.Content = songParameters.name

  -- 3rd input: Short Name
  local nameInput = CreateTextInput(inputsGrid1, 2, "Short Name", "keyboard", "OnShortNameChanged")
  nameInput.Content = songParameters.short_name



  -- Create the divider space.
  -- This is row 3 of the dlgFrame.
  local subTitle = dlgFrame:Append("UIObject")
  subTitle.Text = "Pool objects"
  subTitle.ContentDriven = "Yes"
  subTitle.ContentWidth = "No"
  subTitle.TextAutoAdjust = "No"
  subTitle.Anchors = {
    left = 0,
    right = 0,
    top = 2,
    bottom = 2
  }
  subTitle.Padding = {
    left = 20,
    right = 20,
    top = 15,
    bottom = 15
  }
  subTitle.Font = "Medium20"
  subTitle.HasHover = "No"
  subTitle.BackColor = colorTransparent  
  
  -- Create the 2nd inputs grid.
  -- This is row 4 of the dlgFrame.
  local inputsGrid2 = dlgFrame:Append("UILayoutGrid")
  inputsGrid2.Columns = 10
  inputsGrid2.Rows = 4
  inputsGrid2.Anchors = {
    left = 0,
    right = 0,
    top = 3,
    bottom = 3
  }
  inputsGrid2.Margin = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 5    
  }


  -- 3rd input: Sequence
  local sequenceInput = CreateNumInput(inputsGrid2, 0, "Sequence", "object_sequence", "OnSequenceChanged")
  sequenceInput.Content = songParameters.sequence

  -- 4th input: Page
  local pageInput = CreateNumInput(inputsGrid2, 1, "Page", "object_playback", "OnPageChanged")
  pageInput.Content = songParameters.page

  -- 5th input: Timecode
  local timecodeInput = CreateNumInput(inputsGrid2, 2, "Timecode", "object_timecode", "OnTimecodeChanged")
  timecodeInput.Content = songParameters.timecode

  -- 6th input: Macro
  local macroInput = CreateNumInput(inputsGrid2, 3, "Macro", "object_macro", "OnMacroChanged")
  macroInput.Content = songParameters.macro


  -- Handlers
  signalTable.OnNameChanged = function(caller)
    Echo("Name changed: '" .. caller.Content .. "'")
    songParameters.name = caller.Content
  end

  signalTable.OnShortNameChanged = function(caller)
    Echo("Short Name changed: '" .. caller.Content .. "'")
    songParameters.short_name = caller.Content
  end

  signalTable.OnNumberChanged = function(caller)
    Echo("Number changed: '" .. caller.Content .. "'")
    local num = tonumber(caller.Content)
    if num ~= nil then
      songParameters.number = num

      -- Update UI components (which will update parameters)
      sequenceInput.Content = num * sequenceMultiplier + 1
      pageInput.Content = num
      timecodeInput.Content = num
      macroInput.Content = macroOffset + num
    end
  end

  signalTable.OnSequenceChanged = function(caller)
    Echo("Sequence changed: '" .. caller.Content .. "'")
    local seq = tonumber(caller.Content)
    if seq ~= nil then
      songParameters.sequence = seq
    end
  end

  signalTable.OnPageChanged = function(caller)
    Echo("Page changed: '" .. caller.Content .. "'")
    local page = tonumber(caller.Content)
    if page ~= nil then
      songParameters.page = page
    end
  end

  signalTable.OnTimecodeChanged = function(caller)
    Echo("Timecode changed: '" .. caller.Content .. "'")
    local timecode = tonumber(caller.Content)
    if timecode ~= nil then
      songParameters.timecode = timecode
    end
  end

  signalTable.OnMacroChanged = function(caller)
    Echo("Macro changed: '" .. caller.Content .. "'")
    local macro = tonumber(caller.Content)
    if macro ~= nil then
      songParameters.macro = macro
    end
  end


  -- Create the divider space.
  -- This is row 5 of the dlgFrame.
  local subTitle = dlgFrame:Append("UIObject")
  subTitle.Text = "Settings"
  subTitle.ContentDriven = "Yes"
  subTitle.ContentWidth = "No"
  subTitle.TextAutoAdjust = "No"
  subTitle.Anchors = {
    left = 0,
    right = 0,
    top = 4,
    bottom = 4
  }
  subTitle.Padding = {
    left = 20,
    right = 20,
    top = 15,
    bottom = 15
  }
  subTitle.Font = "Medium20"
  subTitle.HasHover = "No"
  subTitle.BackColor = colorTransparent  

  -- Create the checkbox grid.
  -- This is row 6 of the dlgFrame.
  local checkBoxGrid = dlgFrame:Append("UILayoutGrid")
  checkBoxGrid.Columns = 3
  checkBoxGrid.Rows = 2
  checkBoxGrid.Anchors = {
    left = 0,
    right = 0,
    top = 5,
    bottom = 5
  }
  checkBoxGrid.Margin = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 5
  }

  local applySequencesInput = CreateCheckboxInput(checkBoxGrid, 0, "Main Sequence", "OnApplySequencesClicked")
  applySequencesInput.State = applySequences

  local applySubSequencesInput = CreateCheckboxInput(checkBoxGrid, 1, "Sub Sequences", "OnApplySubSequencesClicked")
  applySubSequencesInput.State = applySubSequences

  local applyExecutorsInput = CreateCheckboxInput(checkBoxGrid, 2, "Executors", "OnApplyExecutorsClicked")
  applyExecutorsInput.State = applyExecutors

  local applyTimecodeInput = CreateCheckboxInput(checkBoxGrid, 3, "Timecode", "OnApplyTimecodeClicked")
  applyTimecodeInput.State = applyTimecode

  local applyViewsInput = CreateCheckboxInput(checkBoxGrid, 4, "Views", "OnApplyViewsClicked")
  applyViewsInput.State = applyViews

  local applyMacroInput = CreateCheckboxInput(checkBoxGrid, 5, "Macro", "OnApplyMacroClicked")
  applyMacroInput.State = applyMacro

  -- Handlers
  signalTable.OnApplySequencesClicked = function(caller)
    Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
    end
    applySequences = caller.State
  end

  signalTable.OnApplySubSequencesClicked = function(caller)
    Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
    end
    applySubSequences = caller.State
  end

  signalTable.OnApplyExecutorsClicked = function(caller)
    Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
    end
    applyExecutors = caller.State
  end

  signalTable.OnApplyTimecodeClicked = function(caller)
    Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
    end
    applyTimecode = caller.State
  end

  signalTable.OnApplyViewsClicked = function(caller)
    Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
    end
    applyViews = caller.State
  end

  signalTable.OnApplyMacroClicked = function(caller)
    Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
    end
    applyMacro = caller.State
  end
  

  -- Create the bottom button grid.
  -- This is row 7 of the dlgFrame.
  local buttonGrid = dlgFrame:Append("UILayoutGrid")
  buttonGrid.Columns = 2
  buttonGrid.Rows = 1
  buttonGrid.Anchors = {
    left = 0,
    right = 0,
    top = 6,
    bottom = 6
  }
  
  local applyButton = buttonGrid:Append("Button");
  applyButton.Anchors = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }
  applyButton.Textshadow = 1;
  applyButton.HasHover = "Yes";
  applyButton.Text = "Apply";
  applyButton.Font = "Medium20";
  applyButton.TextalignmentH = "Centre";
  applyButton.PluginComponent = my_handle
  applyButton.Clicked = "ApplyButtonClicked"

  signalTable.ApplyButtonClicked = function(caller)
    
    Echo("Apply button clicked.")    
    
    if (applyButton.BackColor == colorBackground) then
      applyButton.BackColor = colorBackgroundPlease
    else
      applyButton.BackColor = colorBackground
    end  

    Echo(songParameters.name)
    Echo(songParameters.number)
    Echo(songParameters.sequence)
    Echo(songParameters.page)
    Echo(songParameters.timecode)
    Echo(songParameters.macro)

    CreateSong(songParameters)
    
  end


  local cancelButton = buttonGrid:Append("Button");
  cancelButton.Anchors = {
    left = 1,
    right = 1,
    top = 0,
    bottom = 0
  }
  cancelButton.Textshadow = 1;
  cancelButton.HasHover = "Yes";
  cancelButton.Text = "Cancel";
  cancelButton.Font = "Medium20";
  cancelButton.TextalignmentH = "Centre";
  cancelButton.PluginComponent = my_handle
  cancelButton.Clicked = "CancelButtonClicked"
  cancelButton.Visible = "Yes"  
  
  signalTable.CancelButtonClicked = function(caller)
    
    Echo("Cancel button clicked.")
    Obj.Delete(screenOverlay, Obj.Index(baseInput))
    
  end  
  
end

-- Run the plugin
return Main
  