//
//  TCCodeScanner.m
//  SudiyiClient
//
//  Created by cdk on 15/5/4.
//  Copyright (c) 2015年 Sudiyi. All rights reserved.
//

#import "TCCodeScanner.h"

@import AVFoundation;


@interface TCCodeScanner () <AVCaptureMetadataOutputObjectsDelegate>
@end


@implementation TCCodeScanner
{
    @private
    NSSet *_codesInFOV;
    AVCaptureMetadataOutput *_metadataOutput;
}


- (void)dealloc
{
    [self teardownCaptureSession];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupCaptureSession];
    }
    return self;
}

+ (void)requestAccessAuthorized:(void (^)(BOOL granted))compelet
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (authStatus) {
        case AVAuthorizationStatusAuthorized: {
            if (nil != compelet) {
                compelet(YES);
            }
            break;
        }
            
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (nil != compelet) {
                    compelet(granted);
                }
            }];
            break;
        }
            
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:
        default:
            if (nil != compelet) {
                compelet(NO);
            }
            break;
    }
}

- (AVCaptureDevice *)captureDevice
{
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode
{
    _torchMode = torchMode;
    
    [self.captureDevice lockForConfiguration:NULL];
    
    if (self.captureDevice.isTorchAvailable) {
        self.captureDevice.torchMode = torchMode;
    }
    
    [self.captureDevice unlockForConfiguration];
}

- (BOOL)isTorchModeAvailable
{
    return self.captureDevice.isTorchAvailable;
}


#pragma mark - Capture Session

- (void)setupCaptureSession
{
    _session = [[AVCaptureSession alloc] init];
    
    [_session beginConfiguration];
//    _session.sessionPreset = AVCaptureSessionPreset640x480;
    
    NSError *inputError = nil;
    AVCaptureDeviceInput *cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&inputError];
    if (cameraInput) {
        if ([_session canAddInput:cameraInput]) {
            [_session addInput:cameraInput];
        }
        else {
            NSAssert(false, @"[%@] could not add capture device!", NSStringFromClass(self.class));
        }
    }
    else {
        NSAssert(false, @"[%@] could not create capture device: %@", NSStringFromClass(self.class), inputError);
    }
    
    AVCaptureMetadataOutput *metadata = [[AVCaptureMetadataOutput alloc] init];
    if ([_session canAddOutput:metadata]) {
        dispatch_queue_t metadataQueue = dispatch_queue_create("dake.TCKit.TCCodeScanner.metadata", DISPATCH_QUEUE_SERIAL);
        [metadata setMetadataObjectsDelegate:self queue:metadataQueue];
        if ([_session canAddOutput:metadata]) {
            [_session addOutput:metadata];
        }
        _metadataOutput = metadata;
    }
    else {
        NSAssert(false, @"[%@] could not create metadata output!", NSStringFromClass(self.class));
    }
    [_session commitConfiguration];
}

- (void)teardownCaptureSession
{
    [_session stopRunning];
    _session = nil;
    _metadataOutput = nil;
}


#pragma mark - capturing

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSSet *objectsStillLiving = [NSSet setWithArray:[metadataObjects valueForKeyPath:@"@distinctUnionOfObjects.stringValue"]];
    
    NSMutableSet *objectsAdded = [NSMutableSet setWithSet:objectsStillLiving];
    [objectsAdded minusSet:_codesInFOV];
    
    //	NSMutableSet *objectsUpdated = [NSMutableSet setWithSet:objectsStillLiving];
    //	[objectsUpdated intersectSet:self.codesInFOV];
    
    NSMutableSet *objectsMissing = [NSMutableSet setWithSet:_codesInFOV];
    [objectsMissing minusSet:objectsStillLiving];
    
    _codesInFOV = objectsStillLiving;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (objectsAdded.count > 0 && [self.delegate respondsToSelector:@selector(scanner:codesDidEnterFOV:)]) {
            [self.delegate scanner:self codesDidEnterFOV:[objectsAdded copy]];
        }
        //		if (objectsUpdated.count > 0 && [self.delegate respondsToSelector:@selector(scanner:codesDidUpdate:)]) {
        //			[self.delegate scanner:self codesDidUpdate:[objectsUpdated copy]];
        //		}
        if (objectsMissing.count > 0 && [self.delegate respondsToSelector:@selector(scanner:codesDidLeaveFOV:)]) {
            [self.delegate scanner:self codesDidLeaveFOV:[objectsMissing copy]];
        }
    });
}


- (BOOL)focusAtPoint:(CGPoint)point
{
    AVCaptureDevice *videoDevice = self.captureDevice;
    if ([videoDevice isFocusPointOfInterestSupported]
        && [videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *configurationError = nil;
        if ([videoDevice lockForConfiguration:&configurationError]) {
            [videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [videoDevice setFocusPointOfInterest:point];
            [videoDevice unlockForConfiguration];
            return YES;
        }
        else {
            NSAssert(false, @"[%@] Can not configure focus for input device: %@", NSStringFromClass(self.class), configurationError);
            return NO;
        }
    }
    else {
        return NO;
    }
}

- (BOOL)exposeAtPoint:(CGPoint)point
{
    AVCaptureDevice *videoDevice = self.captureDevice;
    if ([videoDevice isExposurePointOfInterestSupported]
        && [videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *configurationError = nil;
        if ([videoDevice lockForConfiguration:&configurationError]) {
            [videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [videoDevice setExposurePointOfInterest:point];
            [videoDevice unlockForConfiguration];
            return YES;
        }
        else {
            NSAssert(false, @"[%@] Can not configure exposure for input device: %@", NSStringFromClass(self.class), configurationError);
            return NO;
        }
    }
    else {
        return NO;
    }
}


@end
