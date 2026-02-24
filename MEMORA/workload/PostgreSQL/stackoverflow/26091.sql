
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ARRAY_AGG(DISTINCT SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2) ORDER BY SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2)) AS TagsList,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName, U.Reputation
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CommentCount,
        TagsList,
        OwnerDisplayName,
        OwnerReputation,
        RANK() OVER (ORDER BY Score DESC) AS RankScore,
        RANK() OVER (ORDER BY ViewCount DESC) AS RankViews
    FROM 
        PostStats
)
SELECT 
    T.PostId,
    T.Title,
    T.Score,
    T.ViewCount,
    T.CommentCount,
    T.TagsList,
    T.OwnerDisplayName,
    T.OwnerReputation,
    CASE 
        WHEN RankScore <= 10 THEN 'Top Scored'
        ELSE 'Regular'
    END AS ScoreCategory,
    CASE 
        WHEN RankViews <= 10 THEN 'Most Viewed'
        ELSE 'Regular'
    END AS ViewCategory
FROM 
    TopPosts T
WHERE 
    T.RankScore <= 10 OR T.RankViews <= 10
ORDER BY 
    ScoreCategory, ViewCategory;
