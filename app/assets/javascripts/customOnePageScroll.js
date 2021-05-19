/*One page scrolling with active tab*/

$(document).ready(function(){
	
	var aChildren = $(".nav-links a"); // find the a children of the list items
	var gap = $('header').outerHeight(); //Navigation height
	var aArray = []; // create the empty aArray
	for (var i=0; i < aChildren.length; i++) {    
		var aChild = aChildren[i];
		if (!$(aChild).hasClass('extLink')) {
			if ($(aChild).attr('rel')) {
				var ahref = $(aChild).attr('rel');
				aArray.push(ahref);
			}
		}
	}
	
	//On Scroll - Add class active to active tab
	$(window).scroll(function(){
		var windowPos = $(window).scrollTop(); // get the offset of the window from the top of page
		var windowHeight = $(window).height(); // get the height of the window
		var docHeight = $(document).height();
		for(i=0;i<aArray.length;i++){
			var theID = aArray[i];
			var divPos = $("#"+theID).offset().top; // get the offset of the div from the top of page
			var divHeight = $("#"+theID).outerHeight(); // get the height of the div in question
			if (windowPos >= (divPos - gap) && windowPos < ((divPos - gap) + divHeight-180)) {				

				if ( !$("a[rel='" + theID + "']").hasClass("active"))
                {
                   ga('set', 'page', '/'+theID);
                   ga('send', 'pageview');
                   $("a[rel='" + theID + "']").addClass("active"); 
                }                
    			
			} else {
				$("a[rel='" + theID + "']").removeClass("active");
			}
		}	
		
		//If document has scrolled to the end. Add active class to the last navigation menu
		if(windowPos + windowHeight == docHeight) {
			if (!$(".nav-links a:last-child").hasClass("active")) {
				var navActiveCurrent = $(".active").attr("rel");
				$("a[rel='" + navActiveCurrent + "']").removeClass("active");
				$(".nav-links a:last-child").addClass("active");
			}
		}
		
	});
	
	//On Click
	$('.nav-links a').on("click", function(){
		win_wd = $(window).width();
		if(!$(this).hasClass('extLink')) {
			var href = $(this).attr("rel");

			if(win_wd <=768){
				var gap = 60; //Navigation height
				$('html,body').animate({
					scrollTop: $("#"+href).offset().top - gap
				}, 1000);
			}
			else{
				var gap = $('header').outerHeight() - 20; //Navigation height
				$('html,body').animate({
					scrollTop: $("#"+href).offset().top - gap
				}, 1000);
			}			
		
			
			
		}
	});
});
$(window).load(function(){
	gap = $('header').outerHeight();
})