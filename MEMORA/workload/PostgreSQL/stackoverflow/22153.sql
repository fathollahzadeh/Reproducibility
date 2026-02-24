
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS integer) = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes - rp.DownVotes AS NetVotes,
        COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Latest Post'
            ELSE 'Older Post'
        END AS PostLabel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    fp.PostId,
    fp.Title AS PostTitle,
    fp.CreationDate,
    fp.Score,
    fp.NetVotes,
    fp.CloseReasons,
    fp.CloseCount,
    CASE 
        WHEN fp.NetVotes < 0 THEN 'Needs Attention'
        WHEN fp.Score > 50 THEN 'Highly Voted'
        ELSE 'Regular Activity'
    END AS PostActivity
FROM 
    FinalPosts fp
WHERE 
    fp.CloseCount = 0 
ORDER BY 
    fp.Score DESC NULLS LAST, 
    fp.CreationDate ASC
FETCH FIRST 20 ROWS ONLY;
