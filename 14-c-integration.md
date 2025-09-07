# Chapter 14: C Integration

Io is implemented in C and provides excellent C integration capabilities. You can extend Io with C libraries, create high-performance addons, and embed Io in C applications. This chapter explores the bidirectional relationship between Io and C.

## Understanding Io's C Architecture

Io's core is a small C library (around 10,000 lines) that implements:

- The object model (IoObject)
- The message passing system
- Basic types (Number, String, List, etc.)
- The VM and garbage collector

Everything else is built on top of this foundation, either in C addons or pure Io.

## Creating a Simple C Addon

Let's create a basic C addon that adds a method to calculate factorials:

```c
// factorial.c
#include "IoState.h"
#include "IoObject.h"
#include "IoNumber.h"

IoObject *IoObject_factorial(IoObject *self, IoObject *locals, IoMessage *m)
{
    // Get the number from the receiver
    double n = IoNumber_asDouble(self);
    
    if (n < 0) {
        IoState_error_(IOSTATE, m, "factorial of negative number");
        return IONIL(self);
    }
    
    double result = 1;
    for (int i = 2; i <= n; i++) {
        result *= i;
    }
    
    return IoNumber_newWithDouble_(IOSTATE, result);
}

// Initialize the addon
void IoFactorial_init(IoState *state)
{
    IoObject *self = IoState_lobby(state);
    
    // Add method to Number prototype
    IoObject *number = IoState_protoWithName_(state, "Number");
    IoObject_addMethod_(number, 
        IOSYMBOL("factorial"), 
        IoObject_factorial);
}
```

To compile and use:

```bash
# Compile as shared library
gcc -shared -fPIC -o factorial.so factorial.c -lIo

# In Io
DynLib load("./factorial.so")
5 factorial println  // 120
```

## Working with Io Objects in C

```c
// Creating Io objects from C
IoObject *IoAddon_createObject(IoObject *self, IoObject *locals, IoMessage *m)
{
    IoState *state = IOSTATE;
    
    // Create different types
    IoObject *num = IoNumber_newWithDouble_(state, 42.0);
    IoObject *str = IoSeq_newWithCString_(state, "Hello from C");
    IoObject *list = IoList_new(state);
    
    // Add items to list
    IoList_append_(list, num);
    IoList_append_(list, str);
    
    // Create a new object with slots
    IoObject *obj = IoObject_new(state);
    IoObject_setSlot_to_(obj, IOSYMBOL("x"), num);
    IoObject_setSlot_to_(obj, IOSYMBOL("message"), str);
    IoObject_setSlot_to_(obj, IOSYMBOL("items"), list);
    
    return obj;
}

// Accessing Io objects from C
IoObject *IoAddon_processObject(IoObject *self, IoObject *locals, IoMessage *m)
{
    // Get the first argument
    IoObject *arg = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    // Check type
    if (ISSEQ(arg)) {
        char *cstr = IoSeq_asCString(arg);
        printf("String argument: %s\n", cstr);
    }
    else if (ISNUMBER(arg)) {
        double num = IoNumber_asDouble(arg);
        printf("Number argument: %f\n", num);
    }
    else if (ISLIST(arg)) {
        size_t size = IoList_size(arg);
        printf("List with %zu items\n", size);
    }
    
    return self;
}
```

## Creating Custom Types

```c
// customtype.c - Define a Point type
#include "IoState.h"
#include "IoObject.h"
#include "IoNumber.h"

// Define the type structure
typedef struct {
    IoObject obj;  // Must be first
    double x;
    double y;
} IoPoint;

// Type tag
IoTag *IoPoint_tag(void)
{
    static IoTag *tag = NULL;
    if (!tag) {
        tag = IoTag_newWithName_("Point");
    }
    return tag;
}

// Constructor
IoPoint *IoPoint_new(IoState *state, double x, double y)
{
    IoPoint *self = IoObject_new(state);
    IoObject_tag_(self, IoPoint_tag());
    
    self->x = x;
    self->y = y;
    
    return self;
}

// Methods
IoObject *IoPoint_x(IoPoint *self, IoObject *locals, IoMessage *m)
{
    return IoNumber_newWithDouble_(IOSTATE, self->x);
}

IoObject *IoPoint_y(IoPoint *self, IoObject *locals, IoMessage *m)
{
    return IoNumber_newWithDouble_(IOSTATE, self->y);
}

IoObject *IoPoint_distance(IoPoint *self, IoObject *locals, IoMessage *m)
{
    IoPoint *other = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    if (IoObject_tag(other) != IoPoint_tag()) {
        IoState_error_(IOSTATE, m, "argument must be a Point");
        return IONIL(self);
    }
    
    double dx = self->x - other->x;
    double dy = self->y - other->y;
    double distance = sqrt(dx*dx + dy*dy);
    
    return IoNumber_newWithDouble_(IOSTATE, distance);
}

// Initialize the type
void IoPoint_init(IoState *state)
{
    IoObject *self = IoState_lobby(state);
    
    // Create prototype
    IoPoint *proto = IoPoint_new(state, 0, 0);
    IoState_registerProtoWithName_(state, proto, "Point");
    
    // Add methods
    IoObject_addMethod_(proto, IOSYMBOL("x"), IoPoint_x);
    IoObject_addMethod_(proto, IOSYMBOL("y"), IoPoint_y);
    IoObject_addMethod_(proto, IOSYMBOL("distance"), IoPoint_distance);
}
```

## Calling Io from C

```c
// Evaluate Io code from C
IoObject *result = IoState_doString_(state, "1 + 2 * 3");
double value = IoNumber_asDouble(result);
printf("Result: %f\n", value);  // 7.0

// Call Io methods from C
IoObject *obj = IoState_doString_(state, "Object clone");
IoObject *method = IoObject_getSlot_(obj, IOSYMBOL("type"));
IoObject *result = IoObject_activate(method, obj, locals, m, NULL);
char *type = IoSeq_asCString(result);
printf("Type: %s\n", type);  // Object

// Send messages
IoMessage *msg = IoMessage_newWithName_(state, IOSYMBOL("println"));
IoMessage_setCachedResult_(msg, NULL);
IoObject *result = IoObject_perform(obj, locals, msg);
```

## Memory Management

Io uses a garbage collector, but when interfacing with C, you need to be careful:

```c
// Protecting objects from GC
IoObject *IoAddon_keepAlive(IoObject *self, IoObject *locals, IoMessage *m)
{
    IoState *state = IOSTATE;
    
    // Create object that needs to survive GC
    IoObject *important = IoObject_new(state);
    
    // Add reference from a persistent object
    IoObject_setSlot_to_(IoState_lobby(state), 
        IOSYMBOL("_keepAlive"), important);
    
    // Or use IoState_retain/release
    IoState_retain_(state, important);
    
    // Do work...
    
    // Release when done
    IoState_release_(state, important);
    
    return important;
}

// Managing C memory
typedef struct {
    IoObject obj;
    void *cdata;
} IoCWrapper;

void IoCWrapper_free(IoCWrapper *self)
{
    if (self->cdata) {
        free(self->cdata);
        self->cdata = NULL;
    }
}

// Set up finalizer
IoTag *tag = IoTag_newWithName_("CWrapper");
IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoCWrapper_free);
```

## Wrapping C Libraries

Example: Wrapping a simple math library:

```c
// mathlib_wrapper.c
#include <math.h>
#include "IoState.h"
#include "IoObject.h"
#include "IoNumber.h"
#include "IoList.h"

// Wrap sin function
IoObject *IoMath_sin(IoObject *self, IoObject *locals, IoMessage *m)
{
    double x = IoMessage_locals_doubleArgAt_(m, locals, 0);
    return IoNumber_newWithDouble_(IOSTATE, sin(x));
}

// Wrap complex function
IoObject *IoMath_stats(IoObject *self, IoObject *locals, IoMessage *m)
{
    IoList *list = IoMessage_locals_listArgAt_(m, locals, 0);
    size_t count = IoList_size(list);
    
    if (count == 0) {
        return IoList_new(IOSTATE);
    }
    
    double sum = 0, min = INFINITY, max = -INFINITY;
    
    for (size_t i = 0; i < count; i++) {
        IoObject *item = IoList_at_(list, i);
        double value = IoNumber_asDouble(item);
        
        sum += value;
        if (value < min) min = value;
        if (value > max) max = value;
    }
    
    double mean = sum / count;
    
    // Return statistics as list
    IoList *result = IoList_new(IOSTATE);
    IoList_append_(result, IoNumber_newWithDouble_(IOSTATE, mean));
    IoList_append_(result, IoNumber_newWithDouble_(IOSTATE, min));
    IoList_append_(result, IoNumber_newWithDouble_(IOSTATE, max));
    
    return result;
}

void IoMathLib_init(IoState *state)
{
    IoObject *math = IoObject_new(state);
    IoState_registerProtoWithName_(state, math, "Math");
    
    IoObject_addMethod_(math, IOSYMBOL("sin"), IoMath_sin);
    IoObject_addMethod_(math, IOSYMBOL("stats"), IoMath_stats);
}
```

Usage in Io:

```io
DynLib load("./mathlib.so")

Math sin(3.14159 / 2) println  // 1.0

stats := Math stats(list(1, 2, 3, 4, 5))
"Mean: " .. stats at(0) println  // Mean: 3
"Min: " .. stats at(1) println   // Min: 1
"Max: " .. stats at(2) println   // Max: 5
```

## Embedding Io in C Applications

```c
// embed_io.c - Embedding Io in a C application
#include <stdio.h>
#include "IoState.h"
#include "IoObject.h"
#include "IoSeq.h"

// Custom function exposed to Io
IoObject *App_log(IoObject *self, IoObject *locals, IoMessage *m)
{
    char *msg = IoMessage_locals_cStringArgAt_(m, locals, 0);
    printf("[APP LOG] %s\n", msg);
    return self;
}

int main(int argc, char *argv[])
{
    // Initialize Io
    IoState *state = IoState_new();
    IoState_init(state);
    
    // Add custom functions
    IoObject *lobby = IoState_lobby(state);
    IoObject *app = IoObject_new(state);
    IoState_registerProtoWithName_(state, app, "App");
    IoObject_addMethod_(app, IOSYMBOL("log"), App_log);
    
    // Load and run Io script
    IoState_doFile_(state, "script.io");
    
    // Interact with Io objects
    IoObject *result = IoState_doString_(state, 
        "x := 10; y := 20; x + y");
    printf("Result from Io: %f\n", IoNumber_asDouble(result));
    
    // Clean up
    IoState_free(state);
    
    return 0;
}
```

The Io script (script.io):

```io
App log("Hello from Io!")

// Define functions for C to call
calculate := method(a, b,
    App log("Calculating in Io")
    a * b + 100
)
```

## Performance Optimization

```c
// Optimized array operations
IoObject *IoArray_sum(IoObject *self, IoObject *locals, IoMessage *m)
{
    // Get underlying C array for performance
    UArray *array = IoSeq_rawUArray(self);
    size_t size = UArray_size(array);
    uint8_t *data = UArray_bytes(array);
    int itemSize = UArray_itemSize(array);
    
    double sum = 0;
    
    // Fast path for different types
    if (itemSize == sizeof(double)) {
        double *doubles = (double *)data;
        for (size_t i = 0; i < size; i++) {
            sum += doubles[i];
        }
    }
    else if (itemSize == sizeof(float)) {
        float *floats = (float *)data;
        for (size_t i = 0; i < size; i++) {
            sum += floats[i];
        }
    }
    
    return IoNumber_newWithDouble_(IOSTATE, sum);
}

// Batch operations
IoObject *IoMatrix_multiply(IoObject *self, IoObject *locals, IoMessage *m)
{
    IoObject *other = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    // Get dimensions
    int rows1 = IoMessage_locals_intArgAt_(m, locals, 1);
    int cols1 = IoMessage_locals_intArgAt_(m, locals, 2);
    int cols2 = IoMessage_locals_intArgAt_(m, locals, 3);
    
    // Get raw data pointers
    double *data1 = (double *)IoSeq_rawBytes(self);
    double *data2 = (double *)IoSeq_rawBytes(other);
    
    // Allocate result
    IoSeq *result = IoSeq_newWithData_length_(IOSTATE, 
        NULL, rows1 * cols2 * sizeof(double));
    double *resultData = (double *)IoSeq_rawBytes(result);
    
    // Optimized matrix multiplication
    for (int i = 0; i < rows1; i++) {
        for (int j = 0; j < cols2; j++) {
            double sum = 0;
            for (int k = 0; k < cols1; k++) {
                sum += data1[i * cols1 + k] * data2[k * cols2 + j];
            }
            resultData[i * cols2 + j] = sum;
        }
    }
    
    return result;
}
```

## Debugging C Addons

```c
// Debug helpers
#define IO_DEBUG 1

#ifdef IO_DEBUG
    #define DEBUG_PRINT(fmt, ...) \
        fprintf(stderr, "DEBUG: " fmt "\n", ##__VA_ARGS__)
#else
    #define DEBUG_PRINT(fmt, ...)
#endif

IoObject *IoDebug_function(IoObject *self, IoObject *locals, IoMessage *m)
{
    DEBUG_PRINT("Function called with %d arguments", 
        IoMessage_argCount(m));
    
    // Print argument types
    for (int i = 0; i < IoMessage_argCount(m); i++) {
        IoObject *arg = IoMessage_locals_valueArgAt_(m, locals, i);
        DEBUG_PRINT("  Arg %d: %s", i, IoObject_name(arg));
    }
    
    // Check for memory issues
    IoState *state = IOSTATE;
    IoState_check(state);
    
    return self;
}
```

## Common Integration Patterns

### Callback Pattern

```c
// Store Io blocks as callbacks
typedef struct {
    IoObject obj;
    IoObject *callback;
} IoCallbackWrapper;

IoObject *IoWrapper_setCallback(IoCallbackWrapper *self, 
    IoObject *locals, IoMessage *m)
{
    IoObject *block = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    // Retain the block
    IoState_retain_(IOSTATE, block);
    if (self->callback) {
        IoState_release_(IOSTATE, self->callback);
    }
    self->callback = block;
    
    return self;
}

// Call the Io callback from C
void triggerCallback(IoCallbackWrapper *wrapper, double value)
{
    if (wrapper->callback) {
        IoObject *arg = IoNumber_newWithDouble_(IOSTATE, value);
        IoObject_perform(wrapper->callback, wrapper, 
            IoMessage_newWithName_label_(IOSTATE, 
                IOSYMBOL("call"), arg));
    }
}
```

### Event System

```c
// Event emitter in C
typedef struct {
    IoObject obj;
    IoMap *handlers;  // Event name -> List of handlers
} IoEventEmitter;

IoObject *IoEventEmitter_on(IoEventEmitter *self, 
    IoObject *locals, IoMessage *m)
{
    IoSeq *event = IoMessage_locals_seqArgAt_(m, locals, 0);
    IoObject *handler = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    IoList *handlers = IoMap_at_(self->handlers, event);
    if (!handlers) {
        handlers = IoList_new(IOSTATE);
        IoMap_atPut_(self->handlers, event, handlers);
    }
    
    IoList_append_(handlers, handler);
    return self;
}

IoObject *IoEventEmitter_emit(IoEventEmitter *self, 
    IoObject *locals, IoMessage *m)
{
    IoSeq *event = IoMessage_locals_seqArgAt_(m, locals, 0);
    IoList *handlers = IoMap_at_(self->handlers, event);
    
    if (handlers) {
        size_t count = IoList_size(handlers);
        for (size_t i = 0; i < count; i++) {
            IoObject *handler = IoList_at_(handlers, i);
            
            // Pass remaining arguments to handler
            IoMessage *msg = IoMessage_newWithName_(IOSTATE, 
                IOSYMBOL("call"));
            for (int j = 1; j < IoMessage_argCount(m); j++) {
                IoMessage_addArg_(msg, IoMessage_argAt_(m, j));
            }
            
            IoObject_perform(handler, locals, msg);
        }
    }
    
    return self;
}
```

## Build System Integration

Makefile for Io addon:

```makefile
# Makefile for Io addon
CC = gcc
CFLAGS = -shared -fPIC -Wall -O2
INCLUDES = -I$(IO_HOME)/include
LIBS = -L$(IO_HOME)/lib -lIo

ADDON = myaddon.so
SOURCES = myaddon.c utils.c
OBJECTS = $(SOURCES:.c=.o)

all: $(ADDON)

$(ADDON): $(OBJECTS)
    $(CC) $(CFLAGS) -o $@ $^ $(LIBS)

%.o: %.c
    $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
    rm -f $(OBJECTS) $(ADDON)

install: $(ADDON)
    cp $(ADDON) $(IO_HOME)/addons/

test: $(ADDON)
    io test_addon.io
```

## Exercises

1. **SQLite Wrapper**: Create a complete SQLite wrapper for Io.

2. **Graphics Library**: Wrap SDL or Cairo for graphics programming.

3. **Network Addon**: Implement high-performance networking primitives.

4. **Crypto Library**: Wrap OpenSSL for cryptographic operations.

5. **Scientific Computing**: Create bindings for BLAS/LAPACK.

## Conclusion

C integration is one of Io's strongest features. The ability to seamlessly extend Io with C libraries, create high-performance addons, and embed Io in C applications makes it practical for real-world applications. The clean C API and simple object model make integration straightforward, while the garbage collector handles most memory management concerns.

Whether you're optimizing hot paths, wrapping existing libraries, or embedding a scripting language in your application, Io's C integration provides the tools you need while maintaining the simplicity and elegance of the language.

---

*Next: [Chapter 15 - Real-World Patterns](15-real-world-patterns.md)*