
WITH PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2020-01-01'  
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation
    FROM 
        Users U
)
SELECT 
    P.PostId,
    U.UserId,
    U.Reputation,
    P.PostTypeId,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    P.UpVotes,
    P.DownVotes,
    P.LastEditDate
FROM 
    PostAggregates P
JOIN 
    UserReputation U ON P.PostTypeId = U.UserId  
ORDER BY 
    P.ViewCount DESC, P.Score DESC;
