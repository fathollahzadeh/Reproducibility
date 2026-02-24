WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
CommentStatistics AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS TotalComments
    FROM Comments c
    GROUP BY c.UserId
),
BadgeStatistics AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ps.TotalPosts,
    ps.Questions,
    ps.Answers,
    cs.TotalComments,
    bs.TotalBadges,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges,
    ur.ReputationRank,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'Expert'
        WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserRank,
    NOT EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.OwnerUserId = ur.UserId AND p.ClosedDate IS NOT NULL
    ) AS HasActivePosts
FROM UserReputation ur
LEFT JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN CommentStatistics cs ON ur.UserId = cs.UserId
LEFT JOIN BadgeStatistics bs ON ur.UserId = bs.UserId
ORDER BY ur.Reputation DESC, ur.DisplayName;
