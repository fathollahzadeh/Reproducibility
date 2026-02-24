
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(NULLIF(p.Tags, ''), 'No tags') AS ParsedTags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        cp.CloseReasons,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top Post' 
            ELSE 'Regular Post' 
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.CloseReasons,
    p.CloseCount,
    p.PostCategory,
    CASE 
        WHEN p.CloseCount > 0 THEN 'Previously Closed'
        ELSE 'Never Closed'
    END AS ClosureStatus,
    CONCAT('Post Statistics - ', p.PostCategory) AS StatHeader
FROM 
    PostStats p
WHERE 
    (p.CloseCount > 0 OR p.Score > 10)
ORDER BY 
    p.Score DESC, p.ViewCount DESC, p.Rank ASC;
