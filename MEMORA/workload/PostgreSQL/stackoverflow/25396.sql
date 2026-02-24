WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        AVG(V.BountyAmount) AS AverageBounty 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPostStatistics AS (
    SELECT 
        PH.UserId,
        COUNT(DISTINCT PH.PostId) AS TotalClosedPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN PH.PostId END) AS TotalClosedQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN PH.PostId END) AS TotalClosedAnswers,
        COUNT(DISTINCT PH.Comment) AS TotalCloseReasons
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TotalScore,
    US.AverageBounty,
    CPS.TotalClosedPosts,
    CPS.TotalClosedQuestions,
    CPS.TotalClosedAnswers,
    CPS.TotalCloseReasons
FROM 
    UserStatistics US
LEFT JOIN 
    ClosedPostStatistics CPS ON US.UserId = CPS.UserId
ORDER BY 
    US.TotalScore DESC,
    US.TotalPosts DESC;