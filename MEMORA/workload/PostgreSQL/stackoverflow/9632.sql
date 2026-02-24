WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Score, p.CreationDate
),
EngagedUsers AS (
    SELECT 
        DISTINCT u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ap.PostId,
        ap.Title,
        ap.Score,
        ap.CommentCount,
        ap.UpVoteCount
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    JOIN 
        ActivePosts ap ON u.Id = ap.OwnerUserId
)
SELECT 
    eu.UserId,
    eu.DisplayName,
    eu.BadgeCount,
    COUNT(ap.PostId) AS ActivePostCount,
    AVG(ap.Score) AS AveragePostScore,
    SUM(ap.CommentCount) AS TotalCommentCount,
    SUM(ap.UpVoteCount) AS TotalUpVoteCount
FROM 
    EngagedUsers eu
JOIN 
    ActivePosts ap ON eu.UserId = ap.OwnerUserId
GROUP BY 
    eu.UserId, eu.DisplayName, eu.BadgeCount
ORDER BY 
    TotalUpVoteCount DESC, ActivePostCount DESC
LIMIT 10;