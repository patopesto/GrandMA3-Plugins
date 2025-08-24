local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
local myHandle = select(4, ...)

function CreateCheckBoxDialog(displayHandle)  
 
   -- Get the index of the display on which to create the dialog.
  local displayIndex = Obj.Index(GetFocusDisplay())
  if displayIndex > 5 then
    displayIndex = 1
  end
  
  -- Get the colors.
  local colorTransparent = Root().ColorTheme.ColorGroups.Global.Transparent
  local colorBackground = Root().ColorTheme.ColorGroups.Button.Background
  local colorBackgroundPlease = Root().ColorTheme.ColorGroups.Button.BackgroundPlease
  
  -- Get the overlay.
  local display = Root().GraphicsRoot.PultCollect:Ptr(1).DisplayCollect:Ptr(displayIndex)
  local screenOverlay = display.ScreenOverlay
  
  -- Delete any UI elements currently displayed on the overlay.
  screenOverlay:ClearUIChildren()   
  
  -- Create the dialog base.
  local dialogWidth = 650
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
  titleBarIcon.Text = "Dialog Example"
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
  dlgFrame.Rows = 3
  dlgFrame.Anchors = {
    left = 0,
    right = 0,
    top = 1,
    bottom = 1
  }
  dlgFrame[1][1].SizePolicy = "Fixed"
  dlgFrame[1][1].Size = "60"
  dlgFrame[1][2].SizePolicy = "Fixed"
  dlgFrame[1][2].Size = "120"
  dlgFrame[1][3].SizePolicy = "Fixed"  
  dlgFrame[1][3].Size = "80"    
  
  -- Create the sub title.
  -- This is row 1 of the dlgFrame.
  local subTitle = dlgFrame:Append("UIObject")
  subTitle.Text = "This example shows a grid of checkboxes."
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
  
  -- Create the checkbox grid.
  -- This is row 2 of the dlgFrame.
  local checkBoxGrid = dlgFrame:Append("UILayoutGrid")
  checkBoxGrid.Columns = 3
  checkBoxGrid.Rows = 2
  checkBoxGrid.Anchors = {
    left = 0,
    right = 0,
    top = 1,
    bottom = 1
  }
  checkBoxGrid.Margin = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 5
  } 
  
  local checkBox1 = checkBoxGrid:Append("CheckBox")
  checkBox1.Anchors = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }  
  checkBox1.Text = "Check Box 1"
  checkBox1.TextalignmentH = "Left";
  checkBox1.State = 0;
  checkBox1.PluginComponent = myHandle
  checkBox1.Clicked = "CheckBoxClicked"  
  
  local checkBox2 = checkBoxGrid:Append("CheckBox")
  checkBox2.Anchors = {
    left = 1,
    right = 1,
    top = 0,
    bottom = 0
  }    
  checkBox2.Text = "Check Box 2"
  checkBox2.TextalignmentH = "Left";
  checkBox2.State = 0;
  checkBox2.PluginComponent = myHandle
  checkBox2.Clicked = "CheckBoxClicked"
  
  local checkBox3 = checkBoxGrid:Append("CheckBox")
  checkBox3.Anchors = {
    left = 2,
    right = 2,
    top = 0,
    bottom = 0
  }    
  checkBox3.Text = "Check Box 3"
  checkBox3.TextalignmentH = "Left";
  checkBox3.State = 0;
  checkBox3.PluginComponent = myHandle
  checkBox3.Clicked = "CheckBoxClicked"  
  
  local checkBox4 = checkBoxGrid:Append("CheckBox")
  checkBox4.Anchors = {
    left = 0,
    right = 0,
    top = 1,
    bottom = 1
  }    
  checkBox4.Text = "Check Box 4"
  checkBox4.TextalignmentH = "Left";
  checkBox4.State = 0;
  checkBox4.PluginComponent = myHandle
  checkBox4.Clicked = "CheckBoxClicked"   
  
  local checkBox5 = checkBoxGrid:Append("CheckBox")
  checkBox5.Anchors = {
    left = 1,
    right = 1,
    top = 1,
    bottom = 1
  }    
  checkBox5.Text = "Check Box 5"
  checkBox5.TextalignmentH = "Left";
  checkBox5.State = 0;
  checkBox5.PluginComponent = myHandle
  checkBox5.Clicked = "CheckBoxClicked"  
  
  local checkBox6 = checkBoxGrid:Append("CheckBox")
  checkBox6.Anchors = {
    left = 2,
    right = 2,
    top = 1,
    bottom = 1
  }    
  checkBox6.Text = "Check Box 6"
  checkBox6.TextalignmentH = "Left";
  checkBox6.State = 0;
  checkBox6.PluginComponent = myHandle
  checkBox6.Clicked = "CheckBoxClicked"   
   
  -- Create the button grid.
  -- This is row 3 of the dlgFrame.
  local buttonGrid = dlgFrame:Append("UILayoutGrid")
  buttonGrid.Columns = 2
  buttonGrid.Rows = 1
  buttonGrid.Anchors = {
    left = 0,
    right = 0,
    top = 2,
    bottom = 2
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
  applyButton.PluginComponent = myHandle
  applyButton.Clicked = "ApplyButtonClicked"  

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
  cancelButton.PluginComponent = myHandle
  cancelButton.Clicked = "CancelButtonClicked"
  cancelButton.Visible = "Yes"  
  
  -- Handlers.
  signalTable.CancelButtonClicked = function(caller)
    
    Echo("Cancel button clicked.")
    Obj.Delete(screenOverlay, Obj.Index(baseInput))
    
  end  
  
  signalTable.ApplyButtonClicked = function(caller)
    
    Echo("Apply button clicked.")    
    
    if (applyButton.BackColor == colorBackground) then
      applyButton.BackColor = colorBackgroundPlease
    else
      applyButton.BackColor = colorBackground
    end  
    
  end
  
  signalTable.CheckBoxClicked = function(caller)
  
    Echo("Checkbox '" .. caller.Text .. "' clicked. State = " .. caller.State)
    
    if (caller.State == 1) then
      caller.State = 0
    else
      caller.State = 1
    end
  
  end
  
end

-- Run the plugin.
return CreateCheckBoxDialog
  