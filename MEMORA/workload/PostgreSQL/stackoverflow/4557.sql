WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews,
        ROW_NUMBER() OVER (ORDER BY SUM(P.Score) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),

ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),

RankedUsers AS (
    SELECT 
        US.*,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        COALESCE(CP.CloseReasons, 'No Closures') AS CloseReasons
    FROM 
        UserStats US
    LEFT JOIN 
        ClosedPosts CP ON CP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = US.UserId)
)

SELECT 
    R.DisplayName,
    R.TotalPosts,
    R.Questions,
    R.Answers,
    R.TotalScore,
    R.AvgViews,
    R.CloseCount,
    R.CloseReasons
FROM 
    RankedUsers R
WHERE 
    R.Rank <= 10
ORDER BY 
    R.TotalScore DESC;