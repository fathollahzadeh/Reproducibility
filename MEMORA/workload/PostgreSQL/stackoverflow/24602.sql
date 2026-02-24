
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score IS NOT NULL 
        AND p.ViewCount > 0
),
ClosedPostHistories AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN ch.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        COALESCE(ch.CloseReasons, 'No Close Reasons') AS CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostHistories ch ON rp.PostId = ch.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.ViewCount,
    FR.Score,
    FR.UpVotes,
    FR.DownVotes,
    FR.PostStatus,
    FR.CloseReasons,
    CONCAT(
        'Post ID: ', FR.PostId,
        ', Title: ', FR.Title,
        ', Status: ', FR.PostStatus
    ) AS PostDescription
FROM 
    FinalResults FR
WHERE 
    FR.ViewCount > (
        SELECT AVG(ViewCount) FROM Posts
    ) 
    AND FR.Score > (
        SELECT AVG(Score) FROM Posts
    )
ORDER BY 
    FR.CreationDate DESC
LIMIT 50;
