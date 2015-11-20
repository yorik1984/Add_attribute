# Copyright 2014, Igor Sepelev aka goga63
# All Rights Reserved
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE.
# ------------------------------------------------------------------------------
# License: GPL V.3
# Author: Igor Sepelev aka goga63
# Name: add_attribute.rb
# Version: 1.1
# Description: Plugin add attributes of components in model
# Usage: see README
# History:
# 1.0 Initial release
# by Igor Sepelev aka goga63
#
# 1.1-beta 10-November-2015
# by Yurij Kulchevich
#  - add english version of dialogs;
#  - add toolbar icon;
#  - validate input.
# ------------------------------------------------------------------------------

require 'sketchup.rb'

module AddAttributes

  class AddAttributeInputbox

    attr_accessor :prompts, :defaults, :list, :inputbox_window_name

    def initialize
      @prompts_all = { label: "Name",
                   formlabel: "Display label",
                       units: "Display in",
                       value: "Value or formula ( = )",
                formulaunits: "Units",
                      access: "Display rule",
                     options: "List Option (Opt1=Val1&&Opt2=Val2)",
                 lengthunits: "Toggle Units",
                   duplicate: "Duplicate attribute name",
                   recurcive: "Recursive adding attribute(s)",
                     scale_x: "Scale along red. (X)",
                     scale_y: "Scale along green. (Y)",
                     scale_z: "Scale along blue. (Z)",
                   scale_x_z: "Scale in red/blue plane. (X+Z)",
                   scale_y_z: "Scale in green/blue plane. (Y+Z)",
                   scale_x_y: "Scale in red/green plane. (X+Y)",
                 scale_x_y_z: "Scale uniform (from corners). (XYZ)" }
      @prompts = [ @prompts_all[:label],
                   @prompts_all[:formlabel],
                   @prompts_all[:units],
                   @prompts_all[:value],
                   @prompts_all[:formulaunits],
                   @prompts_all[:access],
                   @prompts_all[:options] ]
      @defaults = ["",
                  "",
                  "End user's model units",
                  "",
                  "Text",
                  "User cannot see this attribute",
                  "" ]
      @list = ["",
              "",
              "End user's model units|Whole Number|Decimal Number|Percentage|True/False|Text|Inches|Decimal Feet|Millimeters|Centimeters|Meters|Degrees|Dollars|Euros|Yen|Pounds (weight)|Kilograms",
              "",
              "Decimal Number|Text|Inches|Centimeters",
              "User cannot see this attribute|User can see this attribute|User can edit as a textbox|User can select from a list",
              "" ]
      @inputbox_window_name = "Input attributes"
      @inputbox = []
    end

    def valid_attribute_name(input)
      #Inspect attribute name
      valid_status = []
      status_error = { NO_ERROR: "Input attribute name correct",
                    EMPTY_FIELD: "Attribute name cannot be empty",
                 CONTAIN_SPACES: "Attribute name cannot contain spaces",
           NOT_LETTER_OR_NUMBER: "Attribute name can only contain Latin letters and numbers",
                     UNDERSCOPE: "Attribute name cannot begin with an underscore",
                NUMBER_IN_BEGIN: "Attribute name cannot begin with an number",
                       CYRILLIC: "Attribute name cannot contain Cyrillic symbols",
                  TRUE_OR_FALSE: "You may not name an attribute TRUE or FALSE" }
      if input.to_s == ""
        valid_status[0] = false
        valid_status[1] = status_error[:EMPTY_FIELD]
        return valid_status
        nil
      end
      regex_space = /(\s)/
      if input =~ regex_space
        valid_status[0] = false
        valid_status[1] = status_error[:CONTAIN_SPACES]
        return valid_status
        nil
      end
      special = "?<>',./[]=-)(*&^%$#`~{}\""
      regex_special = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
      regex_latin = /\p{Latin}/
      if input =~ regex_special || !(input.to_s =~ regex_latin)
        valid_status[0] = false
        valid_status[1] = status_error[:NOT_LETTER_OR_NUMBER]
        return valid_status
        nil
      end
       if input[0].to_s == "_"
        valid_status[0] = false
        valid_status[1] = status_error[:UNDERSCOPE]
        return valid_status
        nil
      end
      regex_digits = /(\d)/
      if input[0].to_s=~ regex_digits
        valid_status[0] = false
        valid_status[1] = status_error[:NUMBER_IN_BEGIN]
        return valid_status
        nil
      end
      if input.downcase == "true" || input.downcase == "false"
        valid_status[0] = false
        valid_status[1] = status_error[:TRUE_OR_FALSE]
        return valid_status
        nil
      end
      valid_status[0] = true
      valid_status[1] = status_error[:NO_ERROR]
      return valid_status
    end # valid_attribute_name

    def inputbox(choice)
      if choice == "Custom..."
        input_check = []
        input_check[0] = false
        until input_check[0]
          custom_name = UI.inputbox(["Custom attribute name (String)"], [""], [""], "Custom attribute name")
          input_check = valid_attribute_name(custom_name[0])
          if !input_check[0]
            UI.messagebox("Failure!"+ "\n" + input_check[1])
          end
        end
        custom_is_standart = standart_attribute(custom_name[0])
        if custom_is_standart[0]
          choice = custom_is_standart[1]
        else
          @inputbox_window_name = "Input Custom attribute"
          @prompts[7] = @prompts_all[:lengthunits]
          @defaults[0] = custom_name[0]
          @defaults[7] = "CENTIMETERS"
          @list[0] = custom_name[0]
          @list[7] = "INCHES|CENTIMETERS"
        end
      end
      case choice
      when "Name", "Summary", "Description", "ItemCode"
        @inputbox_window_name = "Input Component Info attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:value],
                     @prompts_all[:access] ]
        @defaults = [ choice,
                      "",
                      "User can see this attribute" ]
        @list = [ choice,
                  "",
                  "User can see this attribute" ]
      when "X","Y","Z","LenX","LenY", "LenZ"
        if choice == "X" || choice == "Y" || choice == "Z"
          @inputbox_window_name = "Input Position attribute " + choice
        else
          @inputbox_window_name = "Input Size attribute " + choice
        end
        @prompts[7] = @prompts_all[:lengthunits]
        @defaults[0] = choice
        @defaults[2] = "Millimeters"
        @defaults[4] = "Centimeters"
        @defaults[7] = "CENTIMETERS"
        @list[0] = choice
        @list[2] = "End user's model units|Inches|Decimal Feet|Millimeters|Centimeters|Meters"
        @list[4] = "Inches|Centimeters"
        @list[7] = "INCHES|CENTIMETERS"
      when "RotX", "RotY", "RotZ"
        @inputbox_window_name = "Input Rotation attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:formlabel],
                     @prompts_all[:units],
                     @prompts_all[:value],
                     @prompts_all[:access],
                     @prompts_all[:options] ]
        @defaults = [ choice,
                      "",
                      "Degrees",
                      "",
                      "User cannot see this attribute",
                      "" ]
        @list = [ choice,
                  "",
                  "Degrees",
                  "",
                  "User cannot see this attribute|User can see this attribute|User can edit as a textbox|User can select from a list",
                  "" ]
      when "Material"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:formlabel],
                     @prompts_all[:units],
                     @prompts_all[:value],
                     @prompts_all[:access],
                     @prompts_all[:options] ]
        @defaults = [ choice,
                      "",
                      "Text",
                      "",
                      "User cannot see this attribute",
                      "" ]
        @list = [ choice,
                  "",
                  "Text",
                  "",
                  "User cannot see this attribute|User can see this attribute|User can edit as a textbox|User can select from a list",
                  "" ]
      when "ScaleTool"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:access],
                     @prompts_all[:scale_x],
                     @prompts_all[:scale_y],
                     @prompts_all[:scale_z],
                     @prompts_all[:scale_x_z],
                     @prompts_all[:scale_y_z],
                     @prompts_all[:scale_x_y],
                     @prompts_all[:scale_x_y_z] ]
        @defaults = [ choice,
                      "User cannot see this attribute",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes",
                      "Yes" ]
        @list = [ choice,
                  "User cannot see this attribute",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No",
                  "Yes|No" ]
      when "Hidden"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:value],
                     @prompts_all[:access] ]
        @defaults = [ choice,
                      "FALSE",
                      "User cannot see this attribute" ]
        @list = [ choice,
                  "",
                  "User cannot see this attribute" ]
      when "onClick"
        @inputbox_window_name = "Input Behaviors attribute " + choice
        @prompts_all[:formlabel] = "Tool tip"
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:formlabel],
                     @prompts_all[:value],
                     @prompts_all[:access] ]
        @defaults = [ choice,
                      "Click to activate",
                      "",
                      "User cannot see this attribute" ]
        @list = [ choice,
                  "",
                  "",
                  "User cannot see this attribute" ]
      when "Copies", "ImageURL"
        if choice == "Copies"
          @inputbox_window_name = "Input Behaviors attribute " + choice
        else
          @inputbox_window_name = "Input Form Design attribute " + choice
        end
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:formlabel],
                     @prompts_all[:value],
                     @prompts_all[:access] ]
        @defaults = [ choice,
                      "Copies",
                      "",
                      "User cannot see this attribute" ]
        @list = [ choice,
                 "Copies",
                 "",
                 "User cannot see this attribute" ]
      when "DialogWidth", "DialogHeight"
        @inputbox_window_name = "Input Form Design attribute " + choice
        @prompts = [ @prompts_all[:label],
                     @prompts_all[:value],
                     @prompts_all[:access] ]
        @defaults = [ choice,
                      "400",
                      "User cannot see this attribute" ]
        @list = [ choice,
                  "",
                  "User cannot see this attribute" ]
      when "Toogle Units"
        @prompts = [ @prompts_all[:lengthunits] ]
        @defaults = [ "CENTIMETERS" ]
        @list = [ "INCHES|CENTIMETERS" ]
      else
        puts "Custom choice"
      end # case choice
      @prompts = @prompts + [ @prompts_all[:duplicate], @prompts_all[:recurcive] ]
      @defaults = @defaults + [ "Ignore", "No" ]
      @list = @list + [ "Ignore|Replace", "Yes|No" ]
      @inputbox = UI.inputbox(@prompts, @defaults, @list, @inputbox_window_name)
      @inputbox[0] = @inputbox[0]
      input_labels = {}
      @inputbox.each_index do |i|
        temp = { @prompts_all.key(@prompts[i]) => @inputbox[i] }
        input_labels = input_labels.merge(temp)
      end
      return input_labels
    end

    def standart_attribute(attribute)
      label_std = { name: "Name",
                 summary: "Summary",
             description: "Description",
                itemcode: "ItemCode",
                       x: "X",
                       y: "Y",
                       z: "Z",
                    lenx: "LenX",
                    leny: "LenY",
                    lenz: "LenZ",
                    rotx: "RotX",
                    roty: "RotY",
                    rotz: "RotZ",
                material: "Material",
               scaletool: "ScaleTool",
                  hidden: "Hidden",
                 onclick: "onClick",
                  copies: "Copies",
                imageurl: "ImageURL",
             dialogwidth: "DialogWidth",
            dialogheight: "DialogHeight" }
      standart_attribute_status = []
      key = attribute.to_s.downcase.to_sym
      if label_std.has_key?(key)
        standart_attribute_status[0] = true
        standart_attribute_status[1] = label_std.fetch(key)
       else
        standart_attribute_status[0] = false
        standart_attribute_status[1] = attribute.to_s
      end
      standart_attribute_status
    end

  end #class AddAttribute

  def self.include_element?(array, element)
    array.each_index do |i|
      if array[i] == element
        return true
        exit
      end
    end
    return false
  end

  def self.select_components_messagebox?(selection)
    if !selection.empty?
      selection.each do |entity|
        if !entity.is_a?(Sketchup::ComponentInstance)
          UI.messagebox("Select only components")
          return false
          nil
        end
      end
    else
      UI.messagebox("Select nothing")
      return false
      nil
    end
    true
  end

  def self.get_definition(entity)
    if entity.is_a?(Sketchup::ComponentInstance)
      entity.definition
    elsif entity.is_a?(Sketchup::Group)
      entity.entities.parent
    else
      nil
    end
  end

  def self.recursive_set_dynamic_attributes(selection, input, duplicate_status, recursive_status)
    dict = "dynamic_attributes"
    selection.each do |entity|
      definition = self.get_definition(entity)
      next if definition.nil?
      instance_attribute = entity.get_attribute dict, input[:label].to_s.downcase
      definition_attribute = entity.definition.get_attribute dict, input[:label].to_s.downcase
      if (duplicate_status == "Replace") || (duplicate_status == "Ignore" && (instance_attribute == nil || definition_attribute == nil))
       self.set_dynamic_attributes(entity, input) if entity.is_a?(Sketchup::ComponentInstance)
      end
      if recursive_status == "Yes"
        self.recursive_set_dynamic_attributes(definition.entities, input, duplicate_status, recursive_status)
      end
    end
  end

  def self.set_dynamic_attributes(entity, input)
    attributes_formulaunits = { FLOAT: "Decimal Number",
                               STRING: "Text",
                               INCHES: "Inches",
                          CENTIMETERS: "Centimeters" }
    attributes_units = { DEFAULT: "End user's model units",
                         INTEGER: "Whole Number",
                           FLOAT: "Decimal Number",
                         PERCENT: "Percentage",
                         BOOLEAN: "True/False",
                          STRING: "Text",
                          INCHES: "Inches",
                            FEET: "Decimal Feet",
                     MILLIMETERS: "Millimeters",
                     CENTIMETERS: "Centimeters",
                          METERS: "Meters",
                         DEGREES: "Degrees",
                         DOLLARS: "Dollars",
                           EUROS: "Euros",
                             YEN: "Yen",
                          POUNDS: "Pounds (weight)",
                       KILOGRAMS: "Kilograms" }
    attributes_access = { NONE: "User cannot see this attribute",
                          VIEW: "User can see this attribute",
                       TEXTBOX: "User can edit as a textbox",
                          LIST: "User can select from a list" }
    standart_input = AddAttributeInputbox.new
    label_input = input[:label].to_s.downcase
    dict = "dynamic_attributes"
    instance_name = entity.name.to_s
    definition_name = entity.definition.name.to_s
    if !instance_name.empty?
     entity.set_attribute dict, "_name", instance_name
     entity.definition.set_attribute dict, "_name", instance_name
    else
     entity.set_attribute dict, "_name", definition_name
     entity.definition.set_attribute dict, "_name", definition_name
    end
    wide_label = ["X", "Y", "Z", "RotX", "RotY", "RotZ", "Copies"]
    without_access = ["Name", "Summary", "Description", "ItemCode", "Material", "ScaleTool", "Hidden", "onclick"]
    wide_formlabel = ["X", "Y", "Z", "RotX", "RotY", "RotZ", "Copies"]
    if input.has_key?("label".to_sym)
      if self.include_element?(wide_label, input[:label].to_s)
        entity.set_attribute dict, "#{label_input}", input[:label].to_s
        entity.set_attribute dict, "_#{label_input}_label", input[:label].to_s
        entity.definition.set_attribute dict, "_inst__#{label_input}_label", input[:label].to_s
      else
        entity.definition.set_attribute dict, "_#{label_input}_label", input[:label].to_s
      end
    end
    if input.has_key?("access".to_sym) && !self.include_element?(without_access, input[:access].to_s)
      if self.include_element?(wide_label, input[:access].to_s)
        entity.set_attribute dict, "#{label_input}", attributes_access.key(input[:access]).to_s
        entity.set_attribute dict, "_#{label_input}_access", attributes_access.key(input[:access]).to_s
        entity.definition.set_attribute dict, "_inst__#{label_input}_access", attributes_access.key(input[:access]).to_s
      else
        entity.definition.set_attribute dict, "_#{label_input}_access", attributes_access.key(input[:access]).to_s
      end
    end
    if input.has_key?("value".to_sym)
      result_value = input[:value]
      if result_value[0] == "="
        value_formula = result_value[1..result_value.length]
        if self.include_element?(wide_label, input[:label].to_s)
          entity.set_attribute dict, "#{label_input}", value_formula
          entity.set_attribute dict, "_#{label_input}_formula", value_formula
          entity.definition.set_attribute dict, "_inst__#{label_input}_formula", value_formula
        else
          entity.definition.set_attribute dict, "_#{label_input}_formula", value_formula
        end
      end
      if input.has_key?("units".to_sym)
        if self.include_element?(wide_label, input[:units].to_s)
          entity.set_attribute dict, "#{label_input}", attributes_units.key(input[:units]).to_s
          entity.set_attribute dict, "_#{label_input}_units", attributes_units.key(input[:units]).to_s
          entity.definition.set_attribute dict, "_inst__#{label_input}_units", attributes_units.key(input[:units]).to_s
        else
          entity.definition.set_attribute dict, "_#{label_input}_units", attributes_units.key(input[:units]).to_s
        end
        case input[:units].to_s
        when "Millimeters"
          result_value = input[:value].to_f*(1.to_inch/1.to_mm)
        when "Centimeters"
          result_value = input[:value].to_f*(1.to_inch/1.to_cm)
        when "Meters"
          result_value = input[:value].to_f*(1.to_inch/1.to_m)
        else
          result_value = input[:value]
        end
      end
      if self.include_element?(wide_label, input[:label].to_s)
        entity.set_attribute dict, label_input, result_value
      else
        entity.set_attribute dict, label_input, result_value
        entity.definition.set_attribute dict, label_input, result_value
      end
    end
    if input[:label] == "ScaleTool"
      scaletool_binary = ""
      input.each_value do |value|
        scaletool_binary = scaletool_binary + "0" if value == "Yes" && input.key(value) != :recurcive
        scaletool_binary = scaletool_binary + "1" if value == "No" && input.key(value) != :recurcive
      end
      scaletool_dec = scaletool_binary.reverse.to_i(2)
      entity.set_attribute dict, "scaletool", scaletool_dec
      entity.definition.set_attribute dict, "scaletool", scaletool_dec
    end
    if input.has_key?("formlabel".to_sym)
      if self.include_element?(wide_formlabel, input[:formlabel].to_s)
        entity.set_attribute dict, "#{label_input}", input[:formlabel].to_s
        entity.set_attribute dict, "_#{label_input}_formlabel", input[:formlabel].to_s
        entity.definition.set_attribute dict, "_inst__#{label_input}_formlabel", input[:formlabel].to_s
      else
       entity.definition.set_attribute dict, "_#{label_input}_formlabel", input[:formlabel].to_s
      end
    end
    if input.has_key?("formulaunits".to_sym)
      if self.include_element?(wide_formlabel, input[:formulaunits].to_s)
        entity.set_attribute dict, "#{label_input}", attributes_formulaunits.key(input[:formulaunits]).to_s
        entity.set_attribute dict, "_#{label_input}_formulaunits", attributes_formulaunits.key(input[:formulaunits]).to_s
        entity.definition.set_attribute dict, "_inst__#{label_input}_formulaunits", attributes_formulaunits.key(input[:formulaunits]).to_s
      else
       entity.definition.set_attribute dict, "_#{label_input}_formulaunits", attributes_formulaunits.key(input[:formulaunits]).to_s
      end
    end
    if input[:options] != nil
      entity.set_attribute dict , "_#{label_input}_options", input[:options].to_s
    end
    if input.has_key?("lengthunits".to_sym)
      entity.set_attribute dict, "_lengthunits", input[:lengthunits].to_s
      entity.definition.set_attribute dict, "_lengthunits", input[:lengthunits].to_s
    elsif entity.get_attribute(dict, "_lengthunits") == nil
      entity.set_attribute dict, "_lengthunits", "INCHES"
      entity.definition.set_attribute dict, "_lengthunits", "INCHES"
    end

    # REDRAW
    # temporary ON
    $dc_observers.get_latest_class.redraw_with_undo(entity)

  end #set_dynamic_attributes


  def self.inputbox_attributes
    model = Sketchup.active_model
    selection = model.selection
    if select_components_messagebox?(selection)
      input = []
      prompts = ["Attribute Name"]
      defaults = ["Custom..."]
      list = ["Custom...|Name|Summary|Description|ItemCode|X|Y|Z|LenX|LenY|LenZ|RotX|RotY|RotZ|Material|ScaleTool|Hidden|onClick|Copies|ImageURL|DialogWidth|DialogHeight|Toogle Units"]
      choice_attributes = UI.inputbox(prompts, defaults, list, "Choice attributes")
      choice = choice_attributes[0].to_s
      attribute_inputbox = AddAttributeInputbox.new
      input = attribute_inputbox.inputbox(choice)
      status = model.start_operation('Adding attribute', true)
      recursive_status = input[:recurcive].to_s
      duplicate_status = input[:duplicate].to_s
      self.recursive_set_dynamic_attributes(selection, input, duplicate_status, recursive_status)
      model.commit_operation
    else
      nil
    end
  end # inputbox_attributes

end # module AddAttributes

# Create menu items
unless file_loaded?(__FILE__)
  # Create toolbar
  add_attribute_tb = UI::Toolbar.new(AddAttributes::PLUGIN_NAME)
  icon_s_inputbox_attributes = File.join(AddAttributes::PATH_ICONS, "inputbox_attributes_16.png")
  icon_inputbox_attributes = File.join(AddAttributes::PATH_ICONS, "inputbox_attributes_24.png")

  # Add item "inputbox_attributes"
  inputbox_attributes_cmd = UI::Command.new("Adding new attribute from inputbox"){ AddAttributes::inputbox_attributes }
  inputbox_attributes_cmd.small_icon = icon_s_inputbox_attributes
  inputbox_attributes_cmd.large_icon = icon_inputbox_attributes
  inputbox_attributes_cmd.tooltip = "Adding new attributes from inputbox"
  inputbox_attributes_cmd.status_bar_text = "Adding new attributes from inputbox"

  add_attribute_tb.add_item(inputbox_attributes_cmd)

  # Create menu
  add_attribute = UI.menu("Plugins").add_submenu(AddAttributes::PLUGIN_NAME)
  add_attribute.add_item("Add attributes inputbox"){ AddAttributes::inputbox_attributes }
  file_loaded(__FILE__)
end
