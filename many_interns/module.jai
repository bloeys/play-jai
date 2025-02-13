#import "Basic";

// Note that here we are using #load, NOT #import!
// #import pulls in the names into this scope, BUT the module being imported remains in its own independent
// scope, and so the module can NOT see stuff within this scope (but we can see it obviously since we imported it).
//
// However, #load imports the names here as usual but puts them into the SAME scope as this file, which means that the loaded
// module can see and use anything we have here.
//
// One effect that happens here is that even though inter_names.jai does NOT import Basic, it can use stuff from it like print,
// and that is because it can see the print that got imported into THIS scope.
//
// #load is commonly used in module.jai because when importing a directory module, ONLY module.jai
// is actually imported! so anything not loaded by module.jai will NOT be seen by the importer. This setup also
// allows you to put all common imports like '#import "Basic";' into module.jai and have them
// be used by all other files in the module.
//
// Now you can import say intern_names.jai individually if you wanted without it being loaded here, but that's a different thing
// and in that case you will also need to make sure that you have all the things it expects in your scope, like say 'print'. 
#load "intern_names.jai";

// Now one might ask, why not just make module.jai automatically load all the files into scope?
// Well what if you wanted to conditionally load some things!
#module_parameters (LOAD_SENIORS := false) (SHOW_SALARIES := false) {
}

#if LOAD_SENIORS {
    #load "senior_names.jai";
}

#if SHOW_SALARIES {
    INTERN_SALARIES :: 0;
}
