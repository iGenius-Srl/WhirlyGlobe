/*
 *  BaseInfo.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 7/6/15.
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

#import <math.h>
#import <set>
#import <map>
#import <string>
#import "Identifiable.h"
#import "Dictionary.h"
#import "WhirlyVector.h"
#import "WhirlyTypes.h"
#import "Drawable.h"
#import "VertexAttribute.h"

namespace WhirlyKit
{
class BasicDrawableBuilder;
typedef std::shared_ptr<BasicDrawableBuilder> BasicDrawableBuilderRef;
class BasicDrawableInstanceBuilder;
typedef std::shared_ptr<BasicDrawableInstanceBuilder> BasicDrawableInstanceBuilderRef;

/// Types of expressions we'll support for certain fields
typedef enum {ExpressionNone,ExpressionLinear,ExpressionExponential} ExpressionInfoType;

/// Base class for expressions
class ExpressionInfo : public Identifiable
{
public:
    EIGEN_MAKE_ALIGNED_OPERATOR_NEW;

    ExpressionInfo();
    ExpressionInfo(const ExpressionInfo &that);
    
    ExpressionInfoType type;
    
    float base;  // Used for exponential expressions
    std::vector<float> stopInputs;
};

/// Single float expression (e.g. opacity or what have you)
class FloatExpressionInfo: public ExpressionInfo
{
public:
    FloatExpressionInfo();
    FloatExpressionInfo(const FloatExpressionInfo &that);
    
    std::vector<float> stopOutputs;
};
typedef std::shared_ptr<FloatExpressionInfo> FloatExpressionInfoRef;

/// Color expression (e.g. for continuous color changes)
class ColorExpressionInfo: public ExpressionInfo
{
public:
    ColorExpressionInfo();
    ColorExpressionInfo(const ColorExpressionInfo &that);
    
    std::vector<RGBAColor> stopOutputs;
};
typedef std::shared_ptr<ColorExpressionInfo> ColorExpressionInfoRef;

/** Object use as the base for parsing description dictionaries.
 */
class BaseInfo
{
public:
    EIGEN_MAKE_ALIGNED_OPERATOR_NEW;

    BaseInfo();
    BaseInfo(const BaseInfo &that);
    BaseInfo(const Dictionary &dict);
    
    // Convert contents to a string for debugging
    virtual std::string toString();
    
    /// Set the various parameters on a basic drawable
    void setupBasicDrawable(BasicDrawableBuilder *drawBuild) const;
    void setupBasicDrawable(BasicDrawableBuilderRef drawBuild) const;

    /// Set the various parameters on a basic drawable instance
    void setupBasicDrawableInstance(BasicDrawableInstanceBuilder *drawBuild) const;
    void setupBasicDrawableInstance(BasicDrawableInstanceBuilderRef drawBuild) const;

    double minVis,maxVis;
    double minVisBand,maxVisBand;
    double minViewerDist,maxViewerDist;
    int zoomSlot;
    double minZoomVis,maxZoomVis;
    Point3d viewerCenter;
    double drawOffset;
    int drawPriority;
    bool enable;
    double fade;
    double fadeIn;
    double fadeOut;
    TimeInterval fadeOutTime;
    TimeInterval startEnable,endEnable;
    SimpleIdentity programID;
    int extraFrames;
    bool zBufferRead,zBufferWrite;
    SimpleIdentity renderTargetID;
    
    SingleVertexAttributeSet uniforms;
};
typedef std::shared_ptr<BaseInfo> BaseInfoRef;

}
