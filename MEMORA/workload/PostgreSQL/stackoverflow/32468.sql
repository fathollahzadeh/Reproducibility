WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.ParentId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        PostHierarchy PH ON P.ParentId = PH.PostId
)

SELECT 
    U.DisplayName AS UserDisplayName,
    COUNT(DISTINCT PH.PostId) AS TotalQuestions,
    SUM(CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END) AS TotalAcceptedAnswers,
    AVG(P.Score) AS AverageQuestionScore,
    SUM(B.Class) AS TotalGoldBadges,
    MAX(PH.CreationDate) AS MostRecentQuestion,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 25 
LEFT JOIN 
    Badges B ON U.Id = B.UserId AND B.Class = 1 
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, '<>')) AS TagName
    ) T ON TRUE
WHERE 
    U.Reputation > 100
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(DISTINCT PH.PostId) > 5
ORDER BY 
    TotalQuestions DESC;