
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        U.Id AS OwnerUserId,
        U.CreationDate AS UserCreationDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerReputation,
    US.BadgeCount,
    US.UpVotesCount,
    US.DownVotesCount
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.OwnerUserId = US.UserId
ORDER BY 
    PS.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
