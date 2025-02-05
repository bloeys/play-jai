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
}

#add_context gg : u8 = 128;
