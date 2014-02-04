CC=w32-clang -wc-use-mingw-linker
#CC=i686-w64-mingw32-gcc
LINK=-L/usr/lib
INCLUDE=-I/usr/include
GSL=-lgsl -lgslcblas -lm
CFLAGS=-Wall -O3 --std=gnu99 -ffast-math -funroll-loops -march=x86-64
LFLAGS=-Wl,--enable-stdcall-fixup

ALL: ./experts/libraries/wrb_analysis.dll \
	 ./experts/libraries/gsl_math.dll

./experts/libraries/wrb_analysis.dll: ./src/wrb_export.o ./wrb_analysis.def
	$(CC) $(LFLAGS) $(LINK) $(INCLUDE) -shared -static $(CFLAGS) -o \
	./experts/libraries/wrb_analysis.dll \
	./src/wrb_export.c ./src/wrb_zone.c ./src/wrb_ajctr.c \
	./src/wrb_management.c ./src/wrb_apaor.c ./src/wrb_fvb.c \
	./src/wrb_vtr.c  \
	./wrb_analysis.def $(GSL)

./experts/libraries/gsl_math.dll: ./src/gsl_math.o
	$(CC) $(LFLAGS) $(LINK) $(INCLUDE) -shared -static $(CFLAGS) -o \
	./experts/libraries/gsl_math.dll \
	./src/gsl_math.c ./gsl_math.def $(GSL)

# ./src/gsl_math.o: ./src/gsl_math.c
# 	$(CC) -lm $(LINK) $(INCLUDE) $(CFLAGS) -c ./src/gsl_math.c \
# 	-o ./src/gsl_math.o

# ./src/wrb_export.o: ./src/wrb_zone.o ./src/wrb_ajctr.o ./src/wrb_apaor.o \
# 	                ./src/wrb_fvb.o ./src/wrb_vtr.o
# 	$(CC) $(LINK) $(INCLUDE) $(CFLAGS) -c ./src/wrb_export.c \
# 	-o ./src/wrb_export.o

# ./src/wrb_vtr.o: ./src/wrb_vtr.c
# 	$(CC) $(LINK) $(INCLUDE) $(CFLAGS) -c ./src/wrb_vtr.c \
# 	-o ./src/wrb_vtr.o

# ./src/wrb_fvb.o: ./src/wrb_fvb.c
# 	$(CC) $(LINK) $(INCLUDE) $(CFLAGS) -c ./src/wrb_fvb.c \
# 	-o ./src/wrb_fvb.o

# ./src/wrb_apaor.o: ./src/wrb_apaor.c
# 	$(CC) $(LINK) $(INCLUDE) $(CFLAGS) -c ./src/wrb_apaor.c \
# 	-o ./src/wrb_apaor.o

# ./src/wrb_ajctr.o: ./src/wrb_ajctr.c
# 	$(CC) $(LINK) $(INCLUDE) $(CFLAGS) -c ./src/wrb_ajctr.c \
# 	-o ./src/wrb_ajctr.o

# ./src/wrb_zone.o: ./src/wrb_zone.c
# 	$(CC) $(LINK) $(INCLUDE) $(CFLAGS) -c ./src/wrb_zone.c \
# 	-o ./src/wrb_zone.o
