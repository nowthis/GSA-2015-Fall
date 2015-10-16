# Data Center Consolidation project
## Extracting differences between periods

change_report.pl

Features:

* Given a pair of DataPoint spreadsheets
   * with consistent column names but not necessarily consistent row/column positions
* Produces CSV-formatted data rows indicating the differences between them

Future directions:

* Based on a configurable Cost Factors CSV file, could easily include the dollar-amount deltas between periods.


Sample output:

    Data Center ID, Field, Period1, Value1, Period2, Value2, Change
    FDCCI-DC-45651, Total Windows Servers, 2016Q1, 22, 2016Q2, 18, -4
    FDCCI-DC-45651, Total Virtual Hosts, 2016Q1, 27, 2016Q2, 29, 2
    FDCCI-DC-45672, Total Other Mainframes, 2016Q1, 4, 2016Q2, 0, -4
    FDCCI-DC-45719, Total Other Mainframes, 2016Q1, 39, 2016Q2, 17, -22