
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
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
        P.OwnerUserId,
        P.Title,
        COUNT(C.CreationDate) AS CommentCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        AVG(P.Score) AS AverageScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rn
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title
),
TopPosts AS (
    SELECT 
        PS.*,
        UVC.DisplayName,
        UVC.Upvotes,
        UVC.Downvotes
    FROM 
        PostStats PS
    JOIN 
        UserVoteCounts UVC ON PS.OwnerUserId = UVC.UserId
    WHERE 
        PS.Rn = 1
)
SELECT 
    TP.Title,
    TP.CommentCount,
    TP.AverageScore,
    COALESCE(TP.Upvotes, 0) AS Upvotes,
    COALESCE(TP.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN TP.AverageScore IS NULL THEN 'No Score'
        WHEN TP.AverageScore > 5 THEN 'High Score'
        WHEN TP.AverageScore BETWEEN 1 AND 5 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
WHERE 
    PH.PostHistoryTypeId NOT IN (12, 10) 
ORDER BY 
    TP.AverageScore DESC,
    TP.CommentCount DESC
LIMIT 10;
