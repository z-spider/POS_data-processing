##读取excel，遍历最大范围的行列，并输出为新的txt(mapID.txt)##
##考虑增加检测sheet数并使用最后一个sheet##

#读取并解析excel文件
$file = "mapID.txt";
open MAPID,">:encoding(utf-8)", $file;
###注意，使用use无法在打包后正确找到这个包！！！
require Spreadsheet::ParseXLSX;#解析xlsx的包
my $parser = Spreadsheet::ParseXLSX->new;#$parser是包里的功能？
my $workbook = $parser->parse(&hand('ID映射表.xlsx'));#这里取出了工作表
$worksheet = $workbook->worksheet(0);#默认取出工作表中第一个sheet，
my ( $row_min, $row_max ) = $worksheet->row_range();#得到列表内容范围
my ( $col_min, $col_max ) = $worksheet->col_range();

#循环取出每个单元格的值
for(0..$row_max){
	$row = $_;
	for(0..$col_max){
		$col = $_;
		my $cell = $worksheet->get_cell($row,$col);
		my $value = $cell->value() if(defined $cell);#防止单元格为空
		push @shelf,$value;
	}
	$shelf = join "\t",@shelf;#输出格式
	print MAPID"$shelf\n";
	undef @shelf;#清空数组反复利用

}
if (-e $file){
	print "Successfully created mapID.txt\n$_";
	close MAPID;
}

##使用mapID.txt整理数据##

#获取当天时间作为文件名
my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime();
$mon=$mon+1;
$year=$year+1900;
my $date = "$mon-$day-$year\_$hour$min$sec";
open ID,"mapID.txt";
open YSY,&hand('易收银日激活.txt');#用utf8编码的文件名无法被实别
open DAYTRADE,&hand('易收银日交易.txt');
open OUT,">$date.txt";
use Encode;
###读取数据文件和ID映射文件###

while(<YSY>){
	chomp;
	if(/^\d+\s(.+?)\s(\d+)\s(\d+)/){#\s\d+\s\d+\s\d+\s 暂时未用到
		$activate{$1}=$3;
	}
}
while(<DAYTRADE>){
	chomp;
	if(/^\d+\s\|\s(\S+?)\s[0-9\-]+\t[0-9\-]+\t\d+\t([0-9,\.]+)\t/){#数字中有逗号
		$trade = $2;
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
		#&dfmt($agency_activate);#激活是整数，不需要保留两位小数
		&dfmt($agency_daytrade);#保留两位小数，因为浮点精度问题
	}
	if($_ eq &hand('直营合计')){
		$direct_activate = $i-$agency_activate;#直营激活总数
		$direct_daytrade = $j-$agency_daytrade;#直营日交易总额
		#&dfmt($direct_activate);#激活是整数，不需要保留两位小数
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
print OUT"$title\n";
for(@order){
	print OUT"$_\t$mapping{$_}\t$activate{$mapping{$_}}\t$daytrade{$mapping{$_}}\n";
}
sub hand{#减少重复输入的子程序(函数)
	encode("gbk", decode("utf8",@_[0]));
}
sub dfmt{
	@_[0] = sprintf "%.2f",@_[0];
}