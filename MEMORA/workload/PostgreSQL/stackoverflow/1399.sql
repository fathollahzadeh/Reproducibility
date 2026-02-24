WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN P.AnswerCount > 0 THEN 1 ELSE 0 END), 0) AS AnsweredQuestions,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        DATE_TRUNC('month', U.CreationDate) AS MonthJoined
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, MonthJoined
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        VoteCount,
        AnsweredQuestions,
        CommentCount,
        TotalViews,
        MonthJoined,
        ROW_NUMBER() OVER (PARTITION BY MonthJoined ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY VoteCount DESC) AS VoteRank
    FROM 
        UserActivity
)
SELECT 
    U.DisplayName,
    U.VoteCount,
    U.AnsweredQuestions,
    U.CommentCount,
    U.TotalViews,
    U.MonthJoined,
    COALESCE(AVG(U2.TotalViews), 0) AS AverageViewsInMonth,
    COALESCE(MAX(U2.VoteCount), 0) AS HighestVotesInMonth
FROM 
    RankedUsers U
LEFT JOIN 
    RankedUsers U2 ON U.MonthJoined = U2.MonthJoined AND U.UserId <> U2.UserId
WHERE 
    U.ViewRank <= 5 
GROUP BY 
    U.DisplayName, U.VoteCount, U.AnsweredQuestions, U.CommentCount, U.TotalViews, U.MonthJoined
ORDER BY 
    U.MonthJoined, U.TotalViews DESC;
