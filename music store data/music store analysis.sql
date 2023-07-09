create database MSDAP;

use MSDAP
go


/* Q1: Who is the senior most employee based on job title? */

select top 1 title, first_name, last_name 
from employee
order by levels desc;


/* Q2: Which countries have the most Invoices? */

select count(*) as count, billing_country
from invoice
group by billing_country
order by count desc


/* Q3: What are top 3 values of total invoice? */

select top 3 total
from invoice
order by total desc;


/* Q4: Which city has the best customers? 
We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select top 1 billing_city, sum(total) as invoice_total
from invoice
group by billing_city, total
order by invoice_total desc;


/* Q5: Who is the best customer? 
The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/



select top 1 customer.customer_id,first_name,last_name,sum(total) as total_spending
from customer
join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id,first_name,last_name
order by total_spending desc;

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select email, first_name, last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in (
	select track_id from track
	join genre on track.genre_id = genre.genre_id
	where genre.name like 'Rock'
)
order by email ;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select top 10 artist.artist_id, artist.name, count(artist.artist_id) as number_of_songs
from track
join album on track.album_id = album.album_id
join artist on album.album_id = artist.artist_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
group by artist.artist_id, artist.name
order by number_of_songs desc;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select * from track

select avg(milliseconds) as avg_track_length
from track

select name, milliseconds 
from track
where milliseconds > 393599
order by milliseconds desc;

		/*	or	*/

select name, milliseconds 
from track
where milliseconds > (
	select avg(milliseconds) as avg_track_length
	from track
)
order by milliseconds desc;

/* Q1: Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist  as (
	select top 1 artist.artist_id as artist_id, artist.name as artist_name, sum(invoice_line.unit_price*invoice_line.quantity) as total_sales
	from invoice_line
	join track on track.track_id = invoice_line.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.artist_id
	group by artist.artist_id, artist.name
	order by total_sales desc
	)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name, sum(il.unit_price*il.quantity) as amount_spend
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa on  bsa.artist_id = alb.artist_id
group by c.customer_id, c.first_name, c.last_name, bsa.artist_name
order by amount_spend desc;


/* Q2: We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

	/* Using CTE */

--
WITH popular_genre AS (
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
		ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY customer.country, genre.name, genre.genre_id
)
SELECT purchases, country, name, genre_id
FROM popular_genre
WHERE RowNo = 1
ORDER BY country ASC;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */
	
	/* Using CTE */

with customer_with_country as 
	(	select top 1 customer.customer_id, first_name, last_name, billing_country, sum(total) as total_spending,
	row_number() over(partition by billing_country order by sum(total) desc) as RowNo
	from invoice
	join customer on customer.customer_id = invoice.customer_id
	group by customer.customer_id, first_name, last_name, billing_country
	order by 4 asc, 5 desc
	)
select * from customer_with_country where RowNo <= 1;











