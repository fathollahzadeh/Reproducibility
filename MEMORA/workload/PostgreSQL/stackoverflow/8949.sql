
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount,
        pht.Name AS HistoryTypeName
    FROM 
        RankedPosts rp
    JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAY')
)
SELECT 
    t.OwnerDisplayName, 
    t.Title, 
    t.Score, 
    t.AnswerCount, 
    t.CommentCount, 
    t.HistoryTypeName
FROM 
    TopPosts t
WHERE 
    t.AnswerCount > 0 
ORDER BY 
    t.Score DESC, 
    t.CreationDate DESC
LIMIT 50;
