//
//  HeeeKeyboardControl.m
//  HeeeKeyboardControl
//
//  Created by hgy on 2018/7/16.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import "HeeeKeyboardControl.h"
#import <objc/message.h>

@interface HeeeKeyboardControl()
@property (nonatomic,strong) NSMutableArray *inputViewArr;
@property (nonatomic,weak) UIView *inputBackView;//所有inputView的总父view
@property (nonatomic,strong) UIVisualEffectView *effectView;//背景view
@property (nonatomic,strong) UIButton *previousBtn;
@property (nonatomic,strong) UIButton *nextBtn;
@property (nonatomic,strong) UIButton *doneBtn;
@property (nonatomic,assign) CGRect backViewOriginalFrame;//inputBackView的初始frame
@property (nonatomic,assign) CGFloat keyBoardTop;//键盘的y坐标
@property (nonatomic,assign) CGFloat inputViewKeyBoardGap;//inputView与键盘顶部的间隙
@property (nonatomic,strong) UIView *selectedInputView;//选中的UITextView

@end

@implementation HeeeKeyboardControl
+ (HeeeKeyboardControl *)makeControlWithInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView {
    if(inputViewArr.count == 0 || inputBackView == nil) return nil;
    return [[HeeeKeyboardControl alloc] initWithInputViews:inputViewArr inputBackView:inputBackView];
}

- (instancetype)initWithInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView {
    self = [super init];
    if (self) {
        _basicGap = 20;
        _color = [UIColor colorWithRed:27/255.0 green:133/255.0 blue:250/255.0 alpha:1.0];
        [self handleInputViews:inputViewArr inputBackView:inputBackView];
    }
    
    return self;
}

- (void)handleInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView {
    if (inputBackView) {
        objc_setAssociatedObject(inputBackView, @"heeeKeyboardControl_AO", self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    _inputViewArr = [NSMutableArray array];
    _inputBackView = inputBackView;
    _backViewOriginalFrame = _inputBackView.frame;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [self setIsEnStyle:_isEnStyle];
    
    for (UIView *view in inputViewArr) {
        if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]]) {
            [_inputViewArr addObject:view];
            [(UITextField *)view setInputAccessoryView:_effectView];
        }
    }
}

- (void)previous {
    NSInteger currentIndex = [self.inputViewArr indexOfObject:self.selectedInputView];
    UIView *inputView = self.inputViewArr[currentIndex - 1];
    [self handleButtonsWithInputView:inputView];
    [inputView becomeFirstResponder];
}

- (void)next {
    NSInteger currentIndex = [self.inputViewArr indexOfObject:self.selectedInputView];
    UIView *inputView = self.inputViewArr[currentIndex + 1];
    [self handleButtonsWithInputView:inputView];
    [inputView becomeFirstResponder];
}

- (void)done {
    if (_delegate && [_delegate respondsToSelector:@selector(keyboardControl:pressDoneButtonWithInputView:)]) {
        [_delegate keyboardControl:self pressDoneButtonWithInputView:_selectedInputView];
    }
    
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    self.previousBtn.layer.borderColor = color.CGColor;
    [self.previousBtn setTitleColor:color forState:(UIControlStateNormal)];
    self.nextBtn.layer.borderColor = color.CGColor;
    [self.nextBtn setTitleColor:color forState:(UIControlStateNormal)];
    self.doneBtn.layer.borderColor = color.CGColor;
    [self.doneBtn setTitleColor:color forState:(UIControlStateNormal)];
}

- (void)setIsEnStyle:(BOOL)isEnStyle {
    _isEnStyle = isEnStyle;
    
    if (isEnStyle) {
        [self.previousBtn setTitle:@"Previous" forState:(UIControlStateNormal)];
        [self.nextBtn setTitle:@"Next" forState:(UIControlStateNormal)];
        [self.doneBtn setTitle:@"Done" forState:(UIControlStateNormal)];
    }else{
        [self.previousBtn setTitle:@"上一个" forState:(UIControlStateNormal)];
        [self.nextBtn setTitle:@"下一个" forState:(UIControlStateNormal)];
        [self.doneBtn setTitle:@"完成" forState:(UIControlStateNormal)];
    }
    
    [self.previousBtn sizeToFit];
    [self.nextBtn sizeToFit];
    [self.doneBtn sizeToFit];
    self.previousBtn.frame = CGRectMake(10, 7, self.previousBtn.bounds.size.width, 30);
    self.nextBtn.frame = CGRectMake(self.previousBtn.frame.origin.x + _previousBtn.bounds.size.width + 20, 7, 60, 30);
    self.doneBtn.frame = CGRectMake(self.effectView.frame.size.width - 60, 7, 50, 30);
}

- (void)handleButtonsWithInputView:(UIView *)inputView {
    if ([_inputViewArr containsObject:inputView]) {
        _previousBtn.enabled = YES;
        _previousBtn.alpha = 1.0;
        _nextBtn.enabled = YES;
        _nextBtn.alpha = 1.0;
        
        if (inputView == _inputViewArr.firstObject) {
            _previousBtn.enabled = NO;
            _previousBtn.alpha = 0.3;
        }
        
        if (inputView == _inputViewArr.lastObject) {
            _nextBtn.enabled = NO;
            _nextBtn.alpha = 0.3;
        }
    }
}

- (void)checkSlectedInputView:(NSNotification *)noti {
    _selectedInputView = nil;
    for (UIView *inputView in _inputViewArr) {
        if (inputView.isFirstResponder) {
            if (_selectedInputView != inputView) {
                _selectedInputView = inputView;
                
                if (_delegate && [_delegate respondsToSelector:@selector(keyboardControl:didSelectInputView:)]) {
                    [_delegate keyboardControl:self didSelectInputView:inputView];
                }
            }
        }
    }
    [self handleButtonsWithInputView:self.selectedInputView];
    
    CGRect endFrame = [[[noti userInfo] objectForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    CGRect frameInWindow = [self.inputBackView.superview convertRect:self.backViewOriginalFrame toView:[UIApplication sharedApplication].keyWindow];
    [UIView animateWithDuration:0.25 animations:^{
        if (self.selectedInputView) {
            CGRect frame = [self.selectedInputView.superview convertRect:self.selectedInputView.frame toView:[UIApplication sharedApplication].keyWindow];
            CGFloat gap = CGRectGetMaxY(frame) + self.basicGap - CGRectGetMinY(endFrame);
            if ([self.inputBackView isKindOfClass:[UIScrollView class]]) {
                if (CGRectGetMaxY(frameInWindow) > CGRectGetMinY(endFrame)) {
                    CGFloat offsetY = CGRectGetMaxY(frameInWindow) - CGRectGetMinY(endFrame);
                    self.inputBackView.frame = CGRectMake(self.backViewOriginalFrame.origin.x, self.backViewOriginalFrame.origin.y, self.backViewOriginalFrame.size.width, self.backViewOriginalFrame.size.height - offsetY);
                }
                
                UIScrollView *sc = (UIScrollView *)self.inputBackView;
                CGFloat ocy = sc.contentOffset.y + gap;
                CGFloat ff = ocy>-sc.adjustedContentInset.top?ocy:-sc.adjustedContentInset.top;
                [sc setContentOffset:CGPointMake(0, ff) animated:NO];
            }else if(gap > 0) {
                self.inputBackView.frame = CGRectMake(self.inputBackView.frame.origin.x, self.inputBackView.frame.origin.y - gap, self.inputBackView.frame.size.width, self.inputBackView.frame.size.height);
            }
        }else{
            self.inputBackView.frame = self.backViewOriginalFrame;
        }
    }];
}

#pragma mark - notification
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self checkSlectedInputView:notification];
    });
}

#pragma mark - lazy
- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:(UIBlurEffectStyleExtraLight)]];
        _effectView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44);
        
        [_effectView.contentView addSubview:self.previousBtn];
        [_effectView.contentView addSubview:self.nextBtn];
        [_effectView.contentView addSubview:self.doneBtn];
        
        UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _effectView.frame.size.width, 0.5)];
        topLineView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [_effectView.contentView addSubview:topLineView];
        
        UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _effectView.frame.size.height - 0.5, _effectView.frame.size.width, 0.5)];
        bottomLineView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [_effectView.contentView addSubview:bottomLineView];
    }
    
    return _effectView;
}

- (UIButton *)previousBtn {
    if (!_previousBtn) {
        _previousBtn = [self createBtnWithTitle:@"上一个"];
        [_previousBtn addTarget:self action:@selector(previous) forControlEvents:(UIControlEventTouchUpInside)];
        _previousBtn.frame = CGRectMake(10, 7, 60, 30);
    }
    
    return _previousBtn;
}

- (UIButton *)nextBtn {
    if (!_nextBtn) {
        _nextBtn = [self createBtnWithTitle:@"下一个"];
        [_nextBtn addTarget:self action:@selector(next) forControlEvents:(UIControlEventTouchUpInside)];
        _nextBtn.frame = CGRectMake(80, 7, 60, 30);
    }
    
    return _nextBtn;
}

- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [self createBtnWithTitle:@"完成"];
        [_doneBtn addTarget:self action:@selector(done) forControlEvents:(UIControlEventTouchUpInside)];
        _doneBtn.frame = CGRectMake(_effectView.frame.size.width - 60, 7, 50, 30);
    }
    
    return _doneBtn;
}

- (UIButton *)createBtnWithTitle:(NSString *)title {
    UIButton *btn = [UIButton new];
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:0.3];
    btn.layer.borderColor = _color.CGColor;
    btn.layer.borderWidth = 0.5;
    btn.layer.cornerRadius = 5;
    btn.layer.masksToBounds = YES;
    [btn setTitle:title forState:(UIControlStateNormal)];
    [btn setTitleColor:_color forState:(UIControlStateNormal)];
    [btn sizeToFit];
    return btn;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
