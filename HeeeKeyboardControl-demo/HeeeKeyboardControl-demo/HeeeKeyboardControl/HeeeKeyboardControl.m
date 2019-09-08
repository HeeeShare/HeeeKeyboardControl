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
@property (nonatomic,  weak) id<HeeeKeyboardControlDelegate> delegate;
@property (nonatomic,strong) NSMutableArray *inputViewArr;
@property (nonatomic,strong) UIView *inputBackView;//所有inputView的总父view
@property (nonatomic,strong) UIVisualEffectView *effectView;//背景view
@property (nonatomic,strong) UIButton *previousBtn;
@property (nonatomic,strong) UIButton *nextBtn;
@property (nonatomic,strong) UIButton *doneBtn;
@property (nonatomic,assign) NSInteger selectedIndex;//当前选中的哪个inputView
@property (nonatomic,strong) NSMutableArray *inputViewBottomArr;//所有inputView底部在window中的纵坐标值
@property (nonatomic,assign) CGRect backViewOriginalFrame;//inputBackView的初始frame
@property (nonatomic,assign) CGRect backViewOriginalFrameInWindow;//inputBackView相对于window的初始frame
@property (nonatomic,assign) CGPoint originalContenOffset;//当inputBackView是scrollview时的初始offset
@property (nonatomic,assign) CGFloat originalBottomContentInset;//当inputBackView是scrollview时bottom的初始inset
@property (nonatomic,assign) CGFloat keyBoardTop;//键盘的y坐标
@property (nonatomic,assign) CGFloat animateDuration;//键盘动画时间
@property (nonatomic,assign) CGFloat inputViewKeyBoardGap;//inputView与键盘顶部的间隙
@property (nonatomic,strong) UIView *selectedInputView;//选中的UITextView
@property (nonatomic,assign) CGFloat originalContentSizeHeight;

@end

@implementation HeeeKeyboardControl
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (HeeeKeyboardControl *)makeControlWithInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView andDelegate:(id)delegate {
    return [[HeeeKeyboardControl alloc] initWithInputViews:inputViewArr inputBackView:inputBackView andDelegate:delegate];
}

- (instancetype)initWithInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView andDelegate:(id)delegate {
    self = [super init];
    if (self) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self handleInputViews:inputViewArr inputBackView:inputBackView andAssociatedObject:delegate];
        });
    }
    
    return self;
}

- (void)handleInputViews:(NSArray *)inputViewArr inputBackView:(UIView *)inputBackView andAssociatedObject:(id)delegate {
    if (delegate) {
        _delegate = delegate;
        
        objc_setAssociatedObject(delegate, @"heeeKeyboardControl_AO", self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        _selectedIndex = -1;
        _basicGap = _basicGap==0?20:_basicGap;
        _color = [UIColor colorWithRed:27/255.0 green:133/255.0 blue:250/255.0 alpha:1.0];
        _inputViewBottomArr = [NSMutableArray array];
        _inputViewArr = [NSMutableArray array];
        _inputBackView = inputBackView;
        _backViewOriginalFrame = _inputBackView.frame;
        _backViewOriginalFrameInWindow = [_inputBackView.superview convertRect:_inputBackView.frame toView:[UIApplication sharedApplication].keyWindow];
        
        if ([_inputBackView isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = ((UIScrollView *)_inputBackView);
            _originalContenOffset = scrollView.contentOffset;
            _originalBottomContentInset = scrollView.contentInset.bottom;
            if (@available(iOS 11.0, *)) {
                _originalBottomContentInset = scrollView.contentInset.bottom - scrollView.adjustedContentInset.bottom;
            }
            _originalContentSizeHeight = scrollView.contentSize.height;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewTextDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewTextDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
        
        _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:(UIBlurEffectStyleExtraLight)]];
        _effectView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44);
        
        UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _effectView.frame.size.width, 0.5)];
        topLineView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [_effectView.contentView addSubview:topLineView];
        
        UIView *bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _effectView.frame.size.height - 0.5, _effectView.frame.size.width, 0.5)];
        bottomLineView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [_effectView.contentView addSubview:bottomLineView];
        
        _previousBtn = [self createBtnWithTitle:@"上一个"];
        [_previousBtn addTarget:self action:@selector(previous) forControlEvents:(UIControlEventTouchUpInside)];
        _previousBtn.frame = CGRectMake(10, 7, 60, 30);
        [_effectView.contentView addSubview:_previousBtn];
        
        _nextBtn = [self createBtnWithTitle:@"下一个"];
        [_nextBtn addTarget:self action:@selector(next) forControlEvents:(UIControlEventTouchUpInside)];
        _nextBtn.frame = CGRectMake(80, 7, 60, 30);
        [_effectView.contentView addSubview:_nextBtn];
        
        _doneBtn = [self createBtnWithTitle:@"完成"];
        [_doneBtn addTarget:self action:@selector(done) forControlEvents:(UIControlEventTouchUpInside)];
        _doneBtn.frame = CGRectMake(_effectView.frame.size.width - 60, 7, 50, 30);
        [_effectView.contentView addSubview:_doneBtn];
        
        [self setIsEnStyle:_isEnStyle];
        
        for (UIView *view in inputViewArr)
        {
            if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]])
            {
                [_inputViewArr addObject:view];
                [(UITextField *)view setInputAccessoryView:_effectView];
                CGRect frameInWindow = [view.superview convertRect:view.frame toView:[UIApplication sharedApplication].keyWindow];
                CGFloat inputViewBottom = frameInWindow.origin.y + view.frame.size.height;
                [_inputViewBottomArr addObject:[NSNumber numberWithFloat:inputViewBottom]];
            }
        }
    }
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

- (void)previous {
    if (_selectedIndex > 0) {
        UITextField *inputView = _inputViewArr[_selectedIndex - 1];
        [self handleButtonsWithInputView:inputView];
        [inputView becomeFirstResponder];
    }
}

- (void)next {
    if (_selectedIndex < _inputViewArr.count - 1) {
        UITextField *inputView = _inputViewArr[_selectedIndex + 1];
        [self handleButtonsWithInputView:inputView];
        [inputView becomeFirstResponder];
    }
}

- (void)done {
    if (_delegate && [_delegate respondsToSelector:@selector(keyboardControl:pressDoneButtonWithInputView:)]) {
        [_delegate keyboardControl:self pressDoneButtonWithInputView:_inputViewArr[_selectedIndex]];
    }
    
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.previousBtn.layer.borderColor = color.CGColor;
        [self.previousBtn setTitleColor:color forState:(UIControlStateNormal)];
        self.nextBtn.layer.borderColor = color.CGColor;
        [self.nextBtn setTitleColor:color forState:(UIControlStateNormal)];
        self.doneBtn.layer.borderColor = color.CGColor;
        [self.doneBtn setTitleColor:color forState:(UIControlStateNormal)];
    });
}

- (void)setIsEnStyle:(BOOL)isEnStyle {
    _isEnStyle = isEnStyle;
    
    if (isEnStyle) {
        [_previousBtn setTitle:@"Previous" forState:(UIControlStateNormal)];
        [_nextBtn setTitle:@"Next" forState:(UIControlStateNormal)];
        [_doneBtn setTitle:@"Done" forState:(UIControlStateNormal)];
    }else{
        [_previousBtn setTitle:@"上一个" forState:(UIControlStateNormal)];
        [_nextBtn setTitle:@"下一个" forState:(UIControlStateNormal)];
        [_doneBtn setTitle:@"完成" forState:(UIControlStateNormal)];
    }
    
    [_previousBtn sizeToFit];
    [_nextBtn sizeToFit];
    [_doneBtn sizeToFit];
    _previousBtn.frame = CGRectMake(10, 7, _previousBtn.bounds.size.width, 30);
    _nextBtn.frame = CGRectMake(_previousBtn.frame.origin.x + _previousBtn.bounds.size.width + 20, 7, 60, 30);
    _doneBtn.frame = CGRectMake(_effectView.frame.size.width - 60, 7, 50, 30);
}

//处理previousBtn与nextBtn的状态
- (void)handleButtonsWithInputView:(UIView *)inputView {
    if ([_inputViewArr containsObject:inputView]) {
        _selectedIndex = [_inputViewArr indexOfObject:inputView];
        
        if (_selectedIndex == 0) {
            _previousBtn.enabled = NO;
            _previousBtn.alpha = 0.3;
        }else{
            _previousBtn.enabled = YES;
            _previousBtn.alpha = 1.0;
        }
        if (_selectedIndex == _inputViewArr.count - 1) {
            _nextBtn.enabled = NO;
            _nextBtn.alpha = 0.3;
        }else{
            _nextBtn.enabled = YES;
            _nextBtn.alpha = 1.0;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self backViewAnimate];
        });
    }
}

//总父view的动画，为了让当前选中的inputView始终可见
- (void)backViewAnimate {
    if (_inputBackView) {
        NSNumber *selectBottom = [_inputViewBottomArr objectAtIndex:_selectedIndex];
        CGFloat selectInputViewBottom = selectBottom.floatValue;
        
        if ([_inputBackView isKindOfClass:[UIScrollView class]]) {
            if ([self calculateInputBackViewKeyboardGap] > 0) {
                _inputViewKeyBoardGap = _basicGap;
            }else{
                _inputViewKeyBoardGap = _basicGap - [self calculateInputBackViewKeyboardGap];
            }
            
            selectInputViewBottom += _inputViewKeyBoardGap;
            
            UIScrollView *temScrollView = (UIScrollView *)_inputBackView;
            if (selectInputViewBottom > _keyBoardTop) {
                [UIView animateWithDuration:_animateDuration animations:^{
                    [temScrollView setContentOffset:CGPointMake(0, selectInputViewBottom - self.keyBoardTop + self.originalContenOffset.y)];
                }];
            }else{
                [temScrollView setContentOffset:_originalContenOffset animated:YES];
            }
        }else{
            selectInputViewBottom += _basicGap;
            
            if (selectInputViewBottom > _keyBoardTop) {
                [UIView animateWithDuration:_animateDuration animations:^{
                    self.inputBackView.frame = CGRectMake(self.backViewOriginalFrame.origin.x, self.backViewOriginalFrame.origin.y - (selectInputViewBottom - self.keyBoardTop), self.backViewOriginalFrame.size.width, self.backViewOriginalFrame.size.height);
                }];
            }else{
                [UIView animateWithDuration:_animateDuration animations:^{
                    self.inputBackView.frame = self.backViewOriginalFrame;
                }];
            }
        }
    }
}

//计算最初总父view底部与键盘顶部的间距
- (CGFloat)calculateInputBackViewKeyboardGap {
    return _backViewOriginalFrameInWindow.origin.y + _backViewOriginalFrameInWindow.size.height - _keyBoardTop;
}

- (void)handleInputBackViewFrame {
    if ([_inputBackView isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollview = (UIScrollView *)self.inputBackView;
        CGFloat bottomOffset = [self calculateInputBackViewKeyboardGap];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            scrollview.contentSize = CGSizeMake(0, self.originalContentSizeHeight);
        });
        scrollview.scrollIndicatorInsets = UIEdgeInsetsMake(scrollview.scrollIndicatorInsets.top, scrollview.scrollIndicatorInsets.left, _originalBottomContentInset + bottomOffset, scrollview.scrollIndicatorInsets.right);
        scrollview.contentInset = UIEdgeInsetsMake(scrollview.contentInset.top, scrollview.contentInset.left, _originalBottomContentInset + bottomOffset, scrollview.contentInset.right);
    }
}

#pragma mark - notification
- (void)textFieldDidBeginEditing:(NSNotification *)notification {
    _selectedInputView = notification.object;
    [self handleButtonsWithInputView:_selectedInputView];
    
    if ([_inputBackView isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollview = (UIScrollView *)self.inputBackView;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            scrollview.contentSize = CGSizeMake(0, self.originalContentSizeHeight);
        });
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(keyboardControl:willSelectInputView:)]) {
        [_delegate keyboardControl:self willSelectInputView:_selectedInputView];
    }
}

- (void)textFieldDidEndEditing:(NSNotification *)notification {
    _selectedInputView = nil;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    _keyBoardTop = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    if ([UIDevice currentDevice].systemVersion.floatValue < 12.0) {
        _animateDuration = 0.25;
    }else{
        _animateDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    }
    
    [self handleInputBackViewFrame];
    [self handleButtonsWithInputView:_selectedInputView];
}

- (void)textViewTextDidBeginEditing:(NSNotification *)notification {
    _selectedInputView = notification.object;
    [self handleButtonsWithInputView:_selectedInputView];
    
    if ([_inputBackView isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollview = (UIScrollView *)self.inputBackView;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            scrollview.contentSize = CGSizeMake(0, self.originalContentSizeHeight);
        });
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(keyboardControl:willSelectInputView:)]) {
        [_delegate keyboardControl:self willSelectInputView:_selectedInputView];
    }
}

- (void)textViewTextDidEndEditing:(NSNotification *)notification {
    _selectedInputView = nil;
}

@end
