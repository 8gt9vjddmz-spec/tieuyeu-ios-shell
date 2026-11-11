// Cau noi JS <-> iOS cho game (tuong duong lop AppActivity / AppSdk cua ban Android).
// Ben Android, SDK la ban rong: quang cao / thanh toan / chia se khong lam gi.
// O day giu dung hanh vi do.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <string>
#include "cocos/bindings/jswrapper/SeApi.h"
#include "application/ApplicationManager.h"
#include "base/Scheduler.h"
#import "ViewController.h"

static void TYEvalJS(NSString *js) {
    std::string script = js.UTF8String ? js.UTF8String : "";
    dispatch_async(dispatch_get_main_queue(), ^{
        auto app = CC_CURRENT_APPLICATION();
        if (!app) return;
        auto engine = app->getEngine();
        if (!engine) return;
        engine->getScheduler()->performFunctionInCocosThread([script]() {
            se::AutoHandleScope hs;
            se::ScriptEngine::getInstance()->evalString(script.c_str());
        });
    });
}

// Gui su kien ve JS: GPlatform.fromNativeCall("<json da escape>")
static void TYSendEvent(NSDictionary *map) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:map options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    json = [json stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    json = [json stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    TYEvalJS([NSString stringWithFormat:@"GPlatform.fromNativeCall(\"%@\")", json]);
}

// Ma thiet bi dung lam ma nguoi choi. Uu tien file Documents/account.txt
// (de dung lai nhan vat cu), neu khong co thi tu sinh va luu lai.
static NSString *TYDeviceUuid(void) {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [docs stringByAppendingPathComponent:@"account.txt"];
    NSString *fromFile = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    fromFile = [fromFile stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (fromFile.length > 0) return fromFile;
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    NSString *uuid = [ud stringForKey:@"device_id"];
    if (uuid.length == 0) {
        uuid = NSUUID.UUID.UUIDString.lowercaseString;
        [ud setObject:uuid forKey:@"device_id"];
        [ud synchronize];
    }
    [uuid writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return uuid;
}

// Lop goc: moi phuong thuc lop chua khai bao deu duoc chap nhan va tra ve gia tri mac dinh.
@interface TYStubBase : NSObject
+ (NSString *)ty_defaultReturn;
@end

@implementation TYStubBase
+ (NSString *)ty_defaultReturn { return @""; }
+ (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig = [super methodSignatureForSelector:sel];
    if (sig) return sig;
    NSString *name = NSStringFromSelector(sel);
    NSMutableString *types = [NSMutableString stringWithString:@"@@:"];
    for (NSUInteger i = 0; i < name.length; i++) {
        if ([name characterAtIndex:i] == ':') [types appendString:@"@"];
    }
    return [NSMethodSignature signatureWithObjCTypes:types.UTF8String];
}
+ (void)forwardInvocation:(NSInvocation *)invocation {
    NSLog(@"[TY] stub %@.%@", NSStringFromClass(self), NSStringFromSelector(invocation.selector));
    __unsafe_unretained NSString *ret = [self ty_defaultReturn];
    [invocation setReturnValue:&ret];
}
@end

// Thong ke (analytics): ban choi offline khong gui di dau, nen de trong.
@interface CocosCreatorProxyApi : TYStubBase
@end
@implementation CocosCreatorProxyApi
@end

@interface AppGame : TYStubBase
@end

@implementation AppGame
+ (NSString *)ty_defaultReturn { return @"{}"; }

+ (NSString *)getGameConfig {
    NSDictionary *cfg = @{
        @"app_pkg_name": @"com.you912.fish.lucky",
        @"app_version": @"10.0.0.0",
        @"operation_plat": @"test",
        @"operation_channel": @"test",
        @"user_had_login": @"0",
        @"app_release_version": @"",
        @"appid": @"0",
        @"app_isLatest": @"1",
        @"is_SNAT": @"1",
        @"is_open200": @"1",
        @"ad_appid": @"",
        @"ad_id": @"",
        @"api_url": @"",
        @"report_url": @"",
        @"phone_info": UIDevice.currentDevice.model ?: @"iPhone",
        @"os_version": UIDevice.currentDevice.systemVersion ?: @"",
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:cfg options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

// Giong ban Android o che do "test login": gui lai su kien loginok cho JS.
+ (void)login {
    NSString *uid = TYDeviceUuid();
    TYSendEvent(@{
        @"name": @"loginok",
        @"action": @"login_verify",
        @"plat": @"",
        @"uid": uid,
        @"token": @"qq123456",
        @"acc": @"qq123456",
        @"passw": @"123456",
        @"reg": @"0",
        @"inviteid": @"",
    });
}

+ (void)loginout {
    // Android: SDK rong -> khong lam gi.
}

+ (void)setClipboardData:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIPasteboard.generalPasteboard.string = text ?: @"";
    });
}

+ (NSString *)consoleLog:(NSString *)json {
    NSLog(@"[TY-js] %@", json);
    return @"{}";
}

+ (NSString *)openPayUrl:(NSString *)json {
    NSData *d = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *o = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
    NSString *url = [o isKindOfClass:NSDictionary.class] ? o[@"url"] : nil;
    if ([url isKindOfClass:NSString.class] && url.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *u = [NSURL URLWithString:url];
            if (u) [UIApplication.sharedApplication openURL:u options:@{} completionHandler:nil];
        });
    }
    return @"{}";
}
@end

@interface ViewController (TYBridge)
@end
@implementation ViewController (TYBridge)
+ (void)openExternalBrowser:(NSString *)url {
    if (url.length == 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *u = [NSURL URLWithString:url];
        if (u) [UIApplication.sharedApplication openURL:u options:@{} completionHandler:nil];
    });
}
@end
