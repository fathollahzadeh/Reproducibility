WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CloseReasonTypes.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ON ph.Comment::int = CloseReasonTypes.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.CloseReasons, 'None') AS CloseReasons,
    COALESCE(v.Score, 0) AS VoteScore,
    rp.CreationDate,
    rp.Score AS OriginalScore,
    CASE 
        WHEN rp.Rank = 1 THEN 'Latest Post'
        ELSE 'Previous Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostVotes v ON rp.PostId = v.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC;