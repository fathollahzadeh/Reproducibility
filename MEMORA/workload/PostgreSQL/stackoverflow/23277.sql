WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' AND 
        p.Score IS NOT NULL
),
PostAggregates AS (
    SELECT 
        p.Id,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS CloseReasons,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(pa.CommentCount, 0) AS CommentCount,
        COALESCE(pa.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(pa.DownvoteCount, 0) AS DownvoteCount,
        ch.FirstClosedDate,
        ch.CloseReasons,
        CASE 
            WHEN ch.CloseReasons IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostAggregates pa ON rp.PostId = pa.Id
    LEFT JOIN 
        ClosedPostHistory ch ON rp.PostId = ch.PostId
)
SELECT 
    Title,
    ViewCount,
    Score,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    PostStatus,
    FirstClosedDate,
    CloseReasons
FROM 
    FinalOutput
WHERE 
    PostStatus = 'Closed' OR 
    (PostStatus = 'Active' AND ViewCount > 1000)
ORDER BY 
    Score DESC, 
    ViewCount DESC;