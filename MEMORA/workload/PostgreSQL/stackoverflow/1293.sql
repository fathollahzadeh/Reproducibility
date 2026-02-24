
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(P.ViewCount) AS TotalViews,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),

RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.PostTypeId,
        PT.Name AS PostTypeName,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
    WHERE 
        PH.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalViews,
    UA.TotalBounty,
    PT.TagName,
    RP.CreationDate AS RecentPostDate,
    RP.Title AS RecentPostTitle,
    RP.PostTypeName
FROM 
    UserActivity UA
LEFT JOIN 
    PopularTags PT ON UA.TotalPosts > 5
LEFT JOIN 
    RecentPostHistory RP ON UA.DisplayName = RP.UserDisplayName
WHERE 
    UA.Reputation > 1000
    AND (PT.TagName IS NOT NULL OR RP.rn = 1)
ORDER BY 
    UA.Reputation DESC, UA.TotalPosts DESC;
