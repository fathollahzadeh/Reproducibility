
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.UserDisplayName, 
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
MostCommentedPosts AS (
    SELECT 
        rp.PostId, 
        COUNT(*) AS TotalComments
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.PostId
    ORDER BY 
        TotalComments DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerName,
    COALESCE(cp.UserDisplayName, 'No closure details') AS ClosureUser,
    cp.Comment AS ClosureReason,
    rp.Rank,
    mc.TotalComments
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    MostCommentedPosts mc ON rp.PostId = mc.PostId
ORDER BY 
    rp.Rank, rp.ViewCount DESC;
