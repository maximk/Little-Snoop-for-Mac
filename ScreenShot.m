//
//  ScreenShot.m
//  SnoopOnMe1
//
//  Created by Maxim Kharchenko on 5/18/09.
//  Copyright 2010 Snoop on.me. All rights reserved.
//

#import "ScreenShot.h"

@interface ScreenShot (PrivateMethods)
-(void)flipImageData;
-(CGImageRef)createRGBImageFromBufferData;
@end

@implementation ScreenShot (PrivateMethods)

/*
 * perform an in-place swap from Quadrant 1 to Quadrant III format
 * (upside-down PostScript/GL to right side up QD/CG raster format)
 * We do this in-place, which requires more copying, but will touch
 * only half the pages.  (Display grabs are BIG!)
 *
 * Pixel reformatting may optionally be done here if needed.
 */

-(void)flipImageData
{
    long top, bottom;
    void * buffer;
    void * topP;
    void * bottomP;
    void * base;
    long rowBytes;
	
    top = 0;
    bottom = mHeight - 1;
    base = mData;
    rowBytes = mByteWidth;
    buffer = malloc(rowBytes);
    NSAssert( buffer != nil, @"malloc failure");
	
    while ( top < bottom )
    {
        topP = (void *)((top * rowBytes) + (intptr_t)base);
        bottomP = (void *)((bottom * rowBytes) + (intptr_t)base);
		
        /*
		 * Save and swap scanlines.
		 *
		 * This code does a simple in-place exchange with a temp buffer.
		 * If you need to reformat the pixels, replace the first two bcopy()
		 * calls with your own custom pixel reformatter.
		 */
        bcopy( topP, buffer, rowBytes );
        bcopy( bottomP, topP, rowBytes );
        bcopy( buffer, bottomP, rowBytes );
		
        ++top;
        --bottom;
    }
    free( buffer );
}

// Create a RGB CGImageRef from our buffer data
-(CGImageRef)createRGBImageFromBufferData
{
    CGColorSpaceRef cSpace = CGColorSpaceCreateWithName (kCGColorSpaceGenericRGB);
    NSAssert( cSpace != NULL, @"CGColorSpaceCreateWithName failure");
	
    CGContextRef bitmap = CGBitmapContextCreate(mData, mWidth, mHeight, 8, mByteWidth,
												cSpace,  
#if __BIG_ENDIAN__
												kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big /* XRGB Big Endian */);
#else
	kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little /* XRGB Little Endian */);
#endif                                    
    NSAssert( bitmap != NULL, @"CGBitmapContextCreate failure");
	
    // Get rid of color space
    CFRelease(cSpace);
	
    // Make an image out of our bitmap; does a cheap vm_copy of the  
    // bitmap
    CGImageRef image = CGBitmapContextCreateImage(bitmap);
    NSAssert( image != NULL, @"CGBitmapContextCreate failure");
	
    // Get rid of bitmap
    CFRelease(bitmap);
    
    return image;
}

@end

@implementation ScreenShot

#pragma mark ---------- Initialization ----------

-(id) init
{
    if (self = [super init])
    {
		// Create a full-screen OpenGL graphics context
		
		// Specify attributes of the GL graphics context
		NSOpenGLPixelFormatAttribute attributes[] = {
			NSOpenGLPFAFullScreen,
			NSOpenGLPFAScreenMask,
			CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
			(NSOpenGLPixelFormatAttribute) 0
		};
		
		NSOpenGLPixelFormat *glPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
		if (!glPixelFormat)
		{
			return nil;
		}
		
		// Create OpenGL context used to render
		mGLContext = [[[NSOpenGLContext alloc] initWithFormat:glPixelFormat shareContext:nil] autorelease];
		
		// Cleanup, pixel format object no longer needed
		[glPixelFormat release];
		
        if (!mGLContext)
        {
            [self release];
            return nil;
        }
        [mGLContext retain];
		
        // Set our context as the current OpenGL context
        [mGLContext makeCurrentContext];
        // Set full-screen mode
        [mGLContext setFullScreen];
		
		NSRect mainScreenRect = [[NSScreen mainScreen] frame];
		mWidth = mainScreenRect.size.width;
		mHeight = mainScreenRect.size.height;
		
        mByteWidth = mWidth * 4;                // Assume 4 bytes/pixel for now
        mByteWidth = (mByteWidth + 3) & ~3;    // Align to 4 bytes
		
        mData = malloc(mByteWidth * mHeight);
        NSAssert( mData != 0, @"malloc failed");
    }
    return self;
}

#pragma mark ---------- Screen Reader  ----------

// Perform a simple, synchronous full-screen read operation using glReadPixels(). 
// Although this is not the most optimal technique, it is sufficient for doing 
// simple one-shot screen grabs.
- (void) readFullScreenToBuffer
{
    [self readPartialScreenToBuffer: mWidth bufferHeight: mHeight bufferBaseAddress: mData];
}

// Use this routine if you want to read only a portion of the screen pixels
- (void) readPartialScreenToBuffer: (size_t) width bufferHeight:(size_t) height bufferBaseAddress: (void *) baseAddress
{
    // select front buffer as our source for pixel data
    glReadBuffer(GL_FRONT);
    
    //Read OpenGL context pixels directly.
	
    // For extra safety, save & restore OpenGL states that are changed
    glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4); /* Force 4-byte alignment */
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    
    //Read a block of pixels from the frame buffer
    glReadPixels(0, 0, width, height, GL_BGRA, 
				 /*
	 IMPORTANT
	 
	 For the pixel data format and type parameters you should *always* specify:
	 
	 format: GL_BGRA
	 type: GL_UNSIGNED_INT_8_8_8_8_REV
	 
	 because this is the native format of the GPU for both PPC and Intel and will 
	 give you the best performance. Any deviation from this format will not give 
	 you optimal performance!
	 
	 BACKGROUND
	 
	 When using GL_UNSIGNED_INT_8_8_8_8_REV, the OpenGL implementation 
	 expects to find data in byte order ARGB on big-endian systems, but BGRA on 
	 little-endian systems. Because there is no explicit way in OpenGL to specify 
	 a byte order of ARGB with 32-bit or 16-bit packed pixels (which are common
	 image formats on Macintosh PowerPC computers), many applications specify 
	 GL_BGRA with GL_UNSIGNED_INT_8_8_8_8_REV. This practice works on a 
	 big-endian system such as PowerPC, but the format is interpreted differently 
	 on a little-endian system, and causes images to be rendered with incorrect colors.
	 
	 To prevent images from being rendered incorrectly by this application on little 
	 endian systems, you must specify the ordering of the data (big/little endian)
	 when creating Quartz bitmap contexts using the CGBitmapContextCreate function. 
	 See the createRGBImageFromBufferData: method in the Buffer.m source file for
	 the details.
	 
	 Also, if you need to reverse endianness, consider using vImage after the read. See: 
	 
	 http://developer.apple.com/documentation/Performance/Conceptual/vImage/
	 
	 */
				 GL_UNSIGNED_INT_8_8_8_8_REV,
				 baseAddress);
	
    glPopClientAttrib();
	
    //Check for OpenGL errors
    GLenum theError = GL_NO_ERROR;
    theError = glGetError();
    NSAssert1( theError == GL_NO_ERROR, @"OpenGL error 0x%04X", theError);
	
	[self flipImageData];
}

- (NSData *) getScreeenBuffer {
	return [NSData dataWithBytesNoCopy:mData length:mByteWidth*mHeight];
}

- (NSImage *) getScreenImage {
	
	// Create a bitmap from pixel data...
	CGImageRef cgImage = [self createRGBImageFromBufferData];
	// Create a bitmap rep from the image...
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	// Create an NSImage and add the bitmap rep to it...
	NSImage *image = [[NSImage alloc] init];
	[image addRepresentation:bitmapRep];
	[bitmapRep release];
	
	return image;
}

@end
