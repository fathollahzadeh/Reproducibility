
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    LEFT JOIN Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    JOIN Users U ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.ViewCount, U.DisplayName
),

TopQuestions AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.ViewCount,
        RP.CreationDate
    FROM 
        RankedPosts RP
    WHERE 
        RP.ViewRank <= 10 
),

TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(*) AS PostsWithTag,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
)

SELECT 
    T.TagName,
    T.PostsWithTag,
    T.AverageViews,
    COUNT(DISTINCT QQ.PostId) AS RelatedQuestions
FROM 
    TagStatistics T
LEFT JOIN TopQuestions QQ ON QQ.Title ILIKE CONCAT('%', T.TagName, '%')
GROUP BY 
    T.TagName, T.PostsWithTag, T.AverageViews
ORDER BY 
    T.PostsWithTag DESC, T.AverageViews DESC;
