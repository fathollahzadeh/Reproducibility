
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN Vote.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN Vote.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes Vote ON U.Id = Vote.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        AVG(P.Score) AS AvgPostScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.BadgeCount,
        U.UpVotesReceived,
        U.DownVotesReceived,
        P.TotalPosts,
        P.Questions,
        P.Answers,
        P.AvgPostScore,
        P.TotalViews
    FROM 
        UserStats U
    JOIN 
        PostStats P ON U.UserId = P.OwnerUserId
)
SELECT 
    C.DisplayName,
    C.Reputation,
    C.BadgeCount,
    C.UpVotesReceived,
    C.DownVotesReceived,
    COALESCE(C.TotalPosts, 0) AS TotalPosts,
    COALESCE(C.Questions, 0) AS TotalQuestions,
    COALESCE(C.Answers, 0) AS TotalAnswers,
    COALESCE(C.AvgPostScore, 0) AS AvgPostScore,
    COALESCE(C.TotalViews, 0) AS TotalViews
FROM 
    CombinedStats C
ORDER BY 
    C.Reputation DESC,
    C.BadgeCount DESC,
    C.UpVotesReceived DESC
LIMIT 100;
