#import "Basic";

the_cake_is_a_lie := false;

// This CAN be seen by others if they #load us.
#scope_module;
module_scoped_int :: 99;

// This will NOT be seen by anything outside even if they #load us!
#scope_file;
file_scoped_int :: -99;
