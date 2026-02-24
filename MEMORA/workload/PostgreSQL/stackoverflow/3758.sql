WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        PA.*, 
        R.ReputationRank
    FROM 
        PostAnalysis PA
    JOIN 
        UserReputation R ON PA.AcceptedAnswerId IN (SELECT Id FROM Posts WHERE OwnerUserId = R.UserId)
    ORDER BY 
        PA.Score DESC, R.ReputationRank
    LIMIT 10
)
SELECT 
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.CommentCount,
    TP.UpVotes,
    TP.DownVotes,
    TP.RelatedPostsCount,
    COALESCE(U.DisplayName, 'Unknown') AS AcceptedAnswerer
FROM 
    TopPosts TP
LEFT JOIN 
    Users U ON TP.AcceptedAnswerId = U.Id
WHERE 
    TP.CommentCount > 5
   AND TP.UpVotes - TP.DownVotes > 0
   AND TP.Score >= (SELECT AVG(Score) FROM PostAnalysis)
UNION ALL
SELECT 
    'Average Score' AS Title,
    NULL AS CreationDate,
    AVG(Score) AS Score,
    NULL AS CommentCount,
    NULL AS UpVotes,
    NULL AS DownVotes,
    NULL AS RelatedPostsCount,
    NULL AS AcceptedAnswerer
FROM 
    PostAnalysis
WHERE 
    Score IS NOT NULL;