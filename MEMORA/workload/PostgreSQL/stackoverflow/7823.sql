WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
    AND 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
FinalRanking AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.CommentCount DESC) AS Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.OwnerDisplayName,
    fr.CommentCount,
    fr.VoteCount
FROM 
    FinalRanking fr
WHERE 
    fr.Rank <= 10  
ORDER BY 
    fr.Rank;