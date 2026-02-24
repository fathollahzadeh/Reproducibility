WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(V.Id) AS TotalVotes 
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
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(PH.EditCount, 0) AS EditCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS EditCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY 
            PostId
    ) PH ON P.Id = PH.PostId
), TopPosts AS (
    SELECT 
        PS.PostId, 
        PS.Title, 
        PS.CreationDate, 
        PS.Score, 
        PS.ViewCount,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS Rank
    FROM 
        PostStats PS
    WHERE 
        PS.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    UPS.UserId, 
    UPS.DisplayName, 
    TP.Title, 
    TP.Score, 
    TP.ViewCount,
    UPS.Upvotes, 
    UPS.Downvotes, 
    TP.Rank
FROM 
    UserVoteSummary UPS
JOIN 
    TopPosts TP ON UPS.TotalVotes > 5
WHERE 
    TP.Rank <= 10
ORDER BY 
    UPS.Upvotes DESC, 
    TP.Score DESC;