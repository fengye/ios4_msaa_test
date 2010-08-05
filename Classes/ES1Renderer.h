//
//  ES1Renderer.h
//  MSAATest
//
//  Created by Feng Ye on 10-8-5.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
    EAGLContext *context;

    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer;
	// MSAA enabled buffers
	GLuint msaaFramebuffer, msaaRenderbuffer, msaaDepthbuffer;
}

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

@end
