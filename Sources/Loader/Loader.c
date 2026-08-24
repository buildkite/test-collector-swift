#include "Loader.h"

__attribute__((constructor))
static void invokeLoadCollector() {
  loadCollector();
}
