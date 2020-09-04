// To fix the msie issue
jQuery.browser = {};
(function () {
    jQuery.browser.msie = false;
    jQuery.browser.version = 0;
    if (navigator.userAgent.match(/MSIE ([0-9]+)\./)) {
        jQuery.browser.msie = true;
        jQuery.browser.version = RegExp.$1;
    }
})();

(function(a){function b(b,d){var e=a.extend({},{width:"",height:"",initial_ZOOM:"",initial_POSITION:"",animation_SMOOTHNESS:5.5,animation_SPEED:5.5,zoom_MAX:800,zoom_MIN:"",zoom_OUT_TO_FIT:"YES",zoom_BUTTONS_SHOW:"YES",pan_BUTTONS_SHOW:"YES",pan_LIMIT_BOUNDARY:"YES",button_SIZE:18,button_COLOR:"#FFFFFF",button_BG_COLOR:"#000000",button_BG_TRANSPARENCY:55,button_ICON_IMAGE:"",button_AUTO_HIDE:"NO",button_AUTO_HIDE_DELAY:1,button_ALIGN:"bottom right",button_MARGIN:10,button_ROUND_CORNERS:"YES",mouse_DRAG:"YES",mouse_WHEEL:"YES",mouse_WHEEL_CURSOR_POS:"YES",mouse_DOUBLE_CLICK:"YES",background_COLOR:"#FFFFFF",border_SIZE:1,border_COLOR:"#000000",border_TRANSPARENCY:10,container:"",max_WIDTH:"",max_HEIGHT:"",full_BROWSER_SIZE:"NO",full_BROWSER_WIDTH_OFF:0,full_BROWSER_HEIGHT_OFF:0},d),f=e.width,g=e.height,h=e.max_WIDTH,i=e.max_HEIGHT,j=e.initial_ZOOM/100,k=e.initial_POSITION.split(" "),l=e.zoom_MAX/100,m=e.zoom_MIN/100,n=e.zoom_OUT_TO_FIT?e.zoom_OUT_TO_FIT===!0?!0:e.zoom_OUT_TO_FIT.toLowerCase()=="yes"||e.zoom_OUT_TO_FIT.toLowerCase()=="true"?!0:!1:!1,o=1+(e.animation_SPEED+1)/20,p=e.zoom_BUTTONS_SHOW?e.zoom_BUTTONS_SHOW===!0?!0:e.zoom_BUTTONS_SHOW.toLowerCase()=="yes"||e.zoom_BUTTONS_SHOW.toLowerCase()=="true"?!0:!1:!1,q=e.animation_SPEED,r=e.pan_BUTTONS_SHOW?e.pan_BUTTONS_SHOW===!0?!0:e.pan_BUTTONS_SHOW.toLowerCase()=="yes"||e.pan_BUTTONS_SHOW.toLowerCase()=="true"?!0:!1:!1,s=e.pan_LIMIT_BOUNDARY?e.pan_LIMIT_BOUNDARY===!0?!0:e.pan_LIMIT_BOUNDARY.toLowerCase()=="yes"||e.pan_LIMIT_BOUNDARY.toLowerCase()=="true"?!0:!1:!1,t=parseInt(e.button_SIZE/2)*2,u=e.button_COLOR,v=e.button_BG_COLOR,w=e.button_BG_TRANSPARENCY/100,x=e.button_ICON_IMAGE,y=e.button_AUTO_HIDE?e.button_AUTO_HIDE===!0?!0:e.button_AUTO_HIDE.toLowerCase()=="yes"||e.button_AUTO_HIDE.toLowerCase()=="true"?!0:!1:!1,z=e.button_AUTO_HIDE_DELAY*1e3,A=e.button_ALIGN.toLowerCase().split(" "),B=e.button_MARGIN,C=e.button_ROUND_CORNERS?e.button_ROUND_CORNERS===!0?!0:e.button_ROUND_CORNERS.toLowerCase()=="yes"||e.button_ROUND_CORNERS.toLowerCase()=="true"?!0:!1:!1,D=e.mouse_DRAG?e.mouse_DRAG===!0?!0:e.mouse_DRAG.toLowerCase()=="yes"||e.mouse_DRAG.toLowerCase()=="true"?!0:!1:!1,E=e.mouse_WHEEL?e.mouse_WHEEL===!0?!0:e.mouse_WHEEL.toLowerCase()=="yes"||e.mouse_WHEEL.toLowerCase()=="true"?!0:!1:!1,F=e.mouse_WHEEL_CURSOR_POS?e.mouse_WHEEL_CURSOR_POS===!0?!0:e.mouse_WHEEL_CURSOR_POS.toLowerCase()=="yes"||e.mouse_WHEEL_CURSOR_POS.toLowerCase()=="true"?!0:!1:!1,G=e.mouse_DOUBLE_CLICK?e.mouse_DOUBLE_CLICK===!0?!0:e.mouse_DOUBLE_CLICK.toLowerCase()=="yes"||e.mouse_DOUBLE_CLICK.toLowerCase()=="true"?!0:!1:!1,H=Math.max(1.5,e.animation_SMOOTHNESS-1),I=e.background_COLOR,J=e.border_SIZE,K=e.border_COLOR,L=e.border_TRANSPARENCY/100,M=e.full_BROWSER_SIZE?e.full_BROWSER_SIZE===!0?!0:e.full_BROWSER_SIZE.toLowerCase()=="yes"||e.full_BROWSER_SIZE.toLowerCase()=="true"?!0:!1:!1,N=e.full_BROWSER_WIDTH_OFF,O=e.full_BROWSER_HEIGHT_OFF,P=1,Q=1,R=0,S=0,T=0,U=0,V=0,W=0,X=0,Y=0,Z=0,_=0,ba,bb,bc,bd,be=0,bf=0,bg=0,bh=0,bi=0,bj=0,bk=0,bl=!1,bm=!1,bn=.5,bo=0,bp=0,bq=0,br=0,bs=!1,bt=!1,bu=!1,bv=!1,bw=!1,bx=!1,by=!1,bz="zoomOut",bA={_zi:!1,_zo:!1,_ml:!1,_mr:!1,_mu:!1,_md:!1,_rs:!1,_nd:!1},bB,bC,bD,bE=[],bF,bG=0,bH,bI,bJ,bK,bL,bM,bN,bO,bP=[],bQ,bR,bS=[],bT=1,bU=b.attr("id"),bV=function(){bN=bX(b),b.attr("galleryimg","no"),bB=e.container==""?b.wrap("<div></div>").parent():a("#"+e.container),bC=a("<div></div>").appendTo(bB).css({position:"absolute","z-index":1,top:"0px",left:"0px",width:"100%",height:"100%"}),M?(a("html").css("height","100%"),a("body").css({width:"100%",height:"100%",margin:"0px"}),String(N).indexOf("%")>-1?f=parseInt(a("body").innerWidth()*((100-parseInt(N))/100)):f=a("body").innerWidth()-N,String(O).indexOf("%")>-1?g=parseInt(a("body").innerHeight()*((100-parseInt(O))/100)):g=a("body").innerHeight()-O,h!==0&&h!==""&&(f=Math.min(h,f)),i!==0&&i!==""&&(g=Math.min(i,g)),a(window).bind("resize.smoothZoom"+bU,cj)):(f===""||f===0?(f=Math.max(bB.parent().width(),100),h!==0&&h!==""&&(f=Math.min(f,h))):!isNaN(f)||String(f).indexOf("px")>-1?(f=parseInt(f),h!==0&&h!==""&&(f=Math.min(f,h))):String(f).indexOf("%")>-1?(f=bB.parent().width()*(f.split("%")[0]/100),h!==0&&h!==""&&(f=Math.min(f,h))):f=100,g===""||g===0?(g=Math.max(bB.parent().height(),100),i!==0&&i!==""&&(g=Math.min(g,i))):!isNaN(g)||String(g).indexOf("px")>-1?(g=parseInt(g),i!==0&&i!==""&&(g=Math.min(g,i))):String(g).indexOf("%")>-1?(g=bB.parent().height()*(g.split("%")[0]/100),i!==0&&i!==""&&(g=Math.min(g,i))):g=100),bB.css({"-moz-user-select":"none","-khtml-user-select":"none","-webkit-user-select":"none","user-select":"none",width:f+"px",height:g+"px",position:"relative",overflow:"hidden","text-align":"left","background-color":e.background_COLOR}).addClass("noSel"),J>0&&(bS[0]=a("<div></div>").appendTo(bB).css({position:"absolute",width:J+"px",height:g+"px",top:"0px",left:"0px","z-index":3,"background-color":K,opacity:L}),bS[1]=a("<div></div>").appendTo(bB).css({position:"absolute",width:J+"px",height:g+"px",top:"0px",left:f-J+"px","z-index":4,"background-color":K,opacity:L}),bS[2]=a("<div>&nbsp;</div>").appendTo(bB).css({position:"absolute",width:f-J*2+"px",height:J+"px",top:"0px",left:J+"px","z-index":5,"background-color":K,opacity:L,"line-height":"1px"}),bS[3]=a("<div>&nbsp;</div>").appendTo(bB).css({position:"absolute",width:f-J*2+"px",height:J+"px",top:g-J+"px",left:J+"px","z-index":6,"background-color":K,opacity:L,"line-height":"1px"})),b.attr("usemap")!=undefined&&(bQ=a("map[name='"+b.attr("usemap").split("#").join("")+"']").children("area"),bQ.each(function(){a(this).css("cursor","pointer"),bP.push(a(this).attr("coords").split(","))})),bO=new c(bB),bR=new Image,bR.src=x,bR.complete?(bs=!0,bt?bW():""):a(bR).bind("load.smoothZoom onreadystatechange.smoothZoom",function(){bs=!0,bt?bW():""}),b.hide(),b.one("load",function(){bt=!0,bs?bW():""}).each(function(){this.complete&&a(this).trigger("load")})},bW=function(){bN=bX(b),b.removeAttr("width"),b.removeAttr("height"),R=b.width(),S=b.height(),bY(),m==0||j!=0?Q=be=j!=""?j:P:Q=be=P=m,bc=be*R,bd=be*S,k==""?(ba=T=(f-bc)/2,bb=U=(g-bd)/2):(ba=T=f/2-parseInt(k[0])*be,bb=U=g/2-parseInt(k[1])*be,V=(T-(f-bc)/2)/(bc/f),W=(U-(g-bd)/2)/(bd/g)),bJ=Math.max(1,(f+g)/500)-1+q*q/4+2;if(!s||bx||j!=P)b.css("cursor","move"),bC.css("cursor","move");b.css({position:"relative","z-index":2,left:"0px",top:"0px"}).hide().fadeIn(500,function(){bO.destroy(),bO=null}),bZ(),ck()},bX=function(a){return{prop_origin:[prop_origin,prop_origin!==!1&&prop_origin!==undefined?a.css(prop_origin):null],prop_transform:[prop_transform,prop_transform!==!1&&prop_transform!==undefined?a.css(prop_transform):null],position:["position",a.css("position")],"z-index":["z-index",a.css("z-index")],cursor:["cursor",a.css("cursor")],left:["left",a.css("left")],top:["top",a.css("top")],width:["width",a.css("width")],height:["height",a.css("height")]}},bY=function(){R==f&&S==g?P=1:R<f&&S<g?(P=f/R,n?P*S>g&&(P=g/S):(P*S<g&&(P=g/S),f/R!==g/S&&(bx=!0,b.css("cursor","move"),bC.css("cursor","move")))):(P=f/R,n?P*S>g&&(P=g/S):(P*S<g&&(P=g/S),f/R!==g/S&&(bx=!0,b.css("cursor","move"),bC.css("cursor","move"))))},bZ=function(){var b=50,c=2,d=3,e=Math.ceil(t/4),h=t<16?50:0;r?(p?bH=parseInt(t+t*.85+(t-c)*3+d*2+e*2):bH=parseInt((t-c)*3+d*2+e*2),bI=parseInt((t-c)*3+d*2+e*2)):p?(bH=parseInt(t+e*2),bI=parseInt(t*2+e*3),bH=parseInt(bH/2)*2,bI=parseInt(bI/2)*2):(bH=0,bI=0);var i=(b-t)/2,j={x:bH-(t-(r?c:0))*2-e-d,y:bI/2-(t-(r?c:0))/2};bD=a("<div></div>").appendTo(bB).css({position:"absolute",width:bH+"px",height:bI+"px","z-index":7}).addClass("noSel"),A[0]=="top"?bD.css("top",B+"px"):A[0]=="center"?bD.css("top",parseInt((g-bI)/2)+"px"):bD.css("bottom",B+"px"),A[1]=="right"?bD.css("right",B+"px"):A[1]=="center"?bD.css("left",parseInt((f-bH)/2)+"px"):bD.css("left",B+"px");var k=a('<div id="controlsBg"></div>').appendTo(bD).css({position:"relative",width:"100%",height:"100%",opacity:w,"z-index":1}).addClass("noSel");use_bordRadius||!use_pngTrans||!C?(k.css({opacity:w,"background-color":v}),use_bordRadius&&C&&k.css({"-moz-border-radius":(h>0?4:5)+"px","-webkit-border-radius":(h>0?4:5)+"px","border-radius":(h>0?4:5)+"px","-khtml-border-radius":(h>0?4:5)+"px"})):cl(k,"cBg",bH,bI,h>0?4:5,375,v,x,1,h?50:0),bE[0]={_var:"_zi",l:e,t:r?(bI-t*2-d*2+2)/2:e,w:t,h:t,bx:-i,by:-i-h},bE[1]={_var:"_zo",l:e,t:r?(bI-t*2-d*2+2)/2+t+d*2-2:bI-t-e,w:t,h:t,bx:-b-i,by:-i-h},bE[2]={_var:"_mr",l:j.x-(t-c)-d,t:j.y,w:t-c,h:t-c,bx:-(c/2)-b*2-i,by:-(c/2)-i-h},bE[3]={_var:"_ml",l:j.x+(t-c)+d,t:j.y,w:t-c,h:t-c,bx:-(c/2)-b*3-i,by:-(c/2)-i-h},bE[4]={_var:"_mu",l:j.x,t:j.y+(t-c)+d,w:t-c,h:t-c,bx:-(c/2)-b*4-i,by:-(c/2)-i-h},bE[5]={_var:"_md",l:j.x,t:j.y-(t-c)-d,w:t-c,h:t-c,bx:-(c/2)-b*5-i,by:-(c/2)-i-h},bE[6]={_var:"_rs",l:j.x,t:j.y,w:t-c,h:t-c,bx:-(c/2)-b*6-i,by:-(c/2)-i-h},bF=bE.length;for(var m=0;m<bF;m++){bE[m].$ob=a("<div></div>").appendTo(a(bD)).css({display:m<2?p?"inherit":"none":r?"inherit":"none",position:"absolute",left:bE[m].l-1+"px",top:bE[m].t-1+"px",width:bE[m].w+2+"px",height:bE[m].h+2+"px",opacity:.7,"z-index":m+1}).addClass("noSel").bind("mouseover.smoothZoom",b$).bind("mouseout.smoothZoom",b_).bind("mousedown.smoothZoom touchstart.smoothZoom",{id:m},ca).bind("mouseup.smoothZoom",{id:m},cb);var n=a("<div></div>").appendTo(bE[m].$ob).attr("id",bE[m]._var+"norm").css({position:"absolute",left:1,top:1,width:bE[m].w+"px",height:bE[m].h+"px"}),o=a("<div></div>").appendTo(bE[m].$ob).attr("id",bE[m]._var+"over").css({position:"absolute",left:"0px",top:"0px",width:bE[m].w+2+"px",height:bE[m].h+2+"px"}).hide();use_bordRadius||!use_pngTrans||!C?(n.css("background",u),o.css("background",u),use_bordRadius&&C&&(n.css({"-moz-border-radius":"2px","-webkit-border-radius":"2px","border-radius":"2px","-khtml-border-radius":"2px"}),o.css({"-moz-border-radius":"2px","-webkit-border-radius":"2px","border-radius":"2px","-khtml-border-radius":"2px"}))):(cl(n,bE[m]._var+"norm",bE[m].w,bE[m].h,2,425,u,x,m+1,h?50:0),cl(o,bE[m]._var+"over",bE[m].w+2,bE[m].h+2,2,425,u,x,m+1,h?50:0));var q=a('<div id="'+bE[m]._var+'_icon"></div>').appendTo(bE[m].$ob);a(q).css({position:"absolute",left:1,top:1,width:bE[m].w+"px",height:bE[m].h+"px",background:"transparent url("+x+") "+bE[m].bx+"px "+bE[m].by+"px no-repeat"})}a(document).bind("mouseup.smoothZoom"+bU+" touchend.smoothZoom"+bU,ce),D&&(bB.bind("mousedown.smoothZoom touchstart.smoothZoom",cc),bB.bind("touchmove.smoothZoom",cd),bB.bind("touchend.smoothZoom",ce)),G&&bB.bind("dblclick.smoothZoom",function(b){bh=b.pageX-bB.offset().left-f/2,bi=b.pageY-bB.offset().top-g/2,cm(!0,!0),by=!1,Q<l&&bT==-1&&bj!=bh&&bk!=bi&&(bT=1),bj=bh,bk=bi,Q>=l&&bT==1&&(bT=-1),Q<=P&&bT==-1&&(bT=1),bT>0?(Q*=2,Q>l?Q=l:"",bA._zi=!0,clearTimeout(bL),ck(),bA._zi=!1):(Q/=2,Q<P?Q=P:"",bA._zo=!0,clearTimeout(bL),ck(),bA._zo=!1),b.stopPropagation(),a.browser.msie||b.preventDefault()}),E&&bB.bind("mousewheel.smoothZoom",cf),y&&bB.bind("mouseleave.smoothZoom",cg),bD.bind("mousedown.smoothZoom",function(b){b.stopPropagation(),a.browser.msie||b.preventDefault()}),G&&bD.bind("dblclick.smoothZoom",function(b){b.stopPropagation(),a.browser.msie||b.preventDefault()}),a(".noSel").each(function(){this.onselectstart=function(){return!1}})},b$=function(b){a(this).css("opacity")>.5&&a(this).css({opacity:1})},b_=function(b){a(this).css("opacity")>.5&&a(this).css({opacity:.7})},ca=function(b){bG=b.data.id,bl=!0,by=!1,a(this).css("opacity")>.5&&(bB.find("#"+bE[bG]._var+"norm").hide(),bB.find("#"+bE[bG]._var+"over").show(),bG!=6?bA[bE[bG]._var]=!0:(bA._rs=!0,Q=P,X=0,Y=0),bh=bi=0,cm(!0,!0),bT=1,bu?"":ck()),b.stopPropagation()},cb=function(b){bl||(bG=b.data.id,a(this).css("opacity")>.5&&(bG!=6?bA[bE[bG]._var]=!0:(bA._rs=!0,Q=P,X=0,Y=0),bh=bi=0,cm(!0,!0),clearTimeout(bL),ck(),bG!=6&&(bA[bE[bG]._var]=!1)))},cc=function(c){c.type=="mousedown"?(bA._nd&&bz!="zoomOut"&&(b.css("-moz-transform")&&use_trans2D&&ch(),bo=c.pageX-bB.offset().left-b.position().left,bp=c.pageY-bB.offset().top-b.position().top,bm=!0,a(document).bind("mousemove.smoothZoom"+bU,cd)),c.stopPropagation(),a.browser.msie||c.preventDefault()):(bA._nd&&bz!="zoomOut"&&(b.css("-moz-transform")&&ch(),bo=c.originalEvent.changedTouches[0].pageX-bB.offset().left-b.position().left,bp=c.originalEvent.changedTouches[0].pageY-bB.offset().top-b.position().top,bm=!0),c.preventDefault())},cd=function(a){if(a.type=="mousemove")return ci(a.pageX-bB.offset().left-bo,a.pageY-bB.offset().top-bp,be),bz="drag",bv=!0,bu?"":ck(),!1;a.preventDefault(),ci(a.originalEvent.changedTouches[0].pageX-bB.offset().left-bo,a.originalEvent.changedTouches[0].pageY-bB.offset().top-bp,be),bz="drag",bv=!0,bu?"":ck()},ce=function(b){bl?(bB.find("#"+bE[bG]._var+"norm").show(),bB.find("#"+bE[bG]._var+"over").hide(),bG!==6&&(bA[bE[bG]._var]=!1),bl=!1,b.stopPropagation()):bm&&D&&(b.type=="mouseup"?(a(document).unbind("mousemove.smoothZoom"+bU),bz="drag",bv=!1,bu?"":ck(),bm=!1):(b.preventDefault(),bz="drag",bv=!1,bu?"":ck(),bm=!1))};FF2&&a(document).bind("mousemove.smoothZoom"+bU+".mmff2",function(a){bq=a.pageX,br=a.pageY});var cf=function(a,b){return F&&(FF2?(bh=bq-bB.offset().left-f/2,bi=br-bB.offset().top-g/2):(bh=a.pageX-bB.offset().left-f/2,bi=a.pageY-bB.offset().top-g/2),cm(!0,!0)),by=!0,bv=!1,b>0?Q!=l&&(Q*=b<1?1+.3*b:1.3,Q>l?Q=l:"",bA._zi=!0,clearTimeout(bL),ck(),bA._zi=!1):Q!=P&&(Q/=b>-1?1+.3*-b:1.3,Q<P?Q=P:"",bA._zo=!0,clearTimeout(bL),ck(),bA._zo=!1),!1},cg=function(a){clearTimeout(bK),bK=setTimeout(function(){bD.fadeOut(600)},z),bB.bind("mouseenter.smoothZoom",function(a){clearTimeout(bK),bD.fadeIn(300)})},ch=function(){var a=b.css("-moz-transform").toString().replace(")","").split(",");bf=parseInt(a[4]),bg=parseInt(a[5])},ci=function(a,b,c){a!==""&&(Z=a+bf,s?(Z=Z+c*R<f?f-c*R:Z,Z=Z>0?0:Z,c*R<f&&(Z=(f-c*R)/2)):(Z=Z+c*R<f/2?f/2-c*R:Z,Z=Z>f/2?f/2:Z)),b!==""&&(_=b+bg,s?(_=_+c*S<g?g-c*S:_,_=_>0?0:_,c*S<g&&(_=(g-c*S)/2)):(_=_+c*S<g/2?g/2-c*S:_,_=_>g/2?g/2:_))},cj=function(){String(N).indexOf("%")>-1?f=parseInt(a("body").innerWidth()*((100-parseInt(N))/100)):f=a("body").innerWidth()-N,String(O).indexOf("%")>-1?g=parseInt(a("body").innerHeight()*((100-parseInt(O))/100)):g=a("body").innerHeight()-O,h!==0&&h!==""&&(f=Math.min(f,h)),i!==0&&i!==""&&(g=Math.min(g,i)),bB.css({width:f+"px",height:g+"px"}),J>0&&(bS[0].css({height:g+"px"}),bS[1].css({height:g+"px",left:f-J+"px"}),bS[2].css({width:f-J*2+"px"}),bS[3].css({width:f-J*2+"px",top:g-J+"px"})),bY(),A[1]=="center"&&bD.css("left",parseInt((f-bH)/2)+"px"),A[0]=="center"&&bD.css("top",parseInt((g-bI)/2)+"px"),bJ=Math.max(1,(f+g)/500)-1+q*q/4+2,bu?"":ck()},ck=function(){bA._nd=!0,bM=!1,bA._zi&&(by||(Q*=o),Q>l?Q=l:"",bA._nd=!1,bA._rs=!1,bz="zoomIn"),bA._zo&&(by||(Q/=o),Q<P?Q=P:"",bA._nd=!1,bA._rs=!1,bz="zoomOut"),bA._ml&&(V-=bJ,bA._nd=!1,bA._rs=!1,bz="left"),bA._mr&&(V+=bJ,bA._nd=!1,bA._rs=!1,bz="right"),bA._mu&&(W-=bJ,bA._nd=!1,bA._rs=!1,bz="up"),bA._md&&(W+=bJ,bA._nd=!1,bA._rs=!1,bz="down"),bA._rs&&(V+=(X-V)/8,W+=(Y-W)/8,bA._nd=!1,bz="reset"),be+=(Q-be)/H,bc=be*R,bd=be*S,bv&&(T=Z,U=_,cm(!0,!0)),bz=="zoomIn"?bc>Q*R-bn&&(bA._nd?bM=!0:"",be=Q,bc=be*R,bd=be*S):bz=="zoomOut"&&bc<Q*R+bn&&(bA._nd?bM=!0:"",be=Q,bc=be*R,bd=be*S),limitX=(bc-f)/(bc/f)/2,limitY=(bd-g)/(bd/g)/2,bv||(s?(V<-limitX-bh?V=-limitX-bh:"",V>limitX-bh?V=limitX-bh:"",bc<f&&(T=(f-bc)/2,cm(!0,!1)),W<-limitY-bi?W=-limitY-bi:"",W>limitY-bi?W=limitY-bi:"",bd<g&&(U=(g-bd)/2,cm(!1,!0))):(V<-limitX-bh-f/(bc/f*2)?V=-limitX-bh-f/(bc/f*2):"",V>limitX-bh+f/(bc/f*2)?V=limitX-bh+f/(bc/f*2):"",W<-limitY-bi-g/(bd/g*2)?W=-limitY-bi-g/(bd/g*2):"",W>limitY-bi+g/(bd/g*2)?W=limitY-bi+g/(bd/g*2):"")),!bv&&bz!="drag"&&(T=(f-bc)/2+bh+V*(bc/f),U=(g-bd)/2+bi+W*(bd/g)),bz=="zoomIn"||bz=="zoomOut"||bA._rs?(ba=T,bb=U):(ba+=(T-ba)/H,bb+=(U-bb)/H),bz=="left"?ba<T+bn&&(bA._nd?bM=!0:"",bz="",ba=T):bz=="right"?ba>T-bn&&(bA._nd?bM=!0:"",bz="",ba=T):bz=="up"?bb<U+bn&&(bA._nd?bM=!0:"",bz="",bb=U):bz=="down"?bb>U-bn&&(bA._nd?bM=!0:"",bz="",bb=U):bz=="drag"&&ba+bn>=T&&ba-bn<=T&&bb+bn>=U&&bb-bn<=U&&(bw&&(bv=!1),bA._nd?bM=!0:"",bz="",ba=T,bb=U),bA._rs&&bc+bn>=Q*R&&bc-bn<=Q*R&&ba==T&&bb==U&&V<bn&&V>-bn&&W<bn&&W>-bn&&(bM=!0,bz="",bA._rs=!1,bA._nd=!0,ba=T,bb=U,be=Q,bc=be*R,bd=be*S);if(Q==P){if(bE[1].$ob.css("opacity")>.5&&Q>=P){s&&D&&!bx&&(b.css("cursor","default"),bC.css("cursor","default"));for(var a=1;a<(s&&!bx?bF:2);a++)bE[a].$ob.css({opacity:.4}),bB.find("#"+bE[a]._var+"norm").show(),bB.find("#"+bE[a]._var+"over").hide()}}else if(bE[1].$ob.css("opacity")<.5){D&&(b.css("cursor","move"),bC.css("cursor","move"));for(var a=1;a<bF;a++)bE[a].$ob.css({opacity:.7})}Q==l?bE[0].$ob.css("opacity")>.5&&(bE[0].$ob.css({opacity:.4}),bB.find("#"+bE[0]._var+"norm").show(),bB.find("#"+bE[0]._var+"over").hide()):bE[0].$ob.css("opacity")<.5&&bE[0].$ob.css({opacity:.7}),use_trans3D?(b.css(prop_origin,"left top"),b.css(prop_transform,"translate3d("+ba+"px,"+bb+"px,0) scale("+be+")")):use_trans2D?(b.css(prop_origin,"left top"),b.css(prop_transform,"translate("+ba+"px,"+bb+"px) scale("+be+")")):b.css({width:bc,height:bd,left:ba+"px",top:bb+"px"}),!use_trans2D&&!use_trans3D&&(bP.length>0?cn():""),bM&&bu&&!bv&&bz!="drag"?(bu=!1,bz="",clearTimeout(bL)):(bu=!0,bL=setTimeout(ck,28))},cl=function(b,c,d,e,f,g,h,i,j,k){var l=25;a('<div class="bgi'+c+'" style="background-position:'+-(g-f)+"px "+(-(l-f)-k)+'px"></div>').appendTo(b),a('<div class="bgh'+c+'"></div>').appendTo(b),a('<div class="bgi'+c+'" style="background-position:'+-g+"px "+(-(l-f)-k)+"px; left:"+(d-f)+'px"></div>').appendTo(b),a('<div class="bgi'+c+'" style="background-position:'+-(g-f)+"px "+(-l-k)+"px; top:"+(e-f)+'px"></div>').appendTo(b),a('<div class="bgh'+c+'" style = "top:'+(e-f)+"px; left:"+f+'px"></div>').appendTo(b),a('<div class="bgi'+c+'" style="background-position:'+-g+"px "+(-l-k)+"px; top:"+(e-f)+"px; left:"+(d-f)+'px"></div>').appendTo(b),a('<div class="bgc'+c+'"></div>').appendTo(b),a(".bgi"+c).css({position:"absolute",width:f+"px",height:f+"px","background-image":"url("+i+")","background-repeat":"no-repeat","-ms-filter":"progid:DXImageTransform.Microsoft.gradient(startColorstr=#00FFFFFF,endColorstr=#00FFFFFF)",filter:"progid:DXImageTransform.Microsoft.gradient(startColorstr=#00FFFFFF,endColorstr=#00FFFFFF)",zoom:1}),a(".bgh"+c).css({position:"absolute",width:d-f*2,height:f+"px","background-color":h,left:f}),a(".bgc"+c).css({position:"absolute",width:d,height:e-f*2,"background-color":h,top:f,left:0})},cm=function(a,b){a?V=(T-(f-bc)/2-bh)/(bc/f):"",b?W=(U-(g-bd)/2-bi)/(bd/g):""},cn=function(){var b=0;bQ.each(function(){var c=[];for(var d=0;d<bP[b].length;d++)c[d]=bP[b][d]*be;c=c.join(","),a(this).attr("coords",c),b++})},co=function(){clearTimeout(bL),bu=!1,bz=""};this.destroy=function(){if(bt&&bs){co();for(prop in bN)bN[prop][0]!==!1&&bN[prop][0]!==undefined&&(bN[prop][0]==="width"||bN[prop][0]==="height"?parseInt(bN[prop][1])!==0&&b.css(bN[prop][0],bN[prop][1]):b.css(bN[prop][0],bN[prop][1]));clearTimeout(bK),a(document).unbind(".smoothZoom"+bU),a(window).unbind(".smoothZoom"+bU),bD=undefined}else b.show();b.unbind("load"),a(bR).unbind("load.smoothZoom onreadystatechange.smoothZoom"),b.insertBefore(bB),bB!==undefined?bB.remove():"",b.removeData("smoothZoom"),bB=undefined,Buttons=undefined,e=undefined,b=undefined},this.focusTo=function(a){bt&&bs&&(a.zoom===undefined||a.zoom===""||a.zoom==0?a.zoom=Q:a.zoom/=100,bw=!0,a.zoom>Q&&Q!=l?(Q=a.zoom,Q>l?Q=l:""):a.zoom<Q&&Q!=P&&(Q=a.zoom,Q<P?Q=P:""),ci(a.x===undefined||a.x===""?"":-a.x*Q+f/2,a.y===undefined||a.y===""?"":-a.y*Q+g/2,Q),bz="drag",bv=!0,clearTimeout(bL),ck())},this.zoomIn=function(a){bE[0].$ob.trigger("mousedown.smoothZoom",{id:0})},this.zoomOut=function(a){bE[1].$ob.trigger("mousedown.smoothZoom",{id:1})},this.moveRight=function(a){bE[2].$ob.trigger("mousedown.smoothZoom",{id:2})},this.moveLeft=function(a){bE[3].$ob.trigger("mousedown.smoothZoom",{id:3})},this.moveUp=function(a){bE[4].$ob.trigger("mousedown.smoothZoom",{id:4})},this.moveDown=function(a){bE[5].$ob.trigger("mousedown.smoothZoom",{id:5})},this.Reset=function(a){bE[6].$ob.trigger("mousedown.smoothZoom",{id:6})},this.getZoomData=function(a){return{normX:-ba/Q,normY:-bb/Q,normWidth:R,normHeight:S,scaledX:-ba,scaledY:-bb,scaledWidth:bc,scaledHeight:bd,ratio:Q,centerX:(-parseInt(ba)+f/2)/Q,centerY:(-parseInt(bb)+g/2)/Q}},bV()}function c(b){var c=0,d=24,e="",f=a("<div></div>"),g=a("<div></div>");return f.appendTo(b).css({position:"absolute",width:d+"px",height:d+"px",top:"50%",left:"50%","z-index":1}),g.appendTo(f).css({position:"absolute",width:d+"px",height:d+"px",top:-d/2+"px",left:-d/2+"px",background: "http://localhost:3000/assets/loader.gif"}),e=setInterval(function(){c-=d,c<0?c=d*14:"",g.css({"background-position":c+"px 0px"})},36),this.destroy=function(){clearInterval(e),f.remove()},this}a.fn.smoothZoom=function(c){var d=arguments,e,f;if(this.length>1)return this.each(function(){e=a(this),f=e.data("smoothZoom"),f?f[c]&&f[c].apply(this,Array.prototype.slice.call(d,1)):(typeof c=="object"||!c)&&e.data("smoothZoom",new b(e,c))});e=a(this),f=e.data("smoothZoom");if(!f){if(typeof c=="object"||!c)return e.data("smoothZoom",new b(e,c))}else if(f[c])return f[c].apply(this,Array.prototype.slice.call(d,1))}})(jQuery);var Modernizr=function(a,b,c){function C(a,b){var c=a.charAt(0).toUpperCase()+a.substr(1),d=(a+" "+n.join(c+" ")+c).split(" ");return B(d,b)}function B(a,b){for(var d in a)if(j[a[d]]!==c)return b=="pfx"?a[d]:!0;return!1}function A(a,b){return!!~(""+a).indexOf(b)}function z(a,b){return typeof a===b}function y(a,b){return x(m.join(a+";")+(b||""))}function x(a){j.cssText=a}var d="2.0.6",e={},f=b.documentElement,g=b.head||b.getElementsByTagName("head")[0],h="modernizr",i=b.createElement(h),j=i.style,k,l=Object.prototype.toString,m=" -webkit- -moz- -o- -ms- -khtml- ".split(" "),n="Webkit Moz O ms Khtml".split(" "),o={},p={},q={},r=[],s=function(a,c,d,e){var g,i,j,k=b.createElement("div");if(parseInt(d,10))while(d--)j=b.createElement("div"),j.id=e?e[d]:h+(d+1),k.appendChild(j);g=["&shy;","<style>",a,"</style>"].join(""),k.id=h,k.innerHTML+=g,f.appendChild(k),i=c(k,a),k.parentNode.removeChild(k);return!!i},t=function(){function d(d,e){e=e||b.createElement(a[d]||"div"),d="on"+d;var f=d in e;f||(e.setAttribute||(e=b.createElement("div")),e.setAttribute&&e.removeAttribute&&(e.setAttribute(d,""),f=z(e[d],"function"),z(e[d],c)||(e[d]=c),e.removeAttribute(d))),e=null;return f}var a={select:"input",change:"input",submit:"form",reset:"form",error:"img",load:"img",abort:"img"};return d}(),u,v={}.hasOwnProperty,w;!z(v,c)&&!z(v.call,c)?w=function(a,b){return v.call(a,b)}:w=function(a,b){return b in a&&z(a.constructor.prototype[b],c)};var D=function(c,d){var f=c.join(""),g=d.length;s(f,function(c,d){var f=b.styleSheets[b.styleSheets.length-1],h=f.cssRules&&f.cssRules[0]?f.cssRules[0].cssText:f.cssText||"",i=c.childNodes,j={};while(g--)j[i[g].id]=i[g];e.touch="ontouchstart"in a||j.touch.offsetTop===9,e.csstransforms3d=j.csstransforms3d.offsetLeft===9},g,d)}([,["@media (",m.join("touch-enabled),("),h,")","{#touch{top:9px;position:absolute}}"].join(""),["@media (",m.join("transform-3d),("),h,")","{#csstransforms3d{left:9px;position:absolute}}"].join("")],[,"touch","csstransforms3d"]);o.touch=function(){return e.touch},o.borderradius=function(){return C("borderRadius")},o.csstransforms=function(){return!!B(["transformProperty","WebkitTransform","MozTransform","OTransform","msTransform"])},o.csstransforms3d=function(){var a=!!B(["perspectiveProperty","WebkitPerspective","MozPerspective","OPerspective","msPerspective"]);a&&"webkitPerspective"in f.style&&(a=e.csstransforms3d);return a};for(var E in o)w(o,E)&&(u=E.toLowerCase(),e[u]=o[E](),r.push((e[u]?"":"no-")+u));x(""),i=k=null,e._version=d,e._prefixes=m,e._domPrefixes=n,e.hasEvent=t,e.testProp=function(a){return B([a])},e.testAllProps=C,e.testStyles=s,e.prefixed=function(a){return C(a,"pfx")};return e}(this,this.document);var FF2=false;var IE6=false;var prop_transform=Modernizr.prefixed('transform');var prop_origin=Modernizr.prefixed('transformOrigin');var use_trans2D=Modernizr.csstransforms&&prop_transform!==false&&prop_origin!==false?true:false;var use_trans3D=Modernizr.csstransforms3d&&prop_transform!==false&&prop_origin!==false?true:false;var use_bordRadius=FF2?false:Modernizr.borderradius;var use_pngTrans=IE6?false:true;(function(c){var a=["DOMMouseScroll","mousewheel"];c.event.special.mousewheel={setup:function(){if(this.addEventListener){for(var d=a.length;d;){this.addEventListener(a[--d],b,false)}}else{this.onmousewheel=b}},teardown:function(){if(this.removeEventListener){for(var d=a.length;d;){this.removeEventListener(a[--d],b,false)}}else{this.onmousewheel=null}}};c.fn.extend({mousewheel:function(d){return d?this.bind("mousewheel",d):this.trigger("mousewheel")},unmousewheel:function(d){return this.unbind("mousewheel",d)}});function b(f){var d=[].slice.call(arguments,1),g=0,e=true;f=c.event.fix(f||window.event);f.type="mousewheel";if(f.wheelDelta){g=f.wheelDelta/120}if(f.detail){g=-f.detail/3}d.unshift(f,g);return c.event.handle.apply(this,d)}})(jQuery);;