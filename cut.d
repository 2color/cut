import std.stdio;
import std.getopt;


struct options {
    string file;
    string fields;
    string bytes;
    char delimiter = 0x09;
    bool complement = false;
}

void main(string[] args) {
    //string file;
    //string fields;
    //string bytes;
    //char delimiter = 0x09;
    //bool complement = false;
    options options;


    getopt(args, 
        std.getopt.config.passThrough,
        "complement", &options.complement,
        "delimiter|d", &options.delimiter,
        "bytes|b", &options.bytes,
        "fields|f", &options.fields);

    if (args.length == 2) {
        options.file = args[1];
    } else {
        writeln("missing the file option.");
        return;
    }


    writefln("option: %s ", options);
    writefln("delimiter: %sEND", options.delimiter);
    writefln("bytes: %s ", options.bytes);
    writefln("fields: %s ", options.fields);

    foreach (i, arg; args) {
        writefln("args[ %s ]:  %s ", i, arg);
    }


    //immutable inchesPerFoot = 12;
    //immutable cmPerInch = 2.54;

    //foreach(feet; 5..7) {
    //    foreach(inches; 0 .. inchesPerFoot) {
    //        writefln("%s'%s''\t%s", feet, inches,
    //            (feet * inchesPerFoot + inches) * cmPerInch);
    //    }
    //}
}