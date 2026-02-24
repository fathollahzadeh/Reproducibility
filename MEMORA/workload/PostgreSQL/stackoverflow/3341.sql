WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPostStats AS (
    SELECT 
        PH.UserId,
        COUNT(DISTINCT PH.PostId) AS TotalClosedPosts,
        STRING_AGG(DISTINCT CT.Name, ', ') AS ClosedReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment = CAST(CT.Id AS VARCHAR)
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        PH.UserId
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.AvgScore,
        COALESCE(CPS.TotalClosedPosts, 0) AS TotalClosedPosts,
        COALESCE(CPS.ClosedReasons, 'None') AS ClosedReasons
    FROM 
        UserStats US
    LEFT JOIN 
        ClosedPostStats CPS ON US.UserId = CPS.UserId
    WHERE 
        US.PostRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.AvgScore,
    TU.TotalClosedPosts,
    TU.ClosedReasons
FROM 
    TopUsers TU
ORDER BY 
    TU.AvgScore DESC,
    TU.TotalPosts DESC;