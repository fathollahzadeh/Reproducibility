
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        NetVotes,
        ReputationRank
    FROM UserStats
    WHERE ReputationRank <= 10
),
PostAggregate AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
JoinedData AS (
    SELECT 
        t.DisplayName AS TopUser,
        pa.PostCount,
        pa.TotalViews,
        pa.AverageScore,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM TopUsers t
    LEFT JOIN PostAggregate pa ON t.UserId = pa.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) b ON t.UserId = b.UserId
)
SELECT 
    jd.TopUser,
    jd.PostCount,
    jd.TotalViews,
    jd.AverageScore,
    jd.BadgeCount,
    CASE 
        WHEN jd.BadgeCount > 5 THEN 'Expert'
        WHEN jd.BadgeCount BETWEEN 1 AND 5 THEN 'Novice'
        ELSE 'Newbie' 
    END AS UserLevel,
    t.ReputationRank
FROM JoinedData jd
JOIN TopUsers t ON jd.TopUser = t.DisplayName
ORDER BY t.ReputationRank, jd.TotalViews DESC
LIMIT 10;
