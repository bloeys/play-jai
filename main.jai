#import "Basic";

#load "Global_Consts.jai";

// Add this gg field to the context
#add_context gg : u8 = 128;

main :: () {

    print("\n\n==================================================================\n");
    print("=========================== Bism Allah ===========================\n");
    print("==================================================================\n\n");

    // This IS_DEBUG const is a placeholder filled by the build.jai metaprogram
    //
    // This is commented out because the language server in vscode shows an error, but it actually works. 
    // print("Is debug (set by build.jai) = %\n", IS_DEBUG);

    core_test();
    print_test();
    loop_test();
    ifx_test();
    if_case_test();
    any_test();
    this_and_loc_and_run_test();
    operator_overloading_test();
    static_if();
    polymorphic_procs_test();
    polymorphic_structs_test();
    limit_polymorphic_types_test();
    modify_directive_test();
    type_variants_test();
    imports_test();
    using_test();
    comma_comma_test();
    pool_test();
    argument_and_return_handling_test();
    log_test();
    module_params_test();
    metaprogramming_test();
    is_constant_test();

    // Clear temp storage
    reset_temporary_storage();
}

Coord :: struct {
    lat: float64;
    long: float64;
}

Person :: struct {
    name: string;
    age: int;
    version := 1; // We can set defaults
    
    // We can even do part of structs!
    pos: Coord;
    pos.lat = -1;

    // Setting default later is even valid, if you want!
    // version = 1;
}

Employee :: struct {
    #as using base: Person;
    salary: float32;
}

core_test :: () {

    print("\n\n================= Core Test =================\n\n");

    x : s32 = 55;
    y : s8 = cast(s8) x;
    z := 1.2;
    w := 55;

    print("x=%, y=%, z=%\n", x,y,z);
    print("tx=%, ty=%, tz=%\n", type_of(x),type_of(y),type_of(z));

    /*
        Arrays        
    */
    // This array is allocated on the stack
    arr1 := int.[1,1,1,1,1,1,1,1,1,1];
    print("arr1 (type=%; size=%)=%\n", type_of(arr1), size_of(type_of(arr1)), arr1);
    
    // Inclusive: [0,9]
    for index: 0..9 {
        print("arr1[%]=%\n", index, arr1[index]);
    }

    arr1_sum := 0;
    arr1_index_sum := 0;
    for item, i: arr1 {
        arr1_sum += item;
        arr1_index_sum += i;
    }
    print("\narr1_sum=%; arr1_index_sum=%\n", arr1_sum, arr1_index_sum);

    // Array view
    arr1_view : []int = arr1;
    print("arr1_view (type=%)=%\n", type_of(arr1_view), arr1_view);

    // Resizable arrays
    resizable_arr : [..]int;
    array_add(*resizable_arr, 1);
    print("resizable_arr=%; resizable_arr.count=%; resizable_arr.allocated=%; resizable_arr.data (ptr) = %; resizable_arr.allocator=%\n",
        resizable_arr,
        resizable_arr.count,
        resizable_arr.allocated,
        resizable_arr.data,
        resizable_arr.allocator
    );

    /*
        Strings
    */

    // strings are simply u8 views ([]u8)
    // Constant strings are automatically zero-terminated (but count doesn't show that) and so allowed to cast to *u8/*s8 automatically.
    // String vars assigned to strings constants (e.g. x := "Hi") will also have zero termination, but will NOT cast automatically.
    s1 := "Hello there, friend!";

    print("s1=%\n", s1);
    print("type_of(s1)=%\n", type_of(s1));
    print("size_of(type_of(s1))=%\n", size_of(type_of(s1)));
    print("s1[5]=%\n", s1[5]);
    print("s1.count=%; s1.data=%\n", s1.count, s1.data);

    s1.data += 1;
    s1.count -= 1;  // Base pointer moved by one (data+=1) so we have to reduce count to avoid accessing potentially invalid memory
    print("s1=%\n", s1);

    // Exact strings
    s2 := #string GG

Hello there, friend!
how are you doing today??
    GG

    print(s2);

    /*
        Structs
    */

    p : Person;
    p.name = "Omar";
    p.age = 27;
    print("Person=%\n", p);

    p = Person.{name="Jon", age=54};
    print("Person=%\n", p);

    // Since type is already known, we can skip writing the type
    p = .{name="Jon"};
    print("Person=%\n", p);

    // Using puts the fields of the struct into scope, for convenience
    {
        using p;

        print("p.name=%\n", name);
    }

    /*
        Types
    */
    int_type := int;
    person_type := Person;
    print("int_type=%\n", int_type);
    print("person_type=%\n", person_type);

    print_personal_info :: (p: Person) {
        print("Person=%\n", p);
    }

    e := Employee.{name="Omar", age=27, salary=1_000_000};
    print_personal_info(p);
    print_personal_info(e); // '#as' allows us to automatically cast to that type, in this case person

    // '$p' means that the value of p must be known at compile time.
    //
    // This is useful for creating variables of unknown type.
    // You can create a variable x based on a variable t type_of(t)=Type, but ONLY if t is known at compile time, which is where '$'
    // becomes necessary.
    //
    // Obviously the usual way here is to just accept 'x: $T' as the second param.
    print_personal_info2 :: ($p: Person, $t: Type) {
        x: t;   // To do this you MUST use '$t'. Simply 't' will throw an error.
        print("Person=%; x=%\n", p, x);
    }

    p2 :: Person.{name="GG"};
    // p2 := Person.{name="GG"}; $p requires a constant value, so we MUST use 'p2 ::'.
    print_personal_info2(p2, s32);

    // Printing derived type from base
    print_emp_from_base :: (p: *Person) {
        print("print_emp_from_base=%\n", (cast(*Employee)p).*);
    }
    print_emp_from_base(*e);

    /*
        Procedures
    */
    default_return_proc :: (x: s32) -> y: int = 0, z: int = 0 {
        if x <= 0 return;
        if x <= 5 return z=5;


        return 10;
    }

    // #must will make it such that the caller can NOT ignore the return value.
    // The caller MUST read the variable. This is very useful when the returned value is allocated, and so
    // you want to ensure its handled to avoid a potential memory leak.
    must_proc :: () -> []s32 #must {
        x : [..]s32;
        array_add(*x, 1, 2, 3);
        return x;
    }

    must_arr : []s32;
    must_arr = must_proc();
    // must_proc(); // This will cause an error
    print("must_arr=%\n", must_arr);

    /*
        Context
    */

    print("context=%\n", context);
    print("context.gg=%\n", context.gg);

    // Pushes a copy of the context that is lost after scope ends
    push_context {
        print("(pushed context 1.1) context.gg=%\n", context.gg);
        context.gg += 1;
        print("(pushed context 1.2) context.gg=%\n", context.gg);
    }
    print("context.gg=%\n", context.gg);

    // Push a specific instance of context
    ctx := context;
    ctx.gg = 77;
    push_context ctx {
        print("(pushed context 2) context.gg=%\n", context.gg);
    }
    print("context.gg=%\n", context.gg);

    // Default enum type is s64, but we can do like 'My_Enum :: enum u32'
    My_Enum :: enum {
        A :: 5;
        B;  // B=6
        C :: 10;
        D;  // D=11
    }

    print_enum_key_values :: ($T : Type) {

        ti := type_info(T);
        assert(ti.type == .ENUM);

        sb : String_Builder;
        sb.allocator = temp;
        for ti.names {
            print_to_builder(*sb, " %=%", it, ti.values[it_index]);
        }

        print("% key/values:[% ]\n", T, builder_to_string(*sb));
    }

    enum1 := My_Enum.A;
    print("enum1=%\n", enum1);
    print("enum1 value type=%\n", type_of(type_info(My_Enum).values[0]));
    print_enum_key_values(My_Enum);

    print_test();
}

print_test :: () {

    print("\n\n================= Print Test =================\n\n");

    print("core_test=%\n", core_test);  // Outputs 'procedure 0x123', where 0x123 is the address
    print("core_test=%\n", cast(*void)core_test); // The cast outputs only the address without 'procedure'

    // We can mix and match numbered and non-numbered print arguments.
    // Non-numbered after numbered will pick the next argument after that number. So here % is used after %1, so %==%2.
    print("%3. Please welcome %1. %1 has been working on this language for % years. Good job %1. Thank you for % years of work.\n", "Jon", 10, "Hi all");

    // Formatting options can be applied using formatting structs like FormatInt/FormatStruct/FormatFloat/FormatArray
    print("some formatted int=%\n", FormatInt.{value = 99, minimum_digits = 3});
    print("some formatted int=%\n", FormatInt.{value = 999999, digits_per_comma = 3, comma_string=","});

    // This will round to 0.5001 as trailing width is numbers after the dot
    print("some formatted float=%\n", FormatFloat.{value = 0.50009, zero_removal = .NO, trailing_width = 4});
    
    print("some formatted struct=%\n",
        FormatStruct.{value = Person.{name = "Jon"}, draw_type_name = true, use_long_form_if_more_than_this_many_members = -1, use_newlines_if_long_form = true},
    );

    print("some formatted array=%\n", FormatArray.{value = u8.[55, 128, 0, 11], separator = "; "});

    // By default, print uses formatting specified in context.print_style, so changing that or pushing context
    // allows us to configure formatting on a global level or on a specific program subtree.
    push_context {
        context.print_style.default_format_int.base = 2;
        print("some formatted int (binary)=0b%\n", 3); // This will print in binary '11'
    }

    // '\%' prints '%'.
    //
    // To avoid some overlap cases (e.g. %%) you can use %0 which is the SAME as %, but avoids the
    // issue. Remember: %0 is NOT a numbered argument like %1/%2/etc. %==%0
    print("You got %0\% on your exam!\n", 91.5);

    // We want to print 'Tomato55', but doing %255 is wrong index, and %0 we can't use because we want argument 2,
    // so instead we can use %00, which is equal to "" (empty string).
    name1 := "Potato";
    name2 := "Tomato";
    print("My favorite fruit is %2%0055.\n", name1, name2);  // We're intentionally picking name2, ignoring name1.

    // Special treatment of '%' happens by print on the format string only. Arguments aren't touched.
    print("%\n", "My score is 99.99%! 99%%!!!");

    // If you want pure and simple print-to-console without any features or parsing, use write_string.
    write_string("This is a %. Do you like it? What about %% and %0 and '%00' and %1?!\n");

    // write_strings is the same pure printing but takes many strings
    write_strings("how", " are", " you?\n");

    // There is also write_number which takes s64
    write_number(-99);
    write_string("\n");
}

loop_test :: () {

    print("\n\n================= Loop Test =================\n\n");

    x := 0;
    while x < 10 {
        defer x += 1;
        print("x=%\n", x);

        if x==5 break;
    }

    // In a normal increment like while x<10 {x+=1;if x==5 break;}, the print
    // AFTER the loop would print x=5.
    //
    // However, 'defer' runs each time we exit the loop body which happens on each iteration AND
    // when we break. As such, if you break at x==5, the defer will run, and you will get x==6 after the loop.
    // This is fine, but must be kept in mind if you rely on the exact index/iteration when using defer.
    //
    // If you want exact index in such a while loop, do NOT use defer.
    print("x after loop=%\n", x);

    // Similar to Go, defer only 'activates' if it is reached.
    // As such, defer here won't be reached as x==6, and so we will exit the loop without changing x.
    while x < 100 {
        if x < 10 break;
        defer x += 1;
    }

    // Unlike Go, defer is attached to scope NOT procedure, and so triggers as soon as scope ends.
    // Here, the defer print will show BEFORE the after-scope print. In Go, it would be the opposite.
    {
        defer print("Hi from scope defer\n");
    }
    
    print("Hi from after scope\n");

    // Continue also fires defer, but again remember that defer must be reached BEFORE continue.
    while x < 10 {
        defer x += 1;
        continue;
    }
    print("x after defer+continue=%\n", x);

    // As you expect, continue/break refer to the innermost loop, but we can also name
    // loops and refer to those when using continue/break.
    //
    // loop1/loop2 are normal bool variables as you might expect, but they allow us to refer to a specific loop.
    //
    // Note: The variable loop1 does NOT need to be a bool. For example, it might be an int, which would still work as it
    // is evaluated as true/false based on its value to keep the loop going (zero==false).
    while loop1 := x < 100{

        defer x += 1;

        while loop2 := x < 1000 {

            print("type_of(loop1)=%\n", type_of(loop1));
            break loop1;
        }
    }
    print("x after nested loops with 1 iteration=%\n", x);

    // In for loops, we can use the loop variable to break/continue
    for 0..5 {
        print("1-iter-for-loop it=%\n", it);
        break it;
    }

    for x: 0..5 {
        print("1-iter-for-loop-v2 x=%\n", x);
        break x;
    }

    // Ranges are only evaluated ONCE before the start of the loop.
    // The following loop prints 0 till 5 even though x is decreasing each iteration. 
    x = 5;
    for 0..x {
        x -= 1;
        print("changing-range for-loop: it=%; x=%\n", it, x);
    }

    // If you want a given range to go in reverse, put '#v2 <' before it. The '#v2' is noted to be temporary.
    //
    // Note: start must still be less than end, its just that you go through a valid range in the other direction.
    for #v2 < 0..5 {
        print("reverse it=%\n", it);
    }

    // The above is all well and good, but pros do this
    arr := int.[1,2,3,4,5];
    
    print("\n");
    for num, i: arr {
        print("forward arr[%]=%\n", i, num);
    }

    print("\n");
    for < arr {
        print("reverse arr[%]=%\n", it_index, it);
    }

    // We can also break on custom iterator
    for x: arr {
        break x;
    }

    // To remove an item from an array where order doesn't matter, we usually
    // copy the last item into the slot of the item we want to delete and then reduce the
    // size of the array by 1 (e.g. In Go you can take a smaller view of the array).
    //
    // If you were removing inside a loop, you do the same thing, along with i-=1, so that the last
    // item gets processed and not skipped over.
    //
    // In Jai, there is a built-in way to remove-by-swap and decrement index: 'remove it'
    dyn_arr : [..]int;
    for 0..5 array_add(*dyn_arr, it);

    print("\ndyn_arr=%\n", dyn_arr);
    for dyn_arr {
        if it == 2 remove it;
    }
    print("dyn_arr after remove=%\n", dyn_arr);

    // Remove copied the last item into dyn_arr[2] and decremented count, which means
    // we can see the original last item again by incrementing the count.
    dyn_arr.count+=1;
    print("dyn_arr after remove and count++ = %\n", dyn_arr);

    tick_counter :: (counter: *int) -> int {
        counter.* += 1;
        print("counter ticked!\n");
        return counter.*;
    }

    // while loop conditions are evaluated each loop
    counter := 0;
    while tick_counter(*counter) < 5 {
        print("counter=%\n", counter);
    }

    // for loop expressions are only called once before the loop starts.
    // This print statement will only be called once!
    get_names :: () -> []string {
        print("\n!! get_names called !!\n");
        // Array literals, and each string within it, are placed in read-only memory allocated by the compiler.
        return .["Ahmed", "Jack", "Jonah", "Alice"];
    }

    // By default, iterator variables like 'it' are done via const reference, which means they can NOT be modified.
    // If you uncomment 'it.count = 5;' and run you will get an error.
    for get_names() {
        // it.count = 5;
        print("name=%\n", it);
    }

    get_names_heap :: () -> []string { // We can also return [..]string
        
        print("\n!! get_names_heap called !!\n");
        NAMES :: string.["Ahmed", "Jack", "Jonah", "Alice"];

        arr: [..]string;
        array_add(*arr, ..NAMES);
        
        return arr;
    }

    // This loop actually changes 'heap_names' in a way that persists
    // after the loop. A few things allow this:
    //
    // - The array used is non-const, making it mutable
    // - 'for *' is used, which makes 'it' a mutable pointer to each element (*string in this case)
    //
    // Note: While the array itself is on the heap, the individual strings within it (in this case) are literals and so read-only.
    heap_names := get_names_heap();
    for * heap_names {
        if it.count > 3 it.count=3;
        print("heap name=%\n", it.*);

        // While this array is on the heap, the individual strings within it are literal and so immutable.
        // Below are different equivalent ways of changing the first character of the string, but they all crash
        // because 'it' points to a literal string.

        // it.data.* = "bro".data.*;
        // (it.*)[0] = "bro"[0];
    }
    print("heap names after loop=%\n", heap_names);
}

ifx_test :: () {

    print("\n\n================= ifx Test =================\n\n");

    // 'ifx' is the ternary operator, but more powerful/nicer
    // The general idea, is its a normal 'if', but where the 'then'/'else' blocks MUST return values of the SAME type.
    is_heavy := false;
    x := ifx is_heavy then 100 else 10; // The last statement is automatically 'returned' (you can't actually use return here)
    x = ifx is_heavy 100 else 10;   // Just like normal if, we can usually omit 'then'

    print("x (type=%)=%\n", type_of(x), x); // This will print x=10

    // When else is omitted, the else automatically returns the default type value
    x = ifx is_heavy 100;
    print("x no else=%\n", x); // This will print x=0, 

    // Both sides can be a block
    is_heavy = true;
    x = ifx is_heavy {
        print("is_heavy=true block!\n");
        100;    // Last statement automatically returned in ifx
    } else {
        print("is_heavy=false block!\n");
        10;
        // "Hi!"; // This will cause an error because with it the two blocks of ifx will return different types, which is not allowed.
    }
    print("x after block=%\n", x);

    print_num :: (x: int) {
        print("got num=%\n", x);
    }

    // If the 'then' block is omitted, the ifx condition variable is returned as 'then'.
    //
    // Here, x=99 is truthy, so 'then' is used, but since no then is given, 'x' is used, and so 99 is printed.
    x = 99;
    print_num(ifx x else -1);
 
    // Since we can also omit else, this will print 'x' if truthy and default value (here its zero) if false 
    x = 0;
    print_num(ifx x);

    // In such expressions and in procedure calls, the first variable is returned (here its 'x')
    x = 3;
    y := 5;
    print_num(ifx x < y);

    // In checks with unary operators, the pure variable is returned if true. Here its 'x'
    print_num(ifx !(x > y));
}

if_case_test :: () {

    print("\n\n================= if+case Test =================\n\n");

    PROG_LANGS :: enum u8 {
        C :: 1;
        CPP;
        C_SHARP;
        GO;
        JAI;
        JAVA;
    }

    // This is just a normal switch statement as you might expect.
    // Each case is an entire block with its own scope.
    //
    // Each case has an automatic 'break' unless you use #through. Similar to how Go behaves.
    lang := PROG_LANGS.JAI;
    if #complete lang == {  // '#complete' forces you to handle all enum values

        case .JAI;
            print("% is an amazing lang\n", lang);

        case .C; #through;   // Falls through to next
        case .C_SHARP; #through;
        case .GO; print("% is a decent lang\n", lang);

        case .CPP; #through;
        case .JAVA; print("% is...oh God why\n", lang);

        // Default case.
        case;
            print("I don't know anything about the lang %\n", lang);
    }

    // There is an important note in the if_case how_to, which is that its useful to have
    // the default case EVEN IF you have #complete, and the reason is that an invalid
    // value can come from a software/hardware bug (e.g. user input)
    lang_ptr := *lang;
    lang_ptr.* = 255;
    if #complete lang == {

        case .JAI; #through;
        case .C; #through;
        case .C_SHARP; #through;
        case .GO; #through;
        case .CPP; #through;
        case .JAVA; print("% is a KNOWN language\n", lang);

        // Default case.
        case;
            print("I do NOT know anything about the lang %\n", lang);
    }
    
    // Case conditions MUST be constant. Variables, procedure calls, and range checks (like below) are NOT allowed
    x := 5;
    if x == {
        // case x > 3; print("x is BIGGER than 3!\n");
    }

    // Anything that is constant AND comparable with '==' can be used in case
    prog_lang_name := PROG_LANGS.JAI;
    if prog_lang_name == {
        case 5; print("It's Jai!\n");
        case; print("It's not Jai :(\n");
    }

    name := "Omar";
    if name == {
        case "Omar"; print("Wait, I know him...\n");
        case; print("Who?\n");
    }

    // We can do type switches!
    my_type := int;
    if my_type == {
        case int; print("As prophesized, its an int!\n");
        case float; print("I didn't expect a float!\n");
    }

    // We can also switch on procedures (of the same signature)
    print_num :: (x: int) {
        print("%\n", x);
    }

    my_proc := ifx_test;
    if my_proc == {
        case ifx_test; print("It's the ifx_test procedure (type=%)\n", type_of(my_proc));
        case main; print("It's the big boss, main\n");

        // This doesn't work because the signature is different
        // case print_num; print("It's the number printer\n");
    }
}

any_test :: () {

    // Any is the 'any' type you might find in Go etc, and here its this simple struct:
    //
    //    Any :: struct {
    //        type : *Type_Info;
    //        value_pointer : *void;
    //    }
    //
    // Note that 'Any' simply takes a pointer to the value its given, wherever that variable might be living.
    // As such, you also need to be careful so that your Any variable does NOT outlive the value it points, or you will find yourself looking at garbage.

    num := 9;
    x: Any = num;

    print("num=%; num address=%;\nx value=%; x.value_pointer=%\n", num, *num, (cast(*int)x.value_pointer).*, x.value_pointer);

    // An example of INVALID use is this:
    //
    // num := 9; x: Any = num; return x;
    //
    // This is because 'num' is allocated on the stack, and by returning Any, you are returning a pointer that now points to invalid memory!
    // Obviously this danger applies to any other pointer usage.
    //
    // The correct way is to allocate the value of Any on some longer lived memory, like below
    num_size := size_of(type_of(num));
    long_any_mem := temporary_alloc(num_size);
    memcpy(long_any_mem, *num, num_size);

    long_any : Any;
    long_any.type = type_info(type_of(num));
    long_any.value_pointer = long_any_mem;

    print("\nlong_any.value_pointer=%\n", long_any.value_pointer);

    // Since we copied into the heap (or temp storage in this case), Any no longer points to the stack num, and changing one doesn't affect the other
    (cast(*int)long_any.value_pointer).* += 1;
    print("long_any after change=%; num=%\n", (cast(*int)long_any.value_pointer).*, num);

    // Usually, assigning something to Any takes its type (e.g. 'long_any=num' makes long_any.type==int), but Any=Any is a special case.
    // Assigning Any to another Any variable does a simple struct copy, which means the original type info and pointer are maintained!
    //
    // This is very nice because it means we avoid having an 'Any' variable with its .type==Any, causing an Any that points to another Any.
    // In the below example, any2 and long_any are identical! They both have type==int and point to the temp memory we allocated above.
    any2 : Any = long_any;
    print("any2=%; long_any=%\n", any2.value_pointer, long_any.value_pointer);
}

this_and_loc_and_run_test :: () {

    print("\n\n================= #this and #location and #run Test =================\n\n");

    // #this refers to the current procedure, struct, or 'data scope' (e.g. somewhere without 'ordered statements', like file-scope) at compile time.
    proc :: #this;
    print("proc=%\n", proc);
    
    // If you refer to a proc, you can also call it, meaning it can be used to make recursive anon procs!
    //
    // For example, here this factorial function does NOT have a name, but it can call itself because
    // #this resolves at compile time to the anonymous proc its in. 
    factorial_num := 3;
    factorial_result := (x: int) -> int {
        if x <= 1 return 1;
        return x * #this(x-1);
    }(factorial_num);

    print("factorial(%)=%\n", factorial_num, factorial_result);

    // This can also be used to simplify definitions of self-referencing structs
    Node :: struct (data_type: Type)  {
        data: data_type;
        next: *#this; // Equivalent to 'next: *Node(data_type)'
    }

    print("node=%\n", Node(int).{});

    // There is also #location(x), which gives you the source location of 'x'. The returned value is the struct 'Source_Code_Location'
    print("% loc=%\n", #procedure_name(#this), #location(#this));

    // #run simply runs the given expression at COMPILE time.
    // This allows you to run arbitrary computations at compile time and save the result in a constant 
    factorial :: (x: int) -> int {
        if x <= 1 return 1;
        return x * #this(x-1);
    };

    FACT_10 :: #run factorial(10);
    // FACT_10 :: factorial(10); // This fails because the expression isn't constant
    print("compile-time factorial(10)=%\n", FACT_10);
}

operator_overloading_test :: () {

    print("\n\n================= Operator Overloading Test =================\n\n");

    // We can overload the following: * / + - ==
    // Things like '*=' and '!=' are supported automatically by implementing '*' and '==', but you can do them if you want more control (e.g. for a bit more perf)
    //
    // Operator overloads MUST have at least 1 struct (i.e. you can NOT overload int+int)
    //
    // Finally, for the overload to be used, it must be lexically seen (i.e. overloading in another proc won't affect operations here)

    Vec2 :: struct {
        x, y: float;
    }

    operator + :: (v1: Vec2, v2: Vec2) -> Vec2 {
        print("Doing Vec2 + Vec2\n");

        out: Vec2 = ---;    // Don't init for perf
        out.x = v1.x + v2.x;
        out.y = v1.y + v2.y;

        return out;
    }

    {
        operator - :: (v1: Vec2, v2: Vec2) -> Vec2 {
            print("Doing Vec2 - Vec2\n");

            out: Vec2 = ---;    // Don't init for perf
            out.x = v1.x - v2.x;
            out.y = v1.y - v2.y;

            return out;
        }
    }

    v1 := Vec2.{x=10, y=10};
    v2 := Vec2.{x=5, y=4};

    v3 := v1 + v2;
    print("v3=%\n", v3);

    // This fails because the code here doesn't 'see' the overload defined in the inner scope above.
    //
    // v4 := v1 - v2;
    // print("v4=%\n", v4);

    // This will call the 'operator +' proc
    print("v1 before=%\n", v1);
    v1 += v2;
    print("v1 after=%\n", v1);

    // We can also explicitly define +=, which is a bit more efficient as we can take the first as a pointer
    {
        operator += :: (v1: *Vec2, v2: Vec2) {
            print("Doing Vec2 += Vec2\n");

            v1.x += v2.x;
            v1.y += v2.y;
        }

        v1 = .{x=1, y=1};
        
        print("v1 before=%\n", v1);
        v1 += v2;   // This will call the 'operator +=' proc
        print("v1 after=%\n", v1);
    }

    // We can also define operators for differing types (but again, at least 1 MUST be a struct).
    // By adding '#symmetric', we allow this same function to be used for Vec2*float AND float*Vec2
    operator * :: (v1: Vec2, scale: float) -> Vec2 #symmetric {
        out: Vec2 = ---;
        out.x = v1.x * scale;
        out.y = v1.y * scale;

        return out;
    }

    v1 *= 2;
    print("v1 * 2 = %\n", v1); 
    
    // Array subscripting can also be overloaded, which is handy for data structures. The following is supported: [] []= *[]
    // When reading like arr[0], [] is checked first, and if not available then *[].
    // When writing like arr[0]=10, []= is checked first, and if not available then *[].
    //
    // *[] is the recommended way, as it gives you both read/write in one proc instead of two (its also used for *arr[0]).
    // But the others are there because its not always possible to give the address of the thing being subscripted (e.g. Bit Array).
    Bucket :: struct {
        item_count: s64;
        items: [100]s64;
    }

    // The first arg must be a struct, the second an integer index, and the return can be anything
    operator *[] :: (b: *Bucket, index: int) -> *int {
        print("'*[]' operator used with index=%\n", index);
        return *b.items[index];
    }

    b := Bucket.{};
    
    b[10] = 99;
    b[0]  = 10;
    print("b[10]=% at address=%\n", b[10], *b[10]);
}

static_if :: () {

    print("\n\n================= #if/#ifx Test =================\n\n");

    CONDITION :: true;

    // #if is a compile time 'if' that allows you to conditionally compile code blocks.
    // However, it does NOT create its own scope. This is done to give you the ability to 'inject'
    // things into your main scope.
    //
    // In this example, even though it appears that 'x' is defined in an inner scope, since #if
    // doesn't change scope, the following print is able to see and use x.
    #if CONDITION {
        x := 10;
        print("'#if' is compiling!\n");
    } else {
        x := -1;
    }

    print("x=%\n", x);

    // #if and #run can be combined for nice effect, as #if requires constants.
    //
    // Also, note that while this code works, it will give a compilation error if the static if does NOT run, as in that case there will be NO 'y' in scope.
    truthy :: () -> bool {
        return true;
    }

    #if #run truthy() {
        y := 55;
    }

    print("y=%\n", y);

    // We can also use them to do conditional compilation based on platform, where 'OS' is provided by the compiler
    #if OS == .WINDOWS {
        print("We are on WINDOWS!\n");
    } else #if OS == MACOS || OS == .LINUX {
        print("We are on MAC or Linux!\n");
    } else {
        print("We are...actually I don't know. All I know is OS=%\n", OS);
    }

    // Unlike C/Cpp, there is NO pre-processor, which means the below is NOT ignored by the compiler.
    // ALL #if paths must parse correctly.
    //
    // Uncomment the incomplete print and you will get an error.
    #if false {
        // print(
    }

    // #if can be put basically anywhere, including structs, enums, and file scope
    Keys :: enum u8 {

        X :: 1; // Available on all platforms

        #if OS == .PS4 || OS == .PS5 {
            O;
            T;
            S;
        }

        #if OS == .XBOX {
            Y;
            A;
            B;
        }

        #if OS == .NN_SWITCH HOME;  // You can do 1-liners
    }

    // There is an #ifx version as well, with similar rules to the normal 'ifx'
    gamer_msg := #ifx OS == .WINDOWS then "GAMER" else "Candy Crush";
    print("msg=%\n", gamer_msg);
}

polymorphic_procs_test :: () {

    print("\n\n================= Polymorphic Procs Test =================\n\n");

    // Polymorphic/generics/templates, whatever you want to call it. Seems Jai uses polymorphic.
    //
    // The idea is that, similar to how a variable can be a type (e.g. NUM :: s32; x: NUM;), variables can be
    // compile time by prefixing with '$', and such types can be used to build polymorphic types and procs.

    // Variable used as type
    NUM :: s32;
    x: NUM;
    print("x=%\n", x);

    // '$SOME_TYPE' defines a compile-time variable, which is used as the type of 'a'.
    // Once this compile-time variable is defined, we can use it like any type WITHOUT prefixing '$', similar to how ':=' is only used the first time.
    //
    // Since '$' is the definition of the type, we are telling the compiler 'this type is the same as what the user passes in this SPECIFIC argument'.
    // This means that when you have (x: $T, y: T), and pass (10, "hi"), the error is 'Wanted s64, got string'. Why? Because '$' is on the first arg.
    // If we had (x: T, y: $T) and called as (10, 'hi'), you will get the error 'Wanted string, got s64'.
    //
    // Understanding this behavior is useful in helping the compiler give you better errors. 
    // By deciding which argument is 'most important', like in array_add(arr: *[..]$T, item: T) the array is what's important, allows
    // you to get an error telling you that you are trying to add an item of the wrong type to your array, instead of telling you the array type is wrong!
    //
    // Its also super cool to note that each polymorphic proc is compiled into a native function equivalent
    // to writing that function for those exact types (e.g. calling sum(int, int) produces a sum proc with int for types).
    // So each unique call signature of a polymorphic proc produces 1 copy of that function with unique types.
    // If a signature is used multiple times, 1 version of the polymorphic type is reused.
    sum :: (a: $SOME_TYPE, b: SOME_TYPE) -> SOME_TYPE {
        
        result: SOME_TYPE;
        result = a + b;

        return result;
    }

    my_sum := sum(10, 9);
    print("my_sum=%\n", my_sum);

    // type_of and type_info can only be used on polymorphic types at compile time (e.g. inside: #run, #modify, etc.)
    #run print("\n(inside proc=%) compile-time type_of of polymorphic proc 'sum'=%\n\n", #procedure_name(polymorphic_procs_test), type_of(sum));

    // The same statement above without #run will cause an error:
    // print("\n(inside proc=%) compile-time type_of of polymorphic proc 'sum'=%\n\n", #procedure_name(polymorphic_test), type_of(sum));

    // Polymorphic procs work as long as the body works with the passed types.
    // Normally, passing Vec2 to 'sum' will be an error as '+' isn't defined on structs,
    // but with 'operator +' for Vec2 being available here, we can pass it to sum.
    Vec2 :: struct {
        x, y: float;
    }

    operator + :: (v1: Vec2, v2: Vec2) -> Vec2 {
        return .{x=v1.x + v2.x, y=v1.y + v2.y};
    }

    vec_sum := sum(Vec2.{x=10, y=5}, Vec2.{x=2, y=2});
    print("vec_sum=%\n", vec_sum);

    // Aside from calling the proc, another situation where a polymorphic function gets polymorphed into a specific
    // type is if its passed as an argument to another function, where that argument allows the compiler to know the type
    // of the polymorphic proc
    apply_int_binary_proc :: (f: (x: int, y: int) -> int, a: int, b: int) {
        result := f(a, b);
        print("apply_int_binary_proc(%, %)=%\n", a, b, result);
    }

    apply_int_binary_proc(sum, 1, 2);

    // Usually, we use polymorphic procs like 'x: $T', but in some cases its useful to have the VALUE be constant/known at compile time
    // which we can guarantee by doing something like '$x: int'. This is known as 'auto baking' (because the value gets baked into the proc).
    //
    // This can be useful to, say, do some optimizations when the value of 'x' is within some range, but be careful because each
    // unique value will cause this proc to generate a new polymorphed version, potentially bloating compile time!
    is_even :: ($x: int) -> bool {

        #run print("is_even compiled with $x=%\n", x);

        #if x & 1 {
            return false;
        } else {
            return true;
        }
    }

    // is_even will get compiled into 3 versions, one for each of these values, and where the body
    // is the one appropriate based on the #if compile time check
    print("is_even(1)=%\n", is_even(1));
    print("is_even(3)=%\n", is_even(3));
    print("is_even(6)=%\n", is_even(6));

    // However, by now you probably noticed that while this is cool, a major problem with it
    // is that it makes the proc only usable by callers who can supply a constant value!
    //
    // temp := 9; is_even(temp); // This causes an error because temp is not a constant
    //
    // Luckily, we can make it optional to supply a constant (man this is such a well designed language!)

    is_even2 :: ($$x: int) -> bool {

        #if is_constant(x) {

            #if x & 1 {
                return false;
            } else {
                return true;
            }

        } else {
            return !(x & 1);
        }
    }

    // In this case, we get 1 polymorph that handles ALL non-const values, and N polymorphs for const values, one per unique const value.
    num := 6;
    print("(const) is_even2(3)=%\n", 3);
    print("(non-const) is_even2(6)=%\n", num);
}

polymorphic_structs_test :: () {

    print("\n\n================= Polymorphic Structs Test =================\n\n");

    // Polymorphic structs have the same behaviors as polymorhpic procedures.
    //
    // However, since struct params MUST ALWAYS be compile time constant, their param values are always auto baked (i.e. require '$').
    // But since the compiler knows them to be constant, writing '$' is optional here (as can bee seen with param 'N').
    Holder :: struct ($T: Type, N: s64 = 300) { // Equivalent to: struct ($T: Type, $N: s64 = 300)
        items: [N]T;
    }

    my_holder: Holder(float);
    my_holder.items[0] = 99.9;
    print("my_holder=%\n", my_holder);

    Static_Holder :: struct {
        items: [my_holder.N]float;
    }

    // Even though these are the same size and layout, they are still distinct types
    assert(Static_Holder != Holder(float));

    // Polymorphs of the same struct AND same params are exactly the same. Similar to procs, same params are only polymorphed once.
    assert(type_of(my_holder) == Holder(float, N=my_holder.N));

    // After the parameters are set, the polymorphic struct becomes just a normal struct
    // which means we can used polymorphed structs like any other struct, for example as a type to create other variables.
    another_holder: type_of(my_holder);
    // another_holder: Holder;  // This is an error because 'Holder' by itself is polymorphic. You need to define or params or give all of them defaults.
    print("\nanother_holder=%\n", another_holder);

    // We haven't mentioned this so far, but polymorphic params of structs/procs live in a special place called 'constants block', that params AND body have access to.
    // This means you can read the values of polymorphic params or use them at any time!
    //
    // Another cool part is that those constants are part of the type, so they do NOT change the size of the struct.
    print("\nmy_holder.N=%; my_holder.T=%\n", my_holder.N, my_holder.T);   
    print("size_of(my_holder)=%\n", size_of(type_of(my_holder))); // 4 bytes, the size of 1 float only, as you might expect.

    // The constants block can be accessed from the 'constant_storage' of Type_Info 
    ti := type_info(type_of(my_holder));
    print("\n\nmy_holder's type info=%\n\n", ti.*);

    // Read the value out from constant storage (assuming $N is the second param).
    //
    // This is done by first getting the offset into constant storage where the value of N starts,
    // then creating a [X]u8 array with base at the offset, and count equal to size of N (here its 8, as its s64).
    // Once we have the correct bytes as a byte array ([]u8), we simply cast its pointer to a s64 pointer.
    N_SIZE_BYTES :: size_of(type_of(my_holder.N));

    holder_n_offset := ti.specified_parameters[1].offset_into_constant_storage;
    n_bytes := cast([N_SIZE_BYTES]u8) *ti.constant_storage[holder_n_offset];
    n_val_ptr := cast(*s64) *n_bytes;
    print("\n'N' from Constants Block of my_holder's type info=%\n", n_val_ptr.*);

    // If a polymorphic struct is placed as a proc argument, the proc argument will accept any polymorph of that struct.
    //
    // The below signature is equivalent to: (h: Holder($T, $N))
    print_holder :: (h: Holder) {
        print("holder %=%\n", type_of(h), h);
    }

    print_holder(Holder(T=float, N=1).{});
    print_holder(Holder(T=int, N=2).{});

    // You can also force the proc to take a specific polymorph only by specifying the holder params.
    // This forces T=string, but accepts any N value
    print_string_holder :: (h: Holder(string, $N)) {
        print("holder %=%\n", type_of(h), h);
    }

    print_string_holder(Holder(T=string, N=3).{});
    // print_string_holder(Holder(T=int, N=3).{}); // This will throw an error because it wants T=string

    // Just like procs, we can have compile time types, and we can even give defaults on both type and value while keeping it polymorphic!
    vec2 :: struct ($init_val: $T = cast(float)0) { // The '$' on init_val isn't required
        x, y := init_val;
    }

    vec2_default := vec2.{};
    vec2_float := vec2(1.1).{};
    vec2_string := vec2("Hi").{};
    print("vec2_default(type=%)=%\n", vec2_default.T, vec2_default);
    print("vec2_float=%\n", vec2_float);
    print("vec2_string=%\n", vec2_string);

    // The only limitation on polymorphic types currently (as of beta 0.2.009), is that the compiler
    // must be able to figure out the types of BOTH polymorphic type variables AND auto bakes of the entire signature in one step.
    //
    // The below example from how_to 120_polymorphic_structs.jai shows such a failure case.
    // Here, '$ReturnType' is an auto baked variable, the value of which relies on Thing, but the final type of Thing relies on T.
    // To typecheck this, you need to figure out T, then only can you do Thing(T), and assign to ReturnType, but this is more than one step and not allowed.
    Thing :: struct (T: Type) {
    }
    
    foo :: ($T: Type, $ReturnType: Type = Thing(T)) -> ReturnType {
        a: ReturnType;
        return a;
    }
    
    // foo(float); // This will cause an error
}

limit_polymorphic_types_test :: () {

    print("\n\n================= Limit Polymorphic Types Test =================\n\n");

    vec2 :: struct {
        x, y : float;
    }

    vec3 :: struct {
        #as using v2: vec2;
        z: float;
    }

    // One way of limiting which types are allowed in a polymorphic proc/struct is by using the $T/R syntax,
    // which limits $T to only be R or one of its derived types.
    //
    // Remember this is polymorphic, so the type of 'v' is whatever got passed (i.e. could be vec2 or vec3)
    vec2_printer :: (v: $T/vec2) {
        print("vec2_printer(type=%)=%\n", type_of(v), v);
    }

    v2 := vec2.{x=5, y=6};
    v3 := vec3.{x=9, y=10, z=11};
    vec2_printer(v2);
    vec2_printer(v3);
    // vec2_printer("Hi"); // This will cause an error because vec2_printer limits its polymorphs to vec2 or stuff derived from it 

    // Another way is to use some compile time checks to ensure the type is as you expect, like by using #assert.
    // There is probably a way to say 'does this type implicitly cast to this other type' to do this assert in a nicer way, but no idea how.
    vec2_printer_v2 :: (v: $T) {
        #assert type_of(v)==vec2 || type_of(v) == vec3 "vec2_printer_v2 only accepts vec2 and vec3";
        // #assert T==vec2 || T == vec3; // This is equivalent to the previous line

        print("vec2_printer_v2(type=%)=%\n", type_of(v), v);
    }

    vec2_printer_v2(v2);
    vec2_printer_v2(v3);
    // vec2_printer_v2("Hi"); // This fails

    // Now we come to the crazy part I didn't expect Jai to have,
    // which is matching types by their 'interface', meaning by whether they contain a given set of vars/types!
    Named :: struct {
        name: string;
    }

    print_named :: (x: $T/interface Named) {
        print("named(type=%).name=%\n", T, x);
    }

    Player :: struct {
        health := 100;
        level := 0;
        name: string;   // This makes it match 'interface Named', even though the position and offset are different!
    }

    print_named(Player.{name="Skele"});
    // print_named(v2); // This fails because vec2 doesn't contain a 'name: string' field
}

// No reset tells the compiler to keep any changes that happened to the value of this variable during compilation.
//
// For example, if #run does x=99, normally this change isn't seen by runtime code, but no_reset allows the change to be seen.
#no_reset modify_directive_test_add_compile_counter := 0;
#no_reset modify_directive_test_add_v2_compile_counter := 0;

modify_directive_test :: () {

    print("\n\n================= Modify Directive Test =================\n\n");

    // #modify is a directive that allows you to write a special code block between the header and body
    // of a polymorphic proc/struct. Within this block you are allowed to change the value of polymorphic variables and then
    // finally to return a bool, true on success, and false to indicate to the compiler that this polymorph must be rejected (i.e. compiler error).
    //
    // After modify does any adjustments, the polymorph continues normally, as if the user used those params (assuming #modify changed them).
    Int_Holder :: struct (N: int)
    #modify {
        // Force N to 10 if user selected less
        if N < 10 N = 10;
        return true;
    }
    {
        arr: [N]int;
    }

    ih: Int_Holder(5);
    print("int_holder.arr.count=%\n", ih.arr.count); // This prints 10 even though we passed 5!

    // Modify also allows something that is otherwise NOT allowed, which is polymorphic return variables.
    //
    // In this example, the return is equal to the array element type, but if we notices the element is too small,
    // we make the return type bigger than the element, making it 4 bytes.   
    sum :: (arr: []$T) -> $R
    #modify {
        
        R = T;  // Default to being the same as array elements

        ti := cast(*Type_Info) R;
        if ti.type == .INTEGER {

            int_info := cast(*Type_Info_Integer)ti;
            if int_info.runtime_size < 4 {
                R = ifx int_info.signed s32 else u32;
            }
        }

        return true;
    }
    {
        result: T;
        for arr result += it;
        return result;
    }

    // Modify changes the return of sum([]u8) to be u32, but leaves s32 and and s64 untouched
    sum_u8 := sum(u8.[1, 2, 3]);
    sum_s32 := sum(s32.[1, 2, 3]);
    sum_s64 := sum(s64.[1, 2, 3]);

    print("sum_u8(type=%)=%\n", type_of(sum_u8), sum_u8);
    print("sum_s32(type=%)=%\n", type_of(sum_s32), sum_s32);
    print("sum_s64(type=%)=%\n", type_of(sum_s64), sum_s64);

    // Aside from validations, another use case for #modify is to force types into other types to reduce polymorphs.
    //
    // The following proc will compile 1 time per unique type passed, causing many polymorphs.
    add :: (x: $T, y: T) -> T {
        #run modify_directive_test_add_compile_counter += 1;
        return x + y;        
    }

    // These will cause 6 polymorphs
    SOME_U8 : u8 : 9;
    SOME_U16 : u16 : 9;
    SOME_U32 : u32 : 9;
    SOME_U64 : u64 : 9;
    SOME_F32 : float : 9;
    SOME_F64 : float64 : 9;
    add(SOME_U8, SOME_U8);
    add(SOME_U16, SOME_U16);
    add(SOME_U32, SOME_U32);
    add(SOME_U64, SOME_U64);
    add(SOME_F32, SOME_F32);
    add(SOME_F64, SOME_F64);

    print("modify_directive_test_add_compile_counter=%\n", modify_directive_test_add_compile_counter);

    // Using #modify, we can force different sized numeric types into the biggest size, thereby reducing polymorphs.
    add_v2 :: (x: $T, y: T) -> T
    #modify {
        if T == {
            case u8; #through;
            case u16; #through;
            case u32; #through;
            case u64; T = u64;

            case s8; #through;
            case s16; #through;
            case s32; #through;
            case s64; T = s64;

            case float; #through;
            case float64; T = float64;

            case; return false, "Unsupported argument type to add_v2";
        }

        return true;
    }
    {
        #run modify_directive_test_add_v2_compile_counter += 1;
        return x + y;        
    }

    // These will cause only 2 polymorphs!
    add_v2(SOME_U8, SOME_U8);
    add_v2(SOME_U16, SOME_U16);
    add_v2(SOME_U32, SOME_U32);
    add_v2(SOME_U64, SOME_U64);
    add_v2(SOME_F32, SOME_F32);
    add_v2(SOME_F64, SOME_F64);

    print("modify_directive_test_add_v2_compile_counter=%\n", modify_directive_test_add_v2_compile_counter);

    // A similar casting approach can be used for derived structs to reduce polymorphs, which works by detecting
    // whether the passed struct Y is derived from struct X, and if yes we do T=X, thereby making all derived structs of X share one polymorph.
    //
    // Example of this is given in how_to "170_modify.jai".

    // There is also this beautiful example given in how_to "170_modify.jai"
    // Really shows the elegance, simplicity, and power of Jai. Everything is just normal procedural code! 
    Bitmap :: struct (Width: s16, Height: s16)
    #modify { return Width >= Height, "Width of a Bitmap must be >= Height."; }
    {
        pixels: [Width*Height] u32;
    } 

    my_bitmap: Bitmap(Width=128, 64);
    print("my_bitmap=%\n", my_bitmap);
    // my_bitmap_2: Bitmap(Width=32, 64); // This causes a compilation error because #modify returns false on it

    // The last to note about #modify, is that they can make identical overloads work!
    // This works if #modify rejects a given type on one of those identical overloads while accepting it on the other, thus allowing the compiler to decide between the overloads.
    mul :: (x: $T, y: T) -> T
    #modify {
        ti := cast(*Type_Info)T;
        return ti.type == .INTEGER, "This mul overload only accepts INTEGERS";
    }
    {
        return x * y;
    }

    mul :: (x: $T, y: T) -> T
    #modify {
        ti := cast(*Type_Info)T;
        return ti.type == .FLOAT, "This mul overload only accepts FLOATS";
    }
    {
        return x * y;
    }

    // Even though the implementations are actually identical, the #modify sections are different
    // and so each of the below calls will only match one of those overloads, and so causing no compilation errors!
    mul_int := mul(1, 2);
    mul_float := mul(2.2, 2);
    print("mul_int=%\n", mul_int);
    print("mul_float=%\n", mul_float);
}

type_variants_test :: () {
        print("\n\n================= Type Variants Test =================\n\n");

        // This is basically type aliases, but with some nice stuff on top.
        //
        // Note: It is mentioned that this feature is still not stable.

        // We can set any constant to a type, and use that to create variables
        MY_INT :: int;  // Equivalent to both MY_INT :: #type int; and MY_INT :: #type,isa int;
        
        x: MY_INT = 12;
        y := 13;
        print("x+y=%\n", x + y);

        print_int :: (val: int) {
            print("print_int=%\n", val);
        }

        print_int(x);   // Implicit cast happening here

        // The type variant casts implicitly, as MY_INT and int are considered the same type
        y = x;
        x = y;
        print("type_of(x)=%; type_of(y)=%; Types are equal=%\n", type_of(x), type_of(y), type_of(x) == type_of(y));

        // However, we can use the #type,distinct to block implicit casts
        MY_INT_V2 :: #type,distinct int; 
        x_v2: MY_INT_V2 = 12;

        y = cast(int) x_v2;
        x_v2 = cast(MY_INT_V2) y;

        // All the below calls will fail. They require explicit casts.
        // print_int(x_v2);
        // y = x_v2;
        // x_v2 = y;
}

imports_test :: () {

    print("\n\n================= Imports Test =================\n\n");

    /*
    (based on how_to '151_file_and_global_scopes')
    Jai operates on 3 main levels of scopes: export, module, and file.
    There is also the 'preload' scope. The scopes live in this hierarchy:
    
                             [----Preload----]
                            /        |        \
                           /         |         \
              [Application]      [Module 1]      [Module 2] 
             /      |                |    \               \ \_________
            /       |                |     \               \          \
    [File 1]    [File 2] ...      [File 1]  [File 2] ...    [File 1]  [File 2] ...

    When you use an identifier, like a variable or a type name, the compiler first looks in file scope,
    and if not found it checks application/module (they are basically the same) scope, and if still not found
    it checks preload scope (which has core stuff like Context, Type_Info, etc.), and if not there you get an
    undeclared identifier error. The checking only goes bottom->top and does NOT cross boundaries between modules/files, normally.

    By default, anything you write goes into 'export scope'. What is that? that is the scope of things
    that you CAN access when you do #import (be that an import of a file or a whole module).
    This scope can be activated by '#scope_export;'.

    If you do '#scope_module;', anything under that goes into module scope.
    But how do you create a module and add many files to it? that is done via '#load "xyz.jai";'.
    
    For example, the usual way, like in Basic, is you have a folder of files and one of them is module.jai,
    and in module.jai you #load all the other files from the folder, which puts all those files in one module scope.
    When that happens, those files can see exported scope AND module scope names from each other, similar to a Go package.

    Then, when someone #imports the module (e.g. #import "Basic";), that module.jai is imported in such a way
    where the importer can see names from the exported scope of that entire module, which is module.jai and everything it did #load on.

    File scope, activated by '#scope_file;', is the simplest, only things in that same file can see file scope names.

    Remember, anything you #import is imported in its own module scope that is different than yours, and its
    module scope includes the file/directory-module (explained in the next section) you imported AND anything it
    did #load on. This means that if I #import Print.jai from the Basic folder, I do NOT get the entire Basic module!
    this is because only Print.jai and stuff it directly does #load on will be imported. This is why module.jai is required!

    Now a question might come up, if A.jai does #load on B.jai and they become one module and can see
    each other's exported+module scope names, can they see the names imported by each other?
    That is, if B.jai imports Basic, can A.jai use print?

    To answer this question we simply need to know: in which scope does #import put things?
    Answer: #import puts things in module scope.

    This means that yes, A.jai CAN use print if anyone in its module imported Basic. This also
    means that importers of A.jai or even B.jai can NOT use print, because print is in module scope
    and importers only see export scope!

    Note however, that while #import and #load both put things in module scope, its different. #load
    in a way 'combines' everything in one scope, giving you a shared module scope where everyone can see everyone else.

    But #import, in a way, puts shortcuts/symlinks of names from the export scope into your module scope. You
    can see these names but they can't see or use stuff you have since you only have symlinks, not the actual things.
    #load allows files to see from each other because it brings in the actual things, not just symlinks.

    Regarding application scope, its simply your 'main' scope and is no different than a module scope.
    It's only given a different name because no one can import the application scope.
    */

    /*
    (based on how_to '040_import_and_load')
    A note on how #import works.

    When doing something like '#import "Basic";' the compiler searches
    the 'import_path', which can be set by the metaprogram. The default import_path is './modules'.

    The compiler searches for either something called Basic.jai in the import path
    or for a subfolder in the import path that has the structure 'import_path/Basic/module.jai'.

    Being able to import either individual files or entire folders is super awesome, because it
    gives us the convenience of splitting a big module into files, while also retaining the freedom
    of importing individual pieces, and of not having to do a folder-per-module like Go does!

    An example of a big folder-module is 'Basic' itself. Basic is in 'modules/Basic/module.jai',
    and that Basic folder has many files, one of which is 'Print.jai' which has the 'print' function.
    */

    // You can do a 'namespaced' import by giving a name to an import, like the import below.
    //
    // Note: If you import two modules into your space without naming them, and you use things that
    // have identical signatures in both (e.g. two modules having a proc called 'print(string)'), you will get an error.
    //
    // Note: Regardless of the scope where you put '#import', it is as if you put it at data scope (other procs will see it).
    My_Basic :: #import "Basic";
    My_Basic.print("Same print as usually\n"); 

    // If you want to name an import AND dump all its names into your namespace, you can use 'using'
    using My_Basic2 :: #import "Basic";

    // You can also do it in two lines:
    // My_Basic2 :: #import "Basic";
    // using My_Basic2;

    My_Basic2.print("My_Basic2.print\n");
    print("in-namespace print from My_Basic2\n");

    // This import will search the import path and finally import './modules/the_cake.jai'
    #import "the_cake";
    print("The cake is a lie=%\n", the_cake_is_a_lie);

    // We can also import things that are NOT in our import path
    // by using ',file' and then specifying a relative or absolute path.
    //
    // Note: since this is an actual path and not search, we need to include the full file name, including the extension.
    #import,file "intern.jai";
    // #import "intern.jai"; // This is an error because intern.jai does NOT exist in import_path

    some_func :: () {
        print("local some_func called\n");
    }

    // The local proc is always given precedence over imported ones,
    // as the search goes inner to outer, and will find this first.
    some_func();

    x := do_intern_on_int(1); // This is from "intern.jai"
    print("x after intern stuff=%\n", x);

    // Similar to loading a file from outside the import path, we can do the same for folder-modules
    using Many_Interns :: #import,dir "many_interns"();
    list_intern_names();

    // Modules can also have parameters
    Many_Interns2 :: #import,dir "many_interns"(LOAD_SENIORS=true);

    Many_Interns2.list_senior_names();
    // Many_Interns.list_senior_names(); // This is an error because in that import we didn't specify LOAD_SENIORS=true

    // Finally, we can import a string as a module.
    Fac1 :: #import,string "factorial :: (x: int) -> int { if x <= 1 return 1; return x*factorial(x-1);}";

    Fac2 :: #import,string #string DONE
    factorial :: (x: int) -> int {
        if x <= 1 return 1;
        return x*factorial(x-1);
    }
    DONE;

    fac1_result := Fac1.factorial(5);
    fac2_result := Fac2.factorial(10);
    print("fac1_result=%\n",fac1_result);
    print("fac2_result=%\n",fac2_result);
}

using_test :: () {

    print("\n\n================= using Test =================\n\n");

    Entity :: struct {
        id: s64;
        name: string;
        is_active: bool;
    }

    // To avoid naming conflict errors, using can have only() and except() modifiers.
    //
    // using,except(a,b,c) imports everthing into scope except the fields a/b/c.
    //
    // using,only(z) imports ONLY z into scope.
    Person :: struct {
        using,except(name) e: Entity;
        name: string;
        height: s64;
    }

    Computer :: struct {
        using,only(id, is_active) e: Entity;
        name: string;
        ram_size: s64;
    }

    // Internally, except/only take a string literal, so we can
    // use them with an actual literal or with compile time variables or constants.
    using,only .["is_active"] e: Entity;
    print("e.is_active=%\n", is_active);
    
    ONLY_COMPUTER :: string.["ram_size"];
    using,only ONLY_COMPUTER c: Computer;
    print("c.ram_size=%\n", ram_size);

    // You can also do using on the arg list of procs
    get_person_using_only :: () -> []string {
        return .["height"];
    }

    print_person_height :: (using p: Person) {
        print("person height=%\n", height);
    }

    using,only #run get_person_using_only() p := Person.{height=99};
    print_person_height(p);

    // Using also works when importing, which helps avoid proc/type conflicts.
    //
    // 'sprint' here is the same as the one from Basic, so 'using' Basic
    // will cause an error. We can use modifiers here to help.
    using,except(sprint) My_Basic :: #import "Basic";
    Basic_Sprint :: My_Basic.sprint;

    sprint :: (format_string: string, args: .. Any) -> string {
        print("local sprint called!\n");
        return My_Basic.sprint(format_string, args);
    }

    // You will only see 1 print from the local sprint
    sprint("Hi!");
    x := Basic_Sprint("Hi!2");
    defer free(x);

    // Another crazy ability, is for us to define a function
    // that takes names incoming from using and renaming them!
    //
    // If you set a name to empty string, it will NOT be imported! this means
    // map can act both as a renamer and as a filter.
    //
    // Regarding lifetime, strings you return must live at least past the return of the function.
    // This means that you can use literals or temp storage like we do here.
    //
    // Note that it is ILLEGAL to change the names passed to you by the compiler. If you want to change, copy first.
    rename_using_names :: (names: []string) {
        for * names {
            it.* = tprint("gg_%", it.*);
        }
    }

    // Without the map, this would give an error, but it works because the names brought into the scope are changed!
    //
    // How_to 044 shows a nice case of using map to prefix opengl functions with gl.
    using,map(rename_using_names) e2 := Entity.{name="Entity #2"};
    print("e2.name=%\n", gg_name);
}

comma_comma_test :: () {
    
    print("\n\n================= ,, Test =================\n\n");

    get_heap_int :: () -> *int {
        x := New(int);
        return x;
    }

    // This is the usuall usage of context and push context, which is to switch
    // out the allocator and maybe other stuff, push them as a context, then
    // call some proc that allocates, and finally use the result (and maybe free).
    ctx := context;
    ctx.allocator = temp;

    push_context ctx {
        x := get_heap_int();
        defer free(x); // This frees at end of push context
        print("heap int=%\n", x);
    }

    // However, the above setup is a bit heavy weight, as we often might just want to switch
    // out some context params, like the allocator, just for one proc call.
    //
    // Following in the tradition of making things convenient, Jai gives us the ',,' operator,
    // which can be put after proc arguments, after which you can put context overrides that are
    // valid only for the duration of that proc call. Its as if you wrapped the proc call in a push context.
    x := get_heap_int(,, allocator=temp);
    defer free(x,, allocator=temp); // Don't forget to free with the correct allocator!
    // defer free(x); // This will cause a crash because it will free with context.allocator, which is different than temp!

    print("heap int with temp=%\n", x);
    
    // Since overriding the allocator is the most common operation, if you don't specify a name
    // like below, its the same as doing 'allocator=temp'.
    //
    // Also, you can override any context param as normal, like setting a new log.
    overlord_logger :: (message: string, data: *void, info: Log_Info) {
        print("Overlord Logger: %\n", message);
    }

    y := get_heap_int(,, temp, logger=overlord_logger);
    defer free(y,, allocator=temp);
    print("heap int with temp 2=%\n", y);
}

pool_test :: () {

    print("\n\n================= Pool Test =================\n\n");

    /*
    Pool is a fast allocator that can be used instead of the generic heap allocator,
    especially useful for use inside subsystems of your programs or other long lived data structures,
    which is described as category 3 of memory lifetimes in how_to 200.

    Looking quickly at Pool.jai, it looks like its a nice Arena allocator.
    Pool uses an underlying allocator (e.g. the default heap allocator) to allocate blocks of memory in
    certain sizes, and then when you want to allocate it uses memory from a pre-allocated block and increments a pointer,
    and if there is not enough space it allocates a new block and gives you memory from that. Blocks are linked to each
    other in a linked list. Block sizes are configurable on the struct.

    Note that allocations above a certain size are *always* allocated separately using the backing/block allocator,
    and this size is also configurable on the Pool struct.

    This test is simply to show the basic usage of pool, but you can look at Pool.jai for an example
    and more details.
    */

    #import "Pool";
    
    pool: Pool;
    // If we don't pass an allocator on the second param, it will use context.allocator as its block allocator.
    // ALWAYS use this BEFORE you use the pool, otherwise it won't have anywhere to allocate memory from.
    set_allocators(*pool);
    pool_allocator := Allocator.{proc = pool_allocator_proc, data=*pool};

    get_heap_int :: () -> *int {
        return New(int);
    }

    get_bytes_used_by_pool :: (p: *Pool) -> int {
        // This only works if we don't allocate more than one block.
        if !p.current_memblock return 0;

        return p.memblock_size - HEADER_SIZE - p.bytes_left;
    }

    print("pool bytes used before alloc = %\n", get_bytes_used_by_pool(*pool));
    
    x := get_heap_int(,,allocator = pool_allocator);
    defer free(x,, allocator = pool_allocator); // Free does NOTHING on pool. Its an arena after all!

    print("pool bytes used after alloc = %\n", get_bytes_used_by_pool(*pool));

    // To mark all the pool memory as 'free' WITHOUT returning it to the OS, we can call reset.
    // This is useful because future allocations will be very fast as we already have the memory, just move a pointer!
    reset(*pool);
    print("pool bytes used after reset = %\n", get_bytes_used_by_pool(*pool));

    // To return the memory to the OS use release. Internally, release calls reset and then gives the memory
    // back the operating system.
    print("pool has memory blocks before release = %\n", pool.current_memblock || pool.unused_memblocks);
    release(*pool);
    print("pool has memory blocks after release = %\n", pool.current_memblock || pool.unused_memblocks);
}

argument_and_return_handling_test :: () {

    print("\n\n================= Argument and Return Handling Test =================\n\n");

    /* 
    (Based on how_to 250)
    When passing arguments to a procedure, basic types that are <= 8 bytes are always passed by value.

    Anything that is > 8 bytes, and structs of any size, are passed 'Maybe By Reference'. This means that
    they are probably passed by const reference (i.e. 'const &' in C++), but they also might be passed by value,
    depending on what the compiler decides is the best for performance in that case, as a copy avoids aliasing issues
    and so might allow the compiler to do additional optimizations making the copy worth it. Either way,
    it is NOT valid for the program to treat 'Maybe By Reference' differently regardless of how its actually passed underneath.

    Also, since 'large' parameters are passed as const reference, it is NOT allowed to mutate them, unless they are a pointer.
    If you want to mutate a large non-pointer, you have to copy first.
    */

    Some_Type :: struct {
        name: string;
    }

    f :: (st: Some_Type) {

        // Make a copy then mutate
        x := st;
        x.name = "bloeys";

        // This is an error!
        // st.name = "Please no";
    }

    // The name doesn't change as its passed by const reference, only the temp copy is changed.
    y := Some_Type.{name = "Initial Name"};
    print("name before proc = %\n", y.name);
    f(y);
    print("name after proc = %\n", y.name);

    /*
    Returns are handled beautifully in Jai. Space is allocated on the stack on the caller side for each return
    parameter of the proc that is being called, and the addresses of these locations are passed implicitly into the proc,
    essentially its out params from C/C++/C#, just nicer.

    Another nice thing is that the compiler smartly optimizes this. For example, if a caller-site variable
    is being assigned to a return value of proc, the compiler will NOT alloc new stack space and then copy, rather
    it will simply use the address of that variable for the return!

    An important consequence of how returns are handled is that we do NOT need to be worried about returning large things
    as value, as there is no extra copy as you might get in other languages. Return values without worry!

    In C or similar, if you create a struct in a function and then return it, you will have stack space in the function itself,
    and then the struct will be copied into the caller's variable, causing an extra copy on return, but no such worries in Jai
    as the struct you create in the function is written to the caller's return variable directly.
    */

    // Here, writing to 'out'/returning is the same as writing directly to 'stack_var', there is no extra copy.
    stack_var := 0;
    f2 :: () -> (out: int) {
        return out=10;
    }
    stack_var = f2();
}

log_test :: () {

    print("\n\n================= Logger Test =================\n\n");

    /*
    The logger is simply a procedure defined in Preload.jai as:
        
        Logger    :: #type (message: string, data: *void, info: Log_Info);
    
    You can provide your own of course. The log proc from Basic is simply a nice wrapper
    on top of the default context.logger, where it does print-style things and then calls the default logger.

    Here, we will define our own logger proc and custom data (which is optional) and use it.
    */

    Overlord_Logger_Data :: struct {
        prefix: string;
    }

    overlord_logger :: (message: string, data: *void, info: Log_Info) {

        // Be careful: print from basic uses log if it encounters errors, so
        // using it here can cause a recursive situation!
        //
        // You can protect against that by say setting a flag on your data.
        logger_data := cast(*Overlord_Logger_Data) data;
        write_string(logger_data.prefix);
        write_string(tprint("(loc=%) ", info.location));
        write_string(message);

        // As per how_to 350, its a convention for log() to NOT require newlines. If one isn't
        // provided, it will be inserted automatically.
        //
        // Honestly, this makes sense for logs.
        if message && message[message.count-1] != #char "\n" write_string("\n");
    }

    // This log, from the Basic module, is basically sprint+context.logger(), with a bit more to pass other info in.
    log("This is a message from the default logger!. Caller proc=%\n", #procedure_name(#this));

    // We can also trivially use our own logger
    my_logger_data := Overlord_Logger_Data.{prefix = "OVERLORD: "};

    /*
    When we set a logger like this, its our 'backend' logger, that is, it is the lowest layer that all
    log calls should eventually go to.

    On the other hand, a 'frontend' logger is more like Basic.log, it can provide a different interface for your convenience
    but at the end it will call the backend logger on context.logger.

    To repeat a note we mentioned inside our overlord_logger, how_to 350_logging.jai mentions that it is
    convention for loggers to ensure that each log has a newline so that logs don't just stick together.
    */   
    ctx := context;
    ctx.logger = overlord_logger;
    ctx.logger_data = *my_logger_data;

    push_context ctx {
        log("Are you using my logger now?!\n");
    }

    // Works as you expect
    log("We are back to the default logger.");
}

module_params_test :: () {

    print("\n\n================= Module Params Test =================\n\n");

    /*
    By having #module_paramters in the first module file that's loaded, we can configure the module
    on an per-import basis and on an entire-program basis.

    #module_paramters takes two sets of params, the first are settable per-import and the second settable
    only the FIRST time its imported+set in the ENTIRE program, and sets that value for everyone forever.

    For example, the module parameters in many_interns.jai looks like:
        #module_parameters (LOAD_SENIORS := false) (SHOW_SALARIES := false) {
        }

    The first list which contains LOAD_SENIORS is the per-import params, and the second containing SHOW_SALARIES
    is the program level module parameters.

    Use the first when the thing being configured is safe for different parts of the program to have differently,
    like maybe a flag of EOF_IS_ERROR should be a per-import parameter, but memory allocation behavior probably
    should live on the program level list.
    */

    // This is allowed because previously in our program when we imported many_interns we did NOT set the second list.
    // Since its program level, by setting it here, ALL imports will have it active, even ones appearing BEFORE us,
    // because if you do NOT set it, the value you get is the value of the first explicit set.
    //
    // If no import sets it explicitly, then default values are used.
    Mi1 :: #import,dir "many_interns"()(SHOW_SALARIES = true);

    print("intern salaries=%\n", Mi1.INTERN_SALARIES);

    // This will cause an error because Mi1 already set the program level param!
    // Mi2 :: #import,dir "many_interns"()(SHOW_SALARIES = false);

    // This is legal because we are only touching import level params,
    // but we must NOT put the program list, as it maintains the one from Mi1.
    Mi2 :: #import,dir "many_interns"(LOAD_SENIORS = true);
 
    Mi2.list_senior_names();
    print("intern salaries from Mi2 = %\n", Mi2.INTERN_SALARIES);   // Its still active even without passing
}

metaprogramming_test :: () {

    print("\n\n================= Metaprogramming Test =================\n\n");

    print("There isn't code here, just a ton of comments! (and build.jai, our metaprogram!)\n");

    /*
    The goal of this test is to talk and show a few things, including:
      - Metaprogramming
      - Workspaces
      - Custom compilation command line flags
      - Compiler message loop
      - The default metaprogram

    Strap in, this is going to be amazing!

    The first note I would like to make, is that ignoring all the fancy/scary names, the whole setup
    is surprisingly simple! like really simple! great power delivered in beautiful simplicity has been the
    modus operandi for this language so far, and am pleasantly surprised to this continue even with things I exepcted
    would require some amount of complexity, but it seems its a skill issue on my end.
    */

    /*
    Metaprogramming

    A metaprogram is simply some function you run at compile time like `#run build();`. You can do anything with a metaprogram,
    like generate an enum, calculate some value and make it a constant, and so on.

    One of the core use cases though is to use a metaprogram as your build 'tool', to control details of how your main
    program is built.
    
    For example, your build metaprogram might decide on output dir, debug/release, set executable name, set compile-time constants,
    set executable logo, and it might even do crazier things like inspect all procs being built and do some custom checks on them,
    or force you to play invaders and get a score of 100 before compiling!

    We will discuss how to do some of the cool metaprogram stuff in a bit, but for now its enough to note its simply a function that
    runs at compile time (e.g. 'jai build.jai', which builds the actual program 'main.jai'), and/or other things you might want.

    Both metaprograms and compilation happen inside 'workspaces', which are our next topic.
    */

    /*
    Workspaces

    Workspaces are *completely* separate environments in which the compiler does all its work
    like compilation, imports, compile time execution (including the metaprogram!), and so on.
    
    Different workspaces are completely independent, they can't see each other's globals or read/write each other in
    any way. The compiler runs all workspaces in parallel and exits when they have all finished compilation.

    The file you feed the compiler (e.g. 'jai main.jai') is run in the default workspace. From there, a metaprogram
    can create additional workspaces, add source files or source text to it and once the compiler sees any source file/text
    it immediately starts compilation of this second workspace (compiler is heavily async, it compiles as soon as it has source
    not necessairly all the source).

    Since each workspace can gets its own settings and even potentially different files, one run of the compiler can compile
    different releases of the program (e.g. debug+release on x64 and ARM at once), and/or you can even compile completely
    different programs all at once!

    Not all workspaces need to produce an executable or dll, you can configure a workspace (e.g. the build.jai workspace) to
    only run at compile time without any 'physical' or direct output (its 'output' is compiling the actual/target program).
    */

    /*
    (based on how_to '495_default_metaprogram.jai')
    The Default Metaprogram

    When you run the compiler, before it runs your own metaprogram and before compiling your code, it actually
    runs the 'default metaprogram', which is just module that can be found at 'modules/Default_Metaprogram.jai'.

    This metaprogram does things like set the working directory of the compiler, set the output executable name,
    handle command line args like '-version' and '-x64' (yes, those aren't part of the compiler, its just a jai metaprogram!),
    and so on. Its not very big and is nice to read to learn what it does and how.

    It is probably of no surprise at this point to know that you can replace this metaprogram with your own. To do so,
    you simply do the following:

        jai main.jai --- meta My_Metaprogram
    
    The above runs modules/My_Metaprogram as the 'default' metaprogram. This can be useful if for example you want to run
    checks on your build.jai metaprogram, or whatever else you want to do. If your metaprogram is in some custom folder not
    in the import path, you can do this:
        
        jai main.jai --- import_dir my_folder meta My_Metaprogram

    If you want to make your own metaprogram, you might consider using 'Minimal_Metaprogram.jai', which is a stripped down version
    of the default metaprogram, as your base for building your default metaprogram.

    It is recommended in how_to 495 to run your program and new default metaprogram *without* '--- meta' first to ensure
    things are working properly, and then switching to it, just to help debug more easily.
    */

    /*
    (based on how_to '420_command_line.jai')
    User-level Arguments During Compilation

    During compilation, you are able to pass any *custom* command line arguments you like to your metaprogram.
    This is possible by doing something like:

        jai -x64 main.jai - invincible

    While '-x64' is a normal argument seen by the compiler, anything after '-' is considered user-level and is *ignored*
    by the compiler, and passed to the metaprogram as-is. User-level compilation arguments can be read in your
    metaprogram using something like this:

        options := get_build_options();
        args := options.compile_time_command_line;
        for args {
            print("user-level compile time arg: %\n", it);
            if it == {
                case "invincible"; enable_invincible_mode = true;
                case; print("unhandled arg %\n", it); exit(1);
            }
        }
    */

    /*
    (based on how_to '450_basic_metaprogram.jai')
    Compiler Message Loop

    As the compiler moves through the different stages of compiling your program, like loading
    source files/strings, handling imports, entering a new 'compilation phase' (like ready to write executable),
    finishing typechecking, and so on, it emits 'messages' detailing what happened (e.g. proc called 'print' finished typechecked).

    A metaprogram is able to listen to compilation messages to do some work. This is where a lot of the power of compile time
    Jai comes from, because by checking things, after say getting typechecked, you are able to implement custom checks,
    generate code, and so on.
    */

    // With this, we are done with the theory! as you can see, its not really complicated.
    // To see much of what we discussed in action, check the file 'build.jai', our own small metaprogram!
    //
    // This build.jai simply creates a workspace and builds this main.jai, just as if you did 'jai main.jai',
    // and also implements the '-is_jai_cool' user-level compile time argument.

    // Aside from build.jai, there are a bunch of how_tos that go over examples of using metaprogramming.
    // Those how tos include (not exhaustive): 450_basic_metaprogram, 460_code_browsing_and_generation,
    // 470_running_hooks_in_the_target_workspace, 480_custom_checks,
    // 490_browsing_by_module, 500_use_of_compile_time_execution
}

is_constant_test :: () {

    print("\n\n================= is_constant Test =================\n\n");

    /*
    This is a small test to explain is_constant a bit, which we have used before.

    is_constant(x) is simply built-in that takes in an *expression* 'x' and reports, at compile time,
    whether the expression is a constant or not. Since this runs at compile time, is_constant always returns
    a constant bool value.

    This constant return value can be assigned to variables, constants, and can be used with things like #if.

    For more on what things are constant, see how_to 551_things_that_are_constant
    */
    
    are_floats_constant := is_constant(1.1);
    IS_NUM_LITERAL_CONSTANT :: is_constant(99);

    print("are_floats_constant = %\n", are_floats_constant);
    print("is_num_literal_constant = %\n", IS_NUM_LITERAL_CONSTANT);

    // It is important to note that is_constant simply reports whether the given expression
    // is a constant or not (which is something known to the compiler regarding all expressions),
    // is_constant does NOT execute whatever you give it.
    add :: (x: float, y: float) -> float {
        print("add called\n"); // This will NOT print!
        return x + y;
    }

    IS_PROC_CALL_CONST :: is_constant(add(1, 2)); // This is false, and will NOT print 'add called'!
    print("is_proc_call_constant = %\n", IS_PROC_CALL_CONST);

    is_run_const := is_constant(#run add(1, 2)); // This is true, and will print 'add called' at compile time

    print("is_run_const = %\n", is_run_const);

    // This ALWAYS returns TRUE.
    //
    // This is because the inner is_constant always returns a const/it is a const, and so the outer
    // is_constant always gets a constant, and so this expression is always true. 
    #if is_constant(is_constant(add(1, 2))) {
        print("is_constant(is_constant(x)) is always true no matter what 'x' is!\n");
    }
}