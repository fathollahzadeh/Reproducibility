
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score
), 
RankedPosts AS (
    SELECT 
        pa.*,
        RANK() OVER (ORDER BY pa.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY pa.Upvotes DESC) AS UpvoteRank,
        RANK() OVER (PARTITION BY pa.OwnerUserId ORDER BY pa.Score DESC) AS UserPostRank
    FROM 
        PostAnalytics pa
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    rp.CommentCount,
    rp.CloseReopenCount,
    rp.ScoreRank,
    rp.UpvoteRank,
    rp.UserPostRank
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    (ub.BadgeCount > 5 OR rp.Score > 100) AND
    (u.Reputation >= 1000 OR rp.Upvotes > 50)
ORDER BY 
    ub.BadgeCount DESC, 
    rp.Score DESC;
