-- use music_store_database;


-- SHOW TABLES ;

-- Question Set 1 - Easy
/* 1. Who is the senior most employee based on job title? */

SELECT * 
FROM EMPLOYEE ORDER BY levels DESC LIMIT 1 ;

/*2. Which countries have the most number Invoices? */

SELECT * FROM Invoice ; 

SELECT COUNT(*) , billing_country 
from Invoice group by billing_country order by count(*) desc;



/*3. What are top 3 values of total invoice?*/

SELECT * FROM INVOICE order by total  desc limit 3  ;


/*4. Which city has the best customers? We would like to throw a promotional Music
Festival in the city we made the most money. Write a query that returns one city that
has the highest sum of invoice totals. Return both the city name & sum of all invoice
totals*/

SELECT  billing_city as city , SUM(total) as sum_total
from invoice group by city order by sum_total desc 
limit 1;  


/*5. Who is the best customer? The customer who has spent the most money will be
declared the best customer. Write a query that returns the person who has spent the
most money */

SELECT c.customer_id as custid , c.first_name as fname , SUM(i.total) as totalsum
FROM customer as c join invoice as i on c.customer_id = i.customer_id 
GROUP BY custid , fname ORDER BY totalsum desc;


-- Question Set 2 – Moderate
/*1. Write query to return the email, first name, last name, & Genre of all Rock Music
email, fname ,last name - customer , genre 
listeners. Return your list ordered alphabetically by email starting with A */

SELECT DISTINCT c.email , c.first_name , c.last_name  
from customer as c  join invoice  as i on c.customer_id = i.customer_id 
join invoice_line as il on il.invoice_id = i.invoice_id 
join track as t on t.track_id = il.track_id
where t.track_id IN (SELECT t.track_id 
from track as t join genre as g on g.genre_id  = t.genre_id
where g.name LIKE 'Rock' ) ORDER BY email; 
    


/*2. Let's invite the artists who have written the most rock music in our dataset. Write a
query that returns the Artist name and total track count of the top 10 rock bands*/

SELECT a.name as artist_name, count(g.name) AS rock_count
FROM artist as a  join album  as al on a.artist_id = al.artist_id 
join track as t on t.album_id = al.album_id 
join genre as g on g.genre_id = t.genre_id WHERE g.name LIKE 'Rock'
GROUP BY a.name ORDER BY rock_count desc LIMIT 10; 

/*3. Return all the track names that have a song length longer than the average song length.
Return the Name and Milliseconds for each track. Order by the song length with the
longest songs listed first */

SELECT name , milliseconds 
from track where milliseconds > (SELECT AVG(milliseconds) FROM track ) 
ORDER BY milliseconds desc ;

Question Set 3 – Advance
1. Find how much amount spent by each customer on artists? Write a query to return
customer name, artist name and total spent

SELECT c.first_name , a.name , SUM(il.unit_price*il.quantity) AS totalsum
FROM customer as c  join invoice as i on i.customer_id = c.customer_id 
join invoice_line as il on il.invoice_id = i.invoice_id 
join track as t on t.track_id = il.track_id 
join album as al on t.album_id = al.album_id 
join artist as a on a.artist_id = al.artist_id 
group by c.first_name , a.name ORDER BY totalsum DESC;

SELECT c.first_name, c.last_name, a.name, SUM(il.unit_price * il.quantity) AS total_spent
FROM customer AS c
JOIN invoice AS i ON i.customer_id = c.customer_id
JOIN invoice_line AS il ON il.invoice_id = i.invoice_id
JOIN track AS t ON t.track_id = il.track_id
JOIN album AS al ON t.album_id = al.album_id
JOIN artist AS a ON a.artist_id = al.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, a.artist_id, a.name
ORDER BY total_spent DESC;


/*2. We want to find out how much each customer has spent on the best-selling artist.
We determine the best-selling artist as the artist with the highest total sales. 
Write a query that returns each customer along with the name of the best-selling artist and 
the total amount spent by the customer on this artist. The query should return the customer 
ID, customer first name, customer last name, artist name, and total amount spent, ordered by
the total amount spent in descending order. */


WITH best_selling_artist AS (
    SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM invoice_line
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
    GROUP BY artist.artist_id, artist.name
    ORDER BY total_sales DESC
    LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;

/* 3. We want to find out the most popular music Genre for each country. We determine the
most popular genre as the genre with the highest amount of purchases. Write a query
that returns each country along with the top Genre. For countries where the maximum
number of purchases is shared return all Genres */

WITH popular_genre AS 
(
    SELECT 
        customer.country, 
        genre.name AS genre_name, 
        genre.genre_id, 
        COUNT(invoice_line.quantity) AS purchases,
        DENSE_RANK() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RankNo
    FROM invoice_line 
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY customer.country, genre.name, genre.genre_id
)
SELECT country, genre_name, genre_id, purchases
FROM popular_genre
WHERE RankNo = 1;





/* 4. Write a query that determines the customer that has spent the most on music for each
country. Write a query that returns the country along with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all
customers who spent this amount*/


WITH customer_spent AS (
    SELECT 
        c.customer_id, 
        CONCAT(c.first_name, ' ', c.last_name) AS full_name, 
        c.country, 
        SUM(i.total) AS total_amount_spent,
        DENSE_RANK() OVER (PARTITION BY c.country ORDER BY SUM(i.total) DESC) AS pos  
    FROM 
        customer AS c
    JOIN 
        invoice AS i ON c.customer_id = i.customer_id
    JOIN 
        invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN 
        track AS t ON il.track_id = t.track_id
    GROUP BY 
        c.customer_id, c.first_name, c.last_name, c.country
) 
SELECT 
    customer_id, 
    full_name, 
    country,
    total_amount_spent
FROM 
    customer_spent 
WHERE 
    pos = 1;
