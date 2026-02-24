
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        u.DisplayName AS OwnerDisplayName, 
        p.CreationDate, 
        p.Score, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 /* Question */
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score
),
MaxScores AS (
    SELECT 
        OwnerDisplayName, 
        MAX(Score) AS MaxScore
    FROM 
        RankedPosts
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.OwnerDisplayName, 
    rp.CreationDate, 
    rp.Score, 
    rp.CommentCount, 
    rp.AnswerCount, 
    ms.MaxScore
FROM 
    RankedPosts rp
JOIN 
    MaxScores ms ON rp.OwnerDisplayName = ms.OwnerDisplayName
WHERE 
    rp.RankByUser = 1 AND
    rp.Score >= ms.MaxScore / 2
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC
FETCH FIRST 10 ROWS ONLY;
