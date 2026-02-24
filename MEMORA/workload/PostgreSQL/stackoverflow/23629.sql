
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p 
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId, pt.Name
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS Status
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
),
FilteredPosts AS (
    SELECT 
        rp.*, 
        COALESCE(cp.Status, 'Active') AS CloseStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    fp.Rank,
    fp.CloseStatus,
    CASE
        WHEN fp.CloseStatus = 'Closed' THEN 'This post has been closed.'
        WHEN fp.CloseStatus = 'Reopened' THEN 'This post has been reopened.'
        ELSE 'This post is active.'
    END AS PostStatusMessage
FROM 
    FilteredPosts fp
WHERE 
    (fp.Rank <= 10 OR fp.UpVotes > 50)
    AND (fp.CloseStatus IS NULL OR fp.CloseStatus = 'Active')
ORDER BY 
    fp.Rank, fp.CreationDate DESC
LIMIT 20;
