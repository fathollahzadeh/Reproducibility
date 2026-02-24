
WITH RECURSIVE UserScore AS (
    SELECT 
        U.Id AS UserId,
        SUM(V.BountyAmount) AS TotalBounty
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
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes, 
        MAX(P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.LastActivityDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
), 
FilteredPostStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.LastActivityDate,
        (PS.UpVotes - PS.DownVotes) AS NetScore
    FROM 
        PostStats PS
    WHERE 
        PS.CommentCount > 0 AND 
        (PS.UpVotes - PS.DownVotes) > 0 
), 
RankedPosts AS (
    SELECT 
        FPS.*,
        RANK() OVER (ORDER BY FPS.NetScore DESC) AS Rank
    FROM 
        FilteredPostStats FPS
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    UPS.TotalBounty,
    RP.PostId,
    RP.Title,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.NetScore,
    RP.Rank
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
JOIN 
    UserScore UPS ON U.Id = UPS.UserId
WHERE 
    U.Reputation > 1000 
ORDER BY 
    RP.Rank;
