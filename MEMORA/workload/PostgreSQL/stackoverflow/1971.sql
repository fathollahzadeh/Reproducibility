
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        u.Reputation AS OwnerReputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerReputation,
    rp.NetVotes,
    rp.CommentCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.Rank <= 5 THEN 'Top 5 Post'
        ELSE 'Other Post'
    END AS PostCategory
FROM 
    RankedPosts rp
WHERE 
    rp.ViewCount > 100
    AND rp.NetVotes > 0
    AND rp.OwnerReputation IS NOT NULL
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
