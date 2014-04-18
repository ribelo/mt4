#pragma once

#include <inttypes.h>

#pragma pack(push,1)
typedef struct{
	uint64_t timestamp;
	double open;
	double high;
	double low;
	double close;
	uint64_t volume;
    int spread;
    uint64_t rvolume;;
} ohlc;
#pragma pack(pop)

typedef struct {
	int dir;
	double open;
	double close;
	int nr;
} body;

typedef struct{
	body v1;
	body v2;
	int type;
} zone;

typedef struct{
	int dir;
	body c1;
	body c2;
	zone zone;
} signal;
