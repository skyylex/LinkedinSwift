//
//  LinkedinOAuthWebClient.m
//  LinkedinSwift
//
//  Created by Li Jiantang on 29/08/2016.
//  Copyright © 2016 Carma. All rights reserved.
//

#import "LinkedinOAuthWebClient.h"

#import <IOSLinkedInAPIFix/LIALinkedInApplication.h>
#import <IOSLinkedInAPIFix/LIALinkedInHttpClient.h>

@implementation LinkedinOAuthWebClient


- (instancetype)initWithRedirectURL:(NSString*)redirectURL clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret state:(NSString*)state permissions:(NSArray*)permissions present:(UIViewController*)presentViewController {
    
    if (self = [super init]) {
        LIALinkedInApplication *application = [LIALinkedInApplication applicationWithRedirectURL:redirectURL clientId:clientId clientSecret:clientSecret state:state grantedAccess:permissions];
        httpClient = [LIALinkedInHttpClient clientForApplication:application presentingViewController:presentViewController];
    }
    
    return self;
}

- (void)authorizeSuccess:(__nullable LinkedinSwiftAuthRequestSuccessCallback)successCallback error:(__nullable LinkedinSwiftRequestErrorCallback)errorCallback cancel:(__nullable LinkedinSwiftRequestCancelCallback)cancelCallback {
    __block LinkedinOAuthWebClient *this = self;
    /**
     *  If Linkedin app is not installed, present a model webview to let use login
     *
     *  WARNING: here we can check the cache save api call as well,
     *  but there is a problem when you login on other devices the accessToken you cached will invalid,
     *  and only you use this will be notice this, so I choose don't use this cache
     */
    [httpClient getAuthorizationCode:^(NSString *code) {
        
        [this->httpClient getAccessToken:code success:^(NSDictionary *dictionary) {
            
            NSString *accessToken = [dictionary objectForKey:@"access_token"];
            NSNumber *expiresInSec = [dictionary objectForKey:@"expires_in"];
            
            LSLinkedinToken *token = [[LSLinkedinToken alloc] initWithAccessToken:accessToken expireDate:[NSDate dateWithTimeIntervalSinceNow:expiresInSec.doubleValue] fromMobileSDK: NO];
            successCallback(token);
        } failure:^(NSError *error) {
            errorCallback(error);
        }];
        
    } cancel:^{
        cancelCallback();
    } failure:^(NSError *error) {
        errorCallback(error);
    }];
}

- (void)requestURL:(NSString* _Nonnull)url requestType:(LinkedinSwiftRequestType* _Nonnull)requestType parameters:(NSDictionary *)parameters token:(LSLinkedinToken * _Nonnull)token success:(__nullable LinkedinSwiftRequestSuccessCallback)successCallback error:(__nullable LinkedinSwiftRequestErrorCallback)errorCallback {
    
    NSMutableDictionary *requestParameters = (parameters == nil) ? @{}.mutableCopy : parameters.mutableCopy;
    requestParameters[@"oauth2_access_token"] = token.accessToken;
    
    if ([requestType isEqualToString:LinkedinSwiftRequestGet]) {
        [httpClient GET:url parameters:requestParameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            successCallback([[LSResponse alloc] initWithDictionary:responseObject statusCode:200]);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            errorCallback(error);
        }];
    } else if ([requestType isEqualToString:LinkedinSwiftRequestPOST]) {
        [httpClient POST:url parameters:requestParameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            successCallback([[LSResponse alloc] initWithDictionary:responseObject statusCode:200]);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            errorCallback(error);
        }];
    } else {
        NSLog(@"LinkedinOAuthWebClient RequestURL Not supported");
    }
}

@end
