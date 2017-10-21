# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "blink_rate" -parent ${Page_0} -widget comboBox


}

proc update_PARAM_VALUE.blink_rate { PARAM_VALUE.blink_rate } {
	# Procedure called to update blink_rate when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.blink_rate { PARAM_VALUE.blink_rate } {
	# Procedure called to validate blink_rate
	return true
}


proc update_MODELPARAM_VALUE.blink_rate { MODELPARAM_VALUE.blink_rate PARAM_VALUE.blink_rate } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.blink_rate}] ${MODELPARAM_VALUE.blink_rate}
}

proc update_MODELPARAM_VALUE.blink_off { MODELPARAM_VALUE.blink_off } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "blink_off". Setting updated value from the model parameter.
set_property value "0" ${MODELPARAM_VALUE.blink_off}
}

proc update_MODELPARAM_VALUE.blink_on { MODELPARAM_VALUE.blink_on } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "blink_on". Setting updated value from the model parameter.
set_property value "1" ${MODELPARAM_VALUE.blink_on}
}

