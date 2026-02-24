
WITH UserAggregates AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END) AS TotalQuestionViews,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS UsageCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
CommentStatistics AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
),
PostViewStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(CS.CommentCount, 0) AS CommentCount,
        CASE WHEN P.PostTypeId = 1 THEN 'Question' ELSE 'Answer' END AS PostType
    FROM 
        Posts P
    LEFT JOIN 
        CommentStatistics CS ON P.Id = CS.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalQuestionViews,
    UA.TotalPosts,
    UA.TotalAnswers,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    PT.TagName,
    PVS.PostId,
    PVS.Title AS PostTitle,
    PVS.ViewCount AS PostViewCount,
    PVS.CommentCount AS PostCommentCount,
    PVS.PostType
FROM 
    UserAggregates UA
JOIN 
    PopularTags PT ON UA.TotalPosts > 5 
JOIN 
    PostViewStatistics PVS ON PVS.ViewCount > 50 
ORDER BY 
    UA.TotalPosts DESC, UA.TotalQuestionViews DESC, PVS.ViewCount DESC;
