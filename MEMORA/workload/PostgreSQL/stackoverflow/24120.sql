
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DATE_TRUNC('day', U.LastAccessDate) AS LastActiveDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users)  
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.LastAccessDate
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(A.AgreedCount, 0) AS AgreedCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(VV.UpvoteCount, 0) AS UpvoteCount,
        CTE.UserId 
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS AgreedCount 
        FROM 
            Votes
        WHERE 
            VoteTypeId IN (1, 2) 
        GROUP BY 
            PostId
    ) A ON P.Id = A.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UpvoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) VV ON P.Id = VV.PostId
    JOIN UserActivity CTE ON P.OwnerUserId = CTE.UserId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
),
RankedPosts AS (
    SELECT 
        PS.*, 
        RANK() OVER (PARTITION BY PS.UserId ORDER BY PS.Score DESC) AS ScoreRank
    FROM 
        PostStatistics PS
)
SELECT 
    U.DisplayName,
    U.Reputation,
    R.Title,
    R.Score,
    R.ViewCount,
    R.CommentCount,
    R.AgreedCount,
    R.UpvoteCount,
    R.ScoreRank,
    CASE 
        WHEN R.ScoreRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    UserActivity U
JOIN 
    RankedPosts R ON U.UserId = R.UserId
WHERE 
    R.CommentCount > 5
AND 
    U.LastActiveDate = (
        SELECT MAX(LastActiveDate) 
        FROM UserActivity UA 
        WHERE UA.Reputation > 500 
    )
ORDER BY 
    U.Reputation DESC, R.Score DESC;
