#数据处理脚本，需要的文件由allsheet2txt生成(格式化)
#遍历目录下所有符合要求的数据文件(txt)，并生成对应的处理结果
#日志写入processing.log
#用法见另外的脚本


use Encode;
package Process;#包名
#时间处理
my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime();
my $time = localtime();
my $date = "_$hour $min $sec";
#open STDOUT,">>processing.log" or die "can not open processing.log, $!";
#open STDERR,">>processing.log" or die "can not open processing.log, $!";

sub new{#这里如果不面向对象，而是采用Process::hand类似的方法是不是也可以？
	my $class = shift;
	my $self = {
		_posname => shift,#pos系统名称
		_filepattern => shift,#文件过滤pattern
		_pattern => shift,#文件内容pattern
	};
	bless $self, $class;#这句不懂
	return $self;#返回匿名哈希
}

sub init{#初始化子程序，读取ID映射
	use Encode;
	my (%mapping, @order);#如果放在外面, 每调用一次init@order都会被push一遍
	my ( $self ) = @_;#接受传回来的数据，独立处理过程
	###文件，抬头格式和日志
	#标准错误和标准输出写入processing.log文件
	#目前用cmd错误输出到run.log,用perl的标准错误输出到processing.log

	#读取ID文件和目录
	opendir DIR,"./trans" or die "can not open dir, $!";
	open ID,"./trans/$self->{_posname}.txt" or die "can not open $self->{_posname}.txt, $!";
	#时间作为文件抬头的一部分
	#print "$self->{_posname}__________ $time __________$self->{_posname}\n";#日志文件抬头,一边10个_

	##读取ID映射文件
	while(<ID>){
		my $temp++;#代表行数
		$_ = &hand($_);#编码转换
		chomp;#去除行尾换行符
		next if($temp ==1 && /ID/);#跳过首行
		if(/^(.+?)\t(.{0,})$/){#匹配有映射关系的id，同时不丢弃任何id
			my @MultipleID = split /;/,$2;
			for(@MultipleID){#遍历拆分后的data中的姓名
				$mapping{$1}=$2; #ID和数据中名字的映射关系
				$mapping{$_}=$2; #拆分分号得到的名字做key，表格名字做值，以变求和时汇总
			}
			push @order,$1;#ID作为key和排序列表
		}
	}
	return \@order, \%mapping;
	
}	

sub TradeProcess{#计算交易数据(一列ID一列数据)(星收宝合利宝日交易)，或者需要求和的数据(易收银日激活)
	my ( $self, $order, $mapping ) = @_;
	my ( %alltrade, @outfile );#注意提前声明，防止多次调用时变量冲突
	###遍历文件夹下符合要求的数据，并计算###
	foreach (sort grep(/$self->{_filepattern}/,readdir(DIR))){#这里取不出$1
		my $filename = $_;#星收宝数据文件名
		my $outname;
		if(/$self->{_filepattern}/){#这里获取文件的部分名字
			$outname = "$self->{_posname}_".$1.$2.$date;#输出文件名，不含txt，因为.无法作为文件句柄
			push @outfile, $outname;#输出文件列表
		}
		open $filename,"./trans/$filename" or die "can not open $filename, $!";#打开对应数据文件句柄
		print "\"$filename\" will be processed\n";#输出标志完成信息
		while(<$filename>){#读取文件数据
			chomp;
			#模式太长了，$1是金额，含逗号和小数据，$2是直属服务商名称
			if(/$self->{_pattern}/){#取出交易金额和直属服务商名称
				my ($temp1, $temp2) = ($1, $2);#不用临时变量if判断无法正常工作或者else无法工作
				my ($trade, $name);
				if($temp1 =~/[0-9,\.]+/){
					$trade = $temp1;#数字不用转换编码
					$name = &hand($temp2);#这里是utf8格式的数据文件
				}
				else{
					$trade = $temp2;#数字不用转换编码
					$name = &hand($temp1);#这里是utf8格式的数据文件
				}
				$trade =~ s/,//;#去掉千分位逗号
				#如果该值不为空(防止空的ID加到一起)，相同代理商数据合计
				$alltrade{$outname}{$$mapping{$name}}+=$trade if($$mapping{$name});
			}
		}
		close $filename;
	}

	##计算求和
	for(@outfile){
		my $outname = $_;
		my ($agency_daytrade, $direct_daytrade, $i);
		for (@$order){
			$i += $alltrade{$outname}{$$mapping{$_}};#全部交易额
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
	return \@outfile, \%alltrade;#返回@outfile(outname列表,用于区分不同文件的数据)和交易数据
}

sub ActivateProcess{#计算激活数据(只有ID，hansh{ID}++)(星收宝合利宝日激活)
	my ( $self, $order, $mapping) = @_;#用到的数据
	my ( %allactivate );#注意提前声明，防止多次调用时变量冲突
	###遍历文件夹下所有激活数据，并计算###
	foreach (sort grep(/$self->{_filepattern}/,readdir(DIR))){#这里取不出$1
		my $filename = $_;#数据文件名
		my $outname;
		if(/$self->{_filepattern}/){#这里获取文件的部分名字
			$outname = "$self->{_posname}_".$1.$2.$date;#输出文件名，不含txt，因为.无法作为文件句柄
			push @outfile, $outname;#输出文件列表
		}
		open $filename,"./trans/$filename" or die "can not open $filename, $!";#打开对应数据文件句柄
		print "\"$filename\" will be processed\n";#输出标志完成信息
		while(<$filename>){#读取文件数据
			chomp;
			#模式太长了，$1是金额，含逗号和小数据，$2是直属服务商名称
			if(/$self->{_pattern}/){#取出符合模式的pattern
				my $name = &hand($1);#utf8转换
				#不为空时累加激活数
				$allactivate{$outname}{$$mapping{$name}}++ if($$mapping{$name});
			}
		}
		close $filename;
	}
	##计算求和
	for(@outfile){
		my $outname = $_;#为了统一名称
		my ($agency_activate, $direct_activate, $i);#提前声明变量
		for (@$order){
			$i += $allactivate{$outname}{$$mapping{$_}};#全部激活数量
			if($_ eq &hand('代理合计')){
				$agency_activate = $i;#代理日激活总额
			}
			if($_ eq &hand('直营合计')){
				$direct_activate = $i-$agency_activate;#直营日激活总额
			}	
		}
	#手动添加计算结果
		$allactivate{$outname}{ &hand('代理合计') } = $agency_activate;
		$allactivate{$outname}{ &hand('直营合计') } = $direct_activate;
	}
	return \@outfile, \%allactivate;#返回@outfile(outname列表,用于区分不同文件的数据)和激活数据
}

###输出数据结果###
sub output{#因为对面向对象的理解不深刻，导致了传入大量的参数，或许可以通过匿名哈希解决
	my ( $self, $T_outfile, $order, $mapping, $all_activate, $all_trade, $A_keyname, $T_keyname) = @_;
	my $title = &hand("$self->{$posname}代理	系统中id(核验是否映射有错)	日激活	日交易");
	for(@$T_outfile){#打开不同的输出句柄
		my ( $outname, $RLname, $writename ) = ( $_, $_, $_ );#输出文件名，不含后缀
		$RLname =~ s/$T_keyname/$A_keyname/;#关联激活数据和交易数据（把激活二字换掉就是交易了
		$writename =~ s/$T_keyname//;#文件名不要包含激活或者交易（但这里不会有交易所以没放入）
		#$filemapping{$outname} = $RLname;#用哈希的写法，但这里没必要
		open $outname,">$writename.txt" or die "can not open $writename.txt, $!";#输出文件
		print $outname "$title\n"; #文件内容标题行
		for(@$order){
			print  $outname "$_\t$$mapping{$_}\t$$all_activate{$RLname}{$$mapping{$_}}\t$$all_trade{$outname}{$$mapping{$_}}\n";#写入结果
		}
		if (-z "$writename.txt"){#
			print "Processing complete, see \"$writename.txt\"\n";#输出转换信息
			close $outname;
		}
	}
}

#辅助子程序
sub hand{#减少重复输入的子程序(函数)
	return encode("gbk", decode("utf8",shift));
}
sub dfmt{#数字精度格式化
	@_[0] = sprintf "%.2f",@_[0];
}
1;