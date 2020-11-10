#遍历sheet版本
#读取excel，遍历最大范围的行列，并输出为新的txt
#遍历"./data"目录并把里面所有的xlsx文件转化为txt，输出在./trans
#考虑增加检测sheet数并使用最后一个sheet

#标准错误和标准输出写入processing.log文件
#目前用cmd错误输出到run.log,用perl的标准错误输出到processing.log
open STDOUT,">>processing.log" or die "can not open processing.log, $!";
open STDERR,">>processing.log" or die "can not open processing.log, $!";
use Encode;#处理编码
###遍历data目录下所有xlsx文件，生成文件句柄，打印结果###
opendir DIR,"./data" or die "can not open dir, $!";;
my $time = localtime();#记录时间
print "FMT__________ $time __________FMT\n";#日志文件抬头,一边10个_
$pattern = &hand("ID映射表");#模式
foreach (sort grep(/^.*\.xlsx$/,readdir(DIR))){
	push @allxlsx,$_;#把遍历到的文件名存入数组
	print "get \"$_\" successfully\n";#输出标志完成信息
}
closedir DIR;

###对xlsx文件进行解析和转换，会解析ID映射表中的每一个sheet
require Spreadsheet::ParseXLSX;#解析xlsx的包，注意，使用use无法在打包后正确找到这个包！！！
for(@allxlsx){#遍历文件句柄，以逐个解析
	my $filename = $_;#不同xlsx文件的名字(包括mapID)
	my $parser = Spreadsheet::ParseXLSX->new;#看不懂这句，官方文档写的
	my $workbook = $parser->parse("./data/$filename");#这里取出了工作表
	#$worksheet = $workbook->worksheet(0);#默认取出工作表中第一个sheet
	for my $worksheet ( $workbook->worksheets() ) {#遍历工作表中的所有sheet
		if($filename =~ /$pattern/){#ID映射表特殊命名，且不影响其他文件处理
			$HANDLE = $filename.$worksheet->get_name();#用工作表和sheet名做文件句柄
			my $tempname = ".\/trans\/".$worksheet->get_name().'.txt';#worksheet作为文件名的一部分
			open $HANDLE,">:encoding(utf-8)", $tempname or die "can not open $tempname, $!";
			$FILEHANDLE{$HANDLE} = $tempname;#保存文件句柄=文件名
			&parse_xlsx($worksheet,$filename);
		}
		else{
			$HANDLE = $filename;#用工作表做文件句柄,默认只解析第一个sheet
			my $tempname = ".\/trans\/".$filename.'.txt';#用临时变量组合文件名，不然后文if无法识别
			open $HANDLE,">:encoding(utf-8)", $tempname or die "can not open $tempname, $!";
			$FILEHANDLE{$HANDLE} = $tempname;#保存文件句柄=文件名
			&parse_xlsx($worksheet,$filename);
			last;
		}
	}
}
#print "______________________ END ______________________\n";#一边22个_
sub hand{#减少重复输入的子程序(函数)
		encode("gbk", decode("utf8",@_[0]));
}
sub parse_xlsx{#解析xlsx并输出，需要两个参数，$worksheet和$filename
	my ( $row_min, $row_max ) = @_[0]->row_range();
	my ( $col_min, $col_max ) = @_[0]->col_range();
	#循环取出每个单元格的值
	for(0..$row_max){
		my $row = $_;
		for(0..$col_max){
			my $col = $_;
			my $cell = @_[0]->get_cell($row,$col);
			my $value = $cell->value() if(defined $cell);#防止单元格为空
			push  @shelf,$value;
		}
		my $shelf = join "\t",@shelf;#输出格式
		print $HANDLE "$shelf\n";#写入$filename文件
		undef @shelf;#清空数组反复利用
	}
	if (-e $FILEHANDLE{$HANDLE}){#因为一些不知道问题，文件存在而不要求是否为空就输出结果
		print "Format \"@_[1]\" to \"$FILEHANDLE{$HANDLE}\"\n";#输出转换信息
		close $HANDLE;
	}

}