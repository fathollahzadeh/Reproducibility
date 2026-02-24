WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.UserId
),
VoteStats AS (
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
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    COALESCE(cs.CloseCount, 0) AS CloseCount,
    vs.UpVotes,
    vs.DownVotes,
    rp.Rank,
    CASE 
        WHEN rp.ViewCount > 100 THEN 'Popular'
        WHEN rp.ViewCount BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cs ON rp.PostId = cs.PostId
LEFT JOIN 
    VoteStats vs ON rp.PostId = vs.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 10;