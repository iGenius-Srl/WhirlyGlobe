package com.mousebirdconsulting.autotester.TestCases;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Color;

import com.mousebird.maply.ComponentObject;
import com.mousebird.maply.GlobeController;
import com.mousebird.maply.LinearTextureBuilder;
import com.mousebird.maply.MapController;
import com.mousebird.maply.BaseController;
import com.mousebird.maply.MaplyTexture;
import com.mousebird.maply.RenderController;
import com.mousebird.maply.VectorInfo;
import com.mousebird.maply.VectorObject;
import com.mousebird.maply.WideVectorInfo;
import com.mousebirdconsulting.autotester.Framework.MaplyTestCase;

import java.io.InputStream;
import java.nio.charset.Charset;
import java.util.ArrayList;

import okio.Okio;

public class WideVectorsTestCase extends MaplyTestCase {
    public WideVectorsTestCase(Activity activity) {
        super(activity);

        setTestName("Wide Vectors Test");
        setDelay(4);
        this.implementation = TestExecutionImplementation.Both;
    }

    void addGeoJSON(BaseController baseController, String name, float width, int drawPriority, int color) {
        // Build a dashed pattern
        LinearTextureBuilder texBuild = new LinearTextureBuilder();
        int[] pattern = new int[2];
        pattern[0] = 4;
        pattern[1] = 4;
        texBuild.setPattern(pattern);
        Bitmap patternImage = texBuild.makeImage();
        RenderController.TextureSettings texSet = new RenderController.TextureSettings();
        texSet.wrapU = true;  texSet.wrapV = true;
        MaplyTexture tex = baseController.addTexture(patternImage, texSet, RenderController.ThreadMode.ThreadCurrent);

        WideVectorInfo wideVecInfo = new WideVectorInfo();
        wideVecInfo.setColor(color);
        wideVecInfo.setLineWidth(width);
        wideVecInfo.setDrawPriority(drawPriority);
        wideVecInfo.setTexture(tex);
        wideVecInfo.setTextureRepeatLength(8.0);

        VectorInfo vecInfo = new VectorInfo();
        vecInfo.setLineWidth(4.0f);
        vecInfo.setColor(Color.BLACK);

        ArrayList<ComponentObject> compObjs = new ArrayList<ComponentObject>();

        try {
            InputStream stream = getActivity().getAssets().open("wide_vecs/" + name);
            String json = Okio.buffer(Okio.source(stream)).readUtf8();

            VectorObject vecObj = new VectorObject();
            vecObj.fromGeoJSON(json);
            vecObj = vecObj.subdivideToGlobeGreatCircle(0.0001f);

            ComponentObject compObj = baseController.addVector(vecObj, vecInfo, RenderController.ThreadMode.ThreadAny);
            compObjs.add(compObj);
            ComponentObject compObj2 = baseController.addWideVector(vecObj, wideVecInfo, RenderController.ThreadMode.ThreadAny);
            compObjs.add(compObj2);
        } catch (Exception e) {
        }
    }

    void wideVecTest(BaseController baseController) {
//        addGeoJSON(baseController, "sawtooth.geojson");
        addGeoJSON(baseController, "mowing-lawn.geojson", 20.0f, VectorInfo.VectorPriorityDefault, Color.BLUE);
        addGeoJSON(baseController, "spiral.geojson", 20.0f, VectorInfo.VectorPriorityDefault, Color.BLUE);
        addGeoJSON(baseController, "square.geojson", 20.0f, VectorInfo.VectorPriorityDefault, Color.BLUE);
        addGeoJSON(baseController, "line.geojson", 100.0f, VectorInfo.VectorPriorityDefault, Color.BLUE);
        addGeoJSON(baseController, "line.geojson", 60.0f, VectorInfo.VectorPriorityDefault+10, Color.RED);
        addGeoJSON(baseController, "track.geojson", 20.0f, VectorInfo.VectorPriorityDefault, Color.BLUE);
        addGeoJSON(baseController, "uturn2.geojson", 20.0f, VectorInfo.VectorPriorityDefault, Color.BLUE);
        addGeoJSON(baseController, "testJson.geojson", 20.0f, VectorInfo.VectorPriorityDefault, Color.BLUE);
    }

    @Override
    public boolean setUpWithMap(MapController mapVC) throws Exception {
        CartoLightTestCase baseTestCase = new CartoLightTestCase(getActivity());
        baseTestCase.setUpWithMap(mapVC);

        wideVecTest(mapVC);

        return true;
    }

    @Override
    public boolean setUpWithGlobe(GlobeController globeVC) throws Exception {
        CartoLightTestCase baseTestCase = new CartoLightTestCase(getActivity());
        baseTestCase.setUpWithGlobe(globeVC);

        wideVecTest(globeVC);

        return true;
    }
}