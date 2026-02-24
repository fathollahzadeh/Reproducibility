WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 5 THEN 1 END) AS Favorites,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END ELSE 0 END) AS VoteBalance
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
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId IN (1, 2)
    GROUP BY 
        P.Id, P.Title
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.AnswerCount,
        PS.TotalScore,
        ROW_NUMBER() OVER (ORDER BY PS.TotalScore DESC) AS Rank
    FROM 
        PostStatistics PS
    WHERE 
        PS.TotalScore > 50
)
SELECT 
    UPC.DisplayName, 
    T.Title, 
    T.CommentCount, 
    T.AnswerCount, 
    T.TotalScore, 
    UPC.UpVotes,
    UPC.DownVotes,
    UPC.VoteBalance,
    DENSE_RANK() OVER (ORDER BY T.TotalScore DESC) AS PostRank
FROM 
    TopPosts T
JOIN 
    UserVoteCounts UPC ON UPC.UserId IN (
        SELECT UserId 
        FROM Votes V 
        WHERE V.PostId = T.PostId AND V.VoteTypeId IN (2, 3)
    )
ORDER BY 
    T.TotalScore DESC, UPC.VoteBalance DESC;
