#if defined(__FreeBSD__)
#include <sys/types.h>
#include <sys/endian.h>
#define htonll(x) bswap64(x)
#define ntohll(x) bswap64(x)
#endif

#if defined(__linux__)

// FUCK LINUX!

#  include <stdint.h>
#  include <sys/param.h>

#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__

#define htonll(x) ((uint64_t) x)
#define ntohll(x) ((uint64_t) x)

#else

#  include <arpa/inet.h>
#define htonll(x) ((((uint64_t)htonl(x)) << 32) + htonl(x >> 32))
#define ntohll(x) ((((uint64_t)ntohl(x)) << 32) + ntohl(x >> 32))

#endif // __BYTE_ORDER == __BIG_ENDIAN

/* On modern Os X'es (>= 10.10) htonll is defined in machine/endian.h, but on older it is missing */
#elif defined(__APPLE__) && !defined(htonll)
#  include <libkern/OSByteOrder.h>
#  define htonll(v) OSSwapHostToBigInt64(v)
#  define ntohll(v) OSSwapBigToHostInt64(v)
#elif defined(SOLARIS)
#  include <sys/byteorder.h>
#endif

#define CERTAIN 1.0

typedef struct {
  double value;
  double confidence;
} ffloat;

#define DDB_ZERO   htonll(0x0100000000000000LL)
#define DDB_UNSET  htonll(0x0000000000000000LL)
#define TYPE_MASK         0xFF00000000000000LL
#define VALUE_MASK        0x00FFFFFFFFFFFFFFLL
#define VALUE_SIGN_MASK   0x0080000000000000LL
#define EMPTY_TYPE   0
#define INTEGER_TYPE 0x01
#define DECIMAL_TYPE 0x02
#define TYPE(v) (uint8_t)((ntohll(v) & TYPE_MASK) >> 56)
#define IS_SET(v) (TYPE(v) != EMPTY_TYPE)
#define FROM_DDB(v) float_deserialize(v)
#define TO_DDB(v) float_serialize(v)
#define TO_DDB_INT(v) ((ntohll(v) & 0xFFFFFFFFFFFFFF00LL) | 0x0000000000000001LL)


#define GET_CHUNK(chunk)                                                \
  if (!enif_get_int64(env, argv[1], &chunk))                            \
    return enif_make_badarg(env);                                       \
  if (chunk < 1)                                                        \
    return enif_make_badarg(env);

#define GET_BIN(pos, bin, count, vs)              \
  if (!enif_inspect_binary(env, argv[pos], &bin)) \
    return enif_make_badarg(env);                 \
  if (bin.size % sizeof(__typeof__(*vs)))         \
    return enif_make_badarg(env);                 \
  count = bin.size / sizeof(__typeof__(*vs));     \
  vs = (__typeof__(vs)) bin.data;


ErlNifSInt64 float_serialize(ffloat f);
ffloat float_deserialize(ErlNifSInt64 v);

ffloat float_from_int64(int64_t v);
ffloat float_from_double(double v);
ffloat float_from_binary(int len, char* str);

ffloat float_mul(ffloat a, ffloat b);
ffloat float_mul3(ffloat a, ffloat b, ffloat c);
ffloat float_mulc(ffloat v, double c);

ffloat float_div(ffloat a, ffloat b);
ffloat float_div3(ffloat a, ffloat b, ffloat c);
ffloat float_divc(ffloat v, double c);

ffloat float_sub(ffloat a, ffloat b);
ffloat float_sub3(ffloat a, ffloat b, ffloat c);
ffloat float_subc(ffloat a, double c);

ffloat float_add(ffloat a, ffloat b);
ffloat float_add3(ffloat a, ffloat b, ffloat c);
ffloat float_addc(ffloat a, double c);

ffloat float_min(ffloat a, ffloat b);
ffloat float_min3(ffloat a, ffloat b, ffloat c);
ffloat float_maxc(ffloat v, double c);

ffloat float_max(ffloat a, ffloat b);
ffloat float_max3(ffloat a, ffloat b, ffloat c);
ffloat float_minc(ffloat v, double c);

ffloat float_const(ffloat a, double b);
