module cut.optionsparser;

import std.stdio;
import std.getopt;
import std.c.process;
import std.algorithm;
import std.string;
import std.file;
import std.conv;



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
 * Cut Options Parser Class
 *
 * Class representing the options parser of the cut cli tool
 * 
 * @author    Daniel Norman   daniel.norman@sociomantic.com
 */
class CutOptionsParser {

    /**
     * Constant chars
     *
     * Used for easy reference
     */
    immutable static char comma = 0x2C;
    immutable static char hyphen = 0x2D;
    immutable static char tab = 0x09;

    /**
     * @var file the file to read
     */
    public string file;

    /**
     * @var mode    cut mode
     */
    public CutMode mode;

    /**
     * @var ranges   range of fields/bytes selected
     */
    public Range[] ranges;

    /**
     * @var delimiter   the character used as delimiter. (defaults to tab)
     */
    public char delimiter = tab;

    /**
     * @var complement   boolean for complement mode. (defaults to false)
     */
    public bool complement = false;


    /**
     * @var debugMode   boolean for debug mode - don't exit
     */
    private bool debugMode = false;

    /**
     * @constructor
     * 
     */
    this() {
      // when the unit tests instanatiate without options debug mode is true;
      debugMode = true;
    }


    /**
     * @constructor
     * 
     * @param   string[]    args    arguments as passed to the main function.
     */
    this(string[] args) {
        parseOpts(args);
    }


    /**
     * Internal exit function
     * 
     * Internal version of exit, which won't exit in debug mode. 
     * This is used so all tests are ran even if an exception or invalid
     * options are found.
     */
    private void exit() {
      if(debugMode) {
        return;
      }

      std.c.process.exit(0);
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
            exit();
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

            if (!exists(this.file)) {
                writefln("file %s doesn't exists", this.file);
                exit();
            }
        } else {
            writeln("missing the file option.");
            exit();
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
        auto hasHyphen = false;

        foreach (string range;ranges) {
           try {
                this.ranges ~= parseRange(range);
           } catch(Exception e) {
                writefln("Range error: %s", e.msg);
                exit();
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
        auto options = new CutOptionsParser();

        options.parseRanges("1");
        assert(options.ranges[options.ranges.length-1].from == 1 && options.ranges[options.ranges.length - 1].to == 1);

        options.parseRanges("1-");
        assert(options.ranges[options.ranges.length - 1].from == 1 && options.ranges[options.ranges.length - 1].to == uint.max);

        options.parseRanges("1-5");
        assert(options.ranges[options.ranges.length - 1].from == 1 && options.ranges[options.ranges.length - 1].to == 5);

        options.parseRanges("-5");
        assert(options.ranges[options.ranges.length - 1].from == 1 && options.ranges[options.ranges.length - 1].to == 5);

        auto preLength = options.ranges.length;
        options.parseRanges("-");
        assert(options.ranges.length == preLength);

        options.parseRanges("1-1");
        assert(options.ranges[options.ranges.length - 1].from == 1 && options.ranges[options.ranges.length - 1].to == 1);


        options.parseRanges("1,2,3");

        assert(options.ranges[options.ranges.length - 3].from == 1 && options.ranges[options.ranges.length - 3].to == 1);
        assert(options.ranges[options.ranges.length - 2].from == 2 && options.ranges[options.ranges.length - 2].to == 2);
        assert(options.ranges[options.ranges.length - 1].from == 3 && options.ranges[options.ranges.length - 1].to == 3);

        options.parseRanges("1,2-");
        assert(options.ranges[options.ranges.length - 2].from == 1 && options.ranges[options.ranges.length - 2].to == 1);
        assert(options.ranges[options.ranges.length - 1].from == 2 && options.ranges[options.ranges.length - 1].to == uint.max);


        options.parseRanges("1-5,6");
        assert(options.ranges[options.ranges.length - 2].from == 1 && options.ranges[options.ranges.length - 2].to == 5);
        assert(options.ranges[options.ranges.length - 1].from == 6 && options.ranges[options.ranges.length - 1].to == 6);


        options.parseRanges("-5,8");
        assert(options.ranges[options.ranges.length - 2].from == 1 && options.ranges[options.ranges.length - 2].to == 5);
        assert(options.ranges[options.ranges.length - 1].from == 8 && options.ranges[options.ranges.length - 1].to == 8);

        writeln("tests: CutOptionsParser \t passed  ✓");


    }


}

