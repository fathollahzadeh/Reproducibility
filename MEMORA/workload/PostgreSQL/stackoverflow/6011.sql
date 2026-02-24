WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        PostID, Title, CreationDate, Score, ViewCount, OwnerName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostID = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostID = v.PostId
    GROUP BY 
        tp.PostID, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerName
)
SELECT 
    pd.PostID,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerName,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    ROUND(COALESCE(NULLIF(pd.UpVoteCount, 0), 1) * 100.0 / NULLIF(pd.UpVoteCount + pd.DownVoteCount, 0), 2) AS UpVotePercentage
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;