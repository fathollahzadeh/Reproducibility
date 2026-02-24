
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpvotes - TotalDownvotes AS ReputationScore,
        RANK() OVER (ORDER BY TotalUpvotes DESC, TotalDownvotes ASC) AS Rank
    FROM 
        UserActivity
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        ReputationScore
    FROM 
        RankedUsers
    WHERE 
        Rank <= 10
)
SELECT 
    TU.DisplayName,
    TU.ReputationScore,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes,
    COALESCE(AVG(DATE_PART('day', PH.CreationDate - CURRENT_DATE)), 0) AS AvgPostAge,
    CASE 
        WHEN TU.ReputationScore > 1000 THEN 'High Reputation'
        WHEN TU.ReputationScore BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
GROUP BY 
    TU.UserId, TU.DisplayName, TU.ReputationScore
ORDER BY 
    TU.ReputationScore DESC;
