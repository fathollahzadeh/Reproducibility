WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        Tags.TagName,
        COALESCE(MAX(b.Date), '1970-01-01') AS LastBadgeDate,
        ROW_NUMBER() OVER (PARTITION BY Tags.TagName ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Tags ON p.Tags LIKE '%' || Tags.TagName || '%'
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, Tags.TagName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        TagName,
        LastBadgeDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
)

SELECT 
    tp.TagName,
    COUNT(tp.PostId) AS TotalTopPosts,
    AVG(tp.Score) AS AvgScore,
    AVG(tp.ViewCount) AS AvgViewCount,
    AVG(tp.AnswerCount) AS AvgAnswerCount,
    MAX(tp.LastBadgeDate) AS LastBadgeDate
FROM 
    TopPosts tp
GROUP BY 
    tp.TagName
ORDER BY 
    TotalTopPosts DESC;