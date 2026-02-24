
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        COALESCE(A.OwnerDisplayName, 'No Accepted Answer') AS AcceptedAnswerOwner,
        P.Score,
        P.ViewCount,
        COUNT(C.ID) AS CommentCount,
        COUNT(H.Id) AS EditHistoryCount,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    WHERE 
        P.CreationDate > DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.AcceptedAnswerId, A.OwnerDisplayName, 
        P.Score, P.ViewCount
),
CombinedStats AS (
    SELECT 
        U.DisplayName AS UserName,
        P.Title AS PostTitle,
        P.CreationDate AS PostCreationDate,
        P.AcceptedAnswerOwner,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.EditHistoryCount,
        U.ReputationRank,
        U.BadgeCount,
        U.UpVotes,
        U.DownVotes
    FROM 
        UserStats U
    INNER JOIN 
        PostDetails P ON U.UserId = P.PostId
)
SELECT 
    UserName,
    PostTitle,
    PostCreationDate,
    AcceptedAnswerOwner,
    Score,
    ViewCount,
    CommentCount,
    EditHistoryCount,
    ReputationRank,
    BadgeCount,
    UpVotes,
    DownVotes
FROM 
    CombinedStats
WHERE 
    (ReputationRank <= 10 OR BadgeCount > 5) 
ORDER BY 
    Score DESC, UserName ASC
FETCH FIRST 50 ROWS ONLY;
