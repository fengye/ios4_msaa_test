//
//  ES1Renderer.m
//  MSAATest
//
//  Created by Feng Ye on 10-8-5.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "ES1Renderer.h"

extern BOOL gMSAAEnabled;

@implementation ES1Renderer

// Create an OpenGL ES 1.1 context
- (id)init
{
    if ((self = [super init]))
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

        if (!context || ![EAGLContext setCurrentContext:context])
        {
            [self release];
            return nil;
        }

        // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
        glGenFramebuffersOES(1, &defaultFramebuffer);
        glGenRenderbuffersOES(1, &colorRenderbuffer);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
		
		// msaa fb
		glGenFramebuffersOES(1, &msaaFramebuffer);
		// msaa color buffer
		glGenRenderbuffersOES(1, &msaaRenderbuffer);
		// msaa depth buffer
		glGenRenderbuffersOES(1, &msaaDepthbuffer);
    }

    return self;
}

- (void)render
{
    // Replace the implementation of this method to do your own custom drawing

    static const GLfloat squareVertices[] = {
        -0.5f,  -0.33f,
         0.5f,  -0.33f,
        -0.5f,   0.33f,
         0.5f,   0.33f,
    };

    static const GLubyte squareColors[] = {
        255, 255,   0, 255,
        0,   255, 255, 255,
        0,     0,   0,   0,
        255,   0, 255, 255,
    };

    static float transY = 0.0f;

    // This application only creates a single context which is already set current at this point.
    // This call is redundant, but needed if dealing with multiple contexts.
    [EAGLContext setCurrentContext:context];

	// Choose framebuffer if it comes to MSAA
    if ( gMSAAEnabled )
	{
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer);
	}
	else {
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
	}
	
    glViewport(0, 0, backingWidth, backingHeight);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    transY += 0.075f;
	glRotatef(transY, 0, 0, 1);

    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// resolve the final pixels if MSAA enabled
	if ( gMSAAEnabled )
	{
		glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
		glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, defaultFramebuffer);
		glResolveMultisampleFramebufferAPPLE();
	}
	
	// discard depth buffer whenever possible, to gain more memory bandwidth.
	// this is no necessary for MSAA but helps boost performance even in non-MSAA cases.
	GLenum attachments[] = {GL_DEPTH_ATTACHMENT_OES};
	glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);

    // need to restore colorRenderbuffer if it's MSAA enabled
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
    // Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }

	GLint maxSamplesAllowed;
	glGetIntegerv(GL_MAX_SAMPLES_APPLE, &maxSamplesAllowed);
	
	// operation on msaa fb
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer);
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaRenderbuffer);
	glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, maxSamplesAllowed, GL_RGBA8_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, msaaRenderbuffer);
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaDepthbuffer);
	glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, maxSamplesAllowed, GL_DEPTH_COMPONENT24_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, msaaDepthbuffer);
	
	if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
	
    return YES;
}

- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffersOES(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffersOES(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }
	
	if ( msaaFramebuffer )
	{
		glDeleteFramebuffersOES(1, &msaaFramebuffer);
		msaaFramebuffer = 0;
	}
	if ( msaaRenderbuffer )
	{
		glDeleteRenderbuffersOES(1, &msaaRenderbuffer);
		msaaRenderbuffer = 0;
	}
	if ( msaaDepthbuffer )
	{
		glDeleteRenderbuffersOES(1, &msaaDepthbuffer);
		msaaDepthbuffer = 0;
	}
	

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

    [super dealloc];
}

@end
