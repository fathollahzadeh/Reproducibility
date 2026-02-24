
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostAggregates AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount, 
        SUM(COALESCE(p.Score, 0)) AS TotalScore, 
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews, 
        AVG(DATE(p.CreationDate) - DATE('2024-10-01')) AS AvgPostAge
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        ru.UserId, 
        ru.DisplayName, 
        pu.PostCount, 
        pu.TotalScore, 
        pu.TotalViews, 
        pu.AvgPostAge, 
        ru.ReputationRank
    FROM RankedUsers ru
    JOIN PostAggregates pu ON ru.UserId = pu.OwnerUserId
),
TopPosters AS (
    SELECT 
        ue.UserId, 
        ue.DisplayName, 
        ue.PostCount, 
        ue.TotalScore, 
        ue.TotalViews, 
        ue.AvgPostAge, 
        ue.ReputationRank
    FROM UserEngagement ue
    WHERE ue.PostCount > 10
    ORDER BY ue.TotalScore DESC
    LIMIT 10
)
SELECT 
    t.UserId, 
    t.DisplayName, 
    t.PostCount, 
    t.TotalScore, 
    t.TotalViews, 
    t.AvgPostAge, 
    t.ReputationRank
FROM TopPosters t
JOIN Badges b ON t.UserId = b.UserId
WHERE b.Class = 1 OR b.Class = 2
ORDER BY t.ReputationRank ASC;
