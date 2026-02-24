
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score > 0
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(*) FILTER (WHERE vt.Name = 'UpMod') AS UpvoteCount,
        COUNT(*) FILTER (WHERE vt.Name = 'DownMod') AS DownvoteCount,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pvs.UpvoteCount, 0) AS UpvoteCount,
    COALESCE(pvs.DownvoteCount, 0) AS DownvoteCount,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(cpr.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    ClosedPostReasons cpr ON rp.PostId = cpr.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
