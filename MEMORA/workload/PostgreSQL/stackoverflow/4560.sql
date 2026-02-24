WITH BadgeStats AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM Posts
    GROUP BY OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.PositivePosts, 0) AS PositivePosts,
        COALESCE(ps.NegativePosts, 0) AS NegativePosts,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.PositivePosts, 0) DESC) AS PerformanceRank
    FROM Users u
    LEFT JOIN BadgeStats bs ON u.Id = bs.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
TopUsers AS (
    SELECT 
        DisplayName, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges, 
        TotalPosts, 
        PositivePosts, 
        NegativePosts, 
        PerformanceRank
    FROM UserPerformance
    WHERE PerformanceRank <= 10
),
DetailedPostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
)

SELECT 
    tu.DisplayName,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    d.PostId,
    d.Title,
    d.CreationDate,
    d.Score,
    d.ViewCount,
    d.CommentCount,
    d.UpVoteCount,
    d.DownVoteCount
FROM TopUsers tu
JOIN DetailedPostInfo d ON tu.DisplayName = (SELECT OwnerDisplayName FROM Posts WHERE Id = d.PostId)
ORDER BY tu.PerformanceRank, d.Score DESC;
