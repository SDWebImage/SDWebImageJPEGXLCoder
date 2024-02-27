//
//  SDImageJPEGXLCoder.m
//  SDWebImageHEIFCoder
//
//  Created by lizhuoli on 2018/5/8.
//

#import "SDImageJPEGXLCoder.h"
#import <Accelerate/Accelerate.h>
#if __has_include(<jxl/decode.h>) && __has_include(<jxl/encode.h>)
#import <jxl/decode.h>
#import <jxl/encode.h>
#else
@import libjxl;
#endif

#define SD_TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))
#define SD_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

/// Calculate the actual thumnail pixel size
static CGSize SDCalculateThumbnailSize(CGSize fullSize, BOOL preserveAspectRatio, CGSize thumbnailSize) {
    CGFloat width = fullSize.width;
    CGFloat height = fullSize.height;
    CGFloat resultWidth;
    CGFloat resultHeight;
    
    if (width == 0 || height == 0 || thumbnailSize.width == 0 || thumbnailSize.height == 0 || (width <= thumbnailSize.width && height <= thumbnailSize.height)) {
        // Full Pixel
        resultWidth = width;
        resultHeight = height;
    } else {
        // Thumbnail
        if (preserveAspectRatio) {
            CGFloat pixelRatio = width / height;
            CGFloat thumbnailRatio = thumbnailSize.width / thumbnailSize.height;
            if (pixelRatio > thumbnailRatio) {
                resultWidth = thumbnailSize.width;
                resultHeight = ceil(thumbnailSize.width / pixelRatio);
            } else {
                resultHeight = thumbnailSize.height;
                resultWidth = ceil(thumbnailSize.height * pixelRatio);
            }
        } else {
            resultWidth = thumbnailSize.width;
            resultHeight = thumbnailSize.height;
        }
    }
    
    return CGSizeMake(resultWidth, resultHeight);
}

@implementation SDImageJPEGXLCoder

+ (instancetype)sharedCoder {
    static SDImageJPEGXLCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageJPEGXLCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode

- (BOOL)canDecodeFromData:(NSData *)data {
    // See: https://en.wikipedia.org/wiki/List_of_file_signatures
    if (!data) {
        return NO;
    }
    
    // Seems libjxl has API to check file signatures :)
    JxlSignature result = JxlSignatureCheck(data.bytes, data.length);
    if (result == JXL_SIG_CODESTREAM || result == JXL_SIG_CONTAINER) {
        return YES;
    }
    
    /**
     if (!data) {
     return NO;
     }
     uint16_t magic2;
     [data getBytes:&magic2 length:2];
     if (magic2 == SD_TWO_CC(0xFF, 0x0A)) {
     // FF 0A
     return YES;
     }
     if (data.length >= 12) {
     // 00 00 00 0C 4A 58 4C 20 0D 0A 87 0A
     uint32_t magic4;
     [data getBytes:&magic4 range:NSMakeRange(0, 4)];
     if (magic4 != SD_FOUR_CC(0x00, 0x00, 0x00, 0x0C)) return NO;
     [data getBytes:&magic4 range:NSMakeRange(4, 8)];
     if (magic4 != SD_FOUR_CC(0x4A, 0x58, 0x4C, 0x20)) return NO;
     [data getBytes:&magic4 range:NSMakeRange(8, 12)];
     if (magic4 != SD_FOUR_CC(0x0D, 0x0A, 0x87, 0x0A)) return NO;
     return YES;
     }
     */
    
    return NO;
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    CGFloat scale = 1;
    if ([options valueForKey:SDImageCoderDecodeScaleFactor]) {
        scale = [[options valueForKey:SDImageCoderDecodeScaleFactor] doubleValue];
        if (scale < 1) {
            scale = 1;
        }
    }
    
    CGSize thumbnailSize = CGSizeZero;
    NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
    if (thumbnailSizeValue != nil) {
#if SD_MAC
        thumbnailSize = thumbnailSizeValue.sizeValue;
#else
        thumbnailSize = thumbnailSizeValue.CGSizeValue;
#endif
    }
    
    BOOL preserveAspectRatio = YES;
    NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
    if (preserveAspectRatioValue != nil) {
        preserveAspectRatio = preserveAspectRatioValue.boolValue;
    }
    
    CGImageRef imageRef = [self sd_createJXLImageWithData:data thumbnailSize:thumbnailSize preserveAspectRatio:preserveAspectRatio];
    if (!imageRef) {
        return nil;
    }
    
#if SD_MAC
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#endif
    CGImageRelease(imageRef);
    
    return image;
}

- (nullable CGImageRef)sd_createJXLImageWithData:(NSData *)data thumbnailSize:(CGSize)thumbnailSize preserveAspectRatio:(BOOL)preserveAspectRatio CF_RETURNS_RETAINED {
    // Learn example to render on screen, see: libjxl/tools/viewer/load_jxl.cc
    
    JxlDecoder *dec = JxlDecoderCreate(NULL);
    if (!dec) return nil;
    
    // feed data
    JxlDecoderStatus status = JxlDecoderSetInput(dec, data.bytes, data.length);
    if (status != JXL_DEC_SUCCESS) return nil;
    
    // note: when using `JxlDecoderSubscribeEvents` libjxl behaves likes incremental decoding
    // which need event loop to get latest status via `JxlDecoderProcessInput`
    // each status reports your next steps's info
    status = JxlDecoderSubscribeEvents(dec, JXL_DEC_BASIC_INFO | JXL_DEC_COLOR_ENCODING | JXL_DEC_FULL_IMAGE);
    if (status != JXL_DEC_SUCCESS) return nil;
    
    // decode it
    status = JxlDecoderProcessInput(dec);
    if (status != JXL_DEC_BASIC_INFO) return nil;
    
    // info about size/alpha
    JxlBasicInfo info;
    status = JxlDecoderGetBasicInfo(dec, &info);
    if (status != JXL_DEC_SUCCESS) return nil;
    
    // colorspace
    CGColorSpaceRef colorSpaceRef;
    size_t profileSize;
    status = JxlDecoderProcessInput(dec);
    if (status != JXL_DEC_COLOR_ENCODING) return nil;
    status = JxlDecoderGetICCProfileSize(dec, JXL_COLOR_PROFILE_TARGET_ORIGINAL, &profileSize);
    
    if (status == JXL_DEC_SUCCESS && profileSize > 0) {
        // embed ICC Profile
        NSMutableData *profileData = [NSMutableData dataWithLength:profileSize];
        status = JxlDecoderGetColorAsICCProfile(dec, JXL_COLOR_PROFILE_TARGET_ORIGINAL, profileData.mutableBytes, profileSize);
        if (status != JXL_DEC_SUCCESS) return nil;
        
        if (@available(iOS 10, tvOS 10, macOS 10.12, watchOS 3, *)) {
            colorSpaceRef = CGColorSpaceCreateWithICCData((__bridge CFDataRef)profileData);
        } else {
            colorSpaceRef = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)profileData);
        }
    } else {
        // Use deviceRGB
        colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        CGColorSpaceRetain(colorSpaceRef);
    }
    
    // bitmap format
    BOOL hasAlpha = info.alpha_bits != 0;
    BOOL premultiplied = info.alpha_premultiplied;
    SDImagePixelFormat pixelFormat = [SDImageCoderHelper preferredPixelFormat:hasAlpha];
    JxlDataType dataType;
    
    // 16 bit or 8 bit, HDR ?
    CGBitmapInfo bitmapInfo = pixelFormat.bitmapInfo;
    CGImageByteOrderInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    size_t alignment = pixelFormat.alignment;
    size_t components = hasAlpha ? 4 : 3;
    size_t bitsPerComponent;
    if (bitmapInfo & kCGBitmapFloatComponents) {
        // float16 HDR
        dataType = JXL_TYPE_FLOAT16;
        bitsPerComponent = 16;
        bitmapInfo = kCGBitmapByteOrderDefault | kCGBitmapFloatComponents;
    } else if (byteOrderInfo == kCGBitmapByteOrder16Big || byteOrderInfo == kCGBitmapByteOrder16Little) {
        // uint16 HDR
        dataType = JXL_TYPE_UINT16;
        bitsPerComponent = 16;
        bitmapInfo = kCGBitmapByteOrder16Host;
    } else {
        // uint8 SDR
        dataType = JXL_TYPE_UINT8;
        bitsPerComponent = 8;
        bitmapInfo = kCGBitmapByteOrderDefault;
    }
    // libjxl now always prefer RGB / RGBA order
    if (hasAlpha) {
        if (premultiplied) {
            bitmapInfo |= kCGImageAlphaPremultipliedLast;
        } else {
            bitmapInfo |= kCGImageAlphaLast;
        }
    } else {
        bitmapInfo |= kCGImageAlphaNone;
    }
    JxlPixelFormat format = {
        .num_channels = (uint32_t)components,
        .data_type = dataType,
        .endianness = JXL_NATIVE_ENDIAN,
        .align = alignment
    };
    
    size_t bitsPerPixel = components * bitsPerComponent;
    size_t width = info.xsize;
    size_t height = info.ysize;
    size_t bytesPerRow = SDByteAlign(width * (bitsPerPixel / 8), alignment);
    
    // bitmap buffer
    size_t bufferSize = height * bytesPerRow;
    void *buffer = malloc(bufferSize); // malloc + free
    status = JxlDecoderSetImageOutBuffer(dec, &format, buffer, bufferSize);
    if (status != JXL_DEC_SUCCESS) return nil;
    
    status = JxlDecoderProcessInput(dec);
    if (status != JXL_DEC_FULL_IMAGE) return nil; // Final status
    
    JxlDecoderDestroy(dec);
    
    // create CGImage
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferSize, FreeImageData);
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    BOOL shouldInterpolate = YES;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, shouldInterpolate, renderingIntent);
    if (!imageRef) {
        return nil;
    }
    return imageRef;
}

#pragma mark - Encode

- (BOOL)canEncodeToFormat:(SDImageFormat)format { 
    return NO;
}


- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image format:(SDImageFormat)format options:(nullable SDImageCoderOptions *)options { 
    return nil;
}

@end
