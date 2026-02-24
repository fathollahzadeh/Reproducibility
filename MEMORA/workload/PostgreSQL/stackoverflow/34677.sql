WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    WHERE 
        P.PostTypeId IN (1, 2) 
), 
UserVoteCounts AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Votes V
    GROUP BY 
        V.UserId
), 
FrequentCommenters AS (
    SELECT 
        C.UserId,
        COUNT(*) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.UserId
    HAVING 
        COUNT(*) > 5
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UVC.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(UVC.DownVotesCount, 0) AS DownVotesCount,
    COALESCE(FC.CommentCount, 0) AS FrequentCommentCount,
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.CreationDate
FROM 
    Users U
LEFT JOIN 
    UserVoteCounts UVC ON U.Id = UVC.UserId
LEFT JOIN 
    FrequentCommenters FC ON U.Id = FC.UserId
LEFT JOIN 
    RankedPosts RP ON RP.RankScore <= 10 
WHERE 
    U.Reputation > 50 
ORDER BY 
    U.Reputation DESC, 
    RP.Score DESC;