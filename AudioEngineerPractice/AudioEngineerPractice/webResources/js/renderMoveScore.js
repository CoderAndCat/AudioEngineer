//八度偏移修复 现阶段sheetmusic默认是c1起,默认中央c是c4=48,这里进行补位，加一个八度 c3=60
const octaveFx = 12;

(async () => {
	const scoreElement = document.getElementById("osmdCanvas");
	const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay(scoreElement, {
		autoResize: true,
		backend: "svg",
		disableCursor: false,
		drawingParameters: true ? "compacttight" : "default", // try compact (instead of default)
		drawPartNames: false, // try false
		drawTitle: false,
		drawSubtitle: false,
		drawFingerings: false,
		renderSingleHorizontalStaffline: true,
		horizontalScrolling: true,
	});
	const audioPlayer = new OsmdAudioPlayer();
	window.playerObj = audioPlayer;
	window.osmdObj = osmd;
	window.scoreElement = scoreElement;
})();

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
	}
}
// 小节索引
var noteSubsectionIndex = 0
// 音符索引
var noteIndex = 0
function updateNoteColorWithId(colorType) {
	var measureList = window.osmdObj.graphic.measureList[noteSubsectionIndex]
	// 所有列表的长度
	let listLength = measureList.map(item => {
		return item.staffEntries.length
	})
	// console.log(listLength)
	// 最大的列表长度
	let max_length = Math.max(...listLength)
	// 最大列表的索引
	let max_index = listLength.indexOf(max_length)
	// console.log(max_index)
	// 当前小节 每个部分 当前位置的音符
	for (i = 0; i < measureList.length; i++) {
		let staffEntry = measureList[i].staffEntries[noteIndex]
		if (typeof staffEntry != "undefined") {
			var vfnote = staffEntry.graphicalVoiceEntries[0].notes[0].vfnote[0]
			var noteId = 'vf-' + vfnote.attrs.id
			document.querySelectorAll(`g#${noteId} path`).forEach(item => {
				item.setAttribute('fill', colorValue(colorType));
			})
		}
	}
	// console.log("index", noteSubsectionIndex, noteIndex)
	// 当前小节已遍历完每个部分的音符（即已经遍历完最长音符列表）
	noteIndex++
	if (noteIndex >= max_length) {
		noteIndex = 0
		noteSubsectionIndex++
	}
}


async function renderMusicxml(scoreXml) {
	await window.osmdObj.load(scoreXml);
	await window.osmdObj.render();
	await window.playerObj.loadScore(window.osmdObj);
	window.playerObj.on("iteration", data => {
		scrollTo(window.osmdObj);
		extraNoteAndTime(window.osmdObj, data);
	});
	window.playerObj.on("state-change", data => {
		console.log(data);
	});
	resizeCongtainerWidth(window.scoreElement, 1.5);
	resumePositionWhenReload(window.osmdObj);
	renderScoreEnd();
}

/**
 * 提取音符和音符演奏时间
 *
 * @param 【Object】data
 */
function extraNoteAndTime(osmd, data) {
	var allNotes = []
	let notes = data.notes
	const iterator = osmd.cursor.Iterator;
	for (var j = 0; j < notes.length; j++) {
		const note = notes[j];
		// make sure our note is not silent
		if (note != null && note.halfTone != 0 && !note.isRest()) {
			let type = 0;
			if(data.type == "NOTE_ON")
				type = 1;
			allNotes.push({
				"note": note.halfTone, // see issue #224
				"transposeNote": note.halfTone + octaveFx, // see issue #224
				"time": iterator.currentTimeStamp.RealValue * 4,
				"noteDuration": note.noteDuration,
				"type": type
			})
		}
	}
	if(allNotes.length > 0)
		scoreCallBack(allNotes);
}

/**
 * 渲染乐谱完毕
 */
function scoreCallBack(allNotes) {
	let noteStr = JSON.stringify(allNotes)
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.scoreCallBack.postMessage(noteStr);
		}
	} catch (e) {
		//TODO handle the exception
	}
	try {
		window.score_js.scoreCallBack(noteStr)
	} catch (e) {
		//TODO handle the exception
	}
}


/**
 * 加载资源文件
 * @param {string} resouceUrl 资源文件地址
 * @param {success} callback 请求成功回调函数
 * @param {error} callback 请求失败
 */
function loadResource(resouceUrl) {
	http.ajax({
		url: resouceUrl,
		dataType: "text",
		success: function(result, status, xhr) {
			loadResourceSuccess(result);
			renderScoreStart();
			renderMusicxml(`${result}`);
		},
		error: (xhr, status, error) => {
			loadResourceError()
		}
	})
}

/**
 * 开始播放
 */
function scorePlayer() {
	if (!window.playerObj) return;
	if (window.playerObj.state === "INIT" || window.playerObj.state === "STOPPED" || window.playerObj.state ===
		"PAUSED") {
		window.playerObj.play();
	}
}

/**
 * 显示游标图标
 */
function showCursorImg() {
	document.getElementById("osmdCursor").style.display = "block"
	document.getElementById("osmdCursor").style.height = document.getElementById("osmdCanvas").offsetHeight + 'px'
}

/**
 * 暂停播放
 */
function scorePause() {
	if (!window.playerObj) return;
	if (window.playerObj.state === "PLAYING") {
		window.playerObj.pause();
	}
}

/**
 * 停止播放
 */
function scoreStop() {
	if (!window.playerObj) return;
	if (window.playerObj.state === "PLAYING" || window.playerObj.state === "PAUSED") {
		window.playerObj.stop();
	}
}

/**
 * 停止播放
 */
function scoreReset() {
    scoreStop()
	resumePositionWhenReload(window.osmdObj);
}

/**
 * @param {Object} element 需要重设置宽度的容器
 */
function resizeCongtainerWidth(element, scale) {
	let width = element.clientWidth
	let clientWidth = width * scale;
	element.style.width = clientWidth + 'px'
}


/**
 * 供原生调用，调用时机为页面加载完毕
 * 滚动到下一个音符
 * @return 无返回值
 */
function scrollTo(osmd) {
	if (!osmd) {
		return
	}
	let index = osmd.cursor.iterator.currentVoiceEntryIndex;
	let endReached = osmd.cursor.iterator.endReached
	if (endReached)
		osmd.cursor.reset();
	osmd.cursor.cursorElement.scrollIntoView({
		behavior: 'smooth',
		block: "start",
		inline: 'center'
	});
}

/**
 * 重新加载时恢复到初始位置
 */
function resumePositionWhenReload(osmd) {
	setTimeout(function() {
		if (!osmd) {
			return
		}
		let positionObj = document.getElementById('start')
		let cacheCursorLeft = positionObj.style.left;
		positionObj.style.left = 0;
		positionObj.scrollIntoView();
		positionObj.style.left = cacheCursorLeft;
		window.osmdObj.cursor.cursorElement.style.zIndex = 0;
	}, 200)
}

/**
 * 加载资源文件失败
 */
function loadResourceError() {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.loadResourceError.postMessage('');
		}
	} catch (e) {
		//TODO handle the exception
	}
	try {
		window.score_js.loadResourceSuccess()
	} catch (e) {
		//TODO handle the exception
	}
}

/**
 * 加载资源文件成功
 */
function loadResourceSuccess(result) {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.loadResourceSuccess.postMessage(result);
		}
	} catch (e) {}
	try {
		window.score_js.loadResourceSuccess(result)
	} catch (e) {
		//TODO handle the exception
	}
}

/**
 * 开始渲染乐谱
 */
function renderScoreStart() {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.renderScoreStart.postMessage('');
		}
	} catch (e) {
		//TODO handle the exception
	}
	try {
		window.score_js.renderScoreStart()
	} catch (e) {
		//TODO handle the exception
	}
}

/**
 * 渲染乐谱完毕
 */
function renderScoreEnd() {
	try {
		if (window.webkit) {
			window.webkit.messageHandlers.renderScoreEnd.postMessage('');
		}
	} catch (e) {
		//TODO handle the exception
	}
	try {
		window.score_js.renderScoreEnd()
	} catch (e) {
		//TODO handle the exception
	}
}
