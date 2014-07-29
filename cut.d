import std.stdio;
import std.getopt;
import std.conv;

immutable char hyphen = 0x2D;

/**
 * struct range
 * 
 * Data structure representing a range
 */
struct range {
    uint from;
    uint to;
}

/**
 * struct options
 * 
 * Data structure representing the cli options
 */
struct options {
    string file;
    range fields;
    range bytes;
    char delimiter = 0x09;
    bool complement = false;
}

void main(string[] args) {
    options opts;

    parseOpts(args, opts);

    writefln("option: %s ", opts);

}

/**
 * Parse Options
 * 
 * Parses the cli options and updates the options data structure
 * 
 * @param   args    string[]    arguments as passed to the main function
 * @param   &opts   options     the options data strcuture to update
 * 
 * @return  void
 */
void parseOpts(string[] args, ref options opts) {
    string fields;
    string bytes;

    getopt(args, 
        std.getopt.config.passThrough,
        "complement", &opts.complement,
        "delimiter|d", &opts.delimiter,
        "bytes|b", &bytes,
        "fields|f", &fields);

    if (bytes.length == 0 && fields.length == 0)
    {
        writeln("usage: cut -b list [file ...]\n cut -f list [-d delim] [file ...]");
        writeln("specify either a byte or a field range ");
        return;        
    }

    parseRange(fields, opts.fields);

    if (args.length == 2) {
        opts.file = args[1];
    } else {
        writeln("missing the file option.");
        return;
    }
}



/**
 * Parse Range
 * 
 * Parses a range string and updates the range data structure
 * 
 * @param   input   string      the string entered by the user
 * @param   range   range       the range data structure to update
 * 
 * @return  void
 */
void parseRange(string input, ref range range) {
    bool hasHyphen = false;

    foreach(i, e; input) {
        if (e == hyphen) {
            hasHyphen = true;
            if (i == 0) {
                if(input.length == 1) {
                    // exception
                    return;
                }
                range.from = 1;
                range.to = to!uint(input[i+1 .. $]);
                break;
            } else if (i == input.length -1) {
                range.from = to!uint(input[0 .. i]);
                range.to = uint.max;
                break;
            } else {
                range.from = to!uint(input[0 .. i]);
                range.to = to!uint(input[i+1 .. $]);
                break;
            }
        }
    }

    // single field
    if (!hasHyphen) {
        range.from = to!uint(input);
        range.to = to!uint(input);
    }

    if(range.from == 0 || range.to == 0 ) {
        // exception
    }


}


unittest {
    range range;

    parseRange("1", range);
    assert(range.from == 1 && range.to == 1);

    parseRange("1-", range);
    assert(range.from == 1 && range.to == uint.max);
    
    parseRange("1-5", range);
    assert(range.from == 1 && range.to == 5);    
 
    parseRange("-5", range);
    assert(range.from == 1 && range.to == 5); 

    range.from = 0;
    range.to = 0;
    parseRange("-", range);
    assert(range.from == 0 && range.to == 0);


    parseRange("1-1", range);
    assert(range.from == 1 && range.to == 1);

}