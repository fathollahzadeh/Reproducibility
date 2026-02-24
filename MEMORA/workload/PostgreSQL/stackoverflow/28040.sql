
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS TagRank
    FROM 
        Posts P
        LEFT JOIN Comments C ON C.PostId = P.Id
        LEFT JOIN Posts A ON A.ParentId = P.Id
        JOIN Users U ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Tags, U.DisplayName, P.CreationDate
),

TagPerformance AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CommentCount) AS TotalComments,
        SUM(AnswerCount) AS TotalAnswers,
        COUNT(DISTINCT OwnerDisplayName) AS UniqueAuthors,
        COUNT(*) FILTER (WHERE CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '1 month') AS RecentPosts
    FROM 
        RankedPosts
    GROUP BY 
        Tag
)

SELECT 
    Tag,
    PostCount,
    TotalComments,
    TotalAnswers,
    UniqueAuthors,
    RecentPosts,
    ROUND((TotalComments::numeric / PostCount), 2) AS AvgCommentsPerPost,
    ROUND((TotalAnswers::numeric / PostCount), 2) AS AvgAnswersPerPost
FROM 
    TagPerformance
WHERE 
    PostCount > 10  
ORDER BY 
    RecentPosts DESC, AvgAnswersPerPost DESC;
