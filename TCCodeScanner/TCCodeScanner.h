//
//  TCCodeScanner.h
//  SudiyiClient
//
//  Created by cdk on 15/5/4.
//  Copyright (c) 2015年 Sudiyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol TCCodeScannerDelegate;

NS_CLASS_AVAILABLE_IOS(7_0) @interface TCCodeScanner : NSObject

@property(nonatomic,weak) id<TCCodeScannerDelegate> delegate;

@property(nonatomic,strong,readonly) AVCaptureMetadataOutput *metadataOutput;

@property(nonatomic,assign) AVCaptureTorchMode torchMode;
@property(nonatomic,assign,readonly) BOOL isTorchModeAvailable;

@property(nonatomic,strong,readonly) AVCaptureSession *session;

+ (void)requestAccessAuthorized:(void (^)(BOOL granted))compelet;

- (BOOL)focusAtPoint:(CGPoint)point;
- (BOOL)exposeAtPoint:(CGPoint)point;


@end


@protocol TCCodeScannerDelegate <NSObject>

@optional
/**
 This method is called whenever a new code enters the field of view.
 
 @param	scanner	The scanner that is calling this delegate
 @param	codes	A list of all the codes that entered the FOV in this interval
 
 @note	If you do a simple scan for the first code you find, you can get the
 code from this method and close the scanner afterwards.
 */
- (void)scanner:(TCCodeScanner *)scanner codesDidEnterFOV:(NSSet *)codes;

//- (void)scanner:(BCScannerViewController *)scanner codesDidUpdate:(NSSet *)codes;

/**
 This method is called whenever an existing code leaves the field of view.
 
 @param	scanner	The scanner that is calling this delegate
 @param	codes	A list of all the codes that left the FOV in this interval
 */
- (void)scanner:(TCCodeScanner *)scanner codesDidLeaveFOV:(NSSet *)codes;


@end