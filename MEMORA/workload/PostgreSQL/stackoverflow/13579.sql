WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalChanges,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (2, 4, 5) THEN 1 ELSE 0 END) AS Edits, 
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS Closures 
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.Questions,
    UPS.Answers,
    UPS.UpvotedPosts,
    UPS.AvgScore,
    PHS.TotalChanges,
    PHS.Edits,
    PHS.Closures
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistoryStats PHS ON UPS.UserId = PHS.UserId
ORDER BY 
    UPS.TotalPosts DESC;