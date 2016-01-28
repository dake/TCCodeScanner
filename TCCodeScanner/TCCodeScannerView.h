//
//  TCCodeScannerView.h
//  TCKit
//
//  Created by dake on 15/5/4.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCCodeScanner.h"

@interface TCCodeScannerView : UIView

@property (nonatomic, strong, readonly) TCCodeScanner *scanner;
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;

// must be set after viewDidLayout
@property (nonatomic, assign) CGRect scannerArea;

- (void)start;
- (void)stop;

@end
