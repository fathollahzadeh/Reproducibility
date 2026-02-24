WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        UserRank, 
        BadgeCount
    FROM RankedUsers
    WHERE UserRank <= 10
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.UserId, 
        u.DisplayName, 
        ps.PostCount, 
        ps.TotalScore, 
        ps.AvgViews,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM TopUsers u
    LEFT JOIN PostStats ps ON u.UserId = ps.OwnerUserId
    LEFT JOIN RankedUsers b ON u.UserId = b.UserId
)
SELECT 
    ups.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.AvgViews,
    ups.BadgeCount,
    CASE 
        WHEN ups.BadgeCount > 5 THEN 'Highly Decorated'
        WHEN ups.BadgeCount > 0 THEN 'Moderately Decorated'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN ups.AvgViews > 1000 THEN 'Popular'
        WHEN ups.AvgViews BETWEEN 500 AND 1000 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityGrade
FROM UserPostStats ups
INNER JOIN Votes v ON ups.UserId = v.UserId
WHERE v.VoteTypeId = 2 
AND ups.PostCount > 10
ORDER BY ups.TotalScore DESC, ups.BadgeCount DESC;