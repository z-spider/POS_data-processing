#星收宝数据处理脚本，需要的文件由allsheet2txt生成(格式化)
#遍历目录下所有星收宝数据文件(txt)，并生成对应的处理结果
#日志写入processing.log

###文件，抬头格式和日志
use Encode;
#标准错误和标准输出写入processing.log文件
#目前用cmd错误输出到run.log,用perl的标准错误输出到processing.log
open STDOUT,">>processing.log" or die "can not open processing.log, $!";
open STDERR,">>processing.log" or die "can not open processing.log, $!";
#读取ID文件和目录
opendir DIR,"./trans" or die "can not open dir, $!";;
open ID,"./trans/XSB.txt" or die "can not open XSB.txt, $!";
#时间作为文件名的一部分
my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime();
my $time = localtime();
my $date = "_$hour $min $sec";
print "XSB__________ $time __________XSB\n";#日志文件抬头,一边10个_

##读取星收宝ID映射文件
while(<ID>){
	$temp++;#代表行数
	$_ = &hand($_);#编码转换
	chomp;#去除行尾换行符
	next if($temp ==1 && /ID/);#跳过首行
	if(/^(.+?)\t(.{0,})$/){#匹配有映射关系的id，同时不丢弃任何id
		my @MultipleID = split /;/,$2;
		for(@MultipleID){#遍历拆分后的data中的姓名
			$mapping{$1}=$2; #ID和星收宝数据中名字的映射关系
			$mapping{$_}=$2; #拆分分号得到的名字做key，表格名字做值，以变求和时汇总
		}
		push @order,$1;#ID作为key和排序列表
	}
}
###遍历文件夹下所有星收宝数据，并计算###
foreach (sort grep(/^ExportTradeAll-(\d+)\.xlsx\.txt$/,readdir(DIR))){#这里取不出$1
	my $filename = $_;#星收宝数据文件名
	my $outname;
	if(/^ExportTradeAll-(\d+)\.xlsx\.txt$/){#这里获取文件的部分名字
		$outname = 'XSB_'.$1.$date;#输出文件名，不含txt，因为.无法作为文件句柄
		push @outfile, $outname;#输出文件列表
	}
	open $filename,"./trans/$filename" or die "can not open $filename, $!";#打开对应数据文件句柄
	print "\"$filename\" will be processed\n";#输出标志完成信息
	while(<$filename>){#读取文件数据
		chomp;
		#模式太长了，$1是金额，含逗号和小数据，$2是直属服务商名称
		$pattern = '^\d+\t\S+\t\d+\t\w+\t\S+\t\d+\t\d+\t\d+\t\S+\t\S+\t\S+\t([0-9,\.]+)\t\S+\t\S+\t\d+\t(\S+)\t';
		if(/$pattern/){#取出交易金额和直属服务商名称
			my $trade = $1;#数字不用转换编码
			my $name = &hand($2);#这里是utf8格式的数据文件
			$trade =~ s/,//;#去掉千分位逗号
			#如果该值不为空(防止空的ID加到一起)，相同代理商数据合计
			$alltrade{$outname}{$mapping{$name}}+=$trade if($mapping{$name});
		}
	}
}

##计算求和
for(@outfile){
	my $outname = $_;
	for (@order){
		$i+=$alltrade{$outname}{$mapping{$_}};#全部交易额
		if($_ eq &hand('代理合计')){
			$agency_daytrade = $i;#代理日交易总额
			&dfmt($agency_daytrade);#保留两位小数因为浮点精度问题
		}
		if($_ eq &hand('直营合计')){
			$direct_daytrade = $i-$agency_daytrade;#直营日交易总额
			&dfmt($direct_daytrade);#保留两位小数
		}	
	}
#手动添加计算结果
	$alltrade{$outname}{ &hand('代理合计') } = $agency_daytrade;
	$alltrade{$outname}{ &hand('直营合计') } = $direct_daytrade;
}

###输出数据结果###
my $title = &hand('星收宝代理	网页中id(核验是否映射有错)	交易金额');
for(@outfile){#打开不同的输出句柄
	my $outname = $_;#输出文件名，不含后缀
	open $outname,">$outname.txt" or die "can not open $outname.txt, $!";#输出文件
	print $outname "$title\n";
	for(@order){
		print  $outname "$_\t$mapping{$_}\t$alltrade{$outname}{$mapping{$_}}\n";#写入结果
	}
	if (-z "$outname.txt"){#
		print "Processing complete, see \"$outname.txt\"\n";#输出转换信息
		close $filename;
	}
}
sub hand{#减少重复输入的子程序(函数)
	encode("gbk", decode("utf8",@_[0]));
}
sub dfmt{#数字精度格式化
	@_[0] = sprintf "%.2f",@_[0];
}