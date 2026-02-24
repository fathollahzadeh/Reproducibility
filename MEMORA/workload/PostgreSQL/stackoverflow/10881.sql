
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        U.Reputation AS OwnerReputation,
        U.Location AS OwnerLocation,
        U.CreationDate AS OwnerCreationDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, 
        U.Reputation, U.Location, U.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        CommentCount,
        AnswerCount,
        OwnerReputation,
        OwnerLocation,
        OwnerCreationDate,
        DENSE_RANK() OVER (ORDER BY Score DESC) AS RankByScore,
        DENSE_RANK() OVER (ORDER BY ViewCount DESC) AS RankByViews
    FROM 
        PostMetrics
)
SELECT 
    *,
    CASE 
        WHEN RankByScore <= 10 THEN 'Top Score'
        WHEN RankByViews <= 10 THEN 'Top Views'
        ELSE 'Other'
    END AS PerformanceCategory
FROM 
    TopPosts
ORDER BY 
    Score DESC, ViewCount DESC;
