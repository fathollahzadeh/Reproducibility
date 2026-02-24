WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UsersVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    cp.LastCloseDate,
    uv.UpVotes,
    uv.DownVotes,
    uv.TotalBounty,
    rp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UsersVotes uv ON rp.PostId = uv.PostId
WHERE 
    rp.Rank <= 5
    AND rp.Score > 0
    AND (cp.CloseCount IS NULL OR cp.LastCloseDate >= cast('2024-10-01' as date) - INTERVAL '30 days')
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;