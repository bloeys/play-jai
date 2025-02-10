// This file is part of the many_interns module, and gets its 'print'
// by having '#load' called on it inside module.jai, and having module.jai import Basic.
//
// #load puts the contents of this file in the same scope as the file using it, and since
// that file (in this case module.jai) is also doing #import "Basic", things in this file
// will also see names imported from Basic.
list_intern_names :: () {
    NAMES :: string.["Aa", "Bb", "Cc", "Gg"];
    print("Intern names=%\n", NAMES);
}