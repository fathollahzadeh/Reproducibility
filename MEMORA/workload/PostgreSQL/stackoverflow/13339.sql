
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        U.Reputation AS OwnerReputation,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        MAX(P.CreationDate) AS CreationDate,
        MAX(P.LastActivityDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, U.Reputation, P.PostTypeId
),
PostHistoryCount AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.OwnerReputation,
    PS.AnswerCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.BadgeCount,
    COALESCE(PHC.HistoryCount, 0) AS HistoryCount,
    PS.CreationDate,
    PS.LastActivityDate
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryCount PHC ON PS.PostId = PHC.PostId
ORDER BY 
    PS.LastActivityDate DESC;
