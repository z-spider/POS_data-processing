if not exist OldData (mkdir OldData)
copy 易收银日激活.txt "OldData\YSYactivation_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
copy 易收银日交易.txt "OldData\YSYdaytrade_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
move Export*Trade*.xlsx OldData
move 合利宝pos*.xlsx OldData
del ..\trans\合利宝pos*.xlsx.txt
echo "DateCLN_____________%time%-|-%date%_____________DateCLN">>../run.log