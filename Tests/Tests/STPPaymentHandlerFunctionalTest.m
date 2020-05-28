//
//  STPPaymentHandlerFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import <OCMock/OCMock.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentHandlerFunctionalTest : XCTestCase <STPAuthenticationContext>
@property (nonatomic) id presentingViewController;
@end

@implementation STPPaymentHandlerFunctionalTest

- (void)setUp {
    self.presentingViewController = OCMClassMock([UIViewController class]);
    [STPAPIClient sharedClient].publishableKey = STPTestingDefaultPublishableKey;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testOpensAlipayURL {
    
    __block NSString *clientSecret = @"pi_1GiohpFY0qyl6XeWw09oKwWi_secret_Co4Etlq8YhmB6p07LQTP1Yklg";
//    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
//    NSDictionary *params = @{
//        @"currency": @"usd",
//        @"amount": @(2000),
//        @"payment_method_types": @[@"alipay"],
//        };
//    NSDictionary *params = @{
//        @"currency": @"usd",
//        @"amount": @(2000),
//        @"payment_method_types": @[@"alipay"],
//        @"confirm": @(YES),
////        @"payment_method_data[type]": @"alipay", // Error creating PaymentIntent: Invalid payment_method_data[type]: must be one of au_becs_debit, bancontact, card, eps, fpx, giropay, ideal, p24, or sepa_debit
//        @"payment_method_data": @{
//                @"type": @"alipay",
//        },
//        @"payment_method_options": @{
//                @"alipay": @{
//                        @"app_bundle_id": @"com.foo.bar",
//                        @"app_version_key": @"1.0",
//                },
//        },
//        @"return_url": @"foo://bar",
//    };
//    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:params
//                                                           completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
//        XCTAssertNotNil(createdClientSecret);
//        XCTAssertNil(creationError);
//        [createExpectation fulfill];
//        clientSecret = [createdClientSecret copy];
//    }];
//    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
//    XCTAssertNotNil(clientSecret);
    
    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);

    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@YES, nil])]).andDo(^(__unused NSInvocation *_) {
        // Simulate the Alipay app opening, followed by the user returning back to the app
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:UIApplicationWillEnterForegroundNotification object:nil]];
        });
    });
//    STPPaymentHandler *paymentHandler = OCMPartialMock([STPPaymentHandler sharedHandler]);
    
    // ...should not present anything
    OCMReject([self.presentingViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
    XCTestExpectation *e = [self expectationWithDescription:@""];
    
    STPPaymentIntentParams *confirmParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    confirmParams.paymentMethodOptions = [STPConfirmPaymentMethodOptions new];
    confirmParams.paymentMethodOptions.alipayOptions = [STPConfirmAlipayOptions new];
    confirmParams.paymentMethodParams = [STPPaymentMethodParams paramsWithAlipay:[STPPaymentMethodAlipayParams new] billingDetails:nil metadata:nil];
    [[STPPaymentHandler sharedHandler] confirmPayment:confirmParams withAuthenticationContext:self completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
        XCTAssertEqual(status, STPPaymentHandlerActionStatusFailed);
        // ...should attempt to open the native URL (ie the alipay app)
        NSString *url = paymentIntent.nextAction.redirectToURL.allResponseFields[@"mobile"][@"native_url"];
        OCMVerify([applicationMock openURL:[OCMArg isEqual:[NSURL URLWithString:url]]
                                   options:[OCMArg isEqual:@{}]
                         completionHandler:[OCMArg isNotNil]]);
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (UIViewController *)authenticationPresentingViewController {
    return self.presentingViewController;
}

@end
