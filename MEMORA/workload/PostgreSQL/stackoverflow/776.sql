WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT COALESCE(c.Id, -1)) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        Questions,
        Answers,
        AvgScore,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM UserPostStats
    WHERE PostCount > 0
),
MaxScores AS (
    SELECT 
        UserId,
        MAX(AvgScore) AS MaxAvgScore
    FROM RankedUsers 
    GROUP BY UserId
)
SELECT 
    ru.DisplayName,
    ru.PostCount,
    ru.Questions,
    ru.Answers,
    ru.AvgScore,
    ru.CommentCount,
    ms.MaxAvgScore,
    CASE 
        WHEN ru.AvgScore = ms.MaxAvgScore THEN 'Top Scorer'
        ELSE NULL 
    END AS Status
FROM RankedUsers ru 
LEFT JOIN MaxScores ms ON ru.UserId = ms.UserId
WHERE ru.UserRank <= 10
    OR ms.MaxAvgScore IS NOT NULL
ORDER BY ru.UserRank, ru.AvgScore DESC;
