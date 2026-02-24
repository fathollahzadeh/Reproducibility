
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UpvoterCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
        AND p.Score IS NOT NULL
        AND p.ViewCount > 0
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpvoterCount,
        CASE
            WHEN rp.ScoreRank <= 5 THEN 'Top5'
            WHEN rp.ScoreRank BETWEEN 6 AND 10 THEN 'Top10'
            ELSE 'Others'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5
)
SELECT 
    fp.ScoreCategory,
    COUNT(fp.PostId) AS TotalPosts,
    AVG(fp.Score) AS AvgScore,
    SUM(fp.ViewCount) AS TotalViews,
    SUM(fp.UpvoterCount) AS UniqueUpvoters,
    MAX(fp.Title) AS MostPopularTitle
FROM 
    FilteredPosts fp
GROUP BY 
    fp.ScoreCategory
ORDER BY 
    TotalPosts DESC;

SELECT 
    1 AS Dummy,
    SUM(1) AS DummyCount
FROM 
    Posts
WHERE 
    Score IS NULL;
