
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPosts,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.ClosedDate IS NOT NULL
    GROUP BY 
        P.OwnerUserId
),
FinalStats AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalAnswers,
        UPS.TotalQuestions,
        UPS.TotalBountyAmount,
        COALESCE(CPS.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(CPS.CloseReopenCount, 0) AS CloseReopenCount
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        ClosedPostStats CPS ON UPS.UserId = CPS.OwnerUserId
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    TotalBountyAmount,
    ClosedPosts,
    CloseReopenCount,
    CASE 
        WHEN TotalPosts > 100 THEN 'Veteran'
        WHEN TotalPosts > 50 THEN 'Experienced'
        WHEN TotalPosts > 10 THEN 'Novice'
        ELSE 'Newcomer'
    END AS UserStatus
FROM 
    FinalStats
WHERE 
    TotalPosts > 0
ORDER BY 
    TotalBountyAmount DESC, TotalPosts DESC;
