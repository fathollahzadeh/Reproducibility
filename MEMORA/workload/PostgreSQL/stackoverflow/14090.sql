WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.CreationDate
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
)

SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CreationDate,
    PS.CommentCount,
    PS.VoteCount,
    PS.UpVotes,
    PS.DownVotes,
    US.UserId,
    US.Reputation,
    US.BadgeCount
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostTypeId = U.Id  
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.CreationDate DESC;