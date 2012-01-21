//
//  DownlaodManager.m
//  Campaign
//
//  Created by Anil Can Baykal on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HappyDownload.h"


#define tmpFile(range)	[NSString stringWithFormat:@"%@~%@", self.downloadDestinationPath, range]



@implementation HappyDownload

@synthesize totalChunk;
@synthesize numberOfWorkers; 

-(id)init{
    
    self = [super init]; 
    
    if(self){
        
        retryCount 	= 15;
        
        totalChunk  	= [[ASINetworkQueue queue] maxConcurrentOperationCount] * 2; 
        numberOfWorkers = [[ASINetworkQueue queue] maxConcurrentOperationCount] - 1; 
               
        requests 	= [NSMutableArray new]; 
        parts 		= [NSMutableArray new]; 
        paths	 	= [NSMutableArray new]; 
    }
    
    return self;
}

-(void)fireDownloadAtIndex:(int)index{
    
    NSString * range 	= [partsAvailable objectAtIndex:index];
    NSString * tmp 		= tmpFile(range);
    NSString * tmptmp 	= [NSString stringWithFormat:@"%@%~", tmp]; 
        
    NSArray * ranges 	= [range componentsSeparatedByString:@"-"];
    int start 			= [[ranges objectAtIndex:0] intValue];
    int end 			= [[ranges objectAtIndex:1] intValue]; 
    
    ASIHTTPRequest * req = [ASIHTTPRequest requestWithURL:url];    
    [req setDownloadDestinationPath:tmp];
    [req setTemporaryFileDownloadPath:tmptmp]; 
    [req setAllowResumeForFileDownloads:NO]; // resume will be calculated with parts. 
    
    [req setTag:[parts indexOfObject:range]]; 
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:[NSDate date] forKey:@"start"]; 
    [dict setObject:range forKey:@"range"];
     
    [req setUserInfo:dict]; 
    
    req.delegate = self; 
    req.downloadProgressDelegate = self;     
        
    [req addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%d-%d", start,end]];
        
    _NSLog(@"downloading: %d-%d at %d", start, end, req.tag);
    [requests addObject:req]; 
    [req startAsynchronous];       
}

-(void)clearDelegatesAndCancel{
    
    for (ASIHTTPRequest * req in requests){
        [req clearDelegatesAndCancel]; 
    }
    
    [requests removeAllObjects];    
    requests = nil; 
    
    [super clearDelegatesAndCancel]; 
}

-(void)cancel{
    
    for (ASIHTTPRequest * req in requests){
        [req cancel]; 
    }    
    
    [requests removeAllObjects];     
    [super cancel]; 
}

-(void)startSynchronous{
    //who downloads stuff synchoronous anyway???
}

-(void)startAsynchronous{
    
    // sending HEAD Request fails on aws and some other servers....
    sentinelRequest = [ASIHTTPRequest requestWithURL:url];    
    sentinelRequest.delegate = self;    
    [sentinelRequest  startAsynchronous]; 
    
    _NSLog(@"discovering file size....");
}

-(void)downloadAvailableChunk{
    
    @synchronized(self){
        
        if ( [partsAvailable count]) {
                        
            [self fireDownloadAtIndex:0];
            [partsAvailable removeObjectAtIndex:0]; 
                             
        }
    }
}

-(void)startDownload{
    
    int chunk = totalBytes/totalChunk; 
    int start = 0; 
    int stop = 0; 
    
    [parts removeAllObjects]; 
    
    while (stop < totalBytes) {
        
        start = stop; 
        stop  = MIN(chunk+stop, totalBytes); 
        
        if (start!=0)start++; 
        
        NSString * range = [NSString stringWithFormat:@"%d-%d", start, stop]; 
        if ( self.allowResumeForFileDownloads && 
            //[[NSFileManager defaultManager] fileExistsAtPath:tmpFile(range)] && omitted
            [[[NSFileManager defaultManager] attributesOfItemAtPath:tmpFile(range) error:nil] fileSize] == stop-start){
            
            _NSLog(@"found in cache %@", range);
            progress  += [[[NSFileManager defaultManager] attributesOfItemAtPath:tmpFile(range) error:nil] fileSize];
                           
        } else {
            [parts addObject:range]; 
            _NSLog(@"ready %@", range); 
        }
    }
    
    partsAvailable = [[NSMutableArray alloc] initWithArray:parts copyItems:YES]; 
    
    startTime = [NSDate timeIntervalSinceReferenceDate];
    
    for ( int i = 0; i < numberOfWorkers; i++){
        [self downloadAvailableChunk]; 
    }
}

- (void)request:(ASIHTTPRequest *)_request didReceiveBytes:(long long)bytes{

    unsigned long long  part = [_request totalBytesRead];
    unsigned long long  size = [_request contentLength];
    float subProgress = (part/(float)size); 
    
    
    progress += bytes;
    [self.downloadProgressDelegate setProgress:progress/totalBytes]; 
    
    if( [downloadProgressDelegate respondsToSelector:@selector(setProgress:forWorker:)]){
        
        [downloadProgressDelegate performSelector:@selector(setProgress:forWorker:)
                                       withObject:[NSNumber numberWithDouble:subProgress]
                                       withObject:_request]; 
        
    }
}


-(void)requestFailed:(ASIHTTPRequest *)_request{
    
    @synchronized(self){
        
        _NSLog(@"request failed:%@",_request.error)
        
        if ( --retryCount == 0) {
                        
            _NSLog(@"failing with error %@",_request.error);
            [self failWithError:_request.error];
            [self clearDelegatesAndCancel];
            
        } else {
                        
            NSString * range = [_request.userInfo objectForKey:@"range"];
            _NSLog(@"will retry chunk %@",range);
            [partsAvailable addObject:range];
            [self downloadAvailableChunk]; // retry another block
            [requests removeObject:_request];
                     
        }        
    }
}

-(void)requestFinished:(ASIHTTPRequest *)_request{    
    
    @synchronized(self){
        
        NSString * range = [_request.userInfo objectForKey:@"range"]; 
        NSDate *startDate = [_request.userInfo objectForKey:@"start"];         
        NSTimeInterval  time = [startDate timeIntervalSinceNow];
                       
        NSLog(@"finised %@ in %.3f",range, -1*time);
        
        [paths addObject:_request.downloadDestinationPath]; 
        [requests removeObject:_request]; 
        
        // download all parts
        if ( [partsAvailable count])
            return [self downloadAvailableChunk]; 
        
        //wait all request to finish
        if ([requests count ])
            return;
        
            
        NSString * path = downloadDestinationPath; 
        if (![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil]){
            NSLog(@"file create failed!"); 
            return; 
        }
        
        NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        
        for ( NSString * range in parts){
            
            NSString * tmp = tmpFile(range); 
            NSData  *data = [[NSFileManager defaultManager] contentsAtPath:tmp];
            
            _NSLog(@"appending %d bytes from tmp:%@", [data length], [tmp lastPathComponent]);
                                    
            [myHandle writeData:data]; 
            
            
            NSError * err = nil; 
            [[NSFileManager defaultManager] removeItemAtPath:tmp error:&err];
            if ( err != nil)
                NSLog(@"failed to clean up!\n%@", err);
        }
        
        [myHandle closeFile]; 
        
        _NSLog(@"finished dowloading %d in %.3f at %@", totalBytes, [NSDate timeIntervalSinceReferenceDate] - startTime, [self.downloadDestinationPath lastPathComponent]);
        
        //all requests are finished
        [self performSelector:@selector(reportFinished)]; 

    }
}

- (void)request:(ASIHTTPRequest *)_request didReceiveResponseHeaders:(NSDictionary *)responseHeaders{
   
    if(_request == sentinelRequest) {
        
        NSString * totalSize = [_request.responseHeaders objectForKey:@"Content-Length"];        
        totalBytes = [totalSize intValue]; 
        _NSLog(@"headers received. file size:%@",totalSize);
        
        [sentinelRequest clearDelegatesAndCancel];         
        [self startDownload];
    } else {
        NSString * range = [_request.responseHeaders objectForKey:@"Content-Range"];
        _NSLog(@"request range :%@", range);
        
    }
}

-(void)dealloc{
    
    [requests release]; requests = nil; 
    [parts release]; parts = nil;     
    [partsAvailable release]; partsAvailable = nil; 
    
    [super dealloc]; 
}

@end
