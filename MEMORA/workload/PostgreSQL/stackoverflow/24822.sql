
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year') 
        AND p.Score IS NOT NULL
),
PostDetail AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.ViewCount,
        COALESCE(pht.Name, 'No History') AS MostRecentHistoryType,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = r.PostId) AS CommentCount,
        (SELECT SUM(v.BountyAmount) FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId IN (8, 9)) AS TotalBountyAmount
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostHistory ph ON r.PostId = ph.PostId 
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        r.Rank <= 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostUser AS (
    SELECT 
        p.Id AS PostId,
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation IS NOT NULL
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.TotalBountyAmount,
    COALESCE(ub.BadgeList, 'No Badges') AS Badges,
    pu.DisplayName AS PostOwner,
    pu.Reputation AS OwnerReputation,
    CASE 
        WHEN pd.TotalBountyAmount IS NULL THEN 'No Bounty'
        ELSE 'Bountied'
    END AS BountyStatus,
    CASE 
        WHEN pd.MostRecentHistoryType LIKE '%Closed%' THEN 'Closed Post'
        WHEN pd.MostRecentHistoryType LIKE '%Deleted%' THEN 'Deleted Post'
        ELSE 'Active Post'
    END AS PostStatus
FROM 
    PostDetail pd
JOIN 
    PostUser pu ON pd.PostId = pu.PostId
LEFT JOIN 
    UserBadges ub ON pu.UserId = ub.UserId
WHERE 
    pd.Score > (
        SELECT AVG(Score) * 0.75 
        FROM Posts 
        WHERE Score IS NOT NULL
    )
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC
LIMIT 50;
