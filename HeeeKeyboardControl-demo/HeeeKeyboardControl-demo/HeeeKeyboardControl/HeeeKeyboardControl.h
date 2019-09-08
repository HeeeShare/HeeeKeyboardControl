//
//  HeeeKeyboardControl.h
//  HeeeKeyboardControl
//
//  Created by hgy on 2018/7/16.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HeeeKeyboardControl;

@protocol HeeeKeyboardControlDelegate <NSObject>
@optional
- (void)keyboardControl:(HeeeKeyboardControl *)keyboardControl willSelectInputView:(UIView *)inputView;
- (void)keyboardControl:(HeeeKeyboardControl *)keyboardControl pressDoneButtonWithInputView:(UIView *)inputView;

@end

@interface HeeeKeyboardControl : NSObject
@property (nonatomic,assign) CGFloat basicGap;//inputView底部距离键盘顶部的间距
@property (nonatomic,strong) UIColor *color;//控件按钮的颜色设置
@property (nonatomic,assign) BOOL isEnStyle;//中英文设置，默认中文

/**
 生成键盘控制的类方法
 
 @param inputViewArr 需要传入包含所有inputView的数组
 @param inputBackView 所有inputView的载体view，让选中的inputView始终可见，如果为nil，就没有此功能
 @param delegate 不能为空
 @return 返回的实例可以设置中英文、颜色、代理和间距
 */
+ (HeeeKeyboardControl *)makeControlWithInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView andDelegate:(nonnull id)delegate;

@end

NS_ASSUME_NONNULL_END

