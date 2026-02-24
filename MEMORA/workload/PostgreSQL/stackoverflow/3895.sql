
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentsCount,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 10
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, p.Score
), FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentsCount,
        rp.AvgBountyAmount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    COALESCE(fp.CommentsCount, 0) AS CommentsCount,
    COALESCE(fp.AvgBountyAmount, 0) AS AvgBountyAmount,
    CASE 
        WHEN fp.Score >= 100 THEN 'Highly Rated'
        WHEN fp.Score BETWEEN 50 AND 99 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC;
