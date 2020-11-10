echo "YSY_____________%time%-|-%date%_____________YSY">>run.log
perl .\script\data2deal.pl 2>>run.log
copy data\易收银日激活.txt "data\OldData\YSYactivation_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt" 2>>run.log
copy data\易收银日交易.txt "data\OldData\YSYdaytrade_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt" 2>>run.log
echo "YSY________________________END________________________YSY">>run.log