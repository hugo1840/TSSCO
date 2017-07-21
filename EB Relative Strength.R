#EB Relative Strength 
#20170711

library(RODBC)
library(xts)

myCon <- odbcConnect(dsn = 'cmoney_41', uid = 'hank', pwd = 'hank')

#Select Trading Date
StartDate <- "2017-01-01"
EndDate <- "2017-07-10"
range <- paste(StartDate, "::", EndDate, sep = "")

MySQL <- "select Tradingdate"
MySQL <- paste(MySQL, " from [DBMain].[dbo].[Tradingdate]", sep = "")
MySQL <- paste(MySQL, " where Tradingdate between '", sep = "")
MySQL <- paste(MySQL, StartDate, "' and '", sep = "")
MySQL <- paste(MySQL, EndDate, "'", sep = "")

TrdDate <- sqlQuery(myCon, MySQL)

#Select FITE Closing Price
# MySQL <- "select ���, �N��, ���L��"
# MySQL <- paste(MySQL, " from Cmoney.dbo.���f����污��", sep = "")
# MySQL <- paste(MySQL, " where ��� between '", sep = "")
# MySQL <- paste(MySQL, StartDate, "' and '", sep = "")
# MySQL <- paste(MySQL, EndDate, "'", sep = "")
# MySQL <- paste(MySQL, " and �N�� = 'TE'")
MySQL <- "select TxDate, TimeTag, TickPrice_EXF�{�f, TickPrice_EXF��� ,TickQty_EXF��� ,B1Price_EXF��� ,B1Qty_EXF��� ,A1Price_EXF��� ,A1Qty_EXF���"
MySQL <- paste(MySQL, " from [Intraday].[dbo].[���ƴ��f�C����]", sep = "")
MySQL <- paste(MySQL, " where TxDate between '", sep = "")
MySQL <- paste(MySQL, StartDate, "' and '", sep = "")
MySQL <- paste(MySQL, EndDate, "'", sep = "")

TE <- sqlQuery(myCon, MySQL)
TE <- na.omit(TE)
names(TE) <- c("TxDate", "TimeTag", "Index_TE", "LastPrice_TE", "TickQty_TE", "B1Price_TE", "B1Qty_TE", "A1Price_TE", "A1Qty_TE")

#Select TE Divisor 
MySQL <- "select distinct(�~���), ���ư��"
MySQL <- paste(MySQL, " from [MarketData].[dbo].[TEJ���Ʀ����ѪѼ�]", sep = "")
MySQL <- paste(MySQL, "where ���q�N�X like 'M2300%'", sep = "")
MySQL <- paste(MySQL, " and �~��� between '", sep = "")
MySQL <- paste(MySQL, StartDate, "' and '", sep = "")
MySQL <- paste(MySQL, EndDate, "'", sep = "")

TEDvr <- sqlQuery(myCon, MySQL)
names(TEDvr) <- c("TxDate", "TE Divisor")

#TE <- merge(TE, TEDvr, by = c("Date"))
TE <- merge(x = TE, y = TEDvr, by.x = 'TxDate', by.y = 'TxDate', fill = -9999)
TE$TE_MktVal <- TE$LastPrice_TE * TE$`TE Divisor`
# TE <- TE[, -c(2, 3, 4)]

#Select FITF Closing Price
# MySQL <- "select ���, �N��, ���L��"
# MySQL <- paste(MySQL, " from Cmoney.dbo.���f����污��", sep = "")
# MySQL <- paste(MySQL, " where ��� between '", sep = "")
# MySQL <- paste(MySQL, StartDate, "' and '", sep = "")
# MySQL <- paste(MySQL, EndDate, "'", sep = "")
# MySQL <- paste(MySQL, " and �N�� = 'TF'")
# MySQL <- paste(MySQL, " order by ���")
MySQL <- "select TxDate, TimeTag, TickPrice_FXF�{�f, TickPrice_FXF��� ,TickQty_FXF��� ,B1Price_FXF��� ,B1Qty_FXF��� ,A1Price_FXF��� ,A1Qty_FXF���"
MySQL <- paste(MySQL, " from [Intraday].[dbo].[���ƴ��f�C����]", sep = "")
MySQL <- paste(MySQL, " where TxDate between '", sep = "")
MySQL <- paste(MySQL, StartDate, "' and '", sep = "")
MySQL <- paste(MySQL, EndDate, "'", sep = "")

TF <- sqlQuery(myCon, MySQL)
TF <- na.omit(TF)
names(TF) <- c("TxDate", "TimeTag", "Index_TF", "LastPrice_TF", "TickQty_TF", "B1Price_TF", "B1Qty_TF", "A1Price_TF", "A1Qty_TF")

#Select TF Divisor
MySQL <- "select distinct(�~���), ���ư��"
MySQL <- paste(MySQL, " from [MarketData].[dbo].[TEJ���Ʀ����ѪѼ�]", sep = "")
MySQL <- paste(MySQL, "where ���q�N�X like 'M2800%'", sep = "")
MySQL <- paste(MySQL, " and �~��� between '", sep = "")
MySQL <- paste(MySQL, StartDate, "' and '", sep = "")
MySQL <- paste(MySQL, EndDate, "'", sep = "")

TFDvr <- sqlQuery(myCon, MySQL)
names(TFDvr) <- c("TxDate", "TF Divisor")

#Close ODBC
odbcClose(myCon)

# TF <- merge(TF, TFDvr, by = c("Date"), all = T)
TF <- merge(x = TF, y = TFDvr, by.x = 'TxDate', by.y = 'TxDate', fill = -9999)
TF$TF_MktVal <- TF$LastPrice_TF * TF$`TF Divisor`
# TF <- TF[, -c(2, 3, 4)]

FUT <- merge(TE, TF, by = c("Date"), all = T)
FUT$A_Val <- 2 * FUT$TE_MktVal - 3 * FUT$TF_MktVal

n <- dim(FUT)[1]
for (i in 36:n)
{
    FUT[i, 5] <- min(FUT[(i-35):i, 4])
    FUT[i, 6] <- max(FUT[(i-35):i, 4])
}
names(FUT) <- c("Date", "TE_MktVal", "TF_MktVal", "A_Val", "35_min", "35_max")

for (i in 36:n)
{
    # print(FUT[i, 4] > FUT[i, 6])
    if(FUT[i, 4] < FUT[i, 5])
        print(i)
    if(FUT[i, 4] > FUT[i, 6])
        print(i)
}

