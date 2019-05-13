/*
 *  BasicDrawableInstance.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/1/11.
 *  Copyright 2011-2019 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import <vector>
#import <set>
#import <map>
#import "Identifiable.h"
#import "WhirlyVector.h"
#import "GlobeView.h"
#import "BasicDrawable.h"

namespace WhirlyKit
{

/** A Basic Drawable Instance replicates a basic drawable while
 tweaking some of the fields.  This is good for using the same
 geometry to implement vectors of multiple colors and line widths.
 */
class BasicDrawableInstance : public Drawable
{
friend class BasicDrawableInstanceBuilder;
    
public:
    EIGEN_MAKE_ALIGNED_OPERATOR_NEW;

    /// Either the old style where we reuse drawables or the new style, largely for models
    typedef enum {ReuseStyle,LocalStyle} Style;
    
    /// Construct empty
    BasicDrawableInstance(const std::string &name);
    virtual ~BasicDrawableInstance();
    
    /// Return the master being instanced
    BasicDrawableRef getMaster() const;

    /// Return the local MBR, if we're working in a non-geo coordinate system
    virtual Mbr getLocalMbr() const;
    
    /// We use this to sort drawables
    virtual unsigned int getDrawPriority() const;
    
    /// For OpenGLES2, this is the program to use to render this drawable.
    virtual SimpleIdentity getProgram() const;
    
    /// Set the shader program
    void setProgram(SimpleIdentity progID);
    
    /// We're allowed to turn drawables off completely
    virtual bool isOn(WhirlyKit::RendererFrameInfo *frameInfo) const;
    
    /// Return true if the drawable has alpha.  These will be sorted last.
    virtual bool hasAlpha(WhirlyKit::RendererFrameInfo *frameInfo) const;
    
    /// We can ask to use the z buffer
    virtual void setRequestZBuffer(bool val);
    virtual bool getRequestZBuffer() const;
    
    /// Set the z buffer mode for this drawable
    virtual void setWriteZBuffer(bool val);
    virtual bool getWriteZbuffer() const;
    
    /// Update anything associated with the renderer.  Probably renderUntil.
    virtual void updateRenderer(WhirlyKit::SceneRenderer *renderer);
    
    /// If present, we'll do a pre-render calculation pass with this program set
    virtual SimpleIdentity getCalculationProgram() const;
    
    /// Some drawables have a pre-render phase that uses the GPU for calculation
    virtual void calculate(RendererFrameInfo *frameInfo,Scene *scene);

    /// Set the enable on/off
    void setEnable(bool newEnable);
    
    /// Set the time range for enable
    void setEnableTimeRange(TimeInterval inStartEnable,TimeInterval inEndEnable);
    
    /// Set the min/max visible range
    void setVisibleRange(float inMinVis,float inMaxVis);

    /// Set the viewer based visibility
    void setViewerVisibility(double inMinViewerDist,double inMaxViewerDist,const Point3d &inViewerCenter);
    
    /// Set the color
    void setColor(RGBAColor inColor);
    
    /// Set the draw priority
    void setDrawPriority(int newPriority);
    
    /// Set the line width
    void setLineWidth(int newLineWidth);
    
    // Time we start counting from for motion
    void setStartTime(TimeInterval inStartTime);

    /// Set the uniforms to be applied to the geometry
    virtual void setUniforms(const SingleVertexAttributeSet &uniforms);

    /// Return the translation matrix if there is one
    const Eigen::Matrix4d *getMatrix() const;
    
    // Single geometry instance when we're doing multiple instance
    class SingleInstance
    {
    public:
        SingleInstance() : colorOverride(false) { }
        
        bool colorOverride;
        RGBAColor color;
        Point3d center;
        Eigen::Matrix4d mat;
        
        // End center and duration for moving models
        Point3d endCenter;
        TimeInterval duration;
    };
    
    /// Add a instance to the stack of instances this instance represents (mmm, noun overload)
    void addInstances(const std::vector<SingleInstance> &insts);
    
    // If set, we'll render this data where directed
    void setRenderTarget(SimpleIdentity newRenderTarget);
    
    // EmptyIdentity is the standard view, anything else ia custom render target
    SimpleIdentity getRenderTarget() const;
    
    /// Texture ID and relative override info
    class TexInfo
    {
    public:
        TexInfo() : texId(EmptyIdentity), relLevel(0), relX(0), relY(0), size(0), borderTexel(0) { }
        /// Texture ID within the scene
        SimpleIdentity texId;
        /// Our use of this texture relative to its native resolution
        int size,borderTexel;
        int relLevel,relX,relY;
    };

    /// Set the texture ID for a specific slot.  You get this from the Texture object.
    virtual void setTexId(unsigned int which,SimpleIdentity inId);
    
    /// Set all the textures at once
    virtual void setTexIDs(const std::vector<SimpleIdentity> &texIDs);
    
    /// Set the relative offsets for texture usage.
    /// We use these to look up parts of a texture at a higher level
    virtual void setTexRelative(int which,int size,int borderTexel,int relLevel,int relX,int relY);
    
protected:
    
    
    Style instanceStyle;
    SimpleIdentity programID;
    bool requestZBuffer,writeZBuffer;
    SimpleIdentity masterID;
    BasicDrawableRef basicDraw;
    bool enable;
    TimeInterval startEnable,endEnable;
    bool hasDrawPriority;
    int drawPriority;
    bool hasColor;
    RGBAColor color;
    bool hasLineWidth;
    float lineWidth;
    float minVis;
    float maxVis;
    double minViewerDist,maxViewerDist;
    Point3d viewerCenter;
    int numInstances;
    
    int centerSize,matSize,colorInstSize,colorSize,instSize,modelDirSize;
    TimeInterval startTime;
    bool moving;
    // Uniforms to apply to shader
    SingleVertexAttributeSet uniforms;
    SimpleIdentity renderTargetID;

    std::vector<TexInfo> texInfo;

    // If set, we'll instance this one multiple times
    std::vector<SingleInstance> instances;
    // While rendering, which instance we're rendering
//    int whichInstance;
};

/// Reference counted version of BasicDrawableInstance
typedef std::shared_ptr<BasicDrawableInstance> BasicDrawableInstanceRef;

}
