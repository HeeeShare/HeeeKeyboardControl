//
//  HeeeKeyboardControl.h
//  HeeeKeyboardControl
//
//  Created by hgy on 2018/7/16.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HeeeKeyboardControl;

@protocol HeeeKeyboardControlDelegate <NSObject>
@optional
- (void)keyboardControl:(HeeeKeyboardControl *)keyboardControl didSelectInputView:(UIView *)inputView;
- (void)keyboardControl:(HeeeKeyboardControl *)keyboardControl pressDoneButtonWithInputView:(UIView *)inputView;

@end

@interface HeeeKeyboardControl : NSObject
/**
 生成键盘控制的类方法
 
 @param inputViewArr 需要传入包含所有inputView的数组
 @param inputBackView 所有inputView的载体view(不要求输入框在同一个父view上)
 @return 返回的实例可以设置中英文、颜色、代理和间距
 */
+ (HeeeKeyboardControl *)makeControlWithInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView;

@property (nonatomic,assign) CGFloat basicGap;//inputView底部距离键盘顶部的间距，默认12
@property (nonatomic,strong) UIColor *color;//控件按钮的颜色设置
@property (nonatomic,assign) BOOL isEnStyle;//中英文设置，默认中文
@property (nonatomic,weak) id <HeeeKeyboardControlDelegate> delegate;

@end

