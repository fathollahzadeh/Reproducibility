
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalAnswers, 
        TotalQuestions, 
        TotalUpVotes, 
        TotalDownVotes, 
        AvgReputation,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpvoteRank
    FROM 
        UserActivity
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.TotalPosts, 
    U.TotalAnswers, 
    U.TotalQuestions, 
    U.TotalUpVotes, 
    U.TotalDownVotes, 
    U.AvgReputation,
    B.Name AS BadgeName,
    PH.PostId, 
    PH.CreationDate AS HistoryTimestamp, 
    PH.Comment AS EditComment
FROM 
    TopUsers U
LEFT JOIN 
    Badges B ON U.UserId = B.UserId
LEFT JOIN 
    PostHistory PH ON U.UserId = PH.UserId
WHERE 
    U.TotalPosts > 10 
    AND U.UpvoteRank <= 10 
    AND PH.PostHistoryTypeId IN (24, 10) 
ORDER BY 
    U.UpvoteRank, U.AvgReputation DESC;
