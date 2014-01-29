//+------------------------------------------------------------------+
//|                                                       LibGMT.mqh |
//|                                 Copyright © 2010, Matthew Kennel |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Matthew Kennel"
#property link      "Version 0.1"

// ***************************************************************************
//  LICENSING:  This is free, open source software, licensed under
//              Version 2 of the GNU General Public License (GPL).
//
//  In particular, this means that distribution of this software in a binary
//  format, e.g. as compiled in as part of a .ex4 format, must be accompanied
//  by the non-obfuscated source code of both this file, AND the .mq4 source
//  files which it is compiled with, or you must make such files available at
//  no charge to binary recipients.	If you do not agree with such terms you
//  must not use this code.  Detailed terms of the GPL are widely available
//  on the Internet.  The Library GPL (LGPL) was intentionally not used,
//  therefore the source code of files which link to this are subject to
//  terms of the GPL if binaries made from them are publicly distributed or
//  sold.
//
//  ANY USE OF THIS CODE NOT CONFORMING TO THIS LICENSE MUST FIRST RECEIVE 
//  PRIOR AUTHORIZATION FROM THE AUTHOR(S).  ANY COMMERCIAL USE MUST FIRST 
//  OBTAIN A COMMERCIAL LICENSE FROM THE AUTHOR(S).
//
//  Copyright (2010), Matthew Kennel, mbkennelfx@gmail.com

/*
    The purpose of this library is to reduce all the confusion about
    time zones and GMT offsets and server time & local time in
    EA's.
    
    Here's how it works. It assumes the *Local* *time* the computer
    running Metatrader (NOT THE BROKER/DEALER's SERVER!!!!) is set correctly in
    Windows operating system, and daylight savings time is
    like wise set correctly (usually happens automatically with Windows
    if you set up internet updating).

    If you are running MT4 via a remote server then of course this
    is the time the remote server is set.

    Then it recomputes GMT time back using the operating system's GMT offset.
 
    Most usefully EA's care about the day of week in GMT and the time in hours 
    and minutes.  I personally feel time of day is most conveniently
    represented by an integer in HHMM format meaning hour * 100 + minutes.
    
    Reading the Windows documentation I believe that the code in FFCal.mq4 or EconomicNews.mq4
    is incorrect for daylight savings adjustment. Specifically a test shows that on my computer
    the adjustment minutes for daylight savings (-60) is returned in location 42 and not 43,
    and the use of the return value from GetTimeZoneInformation() is confused.
 
 UTILITY FUNCTIONS
 
   datetime GMTseconds()       
            return the datetime (seconds since 1/1/1970) for GMT time zone.
   void MakeDayHHMM(datetime dt, int& day_of_week, int& hhmm) 
            set day_of_week and hhmm from 'dt'.
            
 USEFUL FUNCTIONS      
   
 void GetLocalDayHHMM(int& day_of_week, int& hhmm)
 void GetGMTDayHHMM(int& day_of_week, int& hhmm)
 void GetNewYorkDayHHMM(int& day_of_week, int& hhmm) 
 void GetLondonDayHHMM(int& day_of_week, int& hhmm) 
 void GetTokyoDayHHMM(int& day_of_week, int& hhmm) 

These get the day of week & time with respect to the local (computer's local),
GMT, NYC, London and Tokyo. 'hhmm' means an integer of 100*hour + minute, making
comparisons easy.

Look what function is NOT present: the server time which controls all the charts.
Why?  Because there is no automatic way to know the broker's time zone & daylight
saving adjustment.

Example:

   int day, hhmm;
   GetNewYorkDayHHMM(day, hhmm);
   if ((day == 5) && (hhmm > 0730)) {
     // avoid trading after 7:30 AM New York Time on Fridays 
   

 
*/
 
 
 

#import "kernel32.dll"
int  GetTimeZoneInformation(int& TimeZoneInformationStruct[]);
/*
http://msdn.microsoft.com/en-us/library/ms724421%28VS.85%29.aspx
*/

#import

datetime GMTseconds() {
    int TZIS[43];
        int result=GetTimeZoneInformation(TZIS);
    int offsetminutes; /* add to local time to get GMT */
    if ((result == 0) || (result == 1)) {
        /* zero means we are in no daylight, 1 means standard time, confusing
           what that difference is */
        offsetminutes = TZIS[0];
    }
    if (result == 2) {
        /* two means that we are currently in daylight savings */ 
        offsetminutes = TZIS[0]+TZIS[42];
    }
    return(TimeLocal() + offsetminutes*60);

}

/* 
 * note that GMT does NOT respect daylight saving,
 * though New York and London market hours do!
 *
 * New York is in daylight saving between 2nd Sunday in March and 1st Sunday in November.
 * London is in daylight saving between last Sunday in March and 1st Sunday in October.
 * Tokyo does not use daylight saving time.
 * 
 * Absent daylight saving time, New York is 5 hours before GMT.  Tokyo is 9 hours after GMT.
 */



void MakeDayHHMM(datetime dt, int& day_of_week, int& hhmm) {
    day_of_week = TimeDayOfWeek(dt);
    hhmm = TimeHour(dt)*100 + TimeMinute(dt); 
}

int yyyymmdd(datetime dt) {
    return(TimeYear(dt)*10000 + TimeMonth(dt)*100 + TimeDay(dt));
}

/* New York daylight savings changes
 *
 * 2010-03-14 -> 2010-11-07
 * 2011-03-13 -> 2011-11-06
 * 2012-03-11 -> 2012-11-04
 * 2013-03-10 -> 2013-11-03
 * 2014-03-09 -> 2014-11-02
 * 2015-03-08 -> 2015-11-01
 * 2016-03-13 -> 2016-11-06
 * 2017-03-12 -> 2017-11-05
 * 2018-03-11 -> 2018-11-04
 * 2019-03-10 -> 2019-11-03
 */
 
bool isNycDaylightSaving(int date) {
    if (
        ((date >= 20100314) && (date < 20101107)) ||
        ((date >= 20110313) && (date < 20111106)) ||
        ((date >= 20120311) && (date < 20121104)) ||
        ((date >= 20130310) && (date < 20131103)) ||
        ((date >= 20140309) && (date < 20141102)) ||
        ((date >= 20150308) && (date < 20151101)) ||
        ((date >= 20160313) && (date < 20161106)) ||
        ((date >= 20170312) && (date < 20171105)) ||
        ((date >= 20180311) && (date < 20181104)) ||
        ((date >= 20190310) && (date < 20191103))
        ) {
           return(true);
     } else {
        return(false);
     }
}


/*
 * London daylight savings changes
 * 2010-03-28 -> 2010-10-31
 * 2011-03-27 -> 2011-10-30
 * 2012-03-25 -> 2012-10-28
 * 2013-03-31 -> 2013-10-27
 * 2014-03-30 -> 2014-10-26
 * 2015-03-29 -> 2015-10-25
 * 2016-03-27 -> 2016-10-30
 * 2017-03-26 -> 2017-10-29
 * 2018-03-25 -> 2018-10-28
 * 2019-03-31 -> 2019-10-27
 */
 

bool isLondonDaylightSaving(int date) {
    if (
        ((date >= 20100328) && (date < 20101031)) ||
        ((date >= 20110327) && (date < 20111030)) ||
        ((date >= 20120325) && (date < 20121028)) ||
        ((date >= 20130331) && (date < 20131027)) ||
        ((date >= 20140330) && (date < 20141025)) ||
        ((date >= 20150329) && (date < 20151025)) ||
        ((date >= 20160327) && (date < 20161030)) ||
        ((date >= 20170326) && (date < 20171029)) ||
        ((date >= 20180325) && (date < 20181028)) ||
        ((date >= 20190331) && (date < 20191027))
        ) {
           return(true);
     } else {
        return(false);
     }
}

void GetGMTDayHHMM(int& day_of_week, int& hhmm) {
    MakeDayHHMM(GMTseconds(), day_of_week, hhmm); 
}


void GetLocalDayHHMM(int& day_of_week, int& hhmm) {
    MakeDayHHMM(TimeLocal(), day_of_week, hhmm); 
}

void GetNewYorkDayHHMM(int& day_of_week, int& hhmm) {
    datetime nyctime = GMTseconds() - 5*3600;
    int date = yyyymmdd(nyctime);
    if (isNycDaylightSaving(date)) {
        nyctime += 3600; /* add one hour */ 
    }        
    MakeDayHHMM(nyctime, day_of_week, hhmm); 
}


void GetLondonDayHHMM(int& day_of_week, int& hhmm) {
    datetime londontime = GMTseconds();
    int date = yyyymmdd(londontime);
    if (isLondonDaylightSaving(date)) {
        londontime += 3600; /* add one hour */ 
    }        
    MakeDayHHMM(londontime, day_of_week, hhmm); 
}

void GetTokyoDayHHMM(int& day_of_week, int& hhmm) {
    datetime tokyotime = GMTseconds() + 9*3600;
    MakeDayHHMM(tokyotime, day_of_week, hhmm); 
}

/*
datetime DumpTZInfo() {
    int TZIS[43];

    int result=GetTimeZoneInformation(TZIS);
    Print ("DumpTZINFO: result=",result);
    for (int i=0; i < 44; i++) {
        Print("DumpTZINFO: TZIS[", i, "]=", TZIS[i]);
    }
}
*/