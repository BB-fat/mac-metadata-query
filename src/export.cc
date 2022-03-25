// Copyright 2021 alexju
#include <napi.h>

#include "header.h"

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  MDQuery::Init(env, exports);
  return exports;
}

NODE_API_MODULE(NODE_GYP_MODULE_NAME, Init)
