WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS TotalQuestions,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId, 
        PH.CreationDate AS ClosedDate,
        PH.UserDisplayName AS ClosedBy,
        COALESCE(PH.Comment, 'No Comment') AS CloseReason
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 
),
PostLinksStats AS (
    SELECT 
        PL.PostId,
        COUNT(*) AS RelatedLinksCount
    FROM 
        PostLinks PL
    GROUP BY 
        PL.PostId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.TotalScore,
    US.TotalQuestions,
    US.TotalAnswers,
    CL.CLOSEDPOSTS_COUNT AS ClosedPostCount,
    COALESCE(PL.RelatedLinksCount, 0) AS TotalRelatedLinks,
    US.Rank
FROM 
    UserStats US
LEFT JOIN 
    (SELECT COUNT(*) AS CLOSEDPOSTS_COUNT FROM ClosedPosts) CL ON 1=1
LEFT JOIN 
    PostLinksStats PL ON US.UserId = PL.PostId
WHERE 
    US.TotalPosts > 10
ORDER BY 
    US.TotalScore DESC, US.TotalPosts DESC;