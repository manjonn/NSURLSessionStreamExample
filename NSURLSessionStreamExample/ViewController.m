//
//  ViewController.m
//  NSURLSessionStreamExample
//
//  Created by Manjula Jonnalagadda on 10/19/15.
//  Copyright © 2015 Manjula Jonnalagadda. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSURLSessionDataDelegate,NSStreamDelegate>{
    
    NSURLSession *_urlSession;
    NSMutableData *_data;
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)buttonTapped:(UIButton *)sender {
    
    //Comment below code to run it as stream
    
    [self configureUserSession];
    
    //Uncomment below code to run it as a stream
    
    /*
  [self configureStream];
    
    [NSThread detachNewThreadSelector:@selector(threadMethods) toTarget:self withObject:nil];
     */
    
}

-(void)configureUserSession{
    
    NSURLSessionConfiguration *defaultConfiguration=[NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLCache *cache=[[NSURLCache alloc] initWithMemoryCapacity: 16384 diskCapacity: 268435456 diskPath: @"/DataCache"];
    defaultConfiguration.URLCache=cache;
    defaultConfiguration.HTTPMaximumConnectionsPerHost=5;
    
    
        NSString *urlStr=@"http://api.openweathermap.org/data/2.5/forecast/city?id=524901&APPID=f65070ff120b55ef1517f806c8f0eaa3";

    //Comment code to run it without delegate with a completion handler
    
    _urlSession=[NSURLSession sessionWithConfiguration:defaultConfiguration];
 
    //UnComment code to run it without delegate with a completion handler
    
 //   _urlSession=[NSURLSession sessionWithConfiguration:defaultConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    
    NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];

    //Comment code to run it without delegate with a completion handler
 
    NSURLSessionDataTask *dataTask=[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       
        NSDictionary *dictionary=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"data :%@",dictionary.description);
        
    }];
  
    //UnComment code to run it without delegate with a completion handler

    /*
    NSURLSessionDataTask *dataTask=[_urlSession dataTaskWithRequest:request];
    _data=[NSMutableData data];
    [dataTask resume];
     */
    
 
}

-(void)configureStream{
    
    NSString *urlStr = @"http://api.openweathermap.org/data/2.5/forecast/city?id=524901&APPID=f65070ff120b55ef1517f806c8f0eaa3";
    NSURL *url=[NSURL URLWithString:urlStr];
    
         CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[url host], 80, &readStream, &writeStream);
        
        _inputStream = (__bridge_transfer NSInputStream *)readStream;
        _outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [_inputStream setDelegate:self];
    [_outputStream setDelegate:self];
  
    
}

-(void)scheduleStream{
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream open];
    [_outputStream open];

 
}

-(void)threadMethods{
    @autoreleasepool {
        [self scheduleStream];
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:30]];
    }
}

#pragma NSURLSessionTaskDelegate

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
     [_data appendData:data];

}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if (!error) {
        NSDictionary *dictionary=[NSJSONSerialization JSONObjectWithData:_data options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"data :%@",dictionary.description);
    }else{
        
        NSLog(@"Error is %@",error.localizedDescription);
    }
    
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    
}

#pragma mark - NSStreamDelgate

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    
    if (eventCode==NSStreamEventHasSpaceAvailable) {
        NSString *str=@"GET /data/2.5/forecast/city?id=524901&APPID=f65070ff120b55ef1517f806c8f0eaa3 HTTP/1.0\r\nHost: api.openweathermap.org\r\n\r\n";
        const uint8_t * rawstring =
        (const uint8_t *)[str UTF8String];
        [_outputStream write:rawstring maxLength:strlen(rawstring)];
        [_outputStream close];
    }
    if (eventCode==NSStreamEventHasBytesAvailable) {
        if(!_data) {
            _data = [NSMutableData data];
        }
        uint8_t buf[8096];
        NSInteger len = 0;
        len = [(NSInputStream *)aStream read:buf maxLength:8096];
        if(len) {
            [_data appendBytes:(const void *)buf length:len];
            // bytesRead is an instance variable of type NSNumber.
        } else {
            NSLog(@"no buffer!");
        }
    }
 
    if (eventCode==NSStreamEventErrorOccurred) {
        NSError *error = [aStream streamError];
        
        
        
        NSLog(@"Error:%@",error.localizedDescription);     }
    if (eventCode==NSStreamEventEndEncountered) {
        if ([aStream isEqual:_inputStream]) {
            NSString *str=[[NSString alloc]initWithData:_data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",str);
        }
        [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [aStream close];
        
    }
    
}



@end
