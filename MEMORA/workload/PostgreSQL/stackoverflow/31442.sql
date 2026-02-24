
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.CommentCount,
        rp.ViewCount,
        rp.PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10 
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(ph.Comment, '; ') AS Comments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    CASE WHEN tp.CommentCount > 0 THEN CONCAT('Comments: ', tp.CommentCount) ELSE 'No Comments' END AS CommentInfo,
    ph.HistoryCount AS HistoryCount,
    ph.Comments AS HistoryComments,
    tp.ViewCount,
    CASE 
        WHEN ph.HistoryCount > 0 THEN 'Has history modifications'
        ELSE 'Original post'
    END AS HistoryStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistories ph ON tp.Id = ph.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
