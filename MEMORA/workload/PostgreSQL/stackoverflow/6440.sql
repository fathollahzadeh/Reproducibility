
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END) AS Deletions
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT COALESCE(B.UserId, -1)) AS BadgeCount,
        MAX(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS IsClosed,
        SUM(CASE WHEN U.DisplayName IS NOT NULL THEN 1 ELSE 0 END) AS ActiveUserCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score
), CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.TotalVotes,
        U.UpVotes,
        U.DownVotes,
        U.Deletions,
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.Score,
        PS.CommentCount,
        PS.BadgeCount,
        PS.IsClosed,
        PS.ActiveUserCount
    FROM 
        UserVotes U
    JOIN 
        PostStats PS ON U.UserId = PS.PostId 
)
SELECT 
    CS.DisplayName,
    CS.TotalVotes,
    CS.UpVotes,
    CS.DownVotes,
    CS.Deletions,
    CS.Title, 
    CS.ViewCount,
    CS.Score,
    CS.CommentCount,
    CASE WHEN CS.IsClosed = 1 THEN 'Closed' ELSE 'Open' END AS PostStatus,
    CS.BadgeCount,
    CS.ActiveUserCount
FROM 
    CombinedStats CS
WHERE 
    CS.TotalVotes > 10
ORDER BY 
    CS.Score DESC, CS.ViewCount DESC;
