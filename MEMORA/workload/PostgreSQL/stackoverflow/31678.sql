WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
FilteredStats AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        TotalBadges,
        Rank
    FROM UserPostStats
    WHERE PostCount > 5
),
UserAverageScore AS (
    SELECT 
        UserId,
        AVG(TotalScore) AS AvgScore
    FROM FilteredStats
    GROUP BY UserId
)
SELECT 
    fs.DisplayName,
    fs.PostCount,
    fs.TotalScore,
    fs.TotalBadges,
    uas.AvgScore,
    CASE 
        WHEN fs.TotalScore > uas.AvgScore THEN 'Above Average'
        WHEN fs.TotalScore < uas.AvgScore THEN 'Below Average'
        ELSE 'Average'
    END AS ScoreComparison
FROM FilteredStats fs
JOIN UserAverageScore uas ON fs.UserId = uas.UserId
ORDER BY fs.PostCount DESC, fs.TotalScore DESC;