WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Tags) AS UniqueTags
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
VoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    COALESCE(ps.PostCount, 0) AS TotalPosts,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.UniqueTags, 0) AS UniqueTags,
    COALESCE(vs.Upvotes, 0) AS TotalUpvotes,
    COALESCE(vs.Downvotes, 0) AS TotalDownvotes,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    UserBadges ub
LEFT JOIN 
    PostStats ps ON ub.UserId = ps.OwnerUserId
LEFT JOIN 
    VoteSummary vs ON ub.UserId = vs.UserId
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
