WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        SUM(COALESCE(B.Class, 0)) AS TotalBadgeClass,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserEngagement AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.Questions,
        U.Answers,
        U.HighViewCountPosts,
        U.TotalBadgeClass,
        U.AvgPostScore,
        RANK() OVER (ORDER BY U.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY U.AvgPostScore DESC) AS ScoreRank
    FROM 
        UserPostStats U
),
UserSummary AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        HighViewCountPosts,
        TotalBadgeClass,
        AvgPostScore,
        PostRank,
        ScoreRank
    FROM 
        UserEngagement
    WHERE 
        TotalPosts > 0
)
SELECT 
    US.DisplayName,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.HighViewCountPosts,
    US.TotalBadgeClass,
    US.AvgPostScore,
    US.PostRank,
    US.ScoreRank,
    string_agg(DISTINCT PT.Name, ', ') AS PostTypeNames,
    COUNT(CM.Id) AS CommentCount
FROM 
    UserSummary US
LEFT JOIN 
    Posts P ON US.UserId = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Comments CM ON P.Id = CM.PostId
GROUP BY 
    US.UserId, US.DisplayName, US.TotalPosts, US.Questions, US.Answers, 
    US.HighViewCountPosts, US.TotalBadgeClass, US.AvgPostScore,
    US.PostRank, US.ScoreRank
ORDER BY 
    US.PostRank, US.ScoreRank;
