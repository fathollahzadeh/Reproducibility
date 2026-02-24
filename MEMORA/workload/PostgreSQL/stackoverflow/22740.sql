
WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users
),
TopQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(A.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
UserVotingStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 8 THEN V.BountyAmount ELSE 0 END), 0) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId 
    GROUP BY 
        U.Id
),
QuestionCloseStats AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UReputation.ReputationCategory,
    TQ.QuestionId,
    TQ.Title AS QuestionTitle,
    TQ.CreationDate AS QuestionDate,
    TQ.Score AS QuestionScore,
    TQ.AnswerCount,
    UVS.TotalUpvotes,
    UVS.TotalDownvotes,
    UVS.TotalBounties,
    QCS.CloseCount,
    QCS.LastCloseDate
FROM 
    Users U
JOIN 
    UserReputation UReputation ON U.Id = UReputation.Id
LEFT JOIN 
    TopQuestions TQ ON TQ.Rank <= 5 AND U.Id = TQ.QuestionId 
LEFT JOIN 
    UserVotingStats UVS ON U.Id = UVS.UserId
LEFT JOIN 
    QuestionCloseStats QCS ON TQ.QuestionId = QCS.PostId
WHERE 
    UReputation.ReputationCategory = 'High' OR 
    (TQ.Score > 10 AND TQ.QuestionId IS NOT NULL)
ORDER BY 
    U.DisplayName ASC, 
    TQ.Score DESC;
