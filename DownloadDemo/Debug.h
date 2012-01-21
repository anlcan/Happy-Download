//
//  Debug.h
//
//
//
//  Created by anlcan on 11/10/09.
//  Copyright 2009 pozitron. All rights reserved.
//

// inspired from iPhone Advanced Projects book.

#if defined (DISTRIBUTION)

#define _ASSERT(STATEMENT) do { (void) sizeof(STATEMENT); } while(0)
#define _NSLog(format, ...)


#else

#define _ASSERT(STATEMENT) do { assert(STATEMENT); } while(0)
#define _NSLog(format, ...) NSLog(format, ## __VA_ARGS__);		// always needs NSString as the first parameters

#endif 
