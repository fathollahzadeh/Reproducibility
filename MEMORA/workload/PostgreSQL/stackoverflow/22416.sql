
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS PostRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews
    FROM UserPostStats
    WHERE TotalPosts > 0
    ORDER BY TotalPosts DESC
    LIMIT 10
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate
),
PostDetails AS (
    SELECT 
        PE.PostId,
        PE.Title,
        PE.CreationDate,
        PE.CommentCount,
        PE.TotalBounty,
        COALESCE(PE.CommentCount, 0) AS ActualCommentCount,
        COALESCE(LT.Name, 'No Link') AS LinkType
    FROM PostEngagement PE
    LEFT JOIN PostLinks PL ON PE.PostId = PL.PostId
    LEFT JOIN LinkTypes LT ON PL.LinkTypeId = LT.Id
),
FinalOutput AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        P.Title AS PostTitle,
        P.CreationDate,
        P.CommentCount,
        P.TotalBounty,
        P.LinkType,
        CASE 
            WHEN P.CommentCount > 10 THEN 'Popular'
            ELSE 'Moderate'
        END AS EngagementLevel
    FROM TopUsers TU
    LEFT JOIN PostDetails P ON TU.UserId = P.PostId
)
SELECT 
    UserId,
    DisplayName,
    PostTitle,
    CreationDate,
    CommentCount,
    TotalBounty,
    LinkType,
    EngagementLevel
FROM FinalOutput
WHERE EngagementLevel = 'Popular' OR (EngagementLevel = 'Moderate' AND TotalBounty > 0)
ORDER BY CreationDate DESC;
