
WITH PostActivity AS (
    SELECT
        EXTRACT(YEAR FROM CreationDate) AS Year,
        EXTRACT(MONTH FROM CreationDate) AS Month,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM
        Posts
    WHERE
        CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        EXTRACT(YEAR FROM CreationDate),
        EXTRACT(MONTH FROM CreationDate)
),
UserActivity AS (
    SELECT
        EXTRACT(YEAR FROM CreationDate) AS Year,
        EXTRACT(MONTH FROM CreationDate) AS Month,
        COUNT(DISTINCT Id) AS TotalUsers
    FROM
        Users
    WHERE
        CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        EXTRACT(YEAR FROM CreationDate),
        EXTRACT(MONTH FROM CreationDate)
)
SELECT
    p.Year,
    p.Month,
    p.TotalPosts,
    p.TotalQuestions,
    p.TotalAnswers,
    p.TotalViews,
    p.TotalScore,
    u.TotalUsers
FROM
    PostActivity p
JOIN
    UserActivity u ON p.Year = u.Year AND p.Month = u.Month
ORDER BY
    p.Year DESC, p.Month DESC;
