// Copyright 2021 alexju
#ifndef HEADER_H_
#define HEADER_H_

#import <Foundation/Foundation.h>

#include <napi.h>

typedef NS_ENUM(NSUInteger, MDQueryUpdateType) {
    MDQueryUpdateTypeAdd,
    MDQueryUpdateTypeChange,
    MDQueryUpdateTypeRemove,
};

class MDQuery : public Napi::ObjectWrap<MDQuery> {
  public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports);
    MDQuery(const Napi::CallbackInfo& info);
    
    void OnQueryFinished();
    void OnQueryUpdated(CFDictionaryRef updateInfo);
    
    ~MDQuery();

  private:
    MDQueryRef _queryRef;
    bool _stopped;
    
    void Start(const Napi::CallbackInfo &info);
    void Stop(const Napi::CallbackInfo &info);
    
    void Watch(const Napi::CallbackInfo &info);
    void StopWatch(const Napi::CallbackInfo &info);

    void StopQuery();
    
    // 第一次出结果的回调函数，是由Start传入的
    Napi::ThreadSafeFunction _queryResultCallback;
    
    // watch的回调函数
    Napi::ThreadSafeFunction _updateCallback;
};

#endif // NATIVE_ADDON_TEMPLATE_ADD_H_
