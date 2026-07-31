// You want to get all the channel IDs that you are subscribed to on YouTube. You do:
function getChannelIdFromURL(p_url) {
  let rx = /(@.*)/g
  let arr = rx.exec(p_url)
  if (arr !== null && arr[1] !== null) {  
    return arr[1]
  }
}

let elems = document.getElementsByClassName("channel-link yt-simple-endpoint style-scope ytd-channel-renderer")
let elem_arr = {}
elem_arr[elems[0].href] = true
for (let x = 1; x < elems.length; x++) { elem_arr[elems[x].href] = true }
elem_arr = Object.keys(elem_arr)
let elems_str = getChannelIdFromURL(elem_arr[0])
for (let x = 1; x < elem_arr.length; x++) { elems_str = elems_str + ", " + getChannelIdFromURL(elem_arr[x]) }

console.log(elems_str);
