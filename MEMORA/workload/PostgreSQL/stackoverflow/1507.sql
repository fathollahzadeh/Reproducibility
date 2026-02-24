
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    r.UserId,
    r.DisplayName AS UserDisplayName,
    r.Reputation,
    r.BadgeCount,
    COALESCE(cp.CloseCount, 0) AS NumberOfClosures,
    cp.FirstClosedDate,
    CASE 
        WHEN cp.CloseCount IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation r ON r.UserId = rp.OwnerUserId
LEFT JOIN 
    PostComments pc ON pc.PostId = rp.Id
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;
