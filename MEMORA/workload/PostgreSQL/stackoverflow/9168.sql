
WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeletionVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 7 THEN 1 ELSE 0 END), 0) AS ReopenVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(MAX(H.CreationDate), P.CreationDate) AS LastActivityDate,
        MAX(CASE WHEN H.PostHistoryTypeId = 12 THEN H.CreationDate END) AS DeletedDate,
        MAX(CASE WHEN H.PostHistoryTypeId = 10 THEN H.CreationDate END) AS ClosedDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.AnswerCount, P.CreationDate
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    P.AnswerCount,
    PS.CommentCount,
    PS.LastActivityDate,
    PS.DeletedDate,
    PS.ClosedDate,
    U.UpVotes,
    U.DownVotes,
    U.DeletionVotes,
    U.ReopenVotes
FROM 
    UserScore U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    PostStats PS ON P.Id = PS.PostId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
