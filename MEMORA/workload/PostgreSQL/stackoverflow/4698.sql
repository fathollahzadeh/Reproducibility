
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Author,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'No Reasons') AS CloseReasons,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    LEFT JOIN 
        Votes v ON rp.Id = v.PostId
    GROUP BY 
        rp.Id, rp.Title, rp.Author, cp.CloseCount, cp.CloseReasons
)
SELECT 
    ps.Id,
    ps.Title,
    ps.Author,
    ps.CloseCount,
    ps.CloseReasons,
    ps.UpVotes,
    ps.DownVotes,
    ps.AverageBounty,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostStatistics ps
WHERE 
    ps.CloseCount > 2 OR ps.UpVotes > 10
ORDER BY 
    ps.UpVotes DESC, ps.CloseCount ASC
LIMIT 100;
