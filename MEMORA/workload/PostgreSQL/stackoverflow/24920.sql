
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(ch.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 6) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments ch ON p.Id = ch.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score < 0
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        ps.OwnerUserId AS UserId,
        COUNT(DISTINCT ps.Id) AS PostsCreated,
        COALESCE(SUM(ps.ViewCount), 0) AS TotalViews,
        COALESCE(AVG(CASE WHEN ps.Score IS NOT NULL THEN ps.Score ELSE 0 END), 0) AS AvgScore
    FROM 
        Posts ps
    GROUP BY 
        ps.OwnerUserId
),
PostMetrics AS (
    SELECT 
        up.UserId,
        MAX(up.PostsCreated) AS MaxPostsCreated,
        MAX(up.TotalViews) AS MaxTotalViews,
        MAX(up.AvgScore) AS MaxAvgScore,
        us.Reputation,
        us.ReputationRank,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        UserPostStats up
    JOIN 
        UserStats us ON up.UserId = us.UserId
    GROUP BY 
        up.UserId, us.Reputation, us.ReputationRank, us.GoldBadges, us.SilverBadges, us.BronzeBadges
)
SELECT 
    p.UserId,
    COALESCE(c.CommentCount, 0) AS ClosedCommentCount,
    COALESCE(p.MaxPostsCreated, 0) AS MaxPostsCreated,
    COALESCE(p.MaxTotalViews, 0) AS MaxTotalViews,
    COALESCE(p.MaxAvgScore, 0) AS MaxAvgScore,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges
FROM 
    PostMetrics p
LEFT JOIN 
    ClosedPosts c ON p.UserId = c.OwnerUserId
JOIN 
    UserStats us ON p.UserId = us.UserId
WHERE 
    p.MaxPostsCreated > 0 OR us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, ClosedCommentCount DESC;
