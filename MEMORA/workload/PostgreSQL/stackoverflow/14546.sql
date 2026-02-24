WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.LastActivityDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId IN (1, 2)  
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, U.DisplayName, P.CreationDate, P.LastActivityDate
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        OwnerDisplayName, 
        CreationDate, 
        LastActivityDate, 
        CommentCount, 
        AnswerCount,
        RANK() OVER (ORDER BY Score DESC) AS RankByScore,
        RANK() OVER (ORDER BY ViewCount DESC) AS RankByViews
    FROM 
        PostDetails
)

SELECT 
    PostId, 
    Title, 
    ViewCount, 
    Score, 
    OwnerDisplayName, 
    CreationDate, 
    LastActivityDate, 
    CommentCount, 
    AnswerCount,
    RankByScore,
    RankByViews
FROM 
    TopPosts
WHERE 
    RankByScore <= 10 OR RankByViews <= 10
ORDER BY 
    RankByScore, RankByViews;