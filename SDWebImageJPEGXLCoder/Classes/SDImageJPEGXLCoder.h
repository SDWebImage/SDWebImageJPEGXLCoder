//
//  SDImageJPEGXLCoder.h
//  SDWebImageHEIFCoder
//
//  Created by lizhuoli on 2018/5/8.
//

#if __has_include(<SDWebImage/SDWebImage.h>)
#import <SDWebImage/SDWebImage.h>
#else
@import SDWebImage;
#endif

// TODO: This ugly int-based type should be replaced with a class (like UTType), in SDWebImage 6.0
static const SDImageFormat SDImageFormatJPEGXL = 17; // JPEG-XL

@interface SDImageJPEGXLCoder : NSObject <SDImageCoder>

@property (nonatomic, class, readonly, nonnull) SDImageJPEGXLCoder *sharedCoder;

@end
