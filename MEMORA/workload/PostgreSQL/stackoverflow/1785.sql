WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END), 0) AS DeleteCount
    FROM 
        Users U
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    PS.TotalPosts,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.AvgScore,
    PS.TotalViews,
    UA.CloseCount,
    UA.ReopenCount,
    UA.DeleteCount,
    (CASE 
        WHEN UR.Rank <= 10 THEN 'Top User'
        WHEN UR.Reputation > 5000 THEN 'Expert'
        ELSE 'Regular User' 
    END) AS UserType,
    COALESCE(STRING_AGG(DISTINCT T.TagName, ', '), 'No Tags') AS TagNames
FROM 
    UserReputation UR
LEFT JOIN 
    PostStatistics PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN 
    UserActivity UA ON UA.UserId = UR.UserId
LEFT JOIN 
    Posts P ON P.OwnerUserId = UR.UserId
LEFT JOIN 
    Tags T ON T.ExcerptPostId = P.Id
GROUP BY 
    UR.UserId, UR.DisplayName, UR.Reputation, PS.TotalPosts, PS.TotalQuestions,
    PS.TotalAnswers, PS.AvgScore, PS.TotalViews, UA.CloseCount, UA.ReopenCount, UA.DeleteCount,
    UR.Rank
ORDER BY 
    UR.Reputation DESC;
