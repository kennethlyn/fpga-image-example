# This script needs 3 parameters
# 0: Path where to store project root
# 1: board
# 2: path to dyplo IP
if { $argc != 3 } {
    puts "DYPLO_ERROR: This script needs 3 arguments, $argc found. See top of file for explanation."
} else {
	set project_dir [lindex $argv 0]
	set part [lindex $argv 1]
	set path_to_dyplo_ip [lindex $argv 2]
}

# Replace \ with / in path 
set path_to_dyplo_ip [string map {\\ /}  $path_to_dyplo_ip]

puts "Project root: $project_dir"
puts "Part: $part"
puts "Path to Dyplo IP: $path_to_dyplo_ip"

if { ! [file exists "$project_dir/checkpoints"] } {
	file mkdir "$project_dir/checkpoints"
}

if { ! [file exists "$project_dir/bitstreams"] } {
	file mkdir "$project_dir/bitstreams"
}

# Check if path_to_dyplo_ip exists
if { ! [file exists $path_to_dyplo_ip] } { 
	puts "DYPLO_ERROR: Path to Dyplo IP does not exist."
	exit -1
} 

# Create project
create_project dyplo_example $project_dir -part $part -force
set_property target_language VHDL [current_project]

# Update IP Repo
set_property ip_repo_paths  "$path_to_dyplo_ip" [current_fileset]
update_ip_catalog

# Create Block design
source -notrace generate_bd.tcl

# Add constraints file
add_files -fileset constrs_1 -norecurse ./dyplo_example.xdc
import_files -fileset constrs_1 ./dyplo_example.xdc

# Close project
close_project

# Exit vivado
exit
