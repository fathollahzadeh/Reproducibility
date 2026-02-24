WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT ph.Id) AS HistoryEntryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC, CreationDate DESC) AS PostRank
    FROM 
        PostMetrics
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    rp.HistoryEntryCount,
    pt.Name AS PostTypeName,
    ut.DisplayName AS OwnerDisplayName
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
JOIN 
    Users ut ON rp.PostId = ut.Id
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.PostRank;
