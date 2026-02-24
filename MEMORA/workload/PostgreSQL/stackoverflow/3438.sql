
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation >= 1000 
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.RevisionGUID IS NOT NULL THEN 1 ELSE 0 END), 0) AS EditCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.UpVotes,
        UA.DownVotes,
        UA.BadgeCount,
        RANK() OVER (ORDER BY UA.UpVotes DESC) AS VoteRank
    FROM 
        UserActivity UA
)
SELECT 
    RU.DisplayName,
    RU.PostCount,
    RU.UpVotes,
    RU.DownVotes,
    RU.BadgeCount,
    PS.Title,
    PS.CommentCount,
    PS.EditCount
FROM 
    RankedUsers RU
JOIN 
    PostStatistics PS ON RU.UserId = PS.PostId
WHERE 
    RU.VoteRank <= 10 
ORDER BY 
    RU.UpVotes DESC, RU.BadgeCount DESC
LIMIT 5 OFFSET 0;
