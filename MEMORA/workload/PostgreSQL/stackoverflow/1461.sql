WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpvote
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5'
            WHEN rp.Rank <= 10 THEN 'Top 10'
            ELSE 'Beyond Top 10'
        END AS RankCategory
    FROM 
        RankedPosts rp
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.RankCategory,
    CASE 
        WHEN tp.TotalBounties > 0 THEN 'Has Bounties'
        ELSE 'No Bounties'
    END AS BountyStatus,
    CASE 
        WHEN tp.HasUpvote = 1 THEN 'Upvoted'
        ELSE 'Not Upvoted'
    END AS VoteStatus
FROM 
    TopPosts tp
WHERE 
    tp.Rank < 20
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;