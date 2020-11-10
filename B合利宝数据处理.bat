call A数据格式化.bat
echo "HLB_____________%time%-|-%date%_____________HLB">>run.log
perl .\script\hlbProcessing.pl 2>>run.log
if exist .\data\合利宝pos*.xlsx (move .\data\合利宝pos*.xlsx data\OldData 2>>run.log) else (echo "need data named 合利宝pos*.xlsx">>run.log)
if exist .\trans\合利宝pos*.xlsx.txt (del .\trans\合利宝pos*.xlsx.txt 2>>run.log) else (echo "There is no tempfile named 合利宝pos*.xlsx.txt in the trans folder">>run.log)
::正反斜杠cmd下含义不同
echo "HLB________________________END________________________HLB">>run.log
