
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS UserDisplayName,
        COALESCE(p2.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts p2 ON p.AcceptedAnswerId = p2.Id
    WHERE 
        p.PostTypeId = 1 
),
StringMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS UserDisplayName,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        LENGTH(p.Tags) AS TagLength,
        LENGTH(p.Title) AS TitleLength,
        LENGTH(p.Body) AS BodyLength
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PostBenchmark AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.UserDisplayName,
        sm.TagLength,
        sm.TitleLength,
        sm.BodyLength,
        (sm.TagLength + sm.TitleLength + sm.BodyLength) AS TotalStringLength,
        DENSE_RANK() OVER (ORDER BY (sm.TagLength + sm.TitleLength + sm.BodyLength) DESC) AS DensityRank,
        COUNT(DISTINCT c.Id) AS CommentCount 
    FROM 
        RankedPosts rp
    JOIN 
        StringMetrics sm ON rp.PostId = sm.PostId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.UserDisplayName, 
        sm.TagLength, sm.TitleLength, sm.BodyLength
)
SELECT 
    pb.*,
    CASE 
        WHEN pb.DensityRank <= 10 THEN 'Top 10 Posts by String Length'
        WHEN pb.CommentCount > 50 THEN 'Highly Commented Post'
        ELSE 'Regular Post' 
    END AS PostTypeCategory
FROM 
    PostBenchmark pb
WHERE 
    pb.Score > 0 
ORDER BY 
    pb.ViewCount DESC, pb.Score DESC
FETCH FIRST 20 ROWS ONLY;
