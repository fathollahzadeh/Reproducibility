
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        AnswerCount,
        CreationDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS AverageUpVotes,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS AverageDownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.AnswerCount, tp.OwnerDisplayName
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    pt.Name AS PostTypeName,
    MAX(b.Date) AS LastBadgeDate
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON pd.PostId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId)
GROUP BY 
    pd.Title, pd.Score, pd.ViewCount, pd.AnswerCount, pd.CommentCount, pd.OwnerDisplayName, pt.Name
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 10;
