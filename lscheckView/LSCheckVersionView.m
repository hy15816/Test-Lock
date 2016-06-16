//
//  LSCheckVersionView.m
//  anxindian
//
//  Created by Lost_souls on 16/6/6.
//  Copyright © 2016年 anerfa. All rights reserved.
//
/**
 下面是 <stdarg.h> 里面重要的几个宏定义如下：
 typedef char* va_list;
 void va_start ( va_list ap, prev_param ); // ANSI version
 type va_arg ( va_list ap, type );
 void va_end ( va_list ap );
 va_list 是一个字符指针，可以理解为指向当前参数的一个指针，取参必须通过这个指针进行。
 <Step 1> 在调用参数表之前，定义一个 va_list 类型的变量，(假设va_list 类型变量被定义为ap)；
 <Step 2> 然后应该对ap 进行初始化，让它指向可变参数表里面的第一个参数，这是通过 va_start 来实现的，第一个参数是 ap 本身，第二个参数是在变参表前面紧挨着的一个变量,即“...”之前的那个参数；
 <Step 3> 然后是获取参数，调用va_arg，它的第一个参数是ap，第二个参数是要获取的参数的指定类型，然后返回这个指定类型的值，并且把 ap 的位置指向变参表的下一个变量位置；
 <Step 4> 获取所有的参数之后，我们有必要将这个 ap 指针关掉，以免发生危险，方法是调用 va_end，他是输入的参数 ap 置为 NULL，应该养成获取完参数表之后关闭指针的习惯。说白了，就是让我们的程序具有健壮性。通常va_start和va_end是成对出现。
 */

#define kMarginLeft 30.f
#define kCellHeight 40.f

#import "LSCheckVersionView.h"
#import <objc/runtime.h>

@interface LSCheckVersionView ()<UITableViewDelegate,UITableViewDataSource>

@property (strong,nonatomic) UIView *backgView;
@property (strong,nonatomic) UIView *showView;
@property (strong,nonatomic) UIImageView *topImgv;
@property (strong,nonatomic) UITableView *tableView;
@property (strong,nonatomic) UILabel *titleLabel;
@property (strong,nonatomic) UILabel *subLabel;
@property (strong,nonatomic) NSMutableArray *itemsList;
@property (strong,nonatomic) didSelecedIndex selectedIndex;



@property (strong,nonatomic) UIColor *textLabelColor;
@end

@implementation LSCheckVersionView


static LSCheckVersionView *check =  nil;
+ (LSCheckVersionView *)checkView{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (check == nil) {
            check = [[LSCheckVersionView alloc] init];
        }
    });
    
    return check;
}


- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title subTitle:(NSString *)subTitle item:(NSString *)item, ...NS_REQUIRES_NIL_TERMINATION {
    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self = [super initWithFrame:frame];
    if(self){
        
        NSString *other = nil;
        va_list args;// 用于指向第一个参数
//        [self.itemsList addObject:items];
        if(item){
            [self.itemsList addObject:item];
            va_start(args, item); //对args进行初始化，让他指向可变参数表里面的第一个参数
            while ((other = va_arg(args, NSString *))) { //获取指定的参数类型
                [self.itemsList addObject:other];
            }
            va_end(args);// 将args关闭
        }
        NSLog(@"self.itemsList:%@",self.itemsList);
        self.textLabelColor = [UIColor blueColor];
        [self setupViews:title subTitle:subTitle];
        self.topImgv.image = image;
    }
    
    return self;
}



//- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title subTitle:(NSString *)subTitle items:(NSArray *)items{
//    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
//    if (self = [super initWithFrame:frame]) {
//        
//        [self setupViews:title subTitle:subTitle];
//        self.topImgv.image = image;
//    }
//    
//    return self;
//}

- (instancetype)initWithImage:(UIImage *)image msg:(NSString *)msg cancel:(NSString *)cancel sure:(NSString *)sure vc:(UIViewController *)vc selectedIndex:(didSelecedIndex)selectedIndex{
    if ([UIDevice currentDevice].systemVersion.floatValue >=8.0) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"\n\n\n\n%@",msg] preferredStyle:UIAlertControllerStyleAlert];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, alertVC.view.frame.size.width, 300)];
        UIImageView *imgv = [[UIImageView alloc] initWithImage:image];
        imgv.frame = CGRectMake((view.frame.size.width - 100 - 60)/2, 30, 60, 60);
        
        [view addSubview:imgv];
//        alertVC.view.backgroundColor = [UIColor redColor];
        
        [alertVC.view addSubview:view];
        
        if (cancel) {
            [alertVC addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                //
                if (selectedIndex) {
                    selectedIndex(0);
                }
            }]];
        }
        if (sure) {
            [alertVC addAction:[UIAlertAction actionWithTitle:sure style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                //
                if (selectedIndex) {
                    selectedIndex(1);
                }
            }]];
        }
        
        [vc presentViewController:alertVC animated:YES completion:nil];
        self = nil;
    }else{
        CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        if (self = [super initWithFrame:frame]) {
            
            self.textLabelColor = [UIColor blackColor];
            [self addSubview:self.backgView];   //底层灰色view
            [self addSubview:self.showView];    //显示的白色view
            self.topImgv.image = image;
            
            [self.itemsList addObject:msg];
            [self.showView addSubview:self.tableView];
            self.tableView.frame = CGRectMake(0, _showView.frame.size.height - self.itemsList.count * kCellHeight - 40, _showView.frame.size.width, self.itemsList.count * kCellHeight);
            
            [self.tableView reloadData];
        }
        
    }

    
    return self;
}


- (void)showCheckView:(didSelecedIndex)selectedIndex{
    
    
//    [UIView animateWithDuration:.37 animations:^{
        //
    
    [[[UIApplication sharedApplication] delegate].window addSubview:self];
    [[[UIApplication sharedApplication] delegate].window bringSubviewToFront:self];
//    }];
    
    
    if (selectedIndex) {
        self.selectedIndex = selectedIndex;
    }
}

- (void)dismissCheckView {
    
    [UIView animateWithDuration:.37 animations:^{
        //
//        self.transform = CGAffineTransformMakeScale(.9, .9);
//        self.showView.frame = CGRectMake(0, self.frame.size.height, self.showView.frame.size.width, self.showView.frame.size.height);
        
        self.alpha = 0.f;
        
    } completion:^(BOOL finished) {
        if (finished) {
            //
            [self removeFromSuperview];
        }
    }];
    
}

- (void)setupViews:(NSString *)title subTitle:(NSString *)subTitle {
    
    [self addSubview:self.backgView];   //底层灰色view
    [self addSubview:self.showView];    //显示的白色view
    
    [self.showView addSubview:self.tableView];
    
    
    if (title) {
        self.titleLabel.text = title;
        [self.showView addSubview:self.titleLabel];
    }
    
    if (subTitle) {
        self.subLabel.text = subTitle;
        [self.showView addSubview:self.subLabel];
    }
    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.itemsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellidf = @"cellidf";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidf];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellidf];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = self.textLabelColor;
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 1, cell.frame.size.width, .5f)];
        lab.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [cell addSubview:lab];

    }
    
    cell.textLabel.text = self.itemsList[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return kCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.selectedIndex) {
        self.selectedIndex(indexPath.row);
    }
    
    
}

#pragma mark - ----------

- (UIView *)backgView{
    if (!_backgView) {
        _backgView = [[UIView alloc] initWithFrame:self.bounds];
        _backgView.backgroundColor = [UIColor grayColor];
        _backgView.alpha = .3f;
        
    }
    
    return _backgView;
}

- (UIView *)showView{
    if (!_showView) {
        _showView = [[UIView alloc] initWithFrame:CGRectMake(kMarginLeft, ([UIScreen mainScreen].bounds.size.height - 250)/2, [UIScreen mainScreen].bounds.size.width - kMarginLeft *2, 250)];
        _showView.backgroundColor = [UIColor whiteColor];
        _showView.layer.cornerRadius = 5.f;
        _showView.layer.masksToBounds = YES;
        [_showView addSubview:self.topImgv];
    }
    
    return _showView;
}

- (UILabel *)titleLabel{
    
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.topImgv.frame.size.height + self.topImgv.frame.origin.y, self.showView.frame.size.width, 30)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor =[UIColor blackColor];
        _titleLabel.font = [UIFont systemFontOfSize:22.f];
    }
    
    return _titleLabel;
}

- (UILabel *)subLabel {
    
    if (!_subLabel) {
        _subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height, self.showView.frame.size.width, 20)];
        _subLabel.textAlignment = NSTextAlignmentCenter;
        _subLabel.textColor =[UIColor blackColor];
        _subLabel.font = [UIFont systemFontOfSize:14.f];
    }
    
    return _subLabel;
}

- (UIImageView *)topImgv{
    if (!_topImgv) {
        _topImgv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _showView.frame.size.width, 70)];
//        _topImgv.backgroundColor = [UIColor yellowColor];
        _topImgv.contentMode = UIViewContentModeCenter;
    }
    
    return _topImgv;
}


- (NSMutableArray *)itemsList {
    
    if (!_itemsList) {
        _itemsList = [[NSMutableArray alloc] init];
    }
    
    return _itemsList;
}

- (UITableView *)tableView{
    if (!_tableView ) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _showView.frame.size.height - self.itemsList.count * kCellHeight, _showView.frame.size.width, self.itemsList.count * kCellHeight) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.scrollEnabled = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    return _tableView;
}

@end
