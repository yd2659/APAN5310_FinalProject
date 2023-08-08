-- Top 5 Popular Destinations
SELECT
    a."City" AS "DestinationCity",
    COUNT(DISTINCT fb."BookingID") AS "TotalFlightsBookings"
FROM flight_bookings fb
JOIN flight_info fi ON fb."FlightID" = fi."FlightID"
JOIN airport a ON fi."DestinationAirportCode" = a."AirportCode"
GROUP BY "DestinationCity"
ORDER BY "TotalFlightsBookings" DESC
LIMIT 5;

-- Seasonal Trends in Flight Bookings
WITH SeasonalTrends AS (
    SELECT
        CASE
            WHEN EXTRACT(MONTH FROM fi."DepartureTime") IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM fi."DepartureTime") IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM fi."DepartureTime") IN (9, 10, 11) THEN 'Fall'
            WHEN EXTRACT(MONTH FROM fi."DepartureTime") IN (12, 1, 2) THEN 'Winter'
        END AS "Season",
        COUNT(DISTINCT fb."BookingID") AS "TotalFlightsBookings"
    FROM flight_bookings fb
    JOIN flight_info fi ON fb."FlightID" = fi."FlightID"
    GROUP BY "Season"
)
SELECT
    "Season",
    "TotalFlightsBookings"
FROM SeasonalTrends
ORDER BY "TotalFlightsBookings" DESC;

-- Customer Sentiment Analysis of Reviews Across Airlines
SELECT
    al."AirlineName",
    CASE
        WHEN AVG(fr."Rating") > 6 THEN 'Positive'
        WHEN AVG(fr."Rating") > 4 AND AVG(fr."Rating") <= 6 THEN 'Neutral'
        ELSE 'Negative'
    END AS "Sentiment"
FROM flight_reviews fr
JOIN flight_info fi ON fr."FlightID" = fi."FlightID"
JOIN airline al ON fi."AirlineID" = al."AirlineID"
WHERE al."Country" = 'United States'
GROUP BY al."AirlineName"
ORDER BY AVG(fr."Rating") DESC;


-- Popular Travel Bundles (Flight, Hotel, Car Rental)
WITH TravelBundles AS (
    SELECT
        b."BookingID",
        fi."DestinationAirportCode" AS "Destination",
        hi."HotelName" AS "Hotel",
        ci."CarModel" AS "CarModel"
    FROM bookings b
    JOIN flight_bookings fb ON b."BookingID" = fb."BookingID"
    JOIN flight_info fi ON fb."FlightID" = fi."FlightID"
    JOIN hotel_bookings hb ON b."BookingID" = hb."BookingID"
    JOIN hotel_room hr ON hb."RoomID" = hr."RoomID"
    JOIN hotels_info hi ON hr."HotelID" = hi."HotelID"
    JOIN car_rental_bookings crb ON b."BookingID" = crb."BookingID"
    JOIN cars_info ci ON crb."CarID" = ci."CarID"
)

SELECT
    "Destination",
    "Hotel",
    "CarModel",
    COUNT("BookingID") AS "TotalBundledBookings"
FROM TravelBundles
GROUP BY "Destination", "Hotel", "CarModel"
ORDER BY "TotalBundledBookings" DESC
LIMIT 3;

-- Travel Group
SELECT 
    CASE
        WHEN GroupCounts."Number_of_Members" = 1 THEN 'Alone'
        ELSE 'Together'
    END AS "TravelingStatus",
    COUNT(*) AS "Number_of_Groups"
FROM 
    (
        SELECT 
            "GroupID", 
            COUNT("UserID") AS "Number_of_Members"
        FROM 
            travel_groups
        GROUP BY 
            "GroupID"
    ) AS GroupCounts
GROUP BY 
    "TravelingStatus"
ORDER BY 
    "Number_of_Groups" DESC;

-- Hotel Occupancy Rate
WITH HotelOccupancy AS (
    SELECT
        hi."City",
        hi."HotelName",
        COUNT(hb."RoomID") * 1.0 / COUNT(hr."RoomID") AS "OccupancyRate"
    FROM hotels_info hi
    INNER JOIN hotel_room hr ON hi."HotelID" = hr."HotelID"
    LEFT JOIN hotel_bookings hb ON hr."RoomID" = hb."RoomID"
    GROUP BY hi."City", hi."HotelName"
),
Rankings AS (
    SELECT 
        "City",
        "HotelName",
        "OccupancyRate",
        ROW_NUMBER() OVER (PARTITION BY "City" ORDER BY "OccupancyRate" DESC) AS "Rank"
    FROM HotelOccupancy
)
SELECT 
    "City",
    "HotelName",
    "OccupancyRate"
FROM Rankings
WHERE "Rank" = 1
ORDER BY "OccupancyRate" DESC
LIMIT 5;

-- Average Number of Hotel Bookings per Month
SELECT
    EXTRACT(MONTH FROM "CheckInDate") AS "Month",
    COUNT("BookingID") AS "TotalBookings"
FROM
    hotel_bookings
GROUP BY
    "Month"
ORDER BY
    "TotalBookings" DESC
LIMIT 1;

-- Top 5 Highest Average Ratings Hotel
SELECT
    h."HotelID",
    h."HotelName",
    AVG(hr."Rating") AS AvgRating,
    COUNT(hb."BookingID") AS TotalBookings
FROM
    hotels_info h
INNER JOIN
    hotel_reviews hr ON h."HotelID" = hr."HotelID"
INNER JOIN
    hotel_room hr1 ON h."HotelID" = hr1."HotelID"
INNER JOIN
    hotel_bookings hb ON hr1."RoomID" = hb."RoomID"
GROUP BY
    h."HotelID", h."HotelName"
ORDER BY
    AvgRating DESC
LIMIT 5;

-- top 5 most popular car rental companies
WITH CarRentalCompanyStats AS (
    SELECT crc."CompanyID", crc."CompanyName",
           COUNT(crb."BookingID") AS NumBookings,
           AVG(cr."Rating") AS AvgRating
    FROM car_rental_companies crc
    LEFT JOIN cars_info ci ON crc."CompanyID" = ci."CompanyID"
    LEFT JOIN car_rental_bookings crb ON ci."CarID" = crb."CarID"
    LEFT JOIN car_rental_reviews cr ON ci."CarID" = cr."CarID"
    GROUP BY crc."CompanyID", crc."CompanyName"
),
RankedCarRentalCompanies AS (
    SELECT "CompanyID", "CompanyName", NumBookings, AvgRating,
           ROW_NUMBER() OVER (ORDER BY NumBookings DESC, AvgRating DESC) AS Ranking
    FROM CarRentalCompanyStats
)

SELECT "CompanyID", "CompanyName", NumBookings, AvgRating
FROM RankedCarRentalCompanies
WHERE Ranking <= 5;

-- Top 5 Most Popular Car Model
WITH CarModelCountnRating AS (
    SELECT ci."CarModel", ci."CarManufacture",
           COUNT(crb."BookingID") AS NumBookings,
           AVG(cr."Rating") AS AvgRating
    FROM cars_info ci
    LEFT JOIN car_rental_bookings crb ON ci."CarID" = crb."CarID"
    LEFT JOIN car_rental_reviews cr ON ci."CarID" = cr."CarID"
    GROUP BY ci."CarModel", ci."CarManufacture"
),
RankedCarModelStats AS (
    SELECT "CarModel", "CarManufacture", NumBookings, AvgRating,
           ROW_NUMBER() OVER (ORDER BY NumBookings DESC, AvgRating DESC) AS Ranking
    FROM CarModelCountnRating
)

SELECT "CarModel", "CarManufacture", NumBookings, AvgRating
FROM RankedCarModelStats
WHERE Ranking <= 5;

-- Comparative Analysis of Hotel Booking Prices Based on Flight Cabin Classes
SELECT c."ClassName", AVG(hi."PricePerNight") AS AverageHotelPricePerNight
FROM flight_bookings fb
JOIN flight_info fi ON fb."FlightID" = fi."FlightID"
JOIN seat s ON fb."SeatID"= s."SeatID"
JOIN class c ON s."ClassID" = c."ClassID"
JOIN hotel_bookings hb ON fb."BookingID" = hb."BookingID"
JOIN hotel_room hr ON hb."RoomID" = hr."RoomID"
JOIN hotels_info hi ON hr."HotelID" = hi."HotelID"
GROUP BY c."ClassName";

-- Rental Duration and Revenue per Booking Across Car Rental Companies
WITH CarRentalBookingsWithDuration AS (
        SELECT crb."BookingID", crb."CarID", crb."PickUpDate", crb."DropOffDate", ci."CompanyID",
               (DATE_PART('day', crb."DropOffDate"::TIMESTAMP - crb."PickUpDate"::TIMESTAMP)) AS RentalDuration
        FROM car_rental_bookings crb
        LEFT JOIN cars_info ci ON ci."CarID" = crb."CarID"
    ),
    CarRentalCompanyRevenue AS (
        SELECT ci."CompanyID", crc."CompanyName", COUNT(crbd."BookingID") AS NumBookings, SUM(ci."PricePerDay" * crbd.RentalDuration) AS TotalRevenue
        FROM cars_info ci
        LEFT JOIN car_rental_companies crc ON ci."CompanyID" = crc."CompanyID"
        LEFT JOIN CarRentalBookingsWithDuration crbd ON ci."CarID" = crbd."CarID"
        GROUP BY ci."CompanyID", crc."CompanyName"
    )
    
    SELECT crcr."CompanyID", "CompanyName", ROUND(AVG(RentalDuration)) AS AverageRentalDuration, crcr.NumBookings, crcr.TotalRevenue,
           CASE 
             WHEN NumBookings > 0 THEN TotalRevenue / NumBookings
             ELSE 0 
           END AS AverageRevenuePerBooking
    FROM CarRentalCompanyRevenue crcr
    LEFT JOIN CarRentalBookingsWithDuration crbd ON crcr."CompanyID" = crbd."CompanyID"
    GROUP BY crcr."CompanyID", "CompanyName", NumBookings, TotalRevenue
    ORDER BY AverageRevenuePerBooking DESC;






