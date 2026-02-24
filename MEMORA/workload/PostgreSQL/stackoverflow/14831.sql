WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
AverageStats AS (
    SELECT 
        AVG(Reputation) AS AvgReputation,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(QuestionCount) AS AvgQuestionCount,
        AVG(TotalViews) AS AvgTotalViews,
        AVG(UpVoteCount) AS AvgUpVoteCount,
        AVG(DownVoteCount) AS AvgDownVoteCount,
        AVG(BadgeCount) AS AvgBadgeCount
    FROM 
        UserStats
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.AnswerCount,
    U.QuestionCount,
    U.TotalViews,
    U.UpVoteCount,
    U.DownVoteCount,
    U.BadgeCount,
    A.AvgReputation,
    A.AvgAnswerCount,
    A.AvgQuestionCount,
    A.AvgTotalViews,
    A.AvgUpVoteCount,
    A.AvgDownVoteCount,
    A.AvgBadgeCount
FROM 
    UserStats U
CROSS JOIN 
    AverageStats A
ORDER BY 
    U.Reputation DESC;