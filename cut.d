import std.stdio;
import std.getopt;
import std.conv;
import std.file;
import std.algorithm;
import std.string;
import std.c.process;

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
        if (!file) {
            return;
        }
        else if (!exists(file)) {
            writefln("file %s doesn't exists", file);
            exit(0);
        } else {
            cutFile();
        }
    }


    void cutFile() {
        auto f = File(file, "r");

        char[] buf;

        while (f.readln(buf)) {
            writeln(cutLine(buf.strip(newLine)));
        }
    }

    /**
     * Cut line 
     *
     * @TODO Merge the cutLineByFields an cutLineByBytes into one function
     * and split for fields before the call.
     *
     * @param   char[]  line    a single line
     *
     * @return  char[]  the line after it's been cut
     */
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

        auto c = 1U;
        foreach (field; fields) {
            if (isInRanges(c)) {
                // Append to the result the delimiter which has been removed by the splitter.
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

        auto c = 1U;
        foreach (field; line) {
            if (isInRanges(c)) {
                // Append to the result the field(byte).
                result ~= field;
            }
            c++;
        }

        return result;
    }


    /**
     * Checks if a given integer(unsiged) is in one of the selected ranges.
     * If operating in complement mode, the boolean in inverted.
     *
     * O(n) complexity where n is the number of ranges
     *
     * @param   uint    c   the column/field number
     *
     * @return  boolean true if it's in the ranges
     */
    bool isInRanges(uint c) {
        bool isInRanges = false;

        foreach (range; ranges) {
                // stop iterating if the end field has been reached.
                if (c > range.to) {
                    continue;
                }

                if (c >= range.from && c <= range.to) {
                    isInRanges = true;
                    break;
                }
        }

        return (this.complement) ? !isInRanges : isInRanges;
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
        char delimiter;

        getopt(args,
            std.getopt.config.passThrough,
            "complement", &this.complement,
            "delimiter|d", &delimiter,
            "bytes|b", &bytes,
            "fields|f", &fields);


        if ((bytes.length == 0 && fields.length == 0) ||
            (bytes.length > 0 && fields.length > 0))
        {
            writeln("usage: cut -b list [file ...]\n cut -f list [-d delim] [file ...]");
            writeln("specify either a byte or a field range ");
            exit(0);
        }

        this.mode = (fields.length > 0) ? CutMode.fields : CutMode.bytes;

        if(this.mode == CutMode.fields) {
            this.delimiter = delimiter;
            parseRanges(fields);
        } else {
            // TODO check if delimiter is passed and throw error or ignore..
            parseRanges(bytes);
        }


        if (args.length == 2) {
            this.file = args[1];
        } else {
            writeln("missing the file option.");
            exit(0);
        }
    }



    /**
     * Parse Ranges
     *
     * Parses a ranges string and append the range data structure
     *
     * @param   input   string      the string entered by the user
     *
     * @return  void
     */
    void parseRanges(string input) {
        auto ranges = splitter(input, comma);
        bool hasHyphen = false;

        foreach (string range;ranges) {
           try {
                this.ranges ~= parseRange(range);
           } catch(Exception e) {
                writefln("Range error: %s", e.msg);
                exit(0);
           }
        }

    }

    Range parseRange(string input) {
        if (isNumeric(input) && indexOf(input, hyphen) == -1) {
                // parse the range as a single field
                auto field = to!uint(input);
                if (field < 1) throw new Exception("fields/bytes selection starts at 1");
                return Range(field, field);
            } else if (input == to!string(hyphen)) { 
                throw new Exception("invalid range - a single hyphen isn't allowed");
            } else {
                // multiple fileds input
                auto splitRange = findSplit(input, to!string(hyphen));

                // usage of -5 starts the input from 1
                auto start = (splitRange[0].length == 0) ? 1 : to!uint(splitRange[0]);
                // usage of 5- ends the input at the end of the line hence the use of uint.max
                auto end   = (splitRange[2].length == 0) ? uint.max : to!uint(splitRange[2]);

                if (start < 1 || end < 1) throw new Exception("fields/bytes selection starts at 1");
                if (start > end) throw new Exception("fields/bytes range is invalid (the start must be smaller than the end)");

                return Range(start, end);
            }
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

    // Unit test for cut lines by fields/bytes and complement
    unittest {
        auto cut = new Cut();
        cut.ranges ~= Range(1, 5);
        cut.delimiter = 0x20;

        char[] test1 = "col1 col2 col3 col4 col5 col6 col7 col8".dup;

        assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 ");

        cut.ranges[0].from = 1;
        cut.ranges[0].to = uint.max;

        assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 col6 col7 col8 ");


        cut.ranges[0].from = 1;
        cut.ranges[0].to = 4;

        assert(cut.cutLineByBytes(test1) == "col1");

        cut.complement = true;
        assert(cut.cutLineByBytes(test1) == " col2 col3 col4 col5 col6 col7 col8");
    }

}

// Main function
void main(string[] args) {
    auto cut = new Cut(args);
}
