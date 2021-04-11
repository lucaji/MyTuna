//
//  UTHelpBarButtonItem.m
//  StartRec12
//
//  Created by Luca Cipressi on 08/09/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

#import "LJHelpSwitcherBarButton.h"
#import "LJHelpablePopoverViewController.h"

@implementation LJHelpSwitcherBarButton


-(void)awakeFromNib {
    [super awakeFromNib];
    [self setTarget:self];
    [self setAction:@selector(ownTap:)];
}

-(void)ownTap:(id)sender {
    BOOL oldMode = LJHelpablePopoverViewController.singleton.usingHelpMode;
    NSString*helpModeString = oldMode?@"Turns Help Off":@"Turns Help On";
    if (self.presenterVC)
        [LJHelpablePopoverViewController.singleton presentHelpPopoverViewControllerWithTitle:helpModeString withDescriptiveText:@"When the help mode is active, those user elements in the interface you can interact with, will be red colored and you will be able to read an helpful comment instead." withProcessBlock:^{
            LJHelpablePopoverViewController.singleton.usingHelpMode = !oldMode;
            self.tintColor = LJHelpablePopoverViewController.singleton.usingHelpMode?HELPHIGHLIGHTCOLOR_LITE:self.baseTintColor;
        } withAnchorViewOrBarButtonItem:sender fromPresenterVC:self.presenterVC];
}

@end
