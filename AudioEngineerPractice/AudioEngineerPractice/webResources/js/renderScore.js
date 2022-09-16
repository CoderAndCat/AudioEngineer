//默认显示五线谱 0-五线谱 1-简谱
let defaultShowScoreMode = 0
//缓存简谱节点
let cacheNumberScore;
//缓存五线谱节点
let cacheFiveScore;
// 缓存乐谱
let cacheScore;
//简谱连音符
let tieArr = []
//简谱音符x坐标集合
let numNoteXArr = []
//简谱音符y坐标集合
let numNoteYArr = []
//记录简谱定时器
let timerArr = []
//记录屏幕滚动次数
let scrollNum = 1
//屏幕滚动计时器
let time = null
//简谱当前演奏id
let currentPlayingId = 0
//简谱当前演奏时间
let nowSpeedTime = 0
//屏幕滚动距离
let scrollOffsetHeight = 0
//剔除休止符后的数据
let delArr = [];
// 小节索引
let noteNumSubsectionIndex = 0;
// 音符索引
let noteNumIndex = 0;
//记录当前倍速
let speedTime = 1
//记录简谱已变色音符
let colorArr = []
//缩放手势防抖
let zoomTime = null
//是否播放
let isPause = false

/**
 * 加载资源文件
 * @param {string} resourceUrl 资源文件地址
 * @param {number} scoreMode 谱子默认显示类型
 * @param {success} callback 请求成功回调函数
 * @param {error} callback 请求失败
 */
function loadResource(resourceUrl, scoreMode) {
	defaultShowScoreMode = scoreMode
	http.ajax({
		url: resourceUrl,
		dataType: "text",
		success: function (result, status, xhr) {
			cacheNumberScore = getScoreView(`${result}`,window.innerWidth);
			// 缓存文档
			cacheScore = result;
			loadResourceSuccess(result);
			renderScoreStart();
			if (scoreMode === 1) {
				loadNumberScore()
			}else {
				renderQuickStartmusicxml(result);
			}
		},
		error: (xhr, status, error) => {
			loadResourceError()
		}
	})
}

/**
 * 加载五线谱
 * @param {Object} result
 */
function renderQuickStartmusicxml(result) {
	//清空缓存的note
	window.notes = []
	var osmdObj
	if (window.osmd)
		osmdObj = window.osmd
	else
		osmdObj = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmdCanvas", {
			// set options here
			autoResize: true,
			backend: "svg",
			drawingParameters: "compact", // try compact (instead of default)
			drawPartNames: false, // try false
			drawFingerings: false,
			fingeringPosition: "left", // left is default. try right. experimental: auto, above, below.
			setWantedStemDirectionByXml: true, // try false, which was previously the default behavior
			drawFromMeasureNumber: 0,
			drawUpToMeasureNumber: Number.MAX_SAFE_INTEGER,
			drawMeasureNumbers: false, // disable drawing measure numbers
			useXMLMeasureNumbers: false, // read measure numbers from xml
			coloringEnabled: true,
		});
	//将游标设置为透明色
	// osmdObj.cursorsOptions[0].type = 1;
	// osmdObj.cursorsOptions[0].color = "transparent";
	osmdObj.load(result).then(
		function () {
			window.osmd = osmdObj; // give access to osmd object in Browser console, e.g. for osmd.setOptions()
			osmd.zoom = 1.0;
			osmd.render();
			osmd.cursor.hide() // this would show the cursor on the first note
			osmd.cursor.reset();
			renderScoreEnd();
			delNote()
		}
	);
}

/**
 * 加载简谱
 */
function loadNumberScore(result,rest) {
	try {
		if (result) cacheNumberScore = getScoreView(result,window.innerWidth)
		document.getElementById("osmdCanvas").appendChild(cacheNumberScore)
		let data = document.querySelectorAll("g.noteId");
		let restData = document.querySelectorAll("g.restId")
		data.forEach(function (v,i) {
			v.setAttribute('id', 'vf-auto' + i)
		})
		restData.forEach(function (v,i) {
			v.setAttribute('id', 'vf-aut' + i)
		})
		// let myElement = document.getElementById('numberScore');
		// let mc = new Hammer(myElement);
		// let pinch = new Hammer.Pinch(); //创建一个识别器
		// mc.add(pinch);//添加捏放手势
		// mc.get('pinch').set({ enable: true });
		// mc.on("pinch", function(ev) {
		// 	if(zoomTime !== null){
		// 		clearTimeout(zoomTime);
		// 	}
		// 	zoomTime = setTimeout(() => {
		// 		myElement.style.transform = `scale(${ev.scale})`
		// 	},500)
		// });
		// mc.on("panup", function(ev) {
		// 	if(scrollDistance<window.innerHeight) return
		// 	scrollDistance++
		// 	document.documentElement.scrollTo({
		// 		top: scrollDistance,
		// 		left: 0,
		// 		behavior: 'smooth'
		// 	})
		// });
		// mc.on("pandown", function(ev) {
		// 	if(scrollDistance<window.innerHeight) return
		// 	scrollDistance--
		// 	document.documentElement.scrollTo({
		// 		top: scrollDistance,
		// 		left: 0,
		// 		behavior: 'smooth'
		// 	})
		// });
		renderScoreEnd()
		getNumNoteInLine()
		if (rest) {
			isPause && setDoubleSpeed(speedTime,1)
			drawColorChangingNotes()
		}
	} catch (e) { }
}

/**
 * 加载资源文件成功
 */
function loadResourceSuccess(result) {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.loadResourceSuccess.postMessage(result);
		}
	} catch (e) { }
	try {
		window.score_js.loadResourceSuccess(result)
	} catch (e) {}
}

/**
 * 加载资源文件失败
 */
function loadResourceError() {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.loadResourceError.postMessage('');
		}
	} catch (e) {}
	try {
		window.score_js.loadResourceSuccess()
	} catch (e) {}
}

/**
 * 开始渲染乐谱
 */
function renderScoreStart() {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.renderScoreStart.postMessage('');
		}
	} catch (e) {}
	try {
		window.score_js.renderScoreStart()
	} catch (e) {}
}

/**
 * 渲染乐谱完毕
 */
function renderScoreEnd() {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.renderScoreEnd.postMessage('');
		}
	} catch (e) {}
	try {
		window.score_js.renderScoreEnd()
	} catch (e) {}
}

/**
 * 显示五线谱，供原生调用
 * */
function showStavesMode() {
	if(defaultShowScoreMode === 0) return
	reRecord()
	defaultShowScoreMode = 0
	let node = document.getElementById('numberScore')
	document.getElementById("osmdCanvas").removeChild(node)
	cacheFiveScore = document.getElementById('osmdCanvasPage1')
	if (cacheFiveScore){
		document.getElementById("osmdCanvas").appendChild(cacheFiveScore)
	}else {
		renderQuickStartmusicxml(cacheScore);
	}
}

/**
 * 显示简谱，供原生调用
 * */
function showNumberMode() {
	if(defaultShowScoreMode === 1) return
	reRecord()
	defaultShowScoreMode = 1
	let node = document.getElementById('osmdCanvasPage1')
	document.getElementById("osmdCanvas").removeChild(node)
	if (cacheNumberScore){
		document.getElementById("osmdCanvas").appendChild(cacheNumberScore)
	}else {
		loadNumberScore(cacheScore)
	}
}

/**
 * 监听简谱横竖屏切换
 * */
window.addEventListener("orientationchange", isPortrait, false);
function isPortrait() {
	if (defaultShowScoreMode === 1) {
		let node = document.getElementById("numberScore")
		document.getElementById("osmdCanvas").removeChild(node)
		numNoteXArr = []
		numNoteYArr = []
		scrollOffsetHeight = 0
		scrollNum = 1
		setTimeout(() => {
			loadNumberScore(cacheScore,'rest')
		},100)
	}else {
		//TODO 五线谱切换横竖屏相关操作
		scrollOffsetHeight = 0
		scrollNum = 1
	}
}

/**
 * 获取简谱一行有多少个音符
 * */
function getNumNoteInLine() {
	let svg = document.getElementById("numberScore").childNodes[0]
	let data = GetConListBySubKey(svg,'vf-aut')
	data && data.length > 0 && data.forEach(item => {
		item.attributes.tie && tieArr.push(item.attributes.tie.value)
		if (item.childNodes.length > 0) {
			if(item.children[0].tagName === 'text') {
				numNoteYArr.push(item.children[0].y.animVal[0].value)
				numNoteXArr.push(item.children[0].x.animVal[0].value)
				return
			}
			for(let i = 0; i < item.childNodes.length;i++) {
				if (item.childNodes[i].tagName === 'text' && Number(item.childNodes[i].innerHTML) > 0) {
					numNoteYArr.push(item.children[i].y.animVal[0].value)
					numNoteXArr.push(item.children[i].x.animVal[0].value)
				}else {
					if (item.childNodes[i].tagName === 'g' && item.childNodes[i].childNodes.length > 0){
						item.childNodes[i].childNodes[0].tagName === 'text' && Number(item.childNodes[i].childNodes[0].innerHTML) > 0 && numNoteYArr.push(item.childNodes[i].childNodes[0].y.animVal[0].value)
						item.childNodes[i].childNodes[0].tagName === 'text' && Number(item.childNodes[i].childNodes[0].innerHTML) > 0 && numNoteXArr.push(item.childNodes[i].childNodes[0].x.animVal[0].value)
					}
				}
			}
		}
	})
	let xArr = JSON.parse(JSON.stringify(numNoteXArr))
	let yArr = JSON.parse(JSON.stringify(numNoteYArr))
	let tArr = JSON.parse(JSON.stringify(tieArr))
	window.cells.forEach(item => {
		item.data.forEach(it => {
			if (it.name === 'rest' || it.name === 'note') {
				it.x = xArr[0]
				it.y = yArr[0]
				xArr.shift()
				yArr.shift()
				if(it.name === 'note'){
					it.tie = tArr[0]
					tArr.shift()
				}
			}
		})
	})
}

/**
 * 演奏引导开始，供原生调用
 * */
function sheetMusic() {
	isPause = true
	speedTime === 1 ? window.cells.forEach(item => {
		sheetMusicGuide(item.data)
	})
		:
		setDoubleSpeed(speedTime,0)
}

/**
 * 演奏引导
 * @param data 正在播放的数据
 * */
let scrollHeight
function sheetMusicGuide(data) {
	let svgHeight
	if(defaultShowScoreMode) {
		svgHeight = document.getElementById('numberScore').offsetHeight
	}else {
		svgHeight = document.getElementById('osmdCanvasPage1').offsetHeight
	}
	data.forEach( it =>{
		if (it.name === 'rest' || it.name === 'note') {
			(function (){
				let allNote = setTimeout(()=>{
					currentPlayingId = it.id
					let viewHeight = svgHeight - (window.innerHeight * scrollNum)
					if (defaultShowScoreMode) {
						document.getElementById('scrollBox').style.display = 'block'
						document.getElementById('scrollBox').style.left = it.x - 4 + 'px'
						document.getElementById('scrollBox').style.top = it.y - 25 + 'px'
						scrollHeight = it.y -100
					}else {
						osmd.cursor.show()
						osmd.cursor.next()
						let cursorOffset = getPosition(document.getElementById('cursorImg-0'))
						scrollHeight = cursorOffset.top - 100
					}
					// if((window.innerHeight * scrollNum) -scrollHeight > window.innerHeight){
					// 	scrollNum = 1
					// 	scrollOffsetHeight = scrollHeight - 40
					// 	document.documentElement.scrollTo({
					// 		top: scrollOffsetHeight,
					// 		left: 0,
					// 		behavior: 'smooth'
					// 	})
					// }
					// if (scrollHeight > (window.innerHeight * scrollNum) && svgHeight > (window.innerHeight * scrollNum)) {
					// 	scrollNum++
					// 	if (viewHeight > window.innerHeight) {
					// 		scrollOffsetHeight += window.innerHeight
					// 		document.documentElement.scrollTo({
					// 			top: scrollOffsetHeight,
					// 			left: 0,
					// 			behavior: 'smooth'
					// 		})
					// 	} else {
					// 		scrollOffsetHeight += viewHeight
					// 		document.documentElement.scrollTo({
					// 			top: scrollOffsetHeight,
					// 			left: 0,
					// 			behavior: 'smooth'
					// 		})
					// 	}
					// }
					document.documentElement.scrollTo({
						top: scrollHeight,
						left: 0,
						behavior: 'smooth'
					})
				},it.startTime * 1000)
				timerArr.push(allNote)
			}())
		}
	})
}

/**
 * 清除演奏计时器
 * */
function clearTimer() {
	timerArr.forEach(item => {
		clearTimeout(item)
	})
}

/**
 * 供原生调用，返回乐谱数据，乐谱加载完毕后调用
 * */
function getScoreData() {
	let measureNum = 0
	let measureArr = []
	let keyFifths
	let keyMode
	let beats
	let beatType
	let sound = 0
	for(let i = 0; i<window.cells.length;i++){
		if(sound > 0) break
		for(let j =0; j<window.cells[i].data.length;j++){
			if (window.cells[i].data[j].name === 'sound') {
				sound = window.cells[i].data[j].value
				break
			}
		}
	}
	window.cells.map(item => {
		item.data.map(it => {
			let noteData = {}
			it.name === 'sound' && (sound = it.value)
			if(it.name === 'key'){
				keyFifths = it.fifths
				keyMode = it.mode
			}
			if(it.name === 'time'){
				beats = it.beats
				beatType = it.beatType
			}
			noteData.key = keyFifths
			noteData.mode = keyMode
			noteData.beats = beats
			noteData.beatType = beatType
			noteData.measureNum = measureNum
			noteData.sound = +sound
			noteData.noteId = it.id
			if(it.name === 'rest'){
				noteData.noteValue = 0
				noteData.noteTime = it.noteTime
				noteData.startTime = it.startTime
				noteData.rest = true
				noteData.tie = 0
			}
			if(it.name === 'note'){
				noteData.noteValue = +it.pitch.step
				noteData.noteTime = it.noteTime
				noteData.startTime = it.startTime
				noteData.rest = false
				noteData.tie = +it.tie
			}
			if(it.name === 'rest' || it.name === 'note'){
				measureArr.push(noteData)
			}
		})
		measureNum++
	})
	return measureArr
}

/**
 * 暂停播放，供原生调用
 * */
function pausePlayback() {
	isPause = false
	clearTimer()
}

/**
 * 继续播放，供原生调用
 * */
function resumePlaying() {
	isPause = true
	setDoubleSpeed(speedTime,1)
}

/**
 * 时间校对，供原生调用
 * @param {number} noteId 当前演奏音符ID
 * */
function timeProofreading(noteId) {
	clearTimer()
	currentPlayingId = noteId
	setDoubleSpeed(speedTime,1)
}

/**
 * 监听页面滚动并回滚
 * */
window.onscroll = function (){
	if(time !== null){
		clearTimeout(time);
	}
	time = setTimeout(() => {
		document.documentElement.scrollTo({
			top: scrollHeight,
			left: 0,
			behavior: 'smooth'
		})
	},2000)
}

/**
 * 倍速，供原生调用
 * @param {number} speed 倍速数值
 * @param {number} flag 是否是倍速标记
 * */
function setDoubleSpeed(speed,flag) {
	clearTimer()
	speedTime = speed
	if(isPause){
		singleSentenceLoop(speed,flag)
	}
	return (currentPlayingId + 1)
}

/**
 * 倍速逻辑处理
 * */
function singleSentenceLoop(speed,flag) {
	let speedFlag = false
	let speedAllArr = []
	let arr = JSON.parse(JSON.stringify(window.cells))
	arr.forEach(item => {
		let speedArr = []
		item.data.forEach( it =>{
			if (it.name === 'rest' || it.name === 'note') {
				if(speedFlag){
					let time = (speed === 2 || speed === 1.5 || speed === 1) ? (it.startTime/speed - nowSpeedTime) : speed === 0.5 ? (it.startTime*2 - nowSpeedTime) : (it.startTime*(4/3) - nowSpeedTime)
					it.startTime = time
					speedArr.push(it)
				}else {
					let id = flag ? currentPlayingId : (currentPlayingId + 1)
					if ( id=== it.id) {
						nowSpeedTime = (speed === 2 || speed === 1.5 || speed === 1) ? (it.startTime/speed) : speed === 0.5 ? (it.startTime*2) : (it.startTime*(4/3))
						it.startTime = 0
						speedArr.push(it)
						speedFlag = true
					}
				}
			}
		})
		speedArr.length > 0 && speedAllArr.push(speedArr)
	})
	speedAllArr.forEach(item => {
		sheetMusicGuide(item)
	})
}

/**
 * 供原生调用，调用时机为页面加载完毕
 * 滚动到下一个音符
 * @return 无返回值
 */
function scrollTo(color) {
	if(defaultShowScoreMode){
		updateNoteNumColorWithId(color)
	}else {
		updateNoteColorWithId(color)
	}
}
/**
 * 获取节点下有id的子节点
 * */
function GetConListBySubKey(container,subIdKey)
{
	let reConArry = [];
	for(let i = 0; i < container.childNodes.length; i++)
	{
		if(container.childNodes[i].attributes != null && container.childNodes[i].attributes["id"] !== undefined && container.childNodes[i].id.indexOf(subIdKey) > -1)
		{
			reConArry.push(container.childNodes[i]);
		}
		if(container.childNodes[i].childNodes.length > 0)
		{
			const re = GetConListBySubKey(container.childNodes[i], subIdKey);
			for(let k = 0; k<re.length; k++)
			{
				reConArry.push(re[k]);
			}
		}
	}
	return reConArry;
}
/**
 * 重录，供原生调用
 * */
function reRecord() {
	//TODO
	noteNumSubsectionIndex = 0
	noteNumIndex = 0
	tieArr = []
	delArr = []
	clearTimer()
	isPause = false
	if (defaultShowScoreMode) {
		numNoteYArr = []
		numNoteXArr = []
		colorArr = []
		getNumNoteInLine()
		restNumColor('rest')
		document.getElementById('scrollBox').style.display = 'none'
	}else {
		delNote()
		restFiveColor('rest')
		osmd.cursor.reset()
		osmd.cursor.hide()
	}
}


/**
 * 获取元素坐标
 * */
function getPosition(node) {
	let current
	//获取元素相对于其父元素的left值var left
	let left = node.offsetLeft;
	let top = node.offsetTop;
	// 取得元素的offsetParent
	current = node.offsetParent;
	// 一直循环直到根元素
	while(current != null) {
		left += current.offsetLeft;
		top += current.offsetTop;
		current = current.offsetParent;
	}
	return {
		"left": left,
		"top": top
	}}

/**
 * 枚举颜色类型
 * */
function colorValue(type) {
	switch (type) {
		case 'perfect':
			return '#FFAD00'
		case 'great':
			return '#FF36B6'
		case 'good':
			return '#3677FF'
		case 'pass':
			return '#BDC0C5'
		case 'rest':
			return 'black'
	}
}

/**
 * 重制简谱颜色
 * */
function restNumColor(colorType) {
	let svg = document.getElementById("numberScore").childNodes[0]
	let idArr = GetConListBySubKey(svg,'vf-auto')
	for (let i = 0; i < idArr.length; i++) {
		let noteArr = idArr[i].childNodes
		for(let k = 0; k < noteArr.length; k++) {
			for(let j = 0; j < noteArr[k].childNodes.length; j++) {
				if(noteArr[k].childNodes[j].tagName === 'text' && Number(noteArr[k].childNodes[j].innerHTML) > 0){
					noteArr[k].childNodes[j].style.fill = colorValue(colorType)
				}
			}
		}
	}
}

/**
 * 重制五线谱颜色
 * */
function restFiveColor(colorType) {
	let measureList = osmd.graphic.measureList
	measureList.forEach(item => {
		for (let i = 0; i < item.length; i++) {
			let staffEntry = item[i] && item[i].staffEntries
			staffEntry && staffEntry.length > 0 && staffEntry.forEach(it => {
				if (typeof it != "undefined") {
					const vfnote = it.graphicalVoiceEntries[0].notes[0].vfnote && it.graphicalVoiceEntries[0].notes[0].vfnote[0];
					if (vfnote) {
						const noteId = 'vf-' + vfnote.attrs.id;
						document.querySelectorAll(`g#${noteId} path`).forEach(item => {
							item.setAttribute('fill', colorValue(colorType));
						})
					}
				}
			})
		}
	})
}

/**
 * 简谱变色
 * @param {string} colorType 颜色类型
 * */
function updateNoteNumColorWithId(colorType) {
	let svg = document.getElementById("numberScore").childNodes[0]
	let idArr = GetConListBySubKey(svg,'vf-auto')
	let noteArr = idArr[noteNumIndex].childNodes
	for(let i = 0; i < noteArr.length;i++) {
		for(let j = 0; j < noteArr[i].childNodes.length;j++) {
			if(noteArr[i].childNodes[j].tagName === 'text' && Number(noteArr[i].childNodes[j].innerHTML) > 0){
				let colorObj = {}
				colorObj.noteNumIndex = noteNumIndex
				colorObj.noteArrIndex = i
				colorObj.noteArrChildIndex = j
				colorObj.colorType = colorType
				colorArr.push(colorObj)
				noteArr[i].childNodes[j].style.fill = colorValue(colorType)
			}
		}
	}
	noteNumIndex++
	if (noteNumIndex >= idArr.length) {
		noteNumIndex = 0
		noteNumSubsectionIndex++
	}
}

/**
 * 简谱旋转屏幕后，绘制已变色的音符
 * */
function drawColorChangingNotes() {
	let svg = document.getElementById("numberScore").childNodes[0]
	let idArr = GetConListBySubKey(svg,'vf-auto')
	colorArr && colorArr.length > 0 && colorArr.forEach(item => {
		let noteArr = idArr[item.noteNumIndex].childNodes
		noteArr[item.noteArrIndex].childNodes[item.noteArrChildIndex].style.fill = colorValue(item.colorType)
	})
}

/**
 * 剔除五线谱休止符
 * */
function delNote() {
	let list = window.osmd.graphic.measureList
	for(let i=0;i<list.length;i++){
		if(list[i][0] !==undefined){
			for(j=0;j<list[i].length;j++){
				list[i][j].staffEntries.map(item => {
					if (!item.graphicalVoiceEntries[0].notes[0].sourceNote.isRestFlag) {
						delArr.push(item)
					}
				})
			}
		}
	}
}

/**
 * 五线谱变色
 * */
function updateNoteColorWithId(colorType) {
	if (delArr[0].graphicalVoiceEntries[0].notes[0].vfnote) {
		var vfnote = delArr[0].graphicalVoiceEntries[0].notes[0].vfnote[0]
	}
	var noteId = 'vf-' + vfnote.attrs.id
	document.querySelectorAll(`g#${noteId} path`).forEach(item => {
		item.setAttribute('fill', colorValue(colorType));
	})
	delArr.shift()
}
