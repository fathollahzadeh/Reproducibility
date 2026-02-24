WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS EditCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
RankedPosts AS (
    SELECT 
        PS.*,
        RANK() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS PostRank
    FROM 
        PostStatistics PS
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.CommentCount,
    RP.EditCount,
    UV.DisplayName,
    UV.TotalVotes,
    UV.UpVotes,
    UV.DownVotes
FROM 
    RankedPosts RP
JOIN 
    UserVotes UV ON UV.UserId = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = RP.PostId
    )
WHERE 
    RP.PostRank <= 10
ORDER BY 
    RP.PostRank;
