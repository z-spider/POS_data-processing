call A数据格式化.bat
echo "XSB_____________%time%-|-%date%_____________XSB">>run.log
perl .\script\xsbProcessing.pl 2>>run.log
if exist .\data\Export*Trade*.xlsx (move .\data\Export*Trade*.xlsx data\OldData 2>>run.log) else (echo "need data named Export*Trade*.xlsx">>run.log)
if exist .\trans\Export*Trade*.xlsx.txt (del .\trans\Export*Trade*.xlsx.txt 2>>run.log) else (echo "There is no tempfile named Export*Trade*.xlsx.txt in the trans folder">>run.log)
::正反斜杠cmd下含义不同
echo "XSB________________________END________________________XSB">>run.log
