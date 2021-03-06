﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="HealthMap.aspx.cs" Inherits="EasyJoin.HealthMap" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>中山市公众环境与健康地理信息系统</title> 
    <link href="CSS/main.css" type="text/css" rel="stylesheet"/>
    <script src="js/jquery-1.7.2.min.js"></script>
	<script src="Js/global.js" ></script>     
    <script type="text/javascript" src="js/highcharts.js"></script>
    <%--取消下面注释就可以在右上角看到效果--%>
    <%--<script type="text/javascript" src="download/exporting.js" charset="gb2312"></script>--%>
    <script type="text/javascript" src="js/theme/gray.js"></script>
</head>
<body>
    <form id="form1" runat="server">
    <div id="div_logo">中山市公众环境与健康地理信息系统</div>
    <div id="div_Menu">
        <span class="Menu" onclick="javascript:window.open('map.aspx'); ">数据管理</span>
        <span class="Menu" onclick="javascript:window.open('map.aspx'); ">参数设置</span>
        <span class="Menu" onclick="javascript:window.open('map.aspx'); ">统计报表</span>
        <span class="Menu" onclick="javascript:window.open('EasyJoin.aspx'); ">数据导入</span>
        <span class="Menu" onclick="javascript:window.open('MonitorListManage.aspx'); ">用户管理</span>
        <span class="Menu" onclick="javascript:openConfigWindow();">系统设置</span>
        <span class="Menu" onclick="javascript:openLoginWindow();">退出系统</span>
    </div>
    <div id="div_stage">        
        <div id="div_MonitorList">
            <ul class="tabs">                  
                <li class="active"><a href="#container">数据</a></li>  
                <li><a href="#div_List">图表</a></li>  
            </ul>
            <div class="tab_container">  
                <div id="container" class="tab_content" style="display: block; "></div>
			    <div id="div_List" class="tab_content" style="display: none; width:380px;"></div>
           </div>
        </div>
        <div id="div_BaiduMap"></div>
    </div>
        <script src="/js/jquery.messager.js" type="text/javascript"></script>
        <script type="text/javascript" src="http://api.map.baidu.com/api?v=2.0&ak=KGEgH0KtySkG09bItE7MGLGn0npqjEEc"></script>
        <script type="text/javascript">
            var objLogo = GetObj("div_logo");
            var objMenu = GetObj("div_Menu");
            var objStage = GetObj("div_stage");
            var AlarmLevel = 0.22;
            var location_x = 22.514977;
            var location_y = 113.425883;

            var RedIcon = new BMap.Icon("http://api.map.baidu.com/img/markers.png", new BMap.Size(23, 25), {
                offset: new BMap.Size(10, 25),
                imageOffset: new BMap.Size(0, 0 - 11 * 25)
            });

            var NomalIcon = new BMap.Icon("http://api.map.baidu.com/img/markers.png", new BMap.Size(23, 25), {
                offset: new BMap.Size(10, 25),
                imageOffset: new BMap.Size(0, 0 - 10 * 25) 
            });

            var map = new BMap.Map("div_BaiduMap");

            var point = new BMap.Point(location_x, location_y);
            map.centerAndZoom(point, 15);
            
            //setInterval(showTime, 3000);

            //$(document).ready(function () {
            //    $("#time").val("This is Hello World by JQuery");
            //});
            

            getBoundary("中山");
            var MonitorList = new Array();
            var monitorList = new MonitorMap();
            ShowMonitor();
            //SetMarkerAnimationByName(1);
            //setTimeout(SetMarkerAnimationByName("1"), 5000);

            map.addControl(new BMap.NavigationControl());
            map.addControl(new BMap.ScaleControl());
            map.addControl(new BMap.OverviewMapControl());
            map.addControl(new BMap.MapTypeControl());
            map.enableScrollWheelZoom(true);     //开启鼠标滚轮缩放

            setInterval(ShowMonitorData, 3000);
            var opacity = 0;
            var s;
            var h;
            var opacity_C = 0;
            var s_C;
            var h_C;

           

            function GetObj(d) { return document.getElementById(d); }

            function reloadcode() {
                document.getElementById('imgCode').src = 'CreateImgCode.aspx?' + Math.random();
            }

            function LoginWindowChangeshow() {
                var obj = GetObj("LoginWindow");
                opacity=opacity+1; //逐渐显示速度
                obj.style.filter = "Alpha(Opacity=" + opacity + ")"; //透明度逐渐变小
                obj.style.opacity = opacity/100; //兼容FireFox
                if (opacity >= 100) {
                    clearInterval(s);
                    //obj.style.display = "block";
                }
                //document.getElementById("LoginWindow").style.display = "";
            }

            function ConfigWindowChangeshow() {
                var obj = GetObj("ConfigWindow");
                opacity_C = opacity_C + 1; //逐渐显示速度
                obj.style.filter = "Alpha(Opacity=" + opacity_C + ")"; //透明度逐渐变小
                obj.style.opacity = opacity_C / 100; //兼容FireFox
                if (opacity_C >= 100) {
                    clearInterval(s_C);
                    //obj.style.display = "block";
                }
                //document.getElementById("LoginWindow").style.display = "";
            }

            function openLoginWindow() {
                if (s) { clearInterval(s); }
                var obj = GetObj("LoginWindow");
                obj.style.opacity = 1 / 100
                obj.style.display = "block";
                s = setInterval(LoginWindowChangeshow, 10);
                objLogo.style.display = "none";
                objMenu.style.display = "none";
                objStage.style.display = "none";
            }

            

            //function openConfigWindow() {
            //    document.getElementById("ConfigWindow").style.display = "";
            //}
            //function closeConfigWindow() {
            //    document.getElementById("ConfigWindow").style.display = "none";
            //}

            function Monitor(ID, Name, Long, Lat,Value) {
                this.ID = ID;
                this.Name = Name;
                this.Long = Long;
                this.Lat = Lat;
                this.Value = Value;
                this.IsAlarm = false;
                this.Marker = CreateMarker(new BMap.Point(Long,Lat), Name, Value);
                return this;
            }

            function MonitorMap() {
                this.keys = new Array();
                this.data = new Array();
                //添加键值对
                this.set = function (key, value) {
                    if (this.data[key] == null) {//如键不存在则身【键】数组添加键名
                        this.keys.push(value);
                    }
                    this.data[key] = value;//给键赋值
                };
                //获取键对应的值
                this.get = function (key) {
                    return this.data[key];
                };

                //去除键值，(去除键数据中的键名及对应的值)
                this.remove = function (key) {
                    this.keys.remove(key);
                    this.data[key] = null;
                };
                //判断键值元素是否为空
                this.isEmpty = function () {
                    return this.keys.length == 0;
                };
                //获取键值元素大小
                this.size = function () {
                    return this.keys.length;
                };
            }            

            function ShowAlarm(title,msg)
            {
                $.messager.lays(200, 150);
                $.messager.show(title, msg);
            }

            function addMarker(point,monitorname,monitorvalue) {                
                var marker = new BMap.Marker(point, { icon: NomalIcon });
                map.addOverlay(marker);
                //移除标注
                marker.addEventListener("click", function () {
                    var opts = {
                        width: 200,     // 信息窗口宽度   
                        height: 100,     // 信息窗口高度   
                        title: monitorname  // 信息窗口标题
                    }
                    var infoWindow = new BMap.InfoWindow("0.2米", opts);  // 创建信息窗口对象
                    marker.openInfoWindow(infoWindow, this.point);      // 打开信息窗口
                });
            }

            function CreateMarker(point, monitorname, monitorvalue) {
                var myIcon = new BMap.Icon("http://api.map.baidu.com/img/markers.png", new BMap.Size(23, 25), {
                    // 指定定位位置。   
                    // 当标注显示在地图上时，其所指向的地理位置距离图标左上   
                    // 角各偏移10像素和25像素。您可以看到在本例中该位置即是   
                    // 图标中央下端的尖角位置。   
                    offset: new BMap.Size(10, 25),
                    // 设置图片偏移。   
                    // 当您需要从一幅较大的图片中截取某部分作为标注图标时，您   
                    // 需要指定大图的偏移位置，此做法与css sprites技术类似。   
                    imageOffset: new BMap.Size(0, 0 - 10 * 25)   // 设置图片偏移   
                });
                var marker = new BMap.Marker(point, { icon: myIcon });
                map.addOverlay(marker);
                //移除标注
                marker.addEventListener("mouseover", function () {
                    var opts = {
                        width: 200,     // 信息窗口宽度   
                        height: 100,     // 信息窗口高度   
                        title: monitorname  // 信息窗口标题
                    }
                    //var infoWindow = new BMap.InfoWindow("当前水位：" + monitorvalue, opts);  // 创建信息窗口对象
                    var infoWindow = new BMap.InfoWindow("当前水位：" + monitorList.get(monitorname), opts);  // 创建信息窗口对象
                    //marker.openInfoWindow(infoWindow, this.point);      // 打开信息窗口
                    marker.openInfoWindow(infoWindow, map.getCenter());      // 打开信息窗口
                });
                marker.addEventListener("mouseout", function () {
                    map.closeInfoWindow();
                    //map.removeOverlay(all_site[i].cont);
                });
                return marker;
            }

            function SetMarkerAnimationByName(id)
            {
                for (var i = 0; i < MonitorList.length; i++) {
                    if (MonitorList[i].ID == id) {
                        SetMarkerAnimation(MonitorList[i].Marker);
                        ShowAlarm("报警信息", MonitorList[i].Name + "发生报警，当前水位" + MonitorList[i].Value);
                        break;
                    }
                }
            }

            function CancelMarkerAnimationByName(id) {
                for (var i = 0; i < MonitorList.length; i++) {
                    if (MonitorList[i].ID == id) {
                        CancelMarkerAnimation(MonitorList[i].Marker);
                        break;
                    }
                }
            }

            function CancelAllMarkerAnimation() {
                for (var i = 0; i < MonitorList.length; i++) {
                    CancelMarkerAnimation(MonitorList[i].Marker);
                }                
            }

            function SetMarkerAnimation(marker) {
                marker.setIcon(RedIcon);
                marker.setAnimation(BMAP_ANIMATION_BOUNCE); //跳动的动画
            }

            function CancelMarkerAnimation(marker) {
                marker.setIcon(NomalIcon);
                marker.setAnimation(null); //取消跳动的动画
            }

            function getBoundary(sRegion) {
                var bdary = new BMap.Boundary();
                bdary.get(sRegion, function (rs) { //获取行政区域
                    //map.clearOverlays(); //清除地图覆盖物 
                    var count = rs.boundaries.length; //行政区域的点有多少个
                    for (var i = 0; i < count; i++) {
                        var ply = new BMap.Polygon(rs.boundaries[i], { strokeWeight: 2, strokeColor: "#FF0000", fillColor: "" }); //建立多边形覆盖物
                        map.addOverlay(ply); //添加覆盖物
                        map.setViewport(ply.getPath()); //调整视野 
                    }
                });
            }
            
            function showTime() {
                $.post("AlamInfo.ashx",{},function(data){
                    document.getElementById('time').value = data;
                    if (data.length > 0) {
                        setMarkerAnimation();
                    }
                    else {
                        CancelMarkerAnimation();
                    }
                });
            }

            function ShowMonitor() {
                $.getJSON("Position.ashx", {}, function (data) {
                    var listHtml = "";
                    var json = data;
                    for (var i = 0, l = json.length; i < l; i++) {
                        var long = json[i]["Long"];
                        var lat = json[i]["Lat"];
                        //var point = new BMap.Point(long, lat);
                        //addMarker(point, json[i]["Name"], json[i]["Value"]);
                        var oneMonitor = new Monitor(json[i]["ID"], json[i]["Name"], json[i]["Long"], json[i]["Lat"], json[i]["Value"]);
                        MonitorList.push(oneMonitor);
                        monitorList.set(json[i]["Name"], json[i]["Value"]);
                        listHtml += "<div>" + json[i]["Name"] +"-"+ json[i]["Value"] + "</div>"
                    }                    
                    var divshow = $("#div_List");
                    divshow.text("");// 清空数据
                    divshow.append(listHtml); // 添加Html内容，不能用Text 或 Val
                });
            }

            function ShowMonitorData() {
                $.getJSON("MonitorData.ashx", {}, function (data) {
                    var listHtml = "";
                    for (var i = 0, l = data.length; i < l; i++) {
                        if (data[i]["Value"] >= AlarmLevel) {
                            listHtml += "<div style='color:#FF0000'>" + data[i]["Name"] + "-" + data[i]["Value"] + "</div>"
                            for (var l = 0; l < MonitorList.length; l++) {
                                if (MonitorList[l].ID == data[i]["ID"]) {
                                    MonitorList[l].Value = data[i]["Value"];
                                    monitorList.set(data[i]["Name"], data[i]["Value"]);
                                    if (MonitorList[l].IsAlarm == false) {
                                        SetMarkerAnimation(MonitorList[l].Marker);
                                        MonitorList[l].IsAlarm = true;
                                        ShowAlarm("报警信息", MonitorList[l].Name + "发生报警，当前水位" + data[i]["Value"]);
                                    }
                                }
                            }
                        }
                        else {
                            listHtml += "<div>" + data[i]["Name"] + "-" + data[i]["Value"] + "</div>"
                            for (var l = 0; l < MonitorList.length; l++) {
                                if (MonitorList[l].ID == data[i]["ID"]) {
                                    MonitorList[l].Value = data[i]["Value"];
                                    monitorList.set(data[i]["Name"], data[i]["Value"]);
                                    if (MonitorList[l].IsAlarm == true) {
                                        CancelMarkerAnimation(MonitorList[l].Marker);
                                        MonitorList[l].IsAlarm = false;
                                    }
                                }
                            }
                        }
                        var charData = new ChartData(data[i]["Name"], data[i]["Value"]);
                        ShowChartData(charData);
                    }
                    
                    var divshow = $("#div_List");
                    divshow.text("");// 清空数据
                    divshow.append(listHtml); // 添加Html内容，不能用Text 或 Val
                });
            }

            function CancelMonitorData() {
                $.getJSON("MonitorData.ashx", {}, function (data) {
                    //var listHtml = "";
                    for (var i = 0, l = data.length; i < l; i++) {
                        //listHtml += "<div>" + data[i]["Name"] + "【" + data[i]["Value"] + "】</div>";
                        if (data[i]["Value"] >= 0.09) {
                            for (var l = 0; l < MonitorList.length; l++) {
                                if (MonitorList[l].ID == data[i]["ID"]) {
                                    if (MonitorList[l].IsAlarm == false) {
                                        SetMarkerAnimation(MonitorList[l].Marker);
                                        MonitorList[l].IsAlarm = true;
                                        ShowAlarm("报警信息", MonitorList[l].Name + "发生报警，当前水位" + MonitorList[l].Value);
                                    }
                                }
                            }
                        }
                        else {
                            for (var l = 0; l < MonitorList.length; l++) {
                                if (MonitorList[l].ID == data[i]["ID"]) {
                                    if (MonitorList[l].IsAlarm == true) {
                                        CancelMarkerAnimation(MonitorList[l].Marker);
                                        MonitorList[l].IsAlarm = false;
                                    }
                                }
                            }
                        }
                    }
                    //var divshow = $("#div_List");
                    //divshow.text("");// 清空数据
                    //divshow.append(listHtml); // 添加Html内容，不能用Text 或 Val
                });
            }

            function SetHeithtWidth()
            {
                var h = $(window).height() - $("#div_logo").height() - 15;
                var w = $(window).width() - $("#div_MonitorList").width() - 30;
                $("#div_BaiduMap").height(h);
                $("#div_BaiduMap").width(w);
                $("#div_MonitorList").height(h);
                $("#container").width(380);
            }
        </script>
        <script>
            $(document).ready(function () {
                
                //Default Action  
                $(".tab_content").hide(); //Hide all content  
                $("ul.tabs li:first").addClass("active").show(); //Activate first tab  
                $(".tab_content:first").show(); //Show first tab content  

                //On Click Event  
                $("ul.tabs li").click(function () {
                    $("ul.tabs li").removeClass("active"); //Remove any "active" class  
                    $(this).addClass("active"); //Add "active" class to selected tab  
                    $(".tab_content").hide(); //Hide all tab content  
                    var activeTab = $(this).find("a").attr("href"); //Find the rel attribute value to identify the active tab + content  
                    $(activeTab).fadeIn(); //Fade in the active content  
                    return false;
                });
                SetHeithtWidth();
        })
        $(window).resize(function () {
            SetHeithtWidth();
        });
    </script>
    </form>
</body>
</html>


