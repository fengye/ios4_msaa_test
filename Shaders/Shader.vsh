//
//  Shader.vsh
//  MSAATest
//
//  Created by Feng Ye on 10-8-5.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;


varying vec4 colorVarying;

uniform float translate;
uniform mat4 rotation;

void main()
{
    gl_Position = rotation * position;
//	gl_Position.x += cos(translate) / 2.0;
//  gl_Position.y += sin(translate) / 2.0;

    colorVarying = color;
}
