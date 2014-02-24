#property copyright "Copyright Â© 2014 Huxley"
#property link      "email:   huxley_source@gmail_com"

double _ask(string symbol) {
    return (NormalizeDouble(MarketInfo(symbol, MODE_ASK), MarketInfo(symbol, MODE_DIGITS)));
}

double _bid(string symbol) {
    return (NormalizeDouble(MarketInfo(symbol, MODE_BID), MarketInfo(symbol, MODE_DIGITS)));
}


bool _new_bar(string symbol, int timeframe) {
    static datetime symbol_time[9];
    if (timeframe == 1) {
        if (iTime(symbol, timeframe, 0) != symbol_time[0]) {
            symbol_time[0] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 5) {
        if (iTime(symbol, timeframe, 0) != symbol_time[1]) {
            symbol_time[1] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 15) {
        if (iTime(symbol, timeframe, 0) != symbol_time[2]) {
            symbol_time[2] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 30) {
        if (iTime(symbol, timeframe, 0) != symbol_time[3]) {
            symbol_time[3] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 60) {
        if (iTime(symbol, timeframe, 0) != symbol_time[4]) {
            symbol_time[4] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 240) {
        if (iTime(symbol, timeframe, 0) != symbol_time[5]) {
            symbol_time[5] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 1440) {
        if (iTime(symbol, timeframe, 0) != symbol_time[6]) {
            symbol_time[6] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 10080) {
        if (iTime(symbol, timeframe, 0) != symbol_time[7]) {
            symbol_time[7] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    } else if (timeframe == 43200) {
        if (iTime(symbol, timeframe, 0) != symbol_time[8]) {
            symbol_time[8] = iTime(symbol, timeframe, 0);
            return (true);
        } else {
            return (false);
        }
    }
}


int _lower_timeframe(int timeframe, bool skip_m30 = true) {
    if (timeframe == 1) {
        return (1);
    } else if (timeframe == 5) {
        return (1);
    } else if (timeframe == 15) {
        return (5);
    } else if (timeframe == 30) {
        return (15);
    } else if (timeframe == 60 && !skip_m30) {
        return (30);
    } else if (timeframe == 60 && skip_m30) {
        return (15);
    } else if (timeframe == 240) {
        return (60);
    } else if (timeframe == 1440) {
        return (240);
    } else if (timeframe == 10080) {
        return (1440);
    } else if (timeframe == 43200) {
        return (10080);
    }
}


int _higher_timeframe(int timeframe, bool skip_m30 = true) {
    if (timeframe == 1) {
        return (5);
    } else if (timeframe == 5) {
        return (15);
    } else if (timeframe == 15 && !skip_m30) {
        return (30);
    } else if (timeframe == 15 && skip_m30) {
        return (60);
    } else if (timeframe == 30) {
        return (60);
    } else if (timeframe == 60) {
        return (240);
    } else if (timeframe == 240) {
        return (1440);
    } else if (timeframe == 1440) {
        return (10080);
    } else if (timeframe == 10080) {
        return (43200);
    } else if (timeframe == 43200) {
        return (43200);
    }
}


void make_text(string name, string text, int time, double price, int font_size, color font_color, int window = 0) {
    if (ObjectFind(name) == -1) {
        ObjectCreate(name, OBJ_TEXT, window, time, price);
    }
    ObjectSetText(name, text, font_size, "Tahoma", font_color);
}

void make_label(string name, string text, int font_size, color font_color, int corner, int x, int y, int window = 0, string font_type = "Cantarell", bool back = false) {
    if (ObjectFind(name) == -1) {
        ObjectCreate(name, OBJ_LABEL, window, 0, 0);
    }
    ObjectSet(name, OBJPROP_CORNER, corner);
    ObjectSet(name, OBJPROP_XDISTANCE, x);
    ObjectSet(name, OBJPROP_YDISTANCE, y);
    ObjectSet(name, OBJPROP_BACK, back);
    ObjectSetText(name, text, font_size, font_type, font_color);
}
