import std.stdio;
import std.getopt;
import std.conv;
import std.file;
import std.algorithm;
import std.string;

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
    immutable static char comma = 0x2C;
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
     * @var ranges   range of fields/bytes selected
     */
    private Range[] ranges;

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
            foreach (range; ranges) {

                // stop iterating if the end field has been reached.
                if (c > range.to) {
                    continue;
                }

                // Append to the result the delimiter which has been removed by the splitter.
                if (c >= range.from && c <= range.to) {
                    result ~= field ~ delimiter;
                    break;
                }
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

        //auto c = 1;
        //foreach (field; line) {
        //    // stop iterating if the end field has been reached.
        //    if (c > range.to) {
        //        break;
        //    }

        //    // Append to the result the delimiter which has been removed by the splitter.
        //    if (c >= range.from && c <= range.to) {
        //        result ~= field;
        //    }

        //    c++;
        //}

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
            parseRanges(fields);
        } else {
            parseRanges(bytes);
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
     *
     * @return  void
     */
    void parseRanges(string input) {
        auto ranges = splitter(input, comma);
        bool hasHyphen = false;

        foreach (string range;ranges) {
            if (isNumeric(range) && indexOf(range, hyphen) == -1) {
                // parse the range as a single field
                uint field = to!uint(range);
                this.ranges ~= Range(field, field);
            } else if (range == to!string(hyphen)) { 
                // ignore hyphens
                continue;
            } else {
                // multiple fileds range
                auto splitRange = findSplit(range, to!string(hyphen));

                // usage of -5 starts the range from 1
                uint start = (splitRange[0].length == 0) ? 1 : to!uint(splitRange[0]);
                // usage of 5- ends the range at the end of the line hence the use of uint.max
                uint end   = (splitRange[2].length == 0) ? uint.max : to!uint(splitRange[2]);

                this.ranges ~= Range(start, end);
            }   
        }

        //writefln("ranges %s \tlength: %s", this.ranges, this.ranges.length);

    }



    // Unit test for parse range
    unittest {
        auto cut = new Cut();

        cut.parseRanges("1");
        assert(cut.ranges[cut.ranges.length-1].from == 1 && cut.ranges[cut.ranges.length - 1].to == 1);

        cut.parseRanges("1-");
        assert(cut.ranges[cut.ranges.length - 1].from == 1 && cut.ranges[cut.ranges.length - 1].to == uint.max);

        cut.parseRanges("1-5");
        assert(cut.ranges[cut.ranges.length - 1].from == 1 && cut.ranges[cut.ranges.length - 1].to == 5);

        cut.parseRanges("-5");
        assert(cut.ranges[cut.ranges.length - 1].from == 1 && cut.ranges[cut.ranges.length - 1].to == 5);

        auto preLength = cut.ranges.length;
        cut.parseRanges("-");
        assert(cut.ranges.length == preLength);

        cut.parseRanges("1-1");
        assert(cut.ranges[cut.ranges.length - 1].from == 1 && cut.ranges[cut.ranges.length - 1].to == 1);


        cut.parseRanges("1,2,3");

        assert(cut.ranges[cut.ranges.length - 3].from == 1 && cut.ranges[cut.ranges.length - 3].to == 1);
        assert(cut.ranges[cut.ranges.length - 2].from == 2 && cut.ranges[cut.ranges.length - 2].to == 2);
        assert(cut.ranges[cut.ranges.length - 1].from == 3 && cut.ranges[cut.ranges.length - 1].to == 3);

        cut.parseRanges("1,2-");
        assert(cut.ranges[cut.ranges.length - 2].from == 1 && cut.ranges[cut.ranges.length - 2].to == 1);
        assert(cut.ranges[cut.ranges.length - 1].from == 2 && cut.ranges[cut.ranges.length - 1].to == uint.max);


        cut.parseRanges("1-5,6");
        assert(cut.ranges[cut.ranges.length - 2].from == 1 && cut.ranges[cut.ranges.length - 2].to == 5);
        assert(cut.ranges[cut.ranges.length - 1].from == 6 && cut.ranges[cut.ranges.length - 1].to == 6);


        cut.parseRanges("-5,8");
        assert(cut.ranges[cut.ranges.length - 2].from == 1 && cut.ranges[cut.ranges.length - 2].to == 5);
        assert(cut.ranges[cut.ranges.length - 1].from == 8 && cut.ranges[cut.ranges.length - 1].to == 8);
    }

    // Unit test for cut lines by fields/bytes
    //unittest {
    //    auto cut = new Cut();
    //    cut.ranges[0] = Range();
    //    cut.ranges[0].from = 1;
    //    cut.ranges[0].to = 5;
    //    cut.delimiter = 0x20;

    //    char[] test1 = "col1 col2 col3 col4 col5 col6 col7 col8".dup;

    //    assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 ");

    //    cut.ranges.from = 1;
    //    cut.ranges.to = uint.max;

    //    assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 col6 col7 col8 ");


    //    cut.ranges.from = 1;
    //    cut.ranges.to = 4;

    //    assert(cut.cutLineByBytes(test1) == "col1");
    //}

}

// Main function
void main(string[] args) {
    auto cut = new Cut(args);
}
