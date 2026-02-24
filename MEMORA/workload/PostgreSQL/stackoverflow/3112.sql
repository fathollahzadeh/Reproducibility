
WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT p2.Id) AS RelatedPosts
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.NetVotes,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(pe.CommentCount, 0) AS CommentCount,
    COALESCE(pe.RelatedPosts, 0) AS RelatedPosts
FROM 
    UserScore us
LEFT JOIN 
    PostEngagement pe ON us.UserId = pe.OwnerUserId
WHERE 
    us.NetVotes > 10 
    AND (us.GoldBadges > 0 OR us.SilverBadges > 2)
ORDER BY 
    us.NetVotes DESC, us.DisplayName ASC
LIMIT 50;
