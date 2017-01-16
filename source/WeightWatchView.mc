using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class WeightWatchView extends Ui.View {
    hidden var mMeasurementDate = "1.1.2017";
    hidden var mWeight = "0.00";
    hidden var mModel;

    function initialize() {
        Ui.View.initialize();
    }
    
    //! Loading of resources
    function onLayout(dc) {

        View.setLayout(Rez.Layouts.MainLayout(dc));

        var labelView = View.findDrawableById("appLabel");
        labelView.locY = Ui.LAYOUT_VALIGN_TOP;
        labelView.setText(Rez.Strings.appLabel);
        
        var latestMeasurementView = View.findDrawableById("latestMeasurementLabel");
        latestMeasurementView.locY = Ui.LAYOUT_VALIGN_TOP + 20;
		latestMeasurementView.setText(Rez.Strings.latestMeasurementLabel);
        
        var dateView = View.findDrawableById("dateLabel");
        dateView.locY = Ui.LAYOUT_VALIGN_TOP + 40;
        dateView.setText(mMeasurementDate);
		
		var weightDisplayView = View.findDrawableById("weightDisplayLabel");
		weightDisplayView.setText(mWeight);
        weightDisplayView.locY = Ui.LAYOUT_VALIGN_TOP + 80;
        weightDisplayView.setColor(Gfx.COLOR_DK_RED);
        
		return true;
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        var dateView = View.findDrawableById("dateLabel");
        dateView.locY = Ui.LAYOUT_VALIGN_TOP + 40;
        dateView.setText(mMeasurementDate);
    
		var weightDisplayView = View.findDrawableById("weightDisplayLabel");
		weightDisplayView.setText(mWeight);
        weightDisplayView.locY = Ui.LAYOUT_VALIGN_TOP + 80;
        weightDisplayView.setColor(Gfx.COLOR_DK_RED);
		
		View.onUpdate(dc);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

    function onReceive(json) {
        if (json instanceof Lang.String) {
            mWeight = json;
        }
        else if (json instanceof Lang.Dictionary) {
            var keys = json.keys();
            var values = json.values();
            //! Obtain the latest of the measurements
            
            for (var i = 0; i < keys.size(); i++ ) {
                System.println("key: " +keys[i]);
                System.println("value[0]: " +values[0]);
                var internalValues = values[0];
                var internalValuesSize = internalValues.size();
                var index = 0;
                if (internalValuesSize > 1) {
	            	index = internalValuesSize - 1;
	            }
                if (internalValues instanceof Lang.Array) {
                	var weightValue = internalValues[index]["weight"];
                	var weightString = weightValue.format("%.01f");
                	var measurementDate = internalValues[index]["date"];
                	mWeight = weightString;
                	mMeasurementDate = measurementDate;
                }
            }
        }
        Ui.requestUpdate();
    }    
}
