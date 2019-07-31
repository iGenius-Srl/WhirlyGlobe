/*
 *  BasicDrawableInstanceMTL.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 5/16/19.
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

#import "BasicDrawableInstanceMTL.h"
#import "ProgramMTL.h"
#import "SceneRendererMTL.h"
#import "DefaultShadersMTL.h"
#import "TextureMTL.h"

using namespace Eigen;

namespace WhirlyKit
{
    
BasicDrawableInstanceMTL::BasicDrawableInstanceMTL(const std::string &name)
    : BasicDrawableInstance(name), renderState(nil), setupForMTL(false), numInst(0)
{
}

void BasicDrawableInstanceMTL::setupForRenderer(const RenderSetupInfo *inSetupInfo)
{
    if (setupForMTL)
        return;
        
    if (instanceStyle == LocalStyle) {
        RenderSetupInfoMTL *setupInfo = (RenderSetupInfoMTL *)inSetupInfo;

        bzero(&uniMI,sizeof(uniMI));
        
        // Set up the instances in their own array
        std::vector<WhirlyKitShader::VertexTriModelInstance> insts(instances.size());
        for (int which = 0;which < instances.size();which++) {
            auto &inst = instances[which];
            auto &outInst = insts[which];
            
            // Color override
            if (inst.colorOverride) {
                uniMI.useInstanceColor = true;
                float colors[4];
                inst.color.asUnitFloats(colors);
                CopyIntoMtlFloat4(outInst.color, colors);
            } else {
                outInst.color[0] = 1.0;  outInst.color[1] = 1.0;  outInst.color[2] = 1.0;  outInst.color[3] = 1.0;
            }
            
            // Center
            CopyIntoMtlFloat3(outInst.center, inst.center);
            
            // Rotation/translation/scale
            CopyIntoMtlFloat4x4(outInst.mat, inst.mat);
            
            // EndCenter/direction
            Point3d dir = moving ? (inst.endCenter - inst.center)/inst.duration : Point3d(0.0,0.0,0.0);
            CopyIntoMtlFloat3(outInst.dir, dir);
            uniMI.hasMotion |= moving;
        }

        int bufferSize = sizeof(WhirlyKitShader::VertexTriModelInstance) * insts.size();
        instBuffer = [setupInfo->mtlDevice newBufferWithBytes:&insts[0] length:bufferSize options:MTLStorageModeShared];
        numInst = insts.size();
    }
    
    setupForMTL = true;
}

void BasicDrawableInstanceMTL::teardownForRenderer(const RenderSetupInfo *setupInfo)
{
    setupForMTL = false;
    instBuffer = nil;
}

void BasicDrawableInstanceMTL::draw(RendererFrameInfo *inFrameInfo,Scene *inScene)
{
    RendererFrameInfoMTL *frameInfo = (RendererFrameInfoMTL *)inFrameInfo;
    SceneMTL *scene = (SceneMTL *)inScene;
    SceneRendererMTL *sceneRender = (SceneRendererMTL *)frameInfo->sceneRenderer;
    BasicDrawableMTL *basicDrawMTL = (BasicDrawableMTL *)basicDraw.get();
    if (!basicDrawMTL)
        return;

    id<MTLRenderPipelineState> renderState = getRenderPipelineState(sceneRender,frameInfo,basicDrawMTL);
    
    // Wire up the various inputs that we know about
    // TODO: Some of these we need to override
    for (auto vertAttr : basicDrawMTL->vertexAttributes) {
        VertexAttributeMTL *vertAttrMTL = (VertexAttributeMTL *)vertAttr;
        if (vertAttrMTL->buffer)
            [frameInfo->cmdEncode setVertexBuffer:vertAttrMTL->buffer offset:0 atIndex:vertAttrMTL->bufferIndex];
    }
    
    // And provide defaults for the ones we don't
    // TODO: Consolidate this
    for (auto defAttr : basicDrawMTL->defaultAttrs)
        [frameInfo->cmdEncode setVertexBytes:&defAttr.data length:sizeof(defAttr.data) atIndex:defAttr.bufferIndex];
    for (auto defAttr : defaultAttrs)
        [frameInfo->cmdEncode setVertexBytes:&defAttr.data length:sizeof(defAttr.data) atIndex:defAttr.bufferIndex];
    
    // Wire up the model instances if we have them
    if (instanceStyle == LocalStyle) {
        if (moving)
            uniMI.time = frameInfo->currentTime - startTime;
        [frameInfo->cmdEncode setVertexBytes:&uniMI length:sizeof(uniMI) atIndex:WKSUniformDrawStateModelInstanceBuffer];
        [frameInfo->cmdEncode setVertexBuffer:instBuffer offset:0 atIndex:WKSModelInstanceBuffer];
    }

    // Pass through the uniform blocks from this drawable
    BasicDrawableMTL::encodeUniBlocks(frameInfo,uniBlocks);
    
    [frameInfo->cmdEncode setRenderPipelineState:renderState];
    
    // TODO: Fill this in
    float fade = 1.0;
    
    // Pass in the textures (and offsets)
    // Note: We could precalculate most of then when the texture changes
    //       And we should figure out how many textures they actually have
    int numTextures = 0;
    for (unsigned int texIndex=0;texIndex<std::max((int)texInfo.size(),2);texIndex++) {
        TexInfo *thisTexInfo = (texIndex < texInfo.size()) ? &texInfo[texIndex] : NULL;
        
        // Figure out texture adjustment for parent textures
        float texScale = 1.0;
        Vector2f texOffset(0.0,0.0);
        // Adjust for border pixels
        if (thisTexInfo && thisTexInfo->borderTexel > 0 && thisTexInfo->size > 0) {
            texScale = (thisTexInfo->size - 2 * thisTexInfo->borderTexel) / (double)thisTexInfo->size;
            float offset = thisTexInfo->borderTexel / (double)thisTexInfo->size;
            texOffset = Vector2f(offset,offset);
        }
        // Adjust for a relative texture lookup (using lower zoom levels)
        if (thisTexInfo && thisTexInfo->relLevel > 0) {
            texScale = texScale/(1<<thisTexInfo->relLevel);
            texOffset = Vector2f(texScale*thisTexInfo->relX,texScale*thisTexInfo->relY) + texOffset;
        }
        
        // Calculate offset and scales
        WhirlyKitShader::TexIndirect texInd;
        texInd.offset[0] = texOffset.x();  texInd.offset[1] = texOffset.y();
        texInd.scale[0] = texScale; texInd.scale[1] = texScale;
        
        [frameInfo->cmdEncode setVertexBytes:&texInd length:sizeof(texInd) atIndex:WKSTexIndirectStartBuffer+texIndex];
        
        // And the texture itself
        // Note: Should we be setting up the sampler?
        TextureBaseMTL *tex = NULL;
        if (thisTexInfo && thisTexInfo->texId != EmptyIdentity)
            tex = dynamic_cast<TextureBaseMTL *>(scene->getTexture(thisTexInfo->texId));
        if (tex) {
            [frameInfo->cmdEncode setVertexTexture:tex->getMTLID() atIndex:texIndex];
            [frameInfo->cmdEncode setFragmentTexture:tex->getMTLID() atIndex:texIndex];
            numTextures++;
        } else {
            [frameInfo->cmdEncode setVertexTexture:nil atIndex:texIndex];
            [frameInfo->cmdEncode setFragmentTexture:nil atIndex:texIndex];
        }
    }
    
    // Set the per-drawable draw state
    WhirlyKitShader::UniformDrawStateA uni;
    sceneRender->setupDrawStateA(uni,frameInfo);
    uni.numTextures = numTextures;
    uni.fade = fade;
    uni.clipCoords = basicDrawMTL->clipCoords;
    BasicDrawableMTL::applyUniformsToDrawState(uni, uniforms);
    // TODO: Fill in the override matrix
    bzero(&uni.singleMat,sizeof(uni.singleMat));
    [frameInfo->cmdEncode setVertexBytes:&uni length:sizeof(uni) atIndex:WKSUniformDrawStateBuffer];
    [frameInfo->cmdEncode setFragmentBytes:&uni length:sizeof(uni) atIndex:WKSUniformDrawStateBuffer];
    
    // Using the basic drawable geometry with a few tweaks
    if (instanceStyle == ReuseStyle) {
        switch (basicDraw->type) {
            case Lines:
                [frameInfo->cmdEncode drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:basicDrawMTL->numPts];
                break;
            case Triangles:
                if (!basicDrawMTL->triBuffer) {
                    // TODO: Figure out why this happens
                    // NSLog(@"BasicDrawableInstanceMTL: Bad basic drawable with no triangles.");
                    return;
                }
                // This actually draws the triangles (well, in a bit)
                [frameInfo->cmdEncode drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:basicDrawMTL->numTris*3 indexType:MTLIndexTypeUInt16 indexBuffer:basicDrawMTL->triBuffer indexBufferOffset:0];
                break;
            default:
                break;
        }
    } else {
        // Model instancing
        switch (basicDraw->type) {
            case Lines:
                [frameInfo->cmdEncode drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:basicDrawMTL->numPts instanceCount:numInst];
                break;
            case Triangles:
                [frameInfo->cmdEncode drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:basicDrawMTL->numTris*3 indexType:MTLIndexTypeUInt16 indexBuffer:basicDrawMTL->triBuffer indexBufferOffset:0 instanceCount:numInst];
                break;
            default:
                break;
        }
    }
}
    
id<MTLRenderPipelineState> BasicDrawableInstanceMTL::getRenderPipelineState(SceneRendererMTL *sceneRender,RendererFrameInfoMTL *frameInfo,BasicDrawableMTL *basicDrawMTL)
{
    if (renderState)
        return renderState;
    
    ProgramMTL *program = (ProgramMTL *)frameInfo->program;
    id<MTLDevice> mtlDevice = sceneRender->setupInfo.mtlDevice;
    
    MTLRenderPipelineDescriptor *renderDesc = sceneRender->defaultRenderPipelineState(sceneRender,frameInfo);
    renderDesc.vertexDescriptor = basicDrawMTL->getVertexDescriptor(program->vertFunc,basicDrawMTL->defaultAttrs);

    // Set up a render state
    NSError *err = nil;
    renderState = [mtlDevice newRenderPipelineStateWithDescriptor:renderDesc error:&err];
    if (err) {
        NSLog(@"BasicDrawableInstanceMTL: Failed to set up render state because:\n%@",err);
        return nil;
    }
    
    return renderState;
}
    
}