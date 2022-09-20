var data = [];

window.addEventListener('message', function(event) {
    let item = event.data;
    if(item.st===true){
        Show(true);
    } else if(item.st===false) {
        Show(false);
    };
    if(item.d==='m'){
        $('#M'+item[4]).show();
        let doc = document.getElementById('M'+item[4]);
        let str = String(item[1]).substring(2,4)+'.'+String(item[1]).substring(5,8);
        let ctr = String(item[2]).substring(2,4)+'.'+String(item[2]).substring(5,8);
        let str2 = Number(str);
        let ctr2 = Number(ctr);
        if(str2-data[item[4]]['x']>1.0||str2-data[item[4]]['x']<-1.0){
            doc.style.left = str+'%'
            data[item[4]]['x']=str2;
        }
        if(ctr2-data[item[4]]['y']>1.0||ctr2-data[item[4]]['y']<-1.0){
            doc.style.top = ctr+'%'
            data[item[4]]['y']=ctr2;
        }
        document.getElementById('M'+item[4]+'P').textContent = item[3].toFixed(1)+'m';
    } else if(item.d==='c'){
        data[item[1]]=[];
        data[item[1]]['x']=0.0;
        data[item[1]]['y']=0.0;
        $('#mark').append(`<div id="M${item[1]}" class="marker"><p class="marker_text" id="M${item[1]}P"></p></div>`)
    } else if(item.d==='h'){
        $('#M'+item[1]).hide();
    }
});

function Show(st) {
    console.log(st)
    if(st===true){
        $('#background').show();
        $('#list').show();
    } else {
        $('#background').hide();
        $('#list').hide();
    };
};

Show(false);

var back = 'https://'+GetParentResourceName()+'/';

function Clicked(e) {
    $.post(back+e.title, "{}")
}

document.onkeydown=(e)=>{
    if(e.which===27){
        $.post(back+'close', empty);
    };
}