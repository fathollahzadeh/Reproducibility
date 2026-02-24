
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankUser
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND p.Score > 0
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
),
CTE_AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.RankScore,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(cp.LastClosedDate, NULL) AS LastClosedDate,
        COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
        COALESCE(uv.VoteCount, 0) AS TotalVotes,
        COALESCE((uv.UpVotes - uv.DownVotes), 0) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        UserVotes uv ON rp.PostId = uv.UserId
)
SELECT 
    PostId,
    Title,
    Score,
    CreationDate,
    RankScore,
    CommentCount,
    LastClosedDate,
    CloseReasons,
    TotalVotes,
    NetVotes,
    CASE 
        WHEN LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    CTE_AggregatedData
WHERE 
    RankScore <= 5
ORDER BY 
    Score DESC, CreationDate DESC
LIMIT 100;
