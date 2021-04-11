//
//  MTLogSlider.h
//  MyTuna
//
//  Created by Luca Cipressi on 12/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTLogSlider : UISlider {
    float _minimumValue;
    float _maximumValue;
}

@property (nonatomic) float sliderValue;

@end
