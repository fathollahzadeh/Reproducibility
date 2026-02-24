
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.Title,
        P.CreationDate,
        COALESCE(PH.EditBodyCount, 0) AS EditCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
            PH.PostId, 
            COUNT(*) AS EditBodyCount 
         FROM 
            PostHistory PH 
         WHERE 
            PH.PostHistoryTypeId IN (5, 24) 
         GROUP BY 
            PH.PostId) PH ON P.Id = PH.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.Title, P.CreationDate, PH.EditBodyCount
),
RankedPosts AS (
    SELECT 
        PD.*, 
        RANK() OVER (ORDER BY PD.Score DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.EditCount,
    RP.CommentCount,
    RP.Rank
FROM 
    UserVoteStats U
JOIN 
    RankedPosts RP ON U.UserId = RP.OwnerUserId
WHERE 
    RP.Rank <= 10
ORDER BY 
    U.UpVotes DESC, RP.Score DESC;
