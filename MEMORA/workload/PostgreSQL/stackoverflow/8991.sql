
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(UC.VoteCount, 0) AS UserVoteCount,
        COALESCE(UC.UpVotes, 0) AS PostUpVotes,
        COALESCE(UC.DownVotes, 0) AS PostDownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    LEFT JOIN 
        UserVoteCounts UC ON UC.UserId = P.OwnerUserId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, UC.VoteCount, UC.UpVotes, UC.DownVotes
), 
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.UserVoteCount,
    PS.PostUpVotes,
    PS.PostDownVotes,
    PS.CommentCount,
    PS.BadgeCount,
    PHD.EditCount,
    PHD.LastEditDate
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryDetails PHD ON PS.PostId = PHD.PostId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 50;
