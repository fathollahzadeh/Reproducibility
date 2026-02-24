WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
)

, UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    ph.Id AS PostId,
    ph.Title AS PostTitle,
    ph.Level,
    ub.UserId,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(AVG(vote_count.VoteCount), 0) AS AverageVotes,
    STRING_AGG(DISTINCT c.Text, '; ') AS CommentTexts
FROM 
    PostHierarchy ph
LEFT JOIN 
    Users u ON ph.ParentId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.VoteTypeId IN (2, 3) 
    GROUP BY 
        p.Id
) vote_count ON ph.Id = vote_count.PostId
LEFT JOIN 
    Comments c ON c.PostId = ph.Id
GROUP BY 
    ph.Id, ph.Title, ph.Level, ub.UserId, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    ph.Level, ub.BadgeCount DESC;