#pragma once
#include "pd_api.h"

int pd_rand(void);
void pd_srand(unsigned int seed);

int formatStringFloat(PlaydateAPI p, char **outstring, float number) {
    return p.system->formatString(outstring, "%f", number);
}

int formatStringDouble(PlaydateAPI p, char **outstring, double number) {
    return p.system->formatString(outstring, "%lf", number);
}
