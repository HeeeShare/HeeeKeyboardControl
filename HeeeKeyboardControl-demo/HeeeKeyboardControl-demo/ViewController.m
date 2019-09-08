//
//  ViewController.m
//  HeeeKeyboardControl-demo
//
//  Created by hgy on 2018/7/18.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import "ViewController.h"
#import "HeeeKeyboardControl.h"

@interface ViewController ()
@property (nonatomic,strong) NSMutableArray *inputViewArr;
@property (nonatomic,strong) UIScrollView *inputBackView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"HeeeKeyboardControl";
    
    _inputViewArr = [NSMutableArray array];
    _inputBackView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:_inputBackView];
    
    int time = 4;
    for (int i = 0; i < time; i++) {
        UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, [UIScreen mainScreen].bounds.size.width - 40, 40)];
        tf.placeholder = [NSString stringWithFormat:@"第%d个",i+1];
        tf.backgroundColor = [UIColor whiteColor];
        [_inputViewArr addObject:tf];
        
        UIView *tfBackView = [[UIView alloc] initWithFrame:CGRectMake(10, 30 + 100*i, [UIScreen mainScreen].bounds.size.width - 20, 60)];
        tfBackView.layer.cornerRadius = 10;
        tfBackView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        [tfBackView addSubview:tf];
        [_inputBackView addSubview:tfBackView];
    }
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 30 + 100*time, [UIScreen mainScreen].bounds.size.width - 20, 80)];
    textView.backgroundColor = [UIColor redColor];
    
    _inputBackView.contentSize = CGSizeMake(0, textView.frame.origin.y + 100);
    [_inputBackView addSubview:textView];
    [_inputViewArr addObject:textView];
    
    //一句代码搞定
    [HeeeKeyboardControl makeControlWithInputViews:_inputViewArr inputBackView:_inputBackView andDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
