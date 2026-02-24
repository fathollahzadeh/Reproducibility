WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    ph.Id AS PostId,
    ph.Title AS PostTitle,
    COALESCE(us.GoldBadges, 0) AS GoldBadges,
    COALESCE(us.SilverBadges, 0) AS SilverBadges,
    COALESCE(us.BronzeBadges, 0) AS BronzeBadges,
    ps.CommentCount,
    ps.AverageBounty,
    vs.UpVotes,
    vs.DownVotes,
    ph.Depth
FROM 
    PostHierarchy ph
LEFT JOIN 
    UserBadges us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.Id)
LEFT JOIN 
    PostStats ps ON ps.PostId = ph.Id
LEFT JOIN 
    VoteSummary vs ON vs.PostId = ph.Id
WHERE 
    ph.Depth <= 5
ORDER BY 
    ph.Depth, ps.CommentCount DESC, vs.UpVotes DESC;