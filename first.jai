#import "Basic";

main :: () {
    test1();
}

test1 :: () {

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

    Employee :: struct {
        #as using base: Person;
        salary: float32;
    }

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

    /*
        Printing
    */
    print("test1=%\n", test1);  // Outputs 'procedure 0x123', where 0x123 is the address
    print("test1=%\n", cast(*void)test1); // The cast outputs only the address without 'procdure'

    // We can mix and match numbered and non-numbered print arguments.
    // Non-numbered after numbered will pick the next arugment after that number. So here % is used after %1, so %==%2.
    print("%3. Please welcome %1. %1 has been working on this language for % years. Good job %1. Thank you for % years of work.\n", "Jon", 10, "Hi all");

    // Formatting options can be applied using formatting structs like FormatInt/FormatStruct/FormatFloat/FormatArray
    print("some formatted int=%\n", FormatInt.{value = 99, minimum_digits = 3});
    print("some formatted int=%\n", FormatInt.{value = 999999, digits_per_comma = 3, comma_string=","});

    // This will round to 0.5001 as trailing width is numbers after the dot
    print("some formatted float=%\n", FormatFloat.{value = 0.50009, zero_removal = .NO, trailing_width = 4});
    
    print("some formatted struct=%\n",
        FormatStruct.{value = p, draw_type_name = true, use_long_form_if_more_than_this_many_members = -1, use_newlines_if_long_form = true},
    );

    print("some formatted array=%\n", FormatArray.{value = u8.[55, 128, 0, 11], separator = "; "});

    // By default, print uses formatting specified in context.print_style, so changing that or pushing context
    // allows us to configure formatting on a global level or on a specific program subtree.
    push_context {
        context.print_style.default_format_int.base = 2;
        print("some formatted int (binary)=0b%\n", 3); // This will print in binary '11'
    }

    // '%%' prints simply '%'. But its a problem if we want to print like x%, because you will get %%%
    // which leads to the reverse of what you want (it prints %x). One approach is to do %1%%, but that makes you use
    // numbered arguments which can lead to more errors. So instead, you can use %0 which is the SAME as %, but avoids the
    // issue above. Remember: %0 is NOT a numbered argument like %1/%2/etc. %==%0
    print("You got %0%% on your exam!\n", 91.5);

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

#add_context gg : u8 = 128;
