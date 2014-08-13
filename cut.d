module cut.cut;

import std.stdio;
import std.algorithm;
import std.c.process;
import cut.optionsparser;


/**
 * Cut Class
 *
 * Class representing the complete Cut cli tool
 *
 * @author    Daniel Norman   daniel.norman@sociomantic.com
 */
class Cut {

    /**
     * Constant new line char
     *
     * Used for easy reference
     */
    immutable static char newLine = 0x0A;


    /**
     * Options object
     *
     * Used for parsing the cli options
     */
    CutOptionsParser options;

    /**
     * @constructor
     * 
     * @param   string[]    args    arguments as passed to the main function.
     */
    this(string[] args) {
        this.options = new CutOptionsParser(args);
        cutFile();
    }


    /**
     * @constructor
     * 
     * Function overloading without arguments for testing purposes
     */
    this() {
    }


    void cutFile() {
        auto f = File(options.file, "r");

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
        if (options.mode == CutMode.fields) {
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
        auto fields = splitter(line, options.delimiter);
        char[] result;

        auto c = 1U;
        foreach (field; fields) {
            if (isInRanges(c)) {
                // Append to the result the delimiter which has been removed by the splitter.
                result ~= field ~ options.delimiter;
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

        foreach (range; options.ranges) {
                // stop iterating if the end field has been reached.
                if (c > range.to) {
                    continue;
                }

                if (c >= range.from && c <= range.to) {
                    isInRanges = true;
                    break;
                }
        }

        return (options.complement) ? !isInRanges : isInRanges;
    }



    // Unit test for cut lines by fields/bytes and complement
    unittest {
        auto cut = new Cut();
        cut.options = new CutOptionsParser();
        cut.options.ranges ~= Range(1, 5);
        cut.options.delimiter = 0x20;

        char[] test1 = "col1 col2 col3 col4 col5 col6 col7 col8".dup;

        assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 ");

        cut.options.ranges[0].from = 1;
        cut.options.ranges[0].to = uint.max;

        assert(cut.cutLineByFields(test1) == "col1 col2 col3 col4 col5 col6 col7 col8 ");


        cut.options.ranges[0].from = 1;
        cut.options.ranges[0].to = 4;

        assert(cut.cutLineByBytes(test1) == "col1");

        cut.options.complement = true;
        assert(cut.cutLineByBytes(test1) == " col2 col3 col4 col5 col6 col7 col8");

        writeln("tests: Cut \t passed ✓");
    }

}

// Main function
void main(string[] args) {
    auto cut = new Cut(args);
}
