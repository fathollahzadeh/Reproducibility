SELECT
    realestate24.county AS county
FROM
    realestate24
GROUP BY
    realestate24.county
ORDER BY
    county ASC;