Chart.register({
  id: 'no_data',
  afterDraw: function(chart) {
    console.log('After draw: ', chart);
    //console.log('Title: ', chart.options.title.text);
    //console.log(chart.data.datasets[0].data.length,  chart.canvas.id, chart.data.datasets[0].data);
    if (chart.data.datasets.length == 0 || chart.data.datasets[0].data.length == 0) {
      // No data is present
      var ctx = chart.ctx;
      var width = chart.width;
      var height = chart.height;
      chart.clear();

      ctx.save();
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.font = "16px normal 'Helvetica Nueue'";
      if (chart.options.title != undefined && chart.options.title.text != undefined) {
        ctx.fillText(chart.options.title.text, width / 2, 18); // <====   ADDS TITLE
      }
      var lineHeight = 15;
      text = chart.options.noDataMsg || 'No data to display';
      text = text.split('\n');
      _.each(text, function(txt, i) {
        ctx.fillText(txt, width / 2, (height / 2 + i*lineHeight));
      });
      ctx.restore();
    }
  }
});
