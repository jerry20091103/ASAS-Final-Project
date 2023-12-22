# ASAS-Final-Project
This is the final project for the 2023 ASAS course: Formant-preserved harmony effect.

```matlab

for each frame (each frame overlapped)
    inputFrame = audioFile(x:y)
    outputFrame = lpc_pitchshift(inputFrame, shiftAmount)
    windowed = hannWindow(outputFrame)
    output = overLapAdd(windowed, output)
end

case 1:(pitch_shift)
...
break
case 2:(lpc)
...
break
case 3:(cepstrum)
...
break

```
## PPT content:(style 我開心就好)
### team members: (Group 6)
- 林鈺承
- 莊鈞堯
- 黃詠家
### topic: 
Formant-preserved harmony effect
### research motivation: 
Why harmonizer?
因為我唱不上去 (還唱不下去) 錄和聲很麻煩
直接pitch shift會變聲，不自然，formants會跑掉
### anticipated outcomes: 
- 合聲
- 像自己的聲音的和聲(或是其他人的聲音的和聲)
調整和聲 (女變男之類的)
### current progress: 
存音檔
使用方法: lpc
### future work:
和聲 cepstrum(optional) real-time(optional)

## Timeline
Monday night -> lpc + ppt
