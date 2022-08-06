#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UIDevice+SHInterfaceOrientationManager.h"
#import "UIViewController+SHInterfaceOrientationManager.h"

FOUNDATION_EXPORT double SHInterfaceOrientationManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char SHInterfaceOrientationManagerVersionString[];

