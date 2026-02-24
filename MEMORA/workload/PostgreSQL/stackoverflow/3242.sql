
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserActivity
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(CAH.AnswerCount, 0) AS AnswerCount,
        COALESCE(PH.CloseReasonTypes, 'Not Closed') AS CloseReason,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
            ParentId,
            COUNT(*) AS AnswerCount 
         FROM 
            Posts 
         WHERE 
            PostTypeId = 2 
         GROUP BY 
            ParentId) AS CAH ON P.Id = CAH.ParentId
    LEFT JOIN 
        (SELECT 
            PostId,
            STRING_AGG(Comment, ', ') AS CloseReasonTypes
         FROM 
            PostHistory 
         WHERE 
            PostHistoryTypeId = 10 
         GROUP BY 
            PostId) AS PH ON P.Id = PH.PostId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CloseReason
FROM 
    TopUsers TU
JOIN 
    PostDetails PD ON TU.UserId = PD.OwnerUserId
WHERE 
    TU.ViewRank <= 10
ORDER BY 
    TU.Reputation DESC, PD.CreationDate DESC;
