WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 
        AND u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY u.Id, u.Reputation
),
PostActivity AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
PostClosures AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS ClosureCount,
        MIN(ph.CreationDate) AS FirstClosureDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.UserId
),
FinalReport AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.BadgeCount,
        pa.TotalPosts,
        pa.Questions,
        pa.Answers,
        pa.AverageScore,
        pc.ClosureCount,
        pc.FirstClosureDate,
        ROW_NUMBER() OVER (PARTITION BY us.Reputation ORDER BY us.Reputation DESC) AS ReputationRank,
        CASE 
            WHEN us.Reputation < 2000 THEN 'Beginner'
            WHEN us.Reputation BETWEEN 2000 AND 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS UserLevel
    FROM UserStats us
    LEFT JOIN PostActivity pa ON us.UserId = pa.OwnerUserId
    LEFT JOIN PostClosures pc ON us.UserId = pc.UserId
)
SELECT 
    fr.UserId,
    fr.Reputation,
    fr.BadgeCount,
    fr.TotalPosts,
    fr.Questions,
    fr.Answers,
    fr.AverageScore,
    fr.ClosureCount,
    fr.FirstClosureDate,
    fr.ReputationRank,
    fr.UserLevel,
    CASE 
        WHEN fr.ClosureCount IS NULL THEN 'No Closures'
        WHEN fr.ClosureCount > 5 THEN 'Frequent Closer'
        ELSE 'Occasional Closer'
    END AS ClosureActivity
FROM FinalReport fr
WHERE fr.ReputationRank <= 10
ORDER BY fr.Reputation DESC, fr.UserLevel;