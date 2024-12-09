-- Case1: Sipariş Analizi

-- Question 1 :
-- Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır.
select 
(date_trunc('month',order_approved_at))::date as order_month,
count(distinct order_id) as order_dağilimi
from orders
where order_approved_at is not null
group by 1
order by 1

-- 2017 yılı için aylık çıktı:
	
with raw_data as(
select 
	to_char(order_approved_at,'YYYY-MM') as order_month,
	count (order_id) as order_count
from orders
group by order_month)
select * from raw_data 
where order_month between '2016-12-31' and '2017-12-31'

-- Question 2 :
-- Aylık olarak order status kırılımında order sayılarını inceleyiniz.
select
	to_char(order_approved_at,'YYYY-MM') as order_month,
	order_status,
	count(order_id) as siparis_sayisi
from orders
group by 1,2
order by 1

-- Question 3 :
-- Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir? 
select
	to_char(order_approved_at,'YYYY-MM')as order_month,
	t4.product_category_name_english,
	count(t1.order_id) as order_count
from orders as t1
left join order_items as t2
	on t1.order_id=t2.order_id
left join products as t3 
	on t2.product_id=t3.product_id
left join translation as t4
	on t3.product_category_name=t4.product_category_name 
group by 1,2
order by 3 desc

-- önce aylık olarak kategori kırılımlarına baktığımızda; 2017 kasım da bed_bath_table ve furniture_decor kategorilerinde yüksek satış miktarı görüyoruz. 2017 de kasım indirimlerinde bu kategorilere ilgi artmış diyebiliriz.

-- en çok satan kategorilerin computer_accessories, bed_bath_table, health_beauty olduğunu görüyoruz.

-- özel günler için filtreleme yapalım;
with raw_data as (
select
	order_approved_at:: date as order_month,
	t4.product_category_name_english,
	count(t1.order_id) as order_count
from orders as t1
left join order_items as t2
	on t1.order_id=t2.order_id
left join products as t3 
	on t2.product_id=t3.product_id
left join translation as t4
	on t3.product_category_name=t4.product_category_name 
group by 1,2
order by 3 desc)
select
*
from raw_data 
where order_month='2018-02-14'
	
-- 2018 14 şubatta en çok satan 3 kategori:
-- furniture_decor, bed_bath_table,healh_beauty

-- Aynı incelemeyi 2017 14 şubat için yaparsak;

with raw_data as (
select
	order_approved_at:: date as order_month,
	t4.product_category_name_english,
	count(t1.order_id) as order_count
from orders as t1
left join order_items as t2
	on t1.order_id=t2.order_id
left join products as t3 
	on t2.product_id=t3.product_id
left join translation as t4
	on t3.product_category_name=t4.product_category_name 
group by 1,2
order by 3 desc)
select
*
from raw_data 
where order_month='2017-02-14'

-- 2017-02-14 tarihinde satış verisi çok olmamakla beraber en çok satan 2 kategorinin 2018 yılı ile aynı olduğunu görüyoruz. 
-- Yani sevgililer gününde bu iki kategoriye talep artıyor diyebiliriz.

-- Question 4:
-- Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını inceleyiniz. 
SELECT 
    to_char(order_approved_at, 'DAY') AS order_day, 
    COUNT(order_id) AS order_count                  
FROM orders
GROUP BY 1
ORDER BY 2 DESC

-- En çok alışveriş yapılan gün Salı iken en az alışveriş yapılan gün Pazar. Genel olarak hafta içi daha çok alışveriş yapılmakta.

-- haftanın günlerini sıralı yazdırmak istersek;
SELECT 
    to_char(order_approved_at, 'DAY') AS order_day, 
    COUNT(order_id) AS order_count                  
FROM orders
GROUP BY to_char(order_approved_at, 'DAY'), to_char(order_approved_at, 'D')--'D' yi günleri sıralı şekilde listelemek için kullanıyoruz.
ORDER BY to_char(order_approved_at, 'D')::int;  

--Yıllık dağılımları da görmek için;

SELECT 
    to_char(order_approved_at, 'DAY') AS order_day, 
	to_char(order_approved_at,'YYYY') as order_year,
    COUNT(order_id) AS order_count                  
FROM orders
GROUP BY 1,2, to_char(order_approved_at, 'D')--'D' yi günleri sıralı şekilde listelemek için kullanıyoruz.
ORDER BY 2,to_char(order_approved_at, 'D')::int; 

-- Ayın günleri için;
SELECT
	extract(day from order_approved_at) AS order_day,
	count(order_id) AS order_count
FROM orders
GROUP BY 1
ORDER BY 2 DESC

-- En fazla siparişin ayın 24. günü en az siparişin ise ayın 31. günü olduğunu görüyoruz. 
-- Genel olarak baktığımızda ayın ilk haftası ve ay ortasında sonra daha çok sipariş verilmişken ayın son 3 günü siparişin düştüğünü görüyoruz.

-- Case2: Müşteri Analizi
-- Question 1 :
-- Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız.
WITH order_counts AS (
	SELECT 
		t1.customer_id,
		customer_city,
		count(order_id) AS order_count
	FROM orders AS t1
	LEFT JOIN customers AS t2 
	ON t1.customer_id=t2.customer_id
	GROUP BY 1,2
	),-- her müşter, hangi şehirlere kaç sipariş vermiş
	customer_city_rn AS(
	SELECT
		row_number() OVER(PARTITION BY customer_id ORDER BY order_count DESC) AS rn,
		customer_id,
		customer_city
	FROM order_counts
	), -- her müşterinin sipariş verdiği şehirlere row number (rn) atadık. (bu veri setinde her müşteri zaten tek ile sipariş vermiş rn 1 çıktı herkes için)
	customer_city AS(
	SELECT
		customer_id,
		customer_city
	FROM customer_city_rn
	WHERE rn=1
	) -- her müşteri için rn=1 yani sadece en çok sipariş verdiği şehri seçtik.

SELECT
	cc.customer_city,
	count(t1.order_id)
FROM orders AS t1
LEFT JOIN customer_city AS cc 
ON t1.customer_id=cc.customer_id 
GROUP BY 1
ORDER BY 2 desc 

-- Case 3: Satıcı Analizi
-- Question 1:
-- Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız.
with top5 as (
select 
	distinct seller_id,
	avg(age(order_delivered_customer_date,order_purchase_timestamp)) over (partition by seller_id)/count(t1.order_id) over (partition by seller_id) as ort_teslimat_süresi
from orders as t1 
left join order_items as t2 on t1.order_id=t2.order_id
where order_status='delivered'
order by 2
limit 5),
ara_tablo as (
	select
		t1.seller_id,
		count (t1.order_id) as siparis_sayisi,
		avg(review_score) as avg_review_score,
		count(review_comment_message) as total_comment 
	from order_items as t1
	inner join top5 as t2 on t1.seller_id=t2.seller_id
	left join reviews as t3 on t1.order_id=t3.order_id
	group by 1)
select
	t5.seller_id,
	t5.ort_teslimat_süresi,
	t2.siparis_sayisi,
	t2.avg_review_score,
	t2.total_review
from top5 as t5
left join ara_tablo as t2
	on t5.seller_id=t2.seller_id
order by 2

-- Question 2 :
-- -Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır?
--  Fazla kategoriye sahip satıcıların order sayıları da fazla mı? 
SELECT
	t1.seller_id,
	count(DISTINCT t2.product_category_name) AS category_count,
	count(DISTINCT t1.order_id) AS order_count
FROM order_items AS t1
LEFT JOIN products AS t2
ON t1.product_id=t2.product_id
GROUP BY 1
ORDER BY 2 DESC

-- Genel olarak kategori sayısı ne kadar çoksa sipariş sayısı da o ölçüde artar gibi bir çıkarım yapılamayacağını görüyoruz.

-- Case4: Payment Analizi
-- Question 1 :
-- -Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? 
SELECT
	payment_installments,
	t3.customer_city,
	count(DISTINCT t2.customer_id) AS customer_count
FROM payments AS t1
LEFT JOIN orders AS t2 
ON t1.order_id=t2.order_id
LEFT JOIN customers AS t3 
ON t2.customer_id=t3.customer_id
GROUP BY 1,2
ORDER BY 3 DESC, 1 DESC 

-- Question 2 :
-- -Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.
SELECT
	payment_type,
	SUM(CASE WHEN t2.order_status NOT IN ('cancelled','unavailable') THEN t1.payment_value END) AS succ_payment_value,
	--başarılı ödeme tutarı 
	count(DISTINCT t1.order_id) AS order_count --toplam order sayısı
FROM payments AS t1
LEFT JOIN orders AS t2
ON t1.order_id=t2.order_id
GROUP BY 1 

-- Question 3 :
-- -Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?

-- Tek çekim için;
SELECT 
	payment_installments,
	product_category_name_english,
	count(DISTINCT t1.order_id) AS order_count
FROM orders AS t1
LEFT JOIN payments AS t2
	ON t1. order_id=t2.order_id
LEFT JOIN order_items AS t3
	ON t1.order_id=t3.order_id
LEFT JOIN products AS t4
	ON t3.product_id=t4.product_id
LEFT JOIN translation AS t5 
	ON t5.product_category_name=t4.product_category_name
WHERE payment_installments=1
GROUP BY 1,2
ORDER BY 3 DESC

-- Taksitli Satışlar için:
SELECT 
	payment_installments,
	product_category_name_english,
	count(DISTINCT t1.order_id) AS order_count
FROM orders AS t1
LEFT JOIN payments AS t2
	ON t1. order_id=t2.order_id
LEFT JOIN order_items AS t3
	ON t1.order_id=t3.order_id
LEFT JOIN products AS t4
	ON t3.product_id=t4.product_id
LEFT JOIN translation AS t5 
	ON t5.product_category_name=t4.product_category_name
WHERE payment_installments>1
GROUP BY 1,2
ORDER BY 3 DESC, 1 DESC





