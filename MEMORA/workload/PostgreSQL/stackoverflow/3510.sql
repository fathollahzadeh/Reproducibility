
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBountyAmount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalBountyAmount DESC) AS BountyRank
    FROM 
        UserActivity
),
PostStatistics AS (
    SELECT 
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), 0) AS AcceptedAnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.AcceptedAnswerId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalBountyAmount,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.AcceptedAnswerCount,
    PS.CommentCount,
    COALESCE(PH.Comment, 'No comments available') AS LastEditComment
FROM 
    TopUsers TU
JOIN 
    PostStatistics PS ON TU.UserId = (SELECT OwnerUserId FROM Posts ORDER BY CreationDate DESC LIMIT 1 OFFSET 0)
LEFT JOIN 
    PostHistory PH ON PS.Title = PH.Comment
WHERE 
    TU.PostRank <= 10 OR TU.BountyRank <= 10
ORDER BY 
    TU.TotalPosts DESC, TU.TotalBountyAmount DESC;
