// Copyright 2022 alexju
#include "header.h"
#include <string>

typedef NSDictionary<NSString *, id> * MDItemAttributes;

// 处理结果时需要用到的字段列表
CFStringRef mdItemKeys[] = {kMDItemContentType, kMDItemPath, kMDItemFSCreationDate, kMDItemContentModificationDate, kMDItemLastUsedDate, kMDItemCFBundleIdentifier, kMDItemVersion};
int mdItemKeysCount = sizeof(mdItemKeys) / sizeof(mdItemKeys[0]);

bool parseMDItemJs(Napi::Object obj, MDItemAttributes attributes) {
    NSString *contentType = [attributes valueForKey:NSMetadataItemContentTypeKey];
    obj.Set("isDir", [contentType isEqualToString:@"public.folder"]);
    
    NSString *path = [attributes valueForKey:NSMetadataItemPathKey];
    if (!path) {
        return false;
    }
    obj.Set("path", [path UTF8String]);
    obj.Set("extension", [[path pathExtension] UTF8String]);
    
    NSDate *createDate = [attributes valueForKey:NSMetadataItemFSCreationDateKey];
    if (createDate) {
        obj.Set("createTime", [createDate timeIntervalSince1970]);
    }
    
    NSDate *lastModifyDate = [attributes valueForKey:NSMetadataItemContentModificationDateKey];
    if (lastModifyDate) {
        obj.Set("lastModifyTime", [lastModifyDate timeIntervalSince1970]);
    }
    
    NSDate *lastUsedDate = [attributes valueForKey:NSMetadataItemLastUsedDateKey];
    if (lastUsedDate) {
        obj.Set("lastUsedTime", [lastUsedDate timeIntervalSince1970]);
    }
    
    NSString *bundleIdentifier = [attributes valueForKey:NSMetadataItemCFBundleIdentifierKey];
    if (bundleIdentifier) {
        obj.Set("bundleIdentifier", [bundleIdentifier UTF8String]);
    }
    
    NSString *version = [attributes valueForKey:NSMetadataItemVersionKey];
    if (version) {
        obj.Set("version", [version UTF8String]);
    }
    
    return true;
}

Napi::Object MDQuery::Init(Napi::Env env, Napi::Object exports) {
    Napi::Function func = DefineClass(env, "MDQuery", {
        InstanceMethod<&MDQuery::Start>("start", static_cast<napi_property_attributes>(napi_writable | napi_configurable)),
        InstanceMethod<&MDQuery::Watch>("watch", static_cast<napi_property_attributes>(napi_writable | napi_configurable)),
        InstanceMethod<&MDQuery::StopWatch>("stopWatch", static_cast<napi_property_attributes>(napi_writable | napi_configurable)),
        InstanceMethod<&MDQuery::Stop>("stop", static_cast<napi_property_attributes>(napi_writable | napi_configurable)),
    });
    Napi::FunctionReference* constructor = new Napi::FunctionReference();
    *constructor = Napi::Persistent(func);
    exports.Set("MDQuery", func);
    env.SetInstanceData<Napi::FunctionReference>(constructor);

    return exports;
}

void onMDQueryFinished(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
    auto queryObj = static_cast<MDQuery *>(observer);
    queryObj->OnQueryFinished();
}

void onMDQueryUpdated(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
    auto queryObj = static_cast<MDQuery *>(observer);
    queryObj->OnQueryUpdated(CFDictionaryCreateCopy(NULL, userInfo));
}

#pragma mark -

MDQuery::MDQuery(const Napi::CallbackInfo& info) : Napi::ObjectWrap<MDQuery>(info) {
    Napi::Env env = info.Env();

    if (info.Length() < 3) {
        Napi::TypeError::New(env, "MDQuery constructor need 4 args.").ThrowAsJavaScriptException();
        return;
    }
    
    _stopped = false;

    // parse args start
    std::string query_js = info[0].As<Napi::String>();
    NSString *query = [NSString stringWithUTF8String:query_js.c_str()];

    auto scopes_js = info[1].As<Napi::Array>();
    NSMutableArray<NSString *> *scopes = [NSMutableArray array];
    for (uint32_t i = 0; i < scopes_js.Length(); i++) {
        std::string scope = scopes_js.Get(i).As<Napi::String>();
        if (scope.empty()) {
            Napi::TypeError::New(env, "Empty scope is not allowed")
                .ThrowAsJavaScriptException();
            return;
        }
        [scopes addObject:[NSString stringWithUTF8String:scope.c_str()]];
    }

    auto maxResultCount = info[2].As<Napi::Number>().Int64Value();
    // parse args end

    // set MDQuery start
    _queryRef = MDQueryCreate(NULL, (__bridge CFStringRef)query, NULL, NULL);
    if (!_queryRef) {
        Napi::TypeError::New(env, "Create MDQueryRef failed.").ThrowAsJavaScriptException();
        return;
    }
    MDQuerySetSearchScope(_queryRef, (__bridge CFArrayRef)scopes, 0);
    if (maxResultCount > 0) {
        MDQuerySetMaxCount(_queryRef, maxResultCount);
    }
    
    auto localNotifyCenter = CFNotificationCenterGetLocalCenter();
    CFNotificationCenterAddObserver(localNotifyCenter, this, &onMDQueryFinished, kMDQueryDidFinishNotification, _queryRef, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(localNotifyCenter, this, &onMDQueryUpdated, kMDQueryDidUpdateNotification, _queryRef, CFNotificationSuspensionBehaviorDeliverImmediately);
    // set MDQuery end
}

void MDQuery::Start(const Napi::CallbackInfo& info) {
    auto env = info.Env();

    if (info.Length() < 1) {
        Napi::TypeError::New(env, "MDQuery start needs callback.").ThrowAsJavaScriptException();
    }
    
    if (_queryResultCallback) {
        _queryResultCallback.Release();
        _queryResultCallback = NULL;
    }
    _queryResultCallback = Napi::ThreadSafeFunction::New(env, info[0].As<Napi::Function>(), "queryResultCallback", 0, 1);
    
    bool success = MDQueryExecute(_queryRef, kMDQueryWantsUpdates|kMDQueryAllowFSTranslation);
    if (!success) {
        Napi::TypeError::New(env, "MDQuery execute failed.").ThrowAsJavaScriptException();
        return;
    }
    
    MDQueryEnableUpdates(_queryRef);
}

void MDQuery::Watch(const Napi::CallbackInfo &info) {
    auto env = info.Env();

    if (info.Length() < 1) {
        Napi::TypeError::New(env, "MDQuery watch needs callback.").ThrowAsJavaScriptException();
    }
    
    if (_updateCallback) {
        _updateCallback.Release();
        _updateCallback = NULL;
    }
    _updateCallback = Napi::ThreadSafeFunction::New(env, info[0].As<Napi::Function>(), "updateCallback", 0, 1);
}

void MDQuery::StopWatch(const Napi::CallbackInfo &info) {
    if (_updateCallback) {
        _updateCallback.Release();
        _updateCallback = NULL;
    }
}

void MDQuery::Stop(const Napi::CallbackInfo& info) {
    this->StopQuery();
}

void MDQuery::StopQuery() {
    if (_queryRef) {
        MDQueryDisableUpdates(_queryRef);
        MDQueryStop(_queryRef);
    }
    _stopped = true;
}

#pragma mark -

// 在node回调start传进来的callback
void callbackQueryResult(Napi::Env env, Napi::Function callback, NSArray<MDItemAttributes> *mdItemAttributesArray) {
    auto array = Napi::Array::New(env);
    uint32_t arrayIdx = 0;
    
    for (NSUInteger i = 0; i < mdItemAttributesArray.count; i++) {
        Napi::HandleScope scope(env);
        auto jsMDItem = Napi::Object::New(env);
        bool valid = parseMDItemJs(jsMDItem, mdItemAttributesArray[i]);
        if (valid) {
            array.Set((uint32_t)arrayIdx++, jsMDItem);
        }
    }

    callback.Call({array});
}

void MDQuery::OnQueryFinished() {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!_queryResultCallback) {
            return;
        }
        
        // 从query读数据的时候需要关掉update
        MDQueryDisableUpdates(_queryRef);
        
        CFIndex resultCount = MDQueryGetResultCount(_queryRef);
        
        MDItemRef items[resultCount];
        for (long i = 0; i < resultCount; i++) {
            items[i] = (MDItemRef)MDQueryGetResultAtIndex(_queryRef, i);
        }
        CFArrayRef mdItemArray = CFArrayCreate(NULL, (const void **)items, resultCount, NULL);
        
        auto keyArray = CFArrayCreate(NULL, (const void **)mdItemKeys, mdItemKeysCount, NULL);
        
        auto mdItemAttributesArray = (__bridge_transfer NSArray *)MDItemsCopyAttributes(mdItemArray, keyArray);
        
        MDQueryEnableUpdates(_queryRef);
        
        CFRelease(mdItemArray);
        CFRelease(keyArray);
        
        if (!_stopped) {
            _queryResultCallback.BlockingCall(mdItemAttributesArray, &callbackQueryResult);
        }
    });
}

#pragma mark - Update

typedef struct UpdateCallbackInfo {
    MDQueryUpdateType type;
    NSArray<MDItemAttributes> *attributesArray;
} UpdateCallbackInfo;

// 在node回调watch传进来的callback
void callbackUpdate(Napi::Env env, Napi::Function callback, UpdateCallbackInfo *info) {
    CFIndex count = info->attributesArray.count;
    if (count > 0) {
        auto array = Napi::Array::New(env);
        uint32_t arrayIdx = 0;
        
        for (long i = 0; i < count; i++) {
            Napi::HandleScope scope(env);
            auto attributes = info->attributesArray[i];
            auto obj = Napi::Object::New(env);
            bool valid = parseMDItemJs(obj, attributes);
            if (valid) {
                array.Set((uint32_t)arrayIdx++, obj);
            }
        }
        callback.Call({Napi::Number::New(env, info->type), array});
    }
    
    delete info;
}

inline void callbackUpdateForType(CFDictionaryRef updateInfo, MDQueryUpdateType type, CFStringRef key, Napi::ThreadSafeFunction callback) {
    CFArrayRef items = (CFArrayRef)CFDictionaryGetValue(updateInfo, key);
    if (items) {
        CFIndex count = CFArrayGetCount(items);
        auto attributesArray = CFArrayCreateMutable(NULL, count, NULL);
        for (long i = 0; i < count; i++) {
            auto mdItem = (MDItemRef)CFArrayGetValueAtIndex(items, i);
            auto keyArray = CFArrayCreate(NULL, (const void **)mdItemKeys, mdItemKeysCount, NULL);
            auto attributes = MDItemCopyAttributes(mdItem, keyArray);
            CFRelease(keyArray);
            CFArraySetValueAtIndex(attributesArray, i, attributes);
        }
        UpdateCallbackInfo *info = new UpdateCallbackInfo;
        info->type = type;
        info->attributesArray = CFBridgingRelease(attributesArray);
        
        callback.BlockingCall(info, &callbackUpdate);
    }
}

void MDQuery::OnQueryUpdated(CFDictionaryRef updateInfo) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!_updateCallback) {
            return;
        }
        
        callbackUpdateForType(updateInfo, MDQueryUpdateTypeAdd, kMDQueryUpdateAddedItems, _updateCallback);
        callbackUpdateForType(updateInfo, MDQueryUpdateTypeChange, kMDQueryUpdateChangedItems, _updateCallback);
        callbackUpdateForType(updateInfo, MDQueryUpdateTypeRemove, kMDQueryUpdateRemovedItems, _updateCallback);
        
        CFRelease(updateInfo);
    });
}

#pragma mark -

MDQuery::~MDQuery() {
    if (_queryRef) {
        auto localCenter = CFNotificationCenterGetLocalCenter();
        CFNotificationCenterRemoveObserver(localCenter, this, kMDQueryDidFinishNotification, _queryRef);
        CFNotificationCenterRemoveObserver(localCenter, this, kMDQueryDidUpdateNotification, _queryRef);
    }
    
    this->StopQuery();
    if (_queryRef) {
        CFRelease(_queryRef);
        _queryRef = NULL;
    }
    
    if (_queryResultCallback) {
        _queryResultCallback.Release();
        _queryResultCallback = NULL;
    }
    if (_updateCallback) {
        _updateCallback.Release();
        _updateCallback = NULL;
    }
}
