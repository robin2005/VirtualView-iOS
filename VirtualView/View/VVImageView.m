//
//  VVImageView.m
//  VirtualView
//
//  Copyright (c) 2017 Alibaba. All rights reserved.
//

#import "VVImageView.h"
#import "VVBinaryLoader.h"
#import "VVLoader.h"

@implementation VVLayerDelegate

- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)ctx {
    
    UIGraphicsPushContext(ctx);
    CGContextTranslateCTM(ctx, 0.0, self.delegateSource.frame.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    CGRect rt = CGRectMake(self.delegateSource.frame.origin.x+self.delegateSource.paddingLeft, self.delegateSource.frame.origin.y+self.delegateSource.paddingTop, self.delegateSource.frame.size.width, self.delegateSource.frame.size.height);
    
    CGContextDrawImage(ctx,rt,self.delegateSource.defaultImg.CGImage);
    
    UIGraphicsPopContext();
}

@end


@interface VVImageView ()<NSURLSessionDelegate>
{
    VVLayerDelegate* _layerDelegate;
    CALayer *myLayer;
}
//@property(strong, nonatomic)UIImage* defaultImg;
//@property(nonatomic, assign)CGSize   imageSize;
@property(strong, nonatomic)void (^setDataBlock)(void);
@property(strong, nonatomic)NSString* url;
@property(strong, nonatomic)NSURLSession* urlSession;
@property(strong, nonatomic)NSURLSessionDownloadTask *downloadTask;
@end

@implementation VVImageView
@synthesize frame = _frame;
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    NSString* url = downloadTask.originalRequest.URL.absoluteString;
    self.defaultImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:downloadURL]];
    //[[VVLoader shareInstance].cacheDic setObject:self.defaultImg forKey:url];
    @synchronized (self) {
        [[VVLoader shareInstance].cacheDic setObject:self.defaultImg forKey:url];
    }
    //NSDictionary* dd =[VVLoader shareInstance].cacheDic;
    if (self.downloadTask==downloadTask) {
        //__weak typeof(VVImageView*) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新界面
            //__strong typeof(VVImageView*) strongSelf = weakSelf;
            //[strongSelf.updateDelegate updateDisplayRect:self.frame];
            [myLayer setNeedsDisplay];
        });
    }
}

- (void)setFrame:(CGRect)frame{
    _frame = frame;
    myLayer.bounds=CGRectMake(0, 0, frame.size.width, frame.size.height);
    myLayer.anchorPoint=CGPointMake(0,0);
    myLayer.position=CGPointMake(0,frame.origin.y);
}

- (void)setUpdateDelegate:(id<VVWidgetAction>)delegate{
    [super setUpdateDelegate:delegate];
    if (myLayer==nil) {
        myLayer = [CALayer layer];
        myLayer.drawsAsynchronously = YES;
        myLayer.contentsScale = [[UIScreen mainScreen] scale];
        _layerDelegate = [[VVLayerDelegate alloc] init];
        myLayer.delegate = _layerDelegate;
        _layerDelegate.delegateSource = self;
        [myLayer setNeedsDisplay];
        [((UIView*)self.updateDelegate).layer addSublayer:myLayer];
    }
}

-(id)init{
    self = [super init];
    if (self) {
        _defaultImg = [UIImage imageNamed:@"ic_map_gaode"];//[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.imgUrl]]];
        self.width  = _defaultImg.size.width;
        self.height = _defaultImg.size.height;
        __weak typeof(VVImageView*) weakSelf = self;
        self.setDataBlock = ^{
            // 耗时的操作
            __strong typeof(VVImageView*) strongSelf = weakSelf;
            strongSelf.defaultImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:strongSelf.url]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                // 更新界面
                [strongSelf.updateDelegate updateDisplayRect:strongSelf.frame];
            });
        };
        
        //urlSession=[NSURLSession sharedSession];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    return self;
}

- (BOOL)setStringDataValue:(NSString*)value forKey:(int)key{

    switch (key) {
        case STR_ID_src:
            self.imgUrl = value;
            self.defaultImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.imgUrl]]];
            break;
    }
    return YES;
}

-(BOOL)setStringValue:(int)value forKey:(int)key{
    BOOL ret = [super setStringValue:value forKey:key];
    if (!ret) {
        switch (key) {
            case STR_ID_src:
                self.imgUrl = [[VVBinaryLoader shareInstance] getStrCodeWithType:key];
                self.defaultImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.imgUrl]]];
                break;
                
            default:
                break;
        }
    }
    return  ret;
}

- (void)drawRect:(CGRect)rect{
    //
    
    if (self.defaultImg==nil) {
        self.defaultImg = [UIImage imageNamed:@"ic_map_gaode"];
    }
    //CGRect rt = CGRectMake(self.frame.origin.x+self.paddingLeft, self.frame.origin.y+self.paddingTop, self.imageSize.width, self.imageSize.height);
    //UIGraphicsBeginImageContextWithOptions(rt.size, NO, 0.0);
    //CGContextRef con = UIGraphicsGetCurrentContext();
    
    //CGContextSaveGState(con);
    //CGContextDrawImage(con,rt,self.defaultImg.CGImage);
    //[self.defaultImg drawInRect:rt];
    //UIGraphicsEndImageContext();
    //[myLayer setNeedsDisplay];
}

- (CGSize)calculateLayoutSize:(CGSize)maxSize{
    
    switch ((int)self.widthModle) {
        case WRAP_CONTENT:
            //
            _imageSize.width = _defaultImg.size.width/3.0;
            self.width = self.paddingRight+self.paddingLeft+_imageSize.width;
            break;
        case MATCH_PARENT:
            self.width = maxSize.width;

            break;
        default:
            _imageSize.width = self.width;
            self.width = self.paddingRight+self.paddingLeft+self.width;
            break;
    }
    
    switch ((int)self.heightModle) {
        case WRAP_CONTENT:
            //
            _imageSize.height = _defaultImg.size.height/3.0;
            self.height = self.paddingTop+self.paddingBottom+_imageSize.height;
            break;
        case MATCH_PARENT:
            self.height = maxSize.height;

            break;
        default:
            _imageSize.height = self.height;
            self.height = self.paddingTop+self.paddingBottom+self.height;
            break;
    }
    [self autoDim];
    return CGSizeMake(self.width=self.width<maxSize.width?self.width:maxSize.width, self.height=self.height<maxSize.height?self.height:maxSize.height);
    
}

- (void)setData:(NSData*)data{
    //
    self.imgUrl = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.defaultImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.imgUrl]]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_defaultImg drawInRect:self.frame];
    });
}

- (void)setDataObj:(NSObject*)obj forKey:(int)key{
    //
    //self.url = [dic objectForKey:self.dataTag];
    //[super setDataObj:dic];
    self.url = nil;
    switch (key) {
        case STR_ID_src:
            self.url = (NSString*)obj;
            break;
        default:
            self.url = nil;
            break;
    }
        
    
    NSRange rang = [self.url rangeOfString:@":"];
    if (rang.location==NSNotFound) {
        self.url = [NSString stringWithFormat:@"https:%@",self.url];
    }
    UIImage* imgData = [[VVLoader shareInstance].cacheDic objectForKey:self.url];
    if (imgData==nil) {

        //self.defaultImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
        if (self.downloadTask) {
            //[self.downloadTask cancel];
        }
       
        NSURL *downloadURL = [NSURL URLWithString:self.url];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadURL];
        //request.allowsCellularAccess = NO;
        self.downloadTask = [self.urlSession downloadTaskWithRequest:request];
        [self.downloadTask resume];
    }else{
        self.defaultImg = imgData;
        //__weak typeof(VVImageView*) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新界面
            //__strong typeof(VVImageView*) strongSelf = weakSelf;
            //[strongSelf.updateDelegate updateDisplayRect:strongSelf.frame];
            [myLayer setNeedsDisplay];
        });
    }
    /*
    __weak typeof(VVImageView*) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 耗时的操作
        __strong typeof(VVImageView*) strongSelf = weakSelf;
        strongSelf.defaultImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.url]]];
//        _imageSize.width = strongSelf.defaultImg.size.width/3.0;
//        _imageSize.height = strongSelf.defaultImg.size.height/3.0;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新界面
            [strongSelf.updateDelegate updateDisplayRect:self.frame];
        });
    });
    */
    
    /*
    __weak typeof(VVImageView*) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新界面
        __strong typeof(VVImageView*) strongSelf = weakSelf;
        [strongSelf.updateDelegate updateDisplayRect:self.frame];
    });
     */
    
//    if (dispatch_block_testcancel(self.setDataBlock)==0) {
//        dispatch_block_cancel(self.setDataBlock);
//    }
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),self.setDataBlock);
}
@end