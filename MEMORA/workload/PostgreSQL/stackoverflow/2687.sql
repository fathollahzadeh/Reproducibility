WITH UserVoteStats AS (
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
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        COALESCE(UPV.TotalVotes, 0) AS OwnerTotalVotes,
        DENSE_RANK() OVER (PARTITION BY P.Id ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        UserVoteStats UPV ON P.OwnerUserId = UPV.UserId
),
CombinedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.OwnerTotalVotes,
        PH.Comment,
        PH.CreationDate AS HistoryDate
    FROM 
        PostStats PS
    LEFT JOIN 
        PostHistory PH ON PS.PostId = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
        AND PH.CreationDate BETWEEN PS.CreationDate AND cast('2024-10-01 12:34:56' as timestamp)
),
FinalResults AS (
    SELECT 
        CP.PostId,
        CP.Title,
        CP.CreationDate,
        CP.Score,
        CP.OwnerTotalVotes,
        COUNT(DISTINCT CP.Comment) AS CommentCount,
        MAX(CP.HistoryDate) AS LastHistoryDate
    FROM 
        CombinedPosts CP
    GROUP BY 
        CP.PostId, CP.Title, CP.CreationDate, CP.Score, CP.OwnerTotalVotes
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.Score,
    FR.OwnerTotalVotes,
    FR.CommentCount,
    CASE 
        WHEN FR.LastHistoryDate IS NOT NULL THEN 'Edited' 
        ELSE 'Not Edited' 
    END AS EditStatus
FROM 
    FinalResults FR
WHERE 
    FR.Score > 0 
ORDER BY 
    FR.Score DESC, FR.CreationDate DESC
LIMIT 10;