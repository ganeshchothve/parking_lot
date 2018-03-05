// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require noty
//= require lodash
//= require intlTelInput
//= require jquery.ui.widget
//= require jquery.validate
//= require moment
//= require jquery.fileupload
//= require selectize
//= require plugins/array_field
//= require plugins/file_uploader
//= require daterangepicker
//= require fontawesome-all
//= require bootstrap-datetimepicker.min
//= require tooltipster.bundle.min
//= require jquery.colorbox-min
//= require jquery.zoom.min

//= require utils
//= require file-icon
//= require form-initializer
//= require validator
//= require registration

$.ajaxSetup({
  headers: {
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
  }
});

$(document).ready(function(){
	setTimeout(function(){
		$("p.notice, p.alert").fadeOut();
	}, 3000);

	$('body').on('mouseenter', '.unit-tooltip:not(.tooltipstered)', function(){
	    $(this)
	        .tooltipster({
	        	theme: 'tooltipster-borderless',
			 	contentAsHTML: true,
			 	functionInit: function(instance, helper){
			 		var content = instance.content(),
		            	people = JSON.parse(content);

		            newContent = '<div>Flat No: '+ people[0] +'</div><div>Bedrooms: '+ people[3] +'</div><div>Carpet Area: '+ people[1] +' Sq.Ft.</div><div>Base Price: '+ people[2] +'/-</div><div>Booking Status: '+ people[4] +'</div>';
		        	instance.content(newContent);
			 	}
	        })
	        .tooltipster('open');
	});

	/* New UI */
	$(".navigate").on("click", function(){
		var $navigate = $(this);
		var selectedValues = {};
		if($navigate.data("stage") == "choose-tower"){
			if($navigate.data("navigate-to") == "next"){
				$("#stage-apartment-selector").find("select.required").each(function(){
					if($(this).val() != ""){
						selectedValues[$(this).attr("name")] = $(this).val();
					} else {
						selectedValues[$(this).attr("name")] = "NA";
					}
				});
				localStorage.setItem('selectedValues', JSON.stringify(selectedValues));
			}

			if(Object.values(selectedValues).filter(item => item == "NA").length > 1){
				notify("Please select atleast one field", "error", 3000, 300);
			} else {
				selectedValues = JSON.parse(localStorage.getItem("selectedValues"));
				$navigate.attr("href", "/dashboard/apartment-selector/"+selectedValues.bedrooms+","+selectedValues.base_price);
			}
		} else if($navigate.data("stage") == "select-apartment"){
			var towerid = $navigate.data("selected-towerid");
			if(towerid == 0){
				notify("Please select a tower to proceed.", "error", 3000, 300);
			} else {
				selectedValues = JSON.parse(localStorage.getItem("selectedValues"));
				selectedValues.towerid = towerid;
				localStorage.setItem('selectedValues', JSON.stringify(selectedValues));

				$navigate.attr("href", "/dashboard/apartment-selector/"+selectedValues.bedrooms+","+selectedValues.base_price+"/"+selectedValues.towerid);
			}
		} else if($navigate.data("stage") == "kyc-details"){
			selectedValues = JSON.parse(localStorage.getItem("selectedValues"));
			if(selectedValues.unit_id){
				$navigate.attr("href", "/dashboard/apartment-selector/"+selectedValues.bedrooms+","+selectedValues.base_price+"/"+selectedValues.towerid+"/"+selectedValues.unit_id);
			} else {
				notify("Please select any unit to proceed.", "error", 3000, 300);
			}
		}
	});

	$(".tower-name-box").on("click", function(){
		if($(this).hasClass("active")){
			$(this).removeClass("active");
			$('[data-stage="select-apartment"]').data("selected-towerid", 0);
		} else {
			$(".tower-name-box").removeClass("active");
			$(this).addClass("active");
			$('[data-stage="select-apartment"]').data("selected-towerid", $(this).data("towerid"));
		}
	});
	/* New UI */

	$(".colorbox-init").colorbox({
		maxWidth: "90%",
		maxHeight: "90%",
		onComplete: function(){
			$('#cboxLoadedContent').zoom();
		}
	});

	currentScreen = 1;
	selectedTower = "";
	var getAllHeights = [];
	var winHeight = $(window).height();
	var getHeaderHeight = $("header").outerHeight();
	$(".screens-wrapper").css({
		"min-height": winHeight,
		"padding-top": getHeaderHeight
	});
	$('.full-height').css({
		"min-height":winHeight
	});

	// $(".navigate").on("click", function(){
	// 	var navigateTo = $(this).data("goto");
	// 	goToNextScreen(currentScreen, navigateTo);
	// });

	$(".hold-button").on("click", function(){
		window.onbeforeunload = null;
		$("#existing_kyc_form").submit();
	});
	$("#existing_kyc_form").on("submit", function(e){
		window.onbeforeunload = null;
	});

	$("#user_kyc_form").on("submit", function(e){
		window.onbeforeunload = null;
		ajaxUpdate($(this).serialize(), $(this).attr("action"), function(responseData){
			var kyc_userid = responseData._id;
			var kyc_name = responseData.name;

			$('[name="project_unit[user_kyc_ids][]"]')[0].selectize.addOption({text: kyc_name, value: kyc_userid});
			$('[name="project_unit[user_kyc_ids][]"]')[0].selectize.setValue(kyc_userid);

			$("#existing_kyc_form").submit();
		});
		e.preventDefault();
	});

	$("#tower-selector").on("click", ".tower-design", function(){
		if($(this).hasClass("active")){
			$("#tower-selector .tower-design").removeClass("active");
			selectedTower = "";
		} else {
			$("#tower-selector .tower-design").removeClass("active");
			selectedTower = $(this).addClass("active").data("towerid");
		}
	});

	$("#append-floors, #append-floors-clone").on("click", ".apt-selector-box .apt.bstatus-available", function(){
		$("#append-floors .apt-selector-box .apt.bstatus-available, #append-floors-clone .apt-selector-box .apt.bstatus-available").removeClass("bstatus-selected");
		$(this).addClass("bstatus-selected");

		var selectedValues = JSON.parse(localStorage.getItem("selectedValues"));
		console.log(selectedValues);
		selectedValues.unit_id = $(this).data("unit-id");
		console.log(selectedValues);
		localStorage.setItem('selectedValues', JSON.stringify(selectedValues));

		// hightlightUnit(type);

		var unitData = $(this).data("unit-details");
		console.log(unitData);

		var unitHtml = '<div>';
		   unitHtml += '<div>UNIT DETAILS</div>';
		   unitHtml += '<div>Flat No: '+ unitData[0] +'</div>';
		   unitHtml += '<div>Bedrooms: '+ unitData[3] +'</div>';
		   unitHtml += '<div>Carpet Area: '+ unitData[1] +'</div>';
		   unitHtml += '<div>Base Price: Rs.'+ unitData[2] +'/-</div>';
		   unitHtml += '<div>Booking Status: '+ unitData[4] +'</div>';
		   unitHtml += '</div>';

		$(".show-unit-details").html(unitHtml);
	});

	$(".preventSubmit").on("click", function(e){
		e.preventDefault();
	});

	$(".filter-submit-wrapper button").on("click", function(e){

		//clearHighlightedUnit();
		var data = $("#filter-form").serializeArray();
		var selectedValues = JSON.parse(localStorage.getItem("selectedValues"));

		for(let field of data){
			if(field.value!="" && field.value!="NA")
				selectedValues[field.name] = field.value
		}

		window.location.href = "/dashboard/apartment-selector/"+selectedValues.bedrooms+","+selectedValues.base_price+"/"+selectedValues.towerid;
		//return false;

		// for(let key in selectedValues){
		// 	if($('.filter-item-wrapper [name="'+ key +'"]').length > 0)
		// 		$('.filter-item-wrapper [name="'+ key +'"]')[0].selectize.setValue(selectedValues[key]);
		// }
		//localStorage.setItem('selectedValues', JSON.stringify(selectedValues));

		

		// ajaxUpdate({project_tower_id: selectedValues.tower}, "/dashboard/get_units", function(responseData){
		// 	if(responseData){
		// 		var floorWiseData = {};
		// 		var currentFloorData = [];
		// 		var currentFloor;
		// 		for(var unit of responseData){
		// 			if(typeof currentFloor == "undefined"){
		// 				currentFloor = unit.floor;
		// 				currentFloorData.push(unit);
		// 				floorWiseData["floor-"+currentFloor] = currentFloorData;
		// 			} else {
		// 				if(unit.floor == currentFloor){
		// 					currentFloorData.push(unit);
		// 					floorWiseData["floor-"+currentFloor] = currentFloorData;
		// 				} else {
		// 					currentFloor = unit.floor;
		// 					currentFloorData = [];
		// 					currentFloorData.push(unit)
		// 					floorWiseData["floor-"+currentFloor] = currentFloorData;
		// 				}
		// 			}
		// 		}
				
		// 		var buildingHtml = '';
		// 		$.each(floorWiseData, function(key,value) {
		// 			buildingHtml += '<div class="flats-'+ value.length +' apt-selector-box">';
		// 			buildingHtml += '<div class="floor-number">'+ parseInt(key.split("-")[1]).pad() +'</div>';
		// 			// test count
		// 			var testCount = 1;
		// 			for(var unit of value){
		// 				var status = [];
		// 				var finalStatus;
		// 				console.log(selectedValues);
		// 				for(var keyname in selectedValues){
		// 					if(keyname!="tower" && keyname!="unit_id"){
		// 						if((keyname == "base_price" && unit[keyname] > selectedValues[keyname].split("-")[0] && unit[keyname] < selectedValues[keyname].split("-")[1]) || (unit[keyname] == selectedValues[keyname])){
		// 							status.push(unit.status);
		// 						} else {
		// 							status.push("na");
		// 						}	
		// 					}
		// 				}
		// 				if(status.indexOf("na") > -1){
		// 					finalStatus = "na";
		// 				} else {
		// 					finalStatus = status[0];
		// 				}

		// 				buildingHtml += '<span data-testcount="'+ testCount +'" data-unit-id="'+ unit._id +'" class="unit-tooltip apt bstatus-' + finalStatus + '" title=\'["' + unit.name + '","'+ unit.carpet.toFixed(2) +'","'+ unit.base_price +'","'+ unit.bedrooms +'"]\'></span>';
		// 				testCount++;
		// 			}
		// 			buildingHtml += '</div>';
		// 		});

		// 		$("#append-floors").html(buildingHtml);
		// 	}
		// });
		e.preventDefault();
	});
});

$(window).on("load", function(){
	$('.init-selectize').selectize();
});

function hightlightUnit(type){
	$(".toggle-layout").toggleClass("active");
	//clearHighlightedUnit();
	//$("#floor-layout")[0].contentDocument.getElementsByClassName("type-"+type)[0].classList.add("active");
}

function clearHighlightedUnit(){
	var typelength = $("#floor-layout")[0].contentDocument.getElementsByClassName("flattype").length;
	for(let x = 0; x < typelength; x++){
		$("#floor-layout")[0].contentDocument.getElementsByClassName("flattype")[x].classList.remove("active");
	}
}

function goToNextScreen(cScreen, navigateTo){
	currentScreen = cScreen;
	if (currentScreen == 1){
		var goNext = false;
		var selectedValues = {};

		$(".screens-wrapper[data-screen="+currentScreen+"]").find("select.required").each(function(){
			if(!goNext && $(this).val() != ""){
				selectedValues[$(this).attr("name")] = $(this).val();
			}
		});

		localStorage.setItem('selectedValues', JSON.stringify(selectedValues));

		if(Object.keys(selectedValues).length > 0){
			ajaxUpdate(selectedValues, "/dashboard/get_towers", function(responseData){
				if(responseData){

					$(".step-bar-wrapper").addClass("active");

					navigateScreens(navigateTo, currentScreen, function(){
					//===== stuff to do with screen 2
						var towerHtml = "";
						for(var tower of responseData){
							$('[name="tower"]').each(function(){
								this.selectize.addOption({text: tower.project_tower_name, value: tower.project_tower_id});	
							});
							towerHtml += '<div class="tower-design-wrapper"><div class="tower-design" data-towerid="'+ tower.project_tower_id +'">'+ tower.project_tower_name +'</div><div>Total Units: 27<br />Available Units: 16</div></div>';
						}

						$("#tower-selector").html(towerHtml);
						currentScreen = navigateTo;
					});
				} else {
					notify("No data found with the selected values.", "error", 3000, 300);
				}
			});
		} else {
			notify("Please select atleast one field", "error", 3000, 300);
		}
	} else if(currentScreen == 2 && navigateTo == 3) {
		if($("#tower-selector .tower-design.active").length > 0){
			ajaxUpdate({project_tower_id: selectedTower}, "/dashboard/get_units", function(responseData){
				var selectedValues = JSON.parse(localStorage.getItem("selectedValues"));
				selectedValues.tower = selectedTower;
				localStorage.setItem("selectedValues", JSON.stringify(selectedValues));
				if(responseData){
					var floorWiseData = {};
					var currentFloorData = [];
					var currentFloor;
					for(var unit of responseData){
						if(typeof currentFloor == "undefined"){
							currentFloor = unit.floor;
							currentFloorData.push(unit);
							floorWiseData["floor-"+currentFloor] = currentFloorData;
						} else {
							if(unit.floor == currentFloor){
								currentFloorData.push(unit);
								floorWiseData["floor-"+currentFloor] = currentFloorData;
							} else {
								currentFloor = unit.floor;
								currentFloorData = [];
								currentFloorData.push(unit)
								floorWiseData["floor-"+currentFloor] = currentFloorData;
							}
						}
					}
					
					var buildingHtml = '';
					$.each(floorWiseData, function(key,value) {
						buildingHtml += '<div class="flats-'+ value.length +' apt-selector-box">';
						buildingHtml += '<div class="floor-number">'+ parseInt(key.split("-")[1]).pad() +'</div>';
						// test count
						var testCount = 1;
						for(var unit of value){
							var status = [];
							var finalStatus;
							for(var keyname in selectedValues){
								if(keyname!="tower" && keyname!="unit_id"){
									if((keyname == "base_price" && unit[keyname] > selectedValues[keyname].split("-")[0] && unit[keyname] < selectedValues[keyname].split("-")[1]) || (unit[keyname] == selectedValues[keyname])){
										status.push(unit.status);
									} else {
										status.push("na");
									}	
								}
							}
							if(status.indexOf("na") > -1){
								finalStatus = "na";
							} else {
								finalStatus = status[0];
							}

							//buildingHtml += '<span data-testcount="'+ testCount +'" data-unit-id="'+ unit._id +'" class="apt bstatus-' + finalStatus + '" title="'+ unit.name +'"></span>';
							buildingHtml += '<span data-testcount="'+ testCount +'" data-unit-id="'+ unit._id +'" class="unit-tooltip apt bstatus-' + finalStatus + '" title=\'["' + unit.name + '","'+ unit.carpet.toFixed(2) +'","'+ unit.base_price +'","'+ unit.bedrooms +'"]\'></span>';
							testCount++;
						}
						buildingHtml += '</div>';
					});

					$("#append-floors").html(buildingHtml);

					// var drawTowerHtml = "";
					navigateScreens(navigateTo, currentScreen, function(){
						var selectedValues = JSON.parse(localStorage.getItem("selectedValues"));
						for(var key in selectedValues){
							if($('.filter-item-wrapper [name="'+ key +'"]').length > 0)
								$('.filter-item-wrapper [name="'+ key +'"]')[0].selectize.setValue(selectedValues[key]);
						}
						currentScreen = navigateTo;
					});
				}
			});
		} else {
			notify("Please select a tower to proceed.", "error", 3000, 300);	
		}
	} else if (currentScreen == 3 && navigateTo == 4){
		var selectedValues = JSON.parse(localStorage.getItem("selectedValues"));

		$("#existing_kyc_form").attr("action", "/dashboard/hold_project_unit/"+selectedValues.unit_id);

		ajaxUpdate({unit_id:selectedValues.unit_id}, "/dashboard/get_unit_details", function(responseData){
			$(".flat-no").text("Flat: " + responseData.name);
			var flatDetailsHtml = '<div class="pull-left padding-left-30">';
			flatDetailsHtml += 'Tower: '+ responseData.project_tower_name +'<br/>\
					Floor: '+ responseData.floor +'<br/>\
					Flat no: '+ responseData.name +'<br/>';
			flatDetailsHtml += '</div><div class="pull-left padding-left-30 noborder">\
					Configuration: '+ responseData.bedrooms +' BHK<br/>\
					Min. Carpet Area: '+ responseData.carpet.toFixed(2) +' Sq.Ft.<br/>\
					Starting Price: '+ responseData.base_rate +' / Sq. Ft.</div>';
			
			$(".flat-details").html(flatDetailsHtml);

			navigateScreens(navigateTo, currentScreen);
			currentScreen = navigateTo;
		});
	} else if(currentScreen == 4 && navigateTo == 5){
		navigateScreens(navigateTo, currentScreen);
		currentScreen = navigateTo;
	} else {
		navigateScreens(navigateTo, currentScreen);
		currentScreen = navigateTo;
	}
}

function ajaxUpdate(data, url, callback){
	$.ajax({
		url: url,
		dataType: "json",
		method: "POST",
		data: data,
		success: function(response){
			if(typeof callback === "function") callback(response);
		},
		error: function(response){
			//if(typeof callback === "function") callback();
		}
	});
}

function notify(msg, type, display_msg_time, transition_delay=300){
	if(typeof msg == "string"){
		msg = msg;
	} else {
		msg = "We will make something else.";
	}
	$("#notify").html(msg).addClass("show "+type);
	setTimeout(function(){
		$("#notify").removeClass("show "+type);
		setTimeout(function(){
			$("#notify").html("");
		}, transition_delay);
	}, display_msg_time);
}

function navigateScreens(navigateTo, cScreen, callback){
	if(navigateTo == 1){
		$(".step-bar-wrapper").removeClass("active");
	}
	$(".step-bar-wrapper>div").removeClass("active");
	$(".step-bar-wrapper>div[data-step="+navigateTo+"]").addClass("active");

	if(navigateTo>cScreen){ //next
		$(".screens-wrapper[data-screen="+cScreen+"]").addClass("prev");
		$(".screens-wrapper[data-screen="+navigateTo+"]").removeClass("next");
	} else { //prev
		$(".screens-wrapper[data-screen="+cScreen+"]").addClass("next");
		$(".screens-wrapper[data-screen="+navigateTo+"]").removeClass("prev");
	}
	

	// window.history.pushState("", "", '/step-'+navigateTo);

	/*=== Callback after navigation if passed as an argument ===*/
	if(typeof callback === "function") callback();
}

Number.prototype.pad = function(n) {
    return new Array(n || 2).join('0').slice((n || 2) * -1) + this;
}