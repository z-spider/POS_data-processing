#需求：从多份数据源中找到所查ID对应的数据，并输出成一张表格
#目前数据输入文件为ANSI，ID映射文件为utf8
#脚本将所有的utf8编码转化为了gbk处理
#考虑加入单独执行某份文件的功能
#考虑增加空数据警示
#注意，名单中没有映射的id是不会有数据的，手动添加也不行

##使用YSY.txt整理数据##

#错误日志，未完成
open STDOUT,">>processing.log" or die "can not open processing.log";
open STDERR,">>processing.log" or die "can not open processing.log";
#获取当天时间作为文件名
my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime();
$mon=$mon+1;
$year=$year+1900;
my $time = localtime();
my $date = "$year$mon$day\_$hour $min $sec";
print "YSY__________ $time __________YSY\n";#日志文件抬头,一边10个_
open ID,"./trans/YSY.txt" or die "can not open YSY.txt, $!";
open YSYACT,&hand('./data/易收银日激活.txt') or die "can not open YSYDayActivate, $!";#用utf8编码的文件名无法被实别
open DAYTRADE,&hand('./data/易收银日交易.txt') or die "can not open YSYDayTrade, $!";
open OUT,">YSY_$date.txt" or die "can not open YSY_$date.txt, $!";
use Encode;

###读取数据文件和ID映射文件###
while(<YSYACT>){
	chomp;
	if(/^\d+\s(.+?)\s(\d+)\s(\d+)/){#\s\d+\s\d+\s\d+\s 暂时未用到
		$activate{$1}=$3;
	}
}
while(<DAYTRADE>){
	chomp;
	if(/^\d+\s\|\s(\S+?)\s[0-9\-]+\t[0-9\-]+\t\d+\t([0-9,\.]+)\t/){#数字中有逗号
		my $trade = $2;
		my $name = $1;
		$trade =~ s/,//;
		$daytrade{$name}=$trade;
	}
}
$temp=0;
while(<ID>){
	$temp++;#代表行数
	$_ = &hand($_);#编码转换
	chomp;#去除行尾换行符
	next if($temp ==1 && /ID/);#跳过首行
	if(/^(.+?)\t(.{0,})$/){#匹配有映射关系的id，同时不丢弃任何id
		$mapping{$1}=$2; #ID和易收银数据中名字的映射关系
		push @order,$1;#ID作为key和排序列表
	}
}
###计算###
for (@order){
	$i+=$activate{$mapping{$_}};#全部激活数
	$j+=$daytrade{$mapping{$_}};#全部交易额
	if($_ eq &hand('代理合计')){
		$agency_activate = $i;#代理激活总数
		$agency_daytrade = $j;#代理日交易总额
		&dfmt($agency_daytrade);#保留两位小数因为浮点精度问题
	}
	if($_ eq &hand('直营合计')){
		$direct_activate = $i-$agency_activate;#直营激活总数
		$direct_daytrade = $j-$agency_daytrade;#直营日交易总额
		&dfmt($direct_daytrade);#保留两位小数
	}	
}
#手动添加计算结果
$activate{ &hand('代理合计') } = $agency_activate;
$activate{ &hand('直营合计') } = $direct_activate;
$daytrade{ &hand('代理合计') } = $agency_daytrade;
$daytrade{ &hand('直营合计') } = $direct_daytrade;
###输出结果###
$title = &hand('易收银代理	网页中id(核验是否映射有错)	日激活	日交易');
print OUT"$title\n";#结果中的标题
for(@order){
	print OUT"$_\t$mapping{$_}\t$activate{$mapping{$_}}\t$daytrade{$mapping{$_}}\n";
}
if (-z "YSY_$date.txt"){#文件存在且不为空，输出成功
	print "Processing complete, see \"YSY_$date.txt\"\n";#输出转换信息
	close OUT;
}
sub hand{#减少重复输入的子程序(函数)
	encode("gbk", decode("utf8",@_[0]));
}
sub dfmt{#数字精度格式化
	@_[0] = sprintf "%.2f",@_[0];
}