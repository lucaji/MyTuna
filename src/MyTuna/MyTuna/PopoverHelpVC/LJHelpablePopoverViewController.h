//
//  LJHelpablePopoverViewController.h
//  StartRec
//
//  Created by Luca Cipressi on 28/05/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

#import <UIKit/UIKit.h>

#define HELPHIGHLIGHTCOLOR_LITE1 [UIColor colorWithRed:1.0 green:0.8 blue:0.8 alpha:1.0]
#define HELPHIGHLIGHTCOLOR_DARK1 [UIColor colorWithRed:0.9 green:0.7 blue:0.7 alpha:1.0]

#define HELPHIGHLIGHTCOLOR_LITE2 [UIColor colorWithRed:0.99 green:0.25 blue:0.25 alpha:1.0]
#define HELPHIGHLIGHTCOLOR_DARK2 [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0]

#define HELPHIGHLIGHTCOLOR_LITE HELPHIGHLIGHTCOLOR_LITE2
#define HELPHIGHLIGHTCOLOR_DARK HELPHIGHLIGHTCOLOR_LITE2


extern NSString * const kUsingHelpModeKey;

@protocol LJHelpableElementProtocol

@property (nonatomic) IBInspectable UIColor* baseTintColor;
@property (nonatomic) IBInspectable NSString*helpTitle;
@property (nonatomic) IBInspectable NSString*helpMessage;

-(void)configureWithViewController:(UIViewController<UIPopoverPresentationControllerDelegate>*)owner withActionBlock:(dispatch_block_t)actionblock;

@end


//@protocol LJHelpablePopoverViewControllerDelegate <NSObject>
//-(void)lj_HelpablePopoverAboutButtonAction;
//@end
@interface LJHelpablePopoverViewController : UIViewController

@property (nonatomic) BOOL usingHelpMode;
//@property (nonatomic, weak) id<LJHelpablePopoverViewControllerDelegate>delegate;

+(instancetype)singleton;
-(void)presentHelpPopoverViewControllerWithTitle:(NSString*)title
                             withDescriptiveText:(NSString*)descr
                                withProcessBlock:(dispatch_block_t)blocko
                                  withAnchorViewOrBarButtonItem:(id)anchorView
                                 fromPresenterVC:(UIViewController<UIPopoverPresentationControllerDelegate>*)presenter;

@end
