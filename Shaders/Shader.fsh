//
//  Shader.fsh
//  MSAATest
//
//  Created by Feng Ye on 10-8-5.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
