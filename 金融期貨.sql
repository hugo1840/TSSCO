declare @t datetime set @t='2017/4/6'

declare @年月 nvarchar(50) set @年月=(select min(年月) from db.dbmain.[dbo].[期貨結算日] where [結算日]>@t)

create table #StockID(StockID nvarchar(50))
insert #StockID
select 股票代號
from db.cmoney.dbo.上市櫃公司基本資料
where 產業代號='17' and 上市上櫃='1'

create table #FutID(StockID nvarchar(50),FutID nvarchar(50))
insert #FutID
select a.標的代號,a.代號+b.英文月+right(left(@年月,4),1)
from db.marketdata.[dbo].[每日個股期貨契約乘數] a
join #StockID s on s.StockID=a.標的代號
left join db.dbmain.[dbo].[期貨_英文月份對照表] b on b.數字月=right(@年月,2)
where a.日期=@t and a.代號 like '__F'

insert #FutID
select '金融期','FXF'+英文月+right(left(@年月,4),1)
from db.dbmain.[dbo].[期貨_英文月份對照表]
where 數字月=right(@年月,2)

select *
from #FutID a
join Intraday.[dbo].[DailyTick_01min_FU] b on b.TxDate=@t and b.StockId=a.FutID

select *
from #StockID a
join Intraday.[dbo].[DailyTick_01min] b on b.TxDate=@t and b.StockId=a.StockID

drop table #FutID
drop table #StockID


