WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
), RankedPosts AS (
    SELECT 
        pa.*,
        RANK() OVER (ORDER BY pa.Score DESC, pa.CommentCount DESC) AS RankScore
    FROM 
        PostActivity pa
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastEditDate,
        ph.UserId,
        u.DisplayName AS LastEditedBy,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
        JOIN Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.UserId, u.DisplayName, ph.CreationDate
)
SELECT 
    rp.RankScore,
    rp.Title,
    rp.PostCreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    rph.LastEditDate,
    rph.LastEditedBy,
    rph.EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    rp.RankScore <= 10 
ORDER BY 
    rp.RankScore, rp.PostCreationDate DESC;