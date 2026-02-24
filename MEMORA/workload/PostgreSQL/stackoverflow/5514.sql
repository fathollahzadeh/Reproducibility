
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment = CAST(crt.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    COALESCE(pvc.UpvoteCount, 0) AS UpvoteCount,
    COALESCE(pvc.DownvoteCount, 0) AS DownvoteCount,
    COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReasons
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts pvc ON tp.PostId = pvc.PostId
LEFT JOIN 
    ClosedPosts cp ON tp.PostId = cp.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
