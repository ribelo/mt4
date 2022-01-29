#pragma once

#include <inttypes.h>

#pragma pack(push,1)
typedef struct{
	unsigned int timestamp;
	double open;
	double high;
	double low;
	double close;
	unsigned int volume;
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
