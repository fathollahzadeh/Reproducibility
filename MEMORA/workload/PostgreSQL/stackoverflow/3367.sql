
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), 
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), 
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(v.Id) AS VoteCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty,
        MAX(p.CreationDate) AS LatestCreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    rp.Title,
    rp.CommentCount,
    ps.VoteCount,
    ps.AverageBounty,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Most Recent Post'
        ELSE 'Earlier Post'
    END AS PostStatus,
    CASE 
        WHEN ps.LatestCreationDate IS NULL THEN 'No Votes'
        ELSE 'Votes Received'
    END AS VoteStatus
FROM 
    RankedPosts rp
JOIN 
    UserRankings ur ON ur.UserId = rp.PostId
JOIN 
    PostStats ps ON ps.Id = rp.PostId
WHERE 
    ur.Reputation > 1000
ORDER BY 
    ur.Reputation DESC, 
    rp.CommentCount DESC;
