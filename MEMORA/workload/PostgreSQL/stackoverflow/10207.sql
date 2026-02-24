WITH PostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViewCount,
        SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(PC.PostCount, 0) AS PostCount,
        COALESCE(PC.TotalViewCount, 0) AS TotalViewCount,
        COALESCE(PC.TotalScore, 0) AS TotalScore
    FROM Users U
    LEFT JOIN PostCounts PC ON U.Id = PC.OwnerUserId
)
SELECT 
    Id,
    DisplayName,
    Reputation,
    CreationDate,
    LastAccessDate,
    PostCount,
    TotalViewCount,
    TotalScore
FROM UserStats
ORDER BY Reputation DESC
LIMIT 100;