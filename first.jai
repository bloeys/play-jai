#import "Basic";

// Add this gg field to the context
#add_context gg : u8 = 128;

main :: () {
    generic_test();
    print_test();
    loop_test();
    ifx_test();
    if_case_test();
    any_test();
    imports_test();
    this_and_loc_and_run_test();
    operator_overloading_test();
    static_if();
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

generic_test :: () {

    x : s32 = 55;
    y : s8 = cast(s8) x;
    z := 1.2;
    w := 55;

    print("\nBism Allah\n\n");
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
    // becomes necessary
    print_personal_info2 :: ($p: Person, $t: Type) {
        x: t;   // To do this you MUST use '$t'. Simply 't' will throw an error.
        print("Person=%; x=%\n", p, x);
    }

    p2 :: Person.{name="GG"};
    // p2 := Person.{name="GG"}; $p requires a constant value, so we MUST use 'p2 ::'.
    print_personal_info2(p2, s32);

    // Printing derived type from base
    print_emp_from_base :: (p: *Person) {
        print("GG=%\n", <<cast(*Employee)p);
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

    print("generic_test=%\n", generic_test);  // Outputs 'procedure 0x123', where 0x123 is the address
    print("generic_test=%\n", cast(*void)generic_test); // The cast outputs only the address without 'procdure'

    // We can mix and match numbered and non-numbered print arguments.
    // Non-numbered after numbered will pick the next arugment after that number. So here % is used after %1, so %==%2.
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
        <<counter += 1;
        print("counter ticked!\n");
        return <<counter;
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
        print("heap name=%\n", <<it);

        // While this array is on the heap, the individual strings within it are literal and so immutable.
        // Below are different equivalent ways of changing the first character of the string, but they all crash
        // because 'it' points to a literal string.

        // <<it.data = <<"bro".data;
        // (<<it)[0] = "bro"[0];
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
    <<lang_ptr = 255;
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

    print("num=%; num address=%;\nx value=%; x.value_pointer=%\n", num, *num, <<cast(*int)x.value_pointer, x.value_pointer);

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
    <<cast(*int)long_any.value_pointer += 1;
    print("long_any after change=%; num=%\n", <<cast(*int)long_any.value_pointer, num);

    // Usually, assigning something to Any takes its type (e.g. 'long_any=num' makes long_any.type==int), but Any=Any is a special case.
    // Assigning Any to another Any variable does a simple struct copy, which means the original type info and pointer are maintained!
    //
    // This is very nice because it means we avoid having an 'Any' variable with its .type==Any, causing an Any that points to another Any.
    // In the below example, any2 and long_any are identical! They both have type==int and point to the temp memory we allocated above.
    any2 : Any = long_any;
    print("any2=%; long_any=%\n", any2.value_pointer, long_any.value_pointer);
}

imports_test :: () {

    print("\n\n================= Imports Test =================\n\n");

    // Importing a module (Jai name for library) dumps its names into our namespace.
    // This can be useful for very common stuff, like how we can do 'print' instead of 'Basic.print'.
    //
    // Another way to import is by giving a name to an import, like below
    My_Basic :: #import "Basic";
    My_Basic.print("Same print as usualy\n"); 

    // If you want to name an import AND dump all its names into your namespace, you can use 'using'
    using My_Basic2 :: #import "Basic";

    // You can also do it in two lines:
    // My_Basic2 :: #import "Basic";
    // using My_Basic2;

    My_Basic2.print("My_Basic2.print\n");
    print("in-namespace print from My_Basic2\n");
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
    facotrial_num := 3;
    factorial_result := (x: int) -> int {
        if x <= 1 return 1;
        return x * #this(x-1);
    }(facotrial_num);

    print("factorial(%)=%\n", facotrial_num, factorial_result);

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
