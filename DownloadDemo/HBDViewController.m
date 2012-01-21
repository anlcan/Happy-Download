//
//  HBDViewController.m
//  DownloadDemo
//
//  Created by Anil Can Baykal on 1/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HBDViewController.h"

@implementation HBDViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mainProgress.progress = 0.0; 

}

- (IBAction)mainButtonClicked:(id)sender {    
    if ( currentDownload) {
        
        [currentDownload clearDelegatesAndCancel]; 
        currentDownload = nil; 
        [downloadButton setTitle:@"DOWNLOAD" forState:UIControlStateNormal];
        totalWorker = 0; 
        [workers release]; workers = nil; 
        mainProgress.progress = 0.0;
        
    } else {
    
        totalWorker = 3; 
        NSString * tmp = @"http://ipv4.download.thinkbroadband.com/20MB.zip";	
        
        currentDownload = [[HappyDownload alloc] initWithURL:[NSURL URLWithString:tmp]]; 
        currentDownload.numberOfWorkers = totalWorker; 
        currentDownload.delegate = self; 
        currentDownload.downloadProgressDelegate = self;
        //currentDownload.allowResumeForFileDownloads = YES; 
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        [currentDownload setDownloadDestinationPath:[documentsDirectory stringByAppendingPathComponent:@"file.pdf"]]; 
        
        // worker progresses

        workers = [[NSMutableArray alloc] initWithCapacity:currentDownload.totalChunk]; 
        
        
        [currentDownload startAsynchronous]; 
        [downloadButton setTitle:@"CANCEL" forState:UIControlStateNormal]; 
    }
    
    start = [NSDate new]; 
    [table reloadData]; 
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - request delegates
-(void)setProgress:(float)newProgress{
    mainProgress.progress = newProgress; 
}

-(void)setProgress:(NSNumber*)newProgress forWorker:(ASIHTTPRequest *)request{
    int index = request.tag; 
    UIProgressView * p = [workers objectAtIndex:index]; 
    
    [p setProgress:[newProgress floatValue]];
    [p.superview setNeedsLayout];     
}

-(void)requestFinished:(ASIHTTPRequest *)request{
                
    int duration = [[[NSCalendar currentCalendar] components:NSSecondCalendarUnit fromDate:start 
                                                                toDate:[[NSDate new] autorelease] 
                                                                options:0] second];
    
    
    NSString * msg = [NSString stringWithFormat:@"your download finished in %d seconds" , duration];
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@""
                                                     message:msg
                                                    delegate:nil
                                           cancelButtonTitle: @"OK"
                                           otherButtonTitles: nil];
    
    [alert show]; 
    [alert release]; 
    
    [self mainButtonClicked:nil]; 
    
}

#pragma mark - UItableStuff
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30; 
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return currentDownload.totalChunk; 
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString* ident = @""; 
    
    // intentional refusal of reuse.
    //UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:ident]; 
        
    UITableViewCell * cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:ident] autorelease];        
        
    cell.textLabel.text = [NSString stringWithFormat:@"#%d",indexPath.row];
    UIProgressView * p = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];     
    [cell addSubview:p]; 
    p.center = cell.center; 
    
    [workers addObject:p]; 
    
    return cell; 
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; 

}
- (void)dealloc {
    
    [currentDownload release];
    
    [table release];
    [mainProgress release];
    [downloadButton release];
    [super dealloc];
}
- (void)viewDidUnload {
    [table release];
    table = nil;
    [mainProgress release];
    mainProgress = nil;
    [downloadButton release];
    downloadButton = nil;
    [super viewDidUnload];
}

@end
