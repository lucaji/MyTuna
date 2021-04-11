//
//  RTHelpableButton.h
//  StartRec
//
//  Created by Luca Cipressi on 19/08/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LJHelpablePopoverViewController.h"

@interface LJHelpableButton : UIButton
<LJHelpableElementProtocol>

@property (nonatomic) IBInspectable UIColor* baseTintColor;
@property (nonatomic) IBInspectable NSString*helpTitle;
@property (nonatomic) IBInspectable NSString*helpMessage;


-(void)configureWithViewController:(UIViewController<UIPopoverPresentationControllerDelegate>*)owner withActionBlock:(dispatch_block_t)actionblock;

@end


