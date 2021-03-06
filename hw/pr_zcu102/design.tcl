#!/opt/Xilinx/Vivado/2017.2/bin/vivado -mode batch -source 
# Xilinx-provided scripts
set tclDir "./tcl"
source $tclDir/design_utils.tcl
source $tclDir/log_utils.tcl
source $tclDir/synth_utils.tcl
source $tclDir/impl_utils.tcl
source $tclDir/hd_floorplan_utils.tcl

###############################################################
### Define Part, Package, Speedgrade 
###############################################################
# For ZedBoard
#set part "xc7z020clg484-1"
# For zcu102
set part "xczu9eg-ffvb1156-2-i"
check_part $part

###############################################################
###  Setup Variables
###############################################################
#set tclParams [list <param1> <value> <param2> <value> ... <paramN> <value>]
set tclParams [list hd.visual 1 \
              ]

####flow control
set run.rmSynth        0
set run.prImpl         1
set run.prVerify       0
set run.writeBitstream 0
set run.flatImpl       0

####Report and DCP controls - values: 0-required min; 1-few extra; 2-all
set verbose      1
set dcpLevel     1

####Output Directories
set synthDir	"./synth_333"
set implDir	"./impl"
set dcpDir	"./dcp"
set bitDir	"./bit"
set srcDir	""

###############################################################
### Top Definition
###############################################################

set proj_dir	"../base_zcu102"
set proj_name	"base_zcu102"
set top		"sym"

set top_dcp	"${dcpDir}/base/${top}.dcp"
set top_xdc	[list	"${proj_dir}/${proj_name}.srcs/${top}/new/pblocks.xdc"]

set static "${top}_static"
add_module $static
set_attribute module $static moduleName      $top
set_attribute module $static top_level       1
set_attribute module $static synthCheckpoint $top_dcp

####################################################################
### RP Module Definitions
####################################################################

set core_basename "zcore32"
set core_easiest "loopback"
set core_hardest "gauss"
set cores_with_alt_settings [list "contrast" "sharpen"]
set core_list [list "gauss" "sobel" "sharpen" "emboss" "outline" "contrast" "negative" "threshold" "loopback"]

for {set pblock_list [list]; set i 0} {$i < 63} {incr i} {
	lappend pblock_list $i
}; #pblock_list will be [0, 1, 2, ... N-1]

set core_big_list $core_list
##set core_big_list [list "gauss" "sobel" "sharpen" "emboss" "outline"]

##set pblock_small_list [list 4 5 10 11 14 15]
set pblock_small_list [list]
#   ^leave empty if all pblocks are identical

####################################################################
### Configuration generation
####################################################################

foreach core $core_list {
	# The hardes to route module shall be used to define the contact points
	# between static and reconfigurable regions.
	set partition_list [list [list $static $top [expr {$core == $core_hardest ? "implement" : "import"}] ] ]

	foreach pblock $pblock_list {
		# The generic reconfigurable module, in the form of ${myModule}_${myPblock}
		set instance "${core_basename}_${pblock}"

		# The logic implemented in the aforementioned reconfigurable module
		set variant "${instance}_${core}"

		# HDL modules created by Vivado have the form of ${design_name}_${module}_n_m,,
		# usually n=[0,1,2...] and m=0, but if module was copied-pasted in IP-Integrator,
		# naming is not well predictable and therefore we do not attempt to guess it. 
		# The prj file has discovered it by parsing top module, therefore it will be correct.
		set module_name [exec /bin/grep "${core_basename}_[0-9]" ./prj/${variant}.prj | sed s@.*/@@ | sed s/.v$//]
		
		# Assume two sizes of pblocks. If the logic is ``big'' and the pblock is ``small'',
		# then use a simple placeholder logic. The generated bitstream will be discarded.
		if {((${core} in ${core_big_list}) && (${pblock} in ${pblock_small_list}))} {
			lappend partition_list [list "${instance}_${core_easiest}" "${top}_i/${instance}" "implement"]
		} else {
			lappend partition_list [list ${variant} "${top}_i/${instance}" "implement"]
		}

		# Create Xilinx TCL variables for this module variant
		add_module $variant
		set_attribute module $variant moduleName ${module_name}
		set_attribute module $variant prj	"./prj/${variant}.prj"
		set_attribute module $variant xdc	"${proj_dir}/${proj_name}.srcs/sources_1/bd/${top}/ip/${module_name}/constraints/${core_basename}_ooc.xdc"
		set_attribute module $variant synth	${run.rmSynth}
	}
	
	# Define configuration. There will be one configuration for each module design,
	# that will be implemented in all reconfigurable partitions. If the design is too big
	# for the module, placeholder was assigned in previous step
	set config "config_${core}"
	add_implementation $config
	set_attribute impl $config top		$top

	# Implementation parameters. Xilinx scripts were created for Vivado 2014.2
	# and therefore some newer options are recognized or some older may no longer be valid.
	# Please modify tcl/implementation.tcl if that problem arises.
	
	set_param place.closeImportedSites false	
	set_attribute impl $config opt_directive   "Explore"
	set_attribute impl $config place_directive "ExtraPostPlacementOpt"
	set_attribute impl $config phys_directive  "Explore"
	if {$core ni $cores_with_alt_settings} {
		set_attribute impl $config route_directive "Explore"
	} else {
		set_attribute impl $config route_directive "MoreGlobalIterations"
	}

	# Xilinx PR script parameters. The user-configurable ones (ie run.*) are defined above
	set_attribute impl $config pr.impl	1
	set_attribute impl $config implXDC	${top_xdc}
	set_attribute impl $config impl		${run.prImpl}
	set_attribute impl $config partitions	${partition_list}
	set_attribute impl $config verify	${run.prVerify}
	set_attribute impl $config bitstream	${run.writeBitstream}
	set_attribute impl $config cfgmem.pcap	1
}

# Configuration is done, call Xilinx PR scrips
source $tclDir/run.tcl
exit

