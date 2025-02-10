// Just like Go, each module is fully self contained (unless you use #load), so
// to use print here we need to import Basic.
#import "Basic";

SOME_CONST :: 55;

do_intern_on_int :: (x: int) -> int {
    print("intern.jai's do_intern_on_int called with x=%\n", x);
    return -x * SOME_CONST;
}
