WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY OwnerDisplayName ORDER BY Score DESC) AS OwnerRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    trp.OwnerDisplayName,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.CommentCount,
    trp.AnswerCount
FROM 
    TopRankedPosts trp
WHERE 
    trp.OwnerRank <= 5
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;