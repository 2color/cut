import std.stdio;
import std.getopt;
import std.conv;
import std.file;
import std.algorithm;

/**
 * Cut Class
 *
 * Class representing the complete Cut cli tool
 */
class Cut {

    /**
     * Range
     *
     * Range data structure representing a range of fields/bytes
     */
    struct Range {
        uint from;
        uint to;
    }

    /**
     * Cut Enumerated Type
     *
     * Data structure representing the different modes cut can operate in
     */
    enum CutMode { fields, bytes }


    /**
     * Constant chars
     *
     * Used for easy reference
     */
    immutable static char hyphen = 0x2D;
    immutable static char tab = 0x09;
    immutable static char newLine = 0x0A;



    /**
     * @var file the file to read
     */
    private string file;

    /**
     * @var mode    cut mode
     */
    private CutMode mode;

    /**
     * @var range   range of fields/bytes selected
     */
    private Range range;

    /**
     * @var delimiter   the character used as delimiter. (defaults to tab)
     */
    private char delimiter = tab;

    /**
     * @var complement   boolean for complement mode. (defaults to false)
     */
    private bool complement = false;


    /**
     * @constructor
     * 
     * @param   string[]    args    arguments as passed to the main function.
     */
    this(string[] args) {
        parseOpts(args);
        this();
    }


    /**
     * @constructor
     * 
     * Function overloading without arguments for testing purposes
     */
    this() {
        if (!exists(file)) {
            writefln("file %s doesn't exists", file);
            return;
        } else {
            cutFile();
        }
    }


    void cutFile() {
        auto f = File(file, "r");
        string output;

        char[] buf;


        while (f.readln(buf)) {
            //writeln(cutLine(buf.filter!(a => a != newLine)));
            writeln(cutLine(buf.strip(' ')));
        }
    }

    auto cutLine(char[] line) {
        if (mode == CutMode.fields) {
            return cutLineByFields(line);
        } else {
            return cutLineByBytes(line);
        }
    }


    /**
     * Cut lines based on fields
     *
     * Splits the line acording to the delimiter and returns the fields
     *
     * @param   char[]  line    a single line
     *
     * @return  char[]
     */
    auto cutLineByFields(char[] line) {
        auto fields = splitter(line, delimiter);
        char[] result;

        auto c = 1;
        foreach (field; fields) {
            // stop iterating if the end field has been reached.
            if (c > range.to) {
                break;
            }

            // Append to the result the delimiter which has been removed by the splitter.
            if (c >= range.from && c <= range.to) {
                result ~= field ~ delimiter;
            }

            c++;
        }

        return result;
    }


    /**
     * Cut lines based on bytes
     *
     * @param   char[]  line    a single line
     *
     * @return  char[]
     */
    auto cutLineByBytes(char[] line) {
        char[] result;

        auto c = 1;
        foreach (field; line) {
            // stop iterating if the end field has been reached.
            if (c > range.to) {
                break;
            }

            // Append to the result the delimiter which has been removed by the splitter.
            if (c >= range.from && c <= range.to) {
                result ~= field;
            }

            c++;
        }

        return result;
    }


    /**
     * Parse Options
     *
     * Parses the cli options and updates the options data structure
     *
     * @param   args    string[]    arguments as passed to the main function
     *
     * @return  void
     */
    void parseOpts(string[] args) {
        string fields;
        string bytes;

        getopt(args,
            std.getopt.config.passThrough,
            "complement", &this.complement,
            "delimiter|d", &this.delimiter,
            "bytes|b", &bytes,
            "fields|f", &fields);


        if ((bytes.length == 0 && fields.length == 0) ||
            (bytes.length > 0 && fields.length > 0))
        {
            writeln("usage: cut -b list [file ...]\n cut -f list [-d delim] [file ...]");
            writeln("specify either a byte or a field range ");
            return;
        }

        this.mode = (fields.length > 0) ? CutMode.fields : CutMode.bytes;

        if(this.mode == CutMode.fields) {
            parseRange(fields);
        } else {
            parseRange(bytes);
        }


        if (args.length == 2) {
            this.file = args[1];
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
    void parseRange(string input) {
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

}

// Main function
void main(string[] args) {
    auto cut = new Cut(args);
}


// Unit test for parse range
unittest {
    auto cut = new Cut();

    cut.parseRange("1");
    assert(cut.range.from == 1 && cut.range.to == 1);

    cut.parseRange("1-");
    assert(cut.range.from == 1 && cut.range.to == uint.max);

    cut.parseRange("1-5");
    assert(cut.range.from == 1 && cut.range.to == 5);

    cut.parseRange("-5");
    assert(cut.range.from == 1 && cut.range.to == 5);

    cut.range.from = 0;
    cut.range.to = 0;
    cut.parseRange("-");
    assert(cut.range.from == 0 && cut.range.to == 0);


    cut.parseRange("1-1");
    assert(cut.range.from == 1 && cut.range.to == 1);
}




// Unit test for cut lines by fields/bytes
unittest {
    auto cut = new Cut();
    cut.range.from = 1;
    cut.range.to = 5;
    cut.delimiter = 0x20;

    char[] test1 = "col1 col2 col3 col4 col5 col6 col7 col8".dup;

    assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 ");

    cut.range.from = 1;
    cut.range.to = uint.max;

    assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 col6 col7 col8 ");


    cut.range.from = 1;
    cut.range.to = 4;

    assert(cut.cutLineByBytes(test1) == "col1");


}