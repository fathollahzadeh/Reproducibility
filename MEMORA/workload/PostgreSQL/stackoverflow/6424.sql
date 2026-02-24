
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, CreationDate DESC) AS GlobalRanking
    FROM 
        RankedPosts
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.CreationDate,
    trp.Owner,
    trp.CommentCount,
    trp.VoteCount,
    trp.GlobalRanking
FROM 
    TopRankedPosts trp
WHERE 
    trp.OwnerPostRank <= 5
ORDER BY 
    trp.GlobalRanking, trp.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
