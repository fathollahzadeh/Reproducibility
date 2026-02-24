WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
QuestionActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PH.Comment, 'No Close Reason') AS CloseReason,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, PH.Comment
),
TopQuestions AS (
    SELECT 
        Q.PostId,
        Q.Title,
        Q.CreationDate,
        Q.OwnerDisplayName,
        Q.CloseReason,
        Q.TotalVotes,
        Q.UpVotes,
        Q.DownVotes,
        UA.Reputation AS OwnerReputation,
        UA.ReputationRank
    FROM 
        QuestionActivity Q
    JOIN 
        UserActivity UA ON Q.OwnerDisplayName = UA.DisplayName
    WHERE 
        UA.TotalPosts > 5
)
SELECT 
    TQ.Title,
    TQ.CreationDate,
    TQ.OwnerDisplayName,
    TQ.CloseReason,
    TQ.TotalVotes,
    TQ.UpVotes,
    TQ.DownVotes,
    TQ.OwnerReputation,
    TQ.ReputationRank
FROM 
    TopQuestions TQ
WHERE 
    TQ.TotalVotes > 10 AND
    TQ.CloseReason IS NOT NULL
ORDER BY 
    TQ.UpVotes DESC, TQ.OwnerReputation DESC
LIMIT 10;
