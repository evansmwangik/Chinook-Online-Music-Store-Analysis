-- DESCRIPTIVE ANALYSIS
-- Years represented in the data - Using Invoice dates
SELECT DISTINCT YEAR(InvoiceDate)  FROM invoice; -- 2021 to 2025

-- Revenues
-- Yearly and Monthly
SELECT * FROM invoice;

SELECT YEAR(InvoiceDate) rev_year, SUM(Total) total_rev
FROM invoice
GROUP BY rev_year
ORDER BY total_rev DESC; -- 2022 leads in sales by revenue, closely followed by 2024, 2023, 2025, 2021 respectively

SELECT 
	YEAR(InvoiceDate) rev_year, 
    SUM(Total) total_rev,
    ROUND((SUM(Total)/ (SELECT SUM(Total) FROM invoice)) * 100, 2)  AS percent_of_total
FROM invoice
GROUP BY rev_year
ORDER BY total_rev DESC; -- Percentagewise, they are all close with the biggest difference being 1.3 %
-- monthly
SELECT 
	SUBSTRING(InvoiceDate, 1, 7) month_year, 
	SUM(Total) total_rev
FROM invoice
GROUP BY month_year
ORDER BY month_year, total_rev;

WITH top3_months AS
(
SELECT 
	SUBSTRING(InvoiceDate, 1, 7) month_year,
    YEAR(InvoiceDate),
	SUM(Total) total_rev,
    RANK() OVER(PARTITION BY YEAR(InvoiceDate) ORDER BY SUM(Total) DESC) AS `rank`
FROM invoice
GROUP BY YEAR(InvoiceDate),month_year
)
SELECT month_year, total_rev, `rank` 
FROM top3_months
WHERE 	`rank` <= 3; -- The months performans seems to be spread across all most months evenly 37.62 appears accross multiple months over the years


-- Regional Analysis
-- General over the years
SELECT 
	t2.Country, 
    SUM(t1.Total) total_rev,
    ROUND((SUM(t1.Total)/(SELECT SUM(Total) FROM invoice)) * 100, 2) revenue_percentage
FROM invoice t1
JOIN customer t2
	ON t1.CustomerId = t2.CustomerId
GROUP BY t2.Country
ORDER BY total_rev DESC; -- USA Generated most sales by revenue - leading by 22% of the total revenue, followed by Canada with 13%

SELECT * FROM invoice;

SELECT 
    YEAR(t1.InvoiceDate) `year`,
	t2.Country,
    SUM(t1.Total) total_rev,
    ROUND((SUM(t1.Total)/(SELECT SUM(Total) FROM invoice)) * 100, 2) revenue_percentage
FROM invoice t1
JOIN customer t2
	ON t1.CustomerId = t2.CustomerId
GROUP BY `year`, t2.Country
ORDER BY `year`, total_rev DESC;

WITH top3CountriesYearly AS
(
SELECT 
    YEAR(t1.InvoiceDate) `year`,
	t2.Country,
    SUM(t1.Total) total_rev,
    RANK() OVER(PARTITION BY YEAR(t1.InvoiceDate) ORDER BY SUM(t1.Total) DESC) rev_rank
FROM invoice t1
JOIN customer t2
	ON t1.CustomerId = t2.CustomerId
GROUP BY `year`, t2.Country
)
SELECT * 
FROM top3CountriesYearly
WHERE rev_rank <= 3
; 
-- The top 2 countries every year remain to be USA Canada except for one year, 2024, where Canada was beaten by Brazil and became third. 
-- Position 3 is not consistent over the years since the there is a variation in the countries appearing in that position over the years
-- Brazil has appeared twice in the top 3 over the years

-- Rank By No. of Items Bought by country
SELECT
	t2.Country,
    SUM(t3.Quantity) items_count,
    ROUND((SUM(t3.Quantity)/(SELECT SUM(Quantity) FROM invoiceline)) * 100, 2) purchased_items_percentage
FROM invoice t1
JOIN customer t2
	ON t1.CustomerId = t2.CustomerId
JOIN invoiceline t3
	ON t1.InvoiceId = t3.InvoiceId
GROUP BY t2.Country
ORDER BY items_count DESC; -- Top 3 countries leading in sales by item count are USA, Canada, Brazil and France - A tie in Brazil and France

WITH top3CountriesYearlyPurchases AS
(
SELECT 
    YEAR(t1.InvoiceDate) `year`,
	t2.Country,
    SUM(t3.Quantity) items_count,
    RANK() OVER(PARTITION BY YEAR(t1.InvoiceDate) ORDER BY SUM(t3.Quantity) DESC) items_purchased_rank
FROM invoice t1
JOIN customer t2
	ON t1.CustomerId = t2.CustomerId
JOIN invoiceline t3
	ON t1.InvoiceId = t3.InvoiceId
GROUP BY `year`, t2.Country
)
SELECT * 
FROM top3CountriesYearlyPurchases
WHERE items_purchased_rank <= 3
; -- Yearly, the rank is similar to the ranks in yearly revenue. Only difference noted is that there is a tie in items count for the year 2022 where France and Brazil rank as second

-- No. of Customers Per Region
SELECT
	t2.Country,
    COUNT(t2.CustomerId) customers_count
FROM invoice t1
JOIN customer t2
	ON t1.CustomerId = t2.CustomerId
GROUP BY t2.Country
ORDER BY customers_count DESC; -- USA, Canada, France & Brazil

-- Which artists, albums or genres generated the most revenue
-- No. of Artists
SELECT COUNT(*) FROM artist; -- Total Artists 275
-- No. of Albums
SELECT COUNT(*) FROM album; -- 347 Albums
-- No. of Genres
SELECT COUNT(*) FROM genre; -- 25 Music Genres

SELECT t1.`Name`, COUNT(t2.Title) AlbumTitle
FROM artist t1
JOIN album t2
	ON t1.ArtistId = t2.ArtistId
GROUP BY t1.`Name`
ORDER BY AlbumTitle DESC; -- Top 5 Artists by Albums: 'Iron Maiden' , 'Led Zeppelin', 'Deep Purple', 'Metallica', 'U2'

-- Artist Generating the most revenue
SELECT 
	t4.`Name`, 
    SUM(t1.UnitPrice) rev_generated,
    ROUND((SUM(t1.UnitPrice)/(SELECT SUM(UnitPrice) FROM invoiceline)) * 100, 2) `%SaleSize`
FROM invoiceline t1
JOIN track t2
	ON t1.TrackId = t2.TrackId
JOIN album t3
	ON t2.AlbumId = t3.AlbumId
JOIN artist t4
	ON t3.ArtistId = t4.ArtistId
GROUP BY t4.`Name`
ORDER BY rev_generated DESC;

WITH artist_album_counts AS 
(
SELECT 
	t1.Name,
	COUNT(t2.AlbumId) AS album_count
FROM artist t1
JOIN album t2
	ON t1.ArtistId = t2.ArtistId
GROUP BY t1.Name
),

top_5_determinant AS
(SELECT 
    Name,
    album_count,
    RANK() OVER(ORDER BY album_count DESC) AS album_rank
FROM artist_album_counts)

SELECT 
	t4.`Name`, 
    SUM(t1.UnitPrice) rev_generated,
    ROUND((SUM(t1.UnitPrice)/(SELECT SUM(UnitPrice) FROM invoiceline)) * 100, 2) `%SaleSize`
FROM invoiceline t1
JOIN track t2
	ON t1.TrackId = t2.TrackId
JOIN album t3
	ON t2.AlbumId = t3.AlbumId
JOIN artist t4
	ON t3.ArtistId = t4.ArtistId
WHERE t4.`Name` IN (SELECT Name FROM top_5_determinant WHERE album_rank <= 5)
GROUP BY t4.`Name`
ORDER BY rev_generated DESC
; -- Visualizing how the top 5 artists with most albums performed in terms of revenue

-- Leading Genres in terms of Revenue
SELECT
	t3.Name,
    SUM(t1.UnitPrice) rev_generated,
    ROUND((SUM(t1.UnitPrice)/(SELECT SUM(UnitPrice) FROM invoiceline)) * 100, 2) `%SaleSize`
FROM invoiceline t1
JOIN track t2
	ON t1.TrackId = t2.TrackId
JOIN genre t3
	ON t2.GenreId = t3.GenreId
GROUP BY t3.Name
ORDER BY rev_generated DESC;

-- Leading albums by Revenue Generated
SELECT
	t3.Title,
    COUNT(t3.Title) sold_albums_count,
    SUM(t1.UnitPrice) rev_generated,
    ROUND((SUM(t1.UnitPrice)/(SELECT SUM(UnitPrice) FROM invoiceline)) * 100, 2) `%SaleSize`
FROM invoiceline t1
JOIN track t2
	ON t1.TrackId = t2.TrackId
JOIN album t3
	ON t2.AlbumId = t3.AlbumId
GROUP BY t3.Title
ORDER BY rev_generated DESC;


-- Sales Trend Over Time
SELECT 
	YEAR(InvoiceDate) rev_year, 
    SUM(Total) total_rev, 
    ROUND((SUM(Total)/(SELECT SUM(Total) FROM invoice)) * 100, 2)
FROM invoice
GROUP BY rev_year;

-- MediaTypes offered in the music store
SELECT * FROM mediatype;
SELECT * FROM track;
SELECT * FROM invoiceline;
SELECT * FROM invoice;
SELECT 
	DISTINCT t2.Name, 
    COUNT(t2.Name) MediaTypesCount,
    ROUND((COUNT(t2.Name)/(SELECT COUNT(*) FROM track)) * 100, 2) percentage
FROM track t1
JOIN mediatype t2
	ON t1.MediaTypeId = t2.MediaTypeId
GROUP BY t2.Name
ORDER BY MediaTypesCount DESC; -- Most files offered in the store are MPEG audio files - Leading by 82%

-- Most sold MediaType and by what percentage
SELECT 
	DISTINCT t3.Name, 
    COUNT(t3.Name) MediaTypesCount,
    ROUND((COUNT(t3.Name)/(SELECT COUNT(*) FROM invoiceline)) * 100, 2) percentage
FROM invoiceline t1
JOIN track t2
	ON t1.TrackId = t2.TrackId
JOIN mediatype t3
	ON t2.MediaTypeId = t3.MediaTypeId
GROUP BY t3.Name
ORDER BY MediaTypesCount DESC; -- MPEG audio files lead in saes by item count

SELECT 
	DISTINCT t3.Name, 
    SUM(t1.UnitPrice) total_rev,
    ROUND((SUM(t1.UnitPrice)/(SELECT SUM(UnitPrice) FROM invoiceline)) * 100, 2) percentage
FROM invoiceline t1
JOIN track t2
	ON t1.TrackId = t2.TrackId
JOIN mediatype t3
	ON t2.MediaTypeId = t3.MediaTypeId
GROUP BY t3.Name
ORDER BY total_rev DESC;
-- Growth over the years
SELECT 
	YEAR(t2.InvoiceDate) `year`,
    t4.Name,
    SUM(t1.UnitPrice) TotalRevYearly,
    RANK() OVER(PARTITION BY YEAR(t2.InvoiceDate) ORDER BY SUM(t1.UnitPrice) DESC) `rank`
FROM invoiceline t1
JOIN invoice t2
	ON t1.InvoiceId = t2.InvoiceId
JOIN track t3
	ON t1.TrackId = t3.TrackId
JOIN mediatype t4
	ON t3.MediaTypeId = t4.MediaTypeId
GROUP BY `year`, t4.Name
ORDER BY `year`, TotalRevYearly DESC;










