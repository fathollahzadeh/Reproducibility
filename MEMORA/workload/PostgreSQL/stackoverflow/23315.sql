
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPostsByOwner,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
ActiveBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 OR b.Class = 2 
    GROUP BY 
        b.UserId
),
LatestVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    WHERE 
        v.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '15 days' 
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerName,
    rp.TotalPostsByOwner,
    COALESCE(ab.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    CASE 
        WHEN lp.VoteTypeId IS NULL THEN 'No Recent Votes'
        WHEN lp.VoteTypeId = 2 THEN 'Upvoted'
        ELSE 'Downvoted'
    END AS RecentVoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ActiveBadges ab ON rp.OwnerUserId = ab.UserId
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    LatestVotes lp ON rp.PostId = lp.PostId AND lp.VoteRank = 1
WHERE 
    rp.OwnerPostRank <= 10 
ORDER BY 
    rp.CreationDate DESC, 
    rp.TotalPostsByOwner DESC
LIMIT 100;
