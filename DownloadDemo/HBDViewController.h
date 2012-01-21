//
//  HBDViewController.h
//  DownloadDemo
//
//  Created by Anil Can Baykal on 1/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HappyDownload.h"

@interface HBDViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ASIHTTPRequestDelegate, HappyDownloadProgress>{
    
    IBOutlet UITableView *table;
    IBOutlet UIProgressView *mainProgress;
    IBOutlet UIButton *downloadButton;
    
    NSMutableArray * workers; 
    HappyDownload * currentDownload;
    
    NSDate* start; 
    int totalWorker; 
}
- (IBAction)mainButtonClicked:(id)sender;

@end
