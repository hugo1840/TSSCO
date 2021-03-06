declare @sDate datetime 
set @sDate =
(
	select Top 1 Tradingdate
	from [DBMain].[dbo].[Tradingdate]
	where MONTH(Tradingdate) = (case
									when  MONTH(CONVERT(datetime, GETDATE(), 105)) = 1 then 12
									else MONTH(CONVERT(datetime, GETDATE(), 105)) - 1
								end )
		and YEAR(Tradingdate) = (case 
									when MONTH(CONVERT(datetime, GETDATE(), 105)) = 1 then YEAR(CONVERT(datetime, GETDATE(), 105)) - 1
									else YEAR(CONVERT(datetime, GETDATE(), 105))
								 end )
	order by Tradingdate desc 
)


create table #AcctPortf(Acc nvarchar(50), Portfolio nvarchar(50))
insert #AcctPortf
SELECT distinct(Acc)
	  , Portfolio
FROM [DBMain].[dbo].[DefaultPortfolio_策略交易]
where BDate <= @sDate and EDate >= @sDate


--declare @Date1 datetime, @Date2 datetime
--set @Date1 = '2017-07-31'
--set @Date2 = '20170731'
SELECT *
	  ,Fut_PL + Stk_PL + Loan_PL as CumPL
FROM
(
	SELECT FutID
		  ,StockID
		  ,LoanID
		  ,case 
		       when Fut.Portfolio is not NULL then Fut.Portfolio
			   when Stk.Portfolio is not NULL then Stk.Portfolio
			   when Loan.Portfolio is not NULL then Loan.Portfolio
		   end as Portfolio 
		  ,case 
			   when nReal_Fut_CmuPL is NULL then 0
			   else nReal_Fut_CmuPL
		   end as Fut_PL
		  ,case 
			   when nReal_Stk_CumPL is NULL then 0
			   else nReal_Stk_CumPL
		   end as Stk_PL
		  ,case 
			   when Loan_CumPL is NULL then 0
			   else Loan_CumPL
		   end as Loan_PL
	FROM
	(
		--Futures PL
		SELECT distinct(交易代號) as FutID
			  ,Portfolio
			  ,SUM(未平倉損益) over(partition by 交易代號 order by 交易代號) as nReal_Fut_CmuPL
		FROM [PL].[dbo].[期貨_未平倉資料] as Future
		join #AcctPortf as Portfolio on (Future.交易代號 = Portfolio.Acc)
		--where 匯入日期 = @Date1
		where 匯入日期 = @sDate
	)as Fut
	full join
	(
		--Stock PL
		select distinct(交易員代碼) as StockID
			  ,Portfolio
			  ,SUM(今日未實現損益) over(partition by 交易員代碼 order by 交易員代碼) as nReal_Stk_CumPL
		from [PL].[dbo].[400現股庫存檔wkstkx] as Stock
		join #AcctPortf as Portfolio on(Stock.交易員代碼 = Portfolio.Acc)
		--where 庫存日期 = @Date2
		where 庫存日期 = @sDate
	)as Stk on (Fut.Portfolio = Stk.Portfolio)
	full join
	(
		--Loan PL
		select distinct(交易員代碼) as LoanID
			  ,Portfolio
			  ,SUM(今日未實現損益) over (partition by 交易員代碼 order by 交易員代碼) as Loan_CumPL
		from [PL].[dbo].[400券賣庫存損益檔wklnkx] as LoanPos
		join #AcctPortf as Portfolio on (Portfolio.Acc = LoanPos.交易員代碼)
		where 庫存日期 = @sDate
	)as Loan on (Loan.LoanID = Stk.StockID)
)as TotalPL
order by FutID


drop table #AcctPortf
/*
select * from [DBMain].[dbo].[DefaultPortfolio_策略交易]
select * from [PL].[dbo].[400現股庫存檔wkstkx]
*/
/*
select distinct(交易員代碼) as StockID, 
	   SUM(今日未實現損益) over(partition by 交易員代碼 order by 交易員代碼) as nReal_Stk_CumPL
from [PL].[dbo].[400現股庫存檔wkstkx]
where 交易員代碼 in (SELECT distinct(Acc)
					 FROM [DBMain].[dbo].[DefaultPortfolio_策略交易])
	  and 庫存日期 = '20170731'

*/