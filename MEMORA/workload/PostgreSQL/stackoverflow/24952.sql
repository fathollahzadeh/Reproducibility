
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes,
        COUNT(*) AS HistoryCount,
        MAX(CASE WHEN ph.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 1 ELSE 0 END) AS IsStale
    FROM 
        PostHistory ph
    INNER JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ua.DisplayName AS Owner,
    ua.TotalBounties,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    phd.PostHistoryTypes,
    phd.HistoryCount,
    CASE 
        WHEN phd.IsStale = 1 THEN 'Stale'
        ELSE 'Fresh'
    END AS Status,
    CASE 
        WHEN rp.CommentCount = 0 THEN 'No Comments'
        ELSE CONCAT(rp.CommentCount, ' Comment(s)')
    END AS CommentSummary
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.PostId DESC;
