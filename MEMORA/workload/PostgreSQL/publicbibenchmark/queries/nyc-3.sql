SELECT nyc2.borough AS borough,   nyc2.complaint_type AS complaint_type FROM nyc2 WHERE ((nyc2.borough >= 'BRONX') AND (nyc2.borough <= 'STATEN ISLAND')) GROUP BY nyc2.borough,   nyc2.complaint_type;
