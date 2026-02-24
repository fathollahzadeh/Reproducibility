
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
)

SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    us.DisplayName,
    us.TotalBounty,
    us.PostsCreated,
    us.CommentsMade,
    c.CloseReason,
    c.CloseDate
FROM 
    RankedPosts p
LEFT OUTER JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
LEFT JOIN 
    ClosedPostDetails c ON p.Id = c.PostId
WHERE 
    p.Rank <= 5
ORDER BY 
    p.Score DESC, us.TotalBounty DESC, p.CreationDate DESC;
