
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsPosted,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersPosted,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsMade,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedEngagement AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionsPosted,
        AnswersPosted,
        CommentsMade,
        UpVotesReceived,
        DownVotesReceived,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserEngagement
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionsPosted,
        AnswersPosted,
        CommentsMade,
        UpVotesReceived,
        DownVotesReceived
    FROM 
        RankedEngagement
    WHERE 
        ReputationRank <= 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.QuestionsPosted,
    U.AnswersPosted,
    U.CommentsMade,
    U.UpVotesReceived,
    U.DownVotesReceived,
    CASE 
        WHEN U.UpVotesReceived > U.DownVotesReceived THEN 'Positive'
        WHEN U.UpVotesReceived < U.DownVotesReceived THEN 'Negative'
        ELSE 'Neutral'
    END AS OverallEngagement,
    ARRAY_AGG(DISTINCT PT.Name) AS PostTypesEngaged,
    (
        SELECT 
            STRING_AGG(CONCAT(PH.Comment, ' (', CAST(PH.CreationDate AS DATE), ')'), '; ') 
        FROM 
            PostHistory PH 
        WHERE 
            PH.UserId = U.UserId
            AND PH.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days' 
            AND PH.PostHistoryTypeId IN (10, 11, 12) 
    ) AS RecentPostStatusUpdates
FROM 
    TopUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation, U.QuestionsPosted, U.AnswersPosted, U.CommentsMade, U.UpVotesReceived, U.DownVotesReceived
ORDER BY 
    U.Reputation DESC;
