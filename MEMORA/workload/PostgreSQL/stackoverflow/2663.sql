WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
), PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
), CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Upvotes,
        us.Downvotes,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.AvgViewCount,
        (us.Upvotes - us.Downvotes) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY (us.Upvotes - us.Downvotes) DESC) AS Rank
    FROM UserStats us
    LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Upvotes,
    cs.Downvotes,
    cs.TotalPosts,
    cs.Questions,
    cs.Answers,
    cs.AvgViewCount,
    cs.NetVotes,
    CASE 
        WHEN cs.NetVotes > 100 THEN 'High Impact'
        WHEN cs.NetVotes BETWEEN 50 AND 100 THEN 'Medium Impact'
        ELSE 'Low Impact'
    END AS ImpactLevel
FROM CombinedStats cs
WHERE cs.Rank <= 10
ORDER BY cs.Rank;