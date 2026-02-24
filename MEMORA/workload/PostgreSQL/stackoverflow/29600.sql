
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT A.Id) AS AcceptedAnswers,
        SUM(CASE WHEN A.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Posts A ON A.AcceptedAnswerId IS NOT NULL AND A.Id = P.AcceptedAnswerId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
), UserActivity AS (
    SELECT 
        UM.UserId,
        UM.DisplayName,
        UM.Reputation,
        SUM(P.ViewCount) AS TotalViewCount,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT PH.Id) AS TotalPostHistoryEntries
    FROM 
        UserMetrics UM
    LEFT JOIN 
        Posts P ON UM.UserId = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        UM.UserId, UM.DisplayName, UM.Reputation
), Benchmark AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.TotalViewCount,
        UA.TotalScore,
        UA.TotalPostHistoryEntries,
        PT.TagName,
        PT.PostCount
    FROM 
        UserActivity UA
    JOIN 
        PopularTags PT ON UA.Reputation > 1000  
)
SELECT 
    B.UserId,
    B.DisplayName,
    B.Reputation,
    B.TotalViewCount,
    B.TotalScore,
    B.TotalPostHistoryEntries,
    B.TagName AS PopularTag,
    B.PostCount AS RelatedPostCount
FROM 
    Benchmark B
ORDER BY 
    B.TotalScore DESC, B.Reputation DESC
LIMIT 50;
