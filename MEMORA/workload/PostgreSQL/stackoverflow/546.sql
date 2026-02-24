
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
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
        NetVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserScores
    WHERE 
        Reputation >= 1000
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseVoteCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount END), 0) AS QuestionViews,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN P.ViewCount END), 0) AS AnswerViews,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN CP.CloseVoteCount END), 0) AS ClosedQuestions
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        ClosedPosts CP ON P.Id = CP.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PU.UserId,
    PU.DisplayName,
    PU.QuestionViews,
    PU.AnswerViews,
    PU.ClosedQuestions,
    TU.Reputation,
    TU.ReputationRank
FROM 
    UserPostStats PU
JOIN 
    TopUsers TU ON PU.UserId = TU.UserId
ORDER BY 
    PU.QuestionViews DESC, 
    PU.ClosedQuestions ASC
LIMIT 100;
