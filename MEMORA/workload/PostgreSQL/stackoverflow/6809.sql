
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS NumberOfComments,
        COUNT(DISTINCT v.Id) AS NumberOfVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Score, u.DisplayName, p.CreationDate
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.OwnerName, 
    rp.NumberOfComments, 
    rp.NumberOfVotes,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top Post'
        WHEN rp.Rank BETWEEN 11 AND 50 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
WHERE 
    rp.NumberOfComments > 5  
ORDER BY 
    rp.Rank;
