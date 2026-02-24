
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS CommentsCount,
        AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, P.CreationDate, P.Score
),
RankedTopPosts AS (
    SELECT 
        TP.*,
        RANK() OVER (ORDER BY TP.Score DESC, TP.CommentsCount DESC) AS PostRank
    FROM 
        TopPosts TP
    WHERE 
        TP.Score > 0
)

SELECT 
    U.DisplayName,
    U.Reputation,
    RTP.Title,
    RTP.Score,
    RTP.CommentsCount,
    RTP.PostRank,
    CASE 
        WHEN RTP.PostRank <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    UserReputation U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    RankedTopPosts RTP ON P.Id = RTP.PostId
WHERE 
    U.Reputation >= (SELECT AVG(Reputation) FROM Users)
    AND RTP.PostRank <= 20
ORDER BY 
    U.Reputation DESC, RTP.Score DESC
LIMIT 50;
