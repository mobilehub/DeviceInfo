//
//  DeviceInfoAppDelegate.h
//  DeviceInfo
//
//  Created by Tang Xiaoping on 5/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DeviceInfoViewController;

@interface DeviceInfoAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet DeviceInfoViewController *viewController;

@end
