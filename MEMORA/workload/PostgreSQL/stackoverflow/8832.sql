
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.TotalBounty,
        RANK() OVER (ORDER BY rp.Score DESC, rp.CommentCount DESC) AS RankScore,
        RANK() OVER (ORDER BY rp.TotalBounty DESC) AS RankBounty
    FROM 
        RankedPosts rp
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.TotalBounty,
    pt.Name AS PostType,
    CASE 
        WHEN tp.RankScore <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS RankingCategory
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
WHERE 
    tp.RankBounty <= 5
ORDER BY 
    tp.RankScore, tp.TotalBounty DESC;
