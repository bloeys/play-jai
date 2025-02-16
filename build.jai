#import "Basic";
#import "String";
#import "Compiler";

#run build();

build :: () {

    print("\n\n==============================================================\n");
    print("================= build.jai Metaprogram Test =================\n");
    print("==============================================================\n\n");

    // Mark current workspace (the one build.jai is running in, created by the compiler) as one that does NOT generate an executable
    set_build_options_dc(.{do_output = false});

    // Create a new workspace to build main.jai in, with a friendly name
    ws := compiler_create_workspace(name = "Build Workspace");
    if !ws {
        compiler_report("Workspace creation failed\n");
        return;
    }

    // Get the current settings workspace (if we don't supply a workspace, current one is used).
    //
    // You can create a defaut 'Build_Options' struct as well and change that, but then that won't maintain any
    // changes done to the build options earlier in the program, or by an earlier workspace that started this workspace.
    // That's why, in general its better to take the existing options and change.
    opts := get_build_options();
    opts.output_executable_name = "main";

    // This is needed because we made build options 'do_output = false' above.
    // Not needed if we moved set_build_options_dc() to the end of this procedure.
    opts.output_type = .EXECUTABLE;

    // Parse some custom args of our own and set further build options
    is_release := false;
    args := opts.compile_time_command_line;
    for args {
        if it == {
            case "-debug";
                is_release = false;
            case "-release";
                is_release = true;
            case "-is_jai_cool";
                print("\n(from the build.jai metaprogram) Yes, Jai is very cool!\n");
            case;
                compiler_report(
                    tprint("Command-line argument at index=% with value=% is invalid. Valid options are: '-debug'; '-release'; '-is_jai_cool';\n", it_index+1, it),
                );
        }
    }

    if is_release set_optimization(*opts, .VERY_OPTIMIZED); else set_optimization(*opts, .DEBUG);

    // Set build options on our build workspace
    set_build_options(*opts, ws);

    // If you want to read compiler messages, you need to call being intercept BEFORE you add any source to the workspace.
    //
    // Here we are only interested in procedure headers.
    compiler_begin_intercept(ws);

    // AFTER we have set our options, we can start adding source files and/or source strings to this workspace for compilation.
    // Compilation starts as soon as you add 1 source file/string as the compiler is highly non-linear.
    //
    // Note: You can NOT change build options of this workspace after 
    add_build_file("main.jai", ws);

    // Start message loop that only reads procedure headers
    message_loop_handler();
    compiler_end_intercept(ws);
}

message_loop_handler :: () {

    generated_code := false;

    while true {
        
        // Blocks till we get a message
        msg := compiler_wait_for_message();

        if msg.kind == {
            case .IMPORT;
            case .FILE;
            case .PERFORMANCE_REPORT;

            case .TYPECHECKED;

                // This is another way of writing 'cast(*Message_Typechecked)msg', but different syntax being tested.
                // Probably clearer than 'cast()' as we know precedence (same as accessing member and similar to '.*' dereference, always first).
                typechecked_msg := msg.(*Message_Typechecked);

                // The 'procedure_headers' field contains ALL procedure headers not just top-level ones, so instead we will
                // read the 'declarations' member, which only has top level things, but then we need to distinguish different types of things.
                for decl: typechecked_msg.declarations {

                    // Find procedure headers
                    if decl.expression.expression && decl.expression.expression.kind == .PROCEDURE_HEADER {

                        // Print procedure headers that have name ending in '_test'.
                        // The reason is that all procs from our imports are considered top level declarations,
                        // so if we don' we will end up with a ton of prints.
                        proc_name := decl.expression.(*Code_Ident).name;
                        if ends_with(proc_name, "_test")
                            print("Compiler typechecked top-level procedure: %\n", proc_name);
                    }
                }

            case .PHASE;

                phase := msg.(*Message_Phase);

                // Note: Adding build strings like this that the rest of the code
                // relies on, it seems, MUST happen AFTER .TYPECHECKED_ALL_WE_CAN.
                //
                // We protect using 'generated_code' because this might be reached multiple times,
                // like for example when using #run
                if !generated_code && phase.phase == .TYPECHECKED_ALL_WE_CAN {
                    generated_code = true;
                    add_build_string("IS_BUILT_WITH_BUILD_JAI :: true;", msg.workspace);
                }

            case .COMPLETE; break;

            case;
                compiler_report(tprint("unhandled compiler message kind %\n", msg.kind));
        }
    }
}
