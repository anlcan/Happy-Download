//
//  DownlaodManager.h
//  Campaign
//
//  Created by Anil Can Baykal on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "Debug.h"



@protocol HappyDownloadProgress <ASIProgressDelegate>

@optional
-(void)setProgress:(NSNumber*)newProgress forWorker:(ASIHTTPRequest*)request; 

@end

@interface HappyDownload : ASIHTTPRequest <ASIProgressDelegate, ASIHTTPRequestDelegate>{
    
    
    float progress; 
    int totalBytes; 
    
    __block ASIHTTPRequest * sentinelRequest;
    NSMutableArray * requests; 
    NSMutableArray * parts; 
    NSMutableArray * partsAvailable; 
    NSMutableArray * paths; 
    
    int totalChunk;
    int numberOfWorkers; 
    
    NSTimeInterval startTime;     
}

@property(nonatomic, assign) int totalChunk; 
@property(nonatomic, assign) int numberOfWorkers; 

@end
