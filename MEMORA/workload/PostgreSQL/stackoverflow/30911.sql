
WITH RecursiveUserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        V.VoteTypeId,
        COUNT(V.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, V.VoteTypeId
    HAVING 
        COUNT(V.Id) > 0
),
ActivePosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(AP.AnnualScore, 0) AS AnnualScore,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER(ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM 
        Posts P 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(Score) AS AnnualScore 
         FROM 
            Posts 
         WHERE 
            CreationDate >= CURRENT_DATE - INTERVAL '1 year'
         GROUP BY 
            PostId) AP ON P.Id = AP.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, AP.AnnualScore
),
UserTopVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.UpVotes,
    UP.DownVotes,
    AP.Id AS PostId,
    AP.Title,
    AP.CreationDate,
    AP.ViewCount,
    AP.Score,
    AP.AnnualScore,
    AP.CommentCount,
    UP.UserRank,
    AP.PopularityRank
FROM 
    UserTopVotes UP
JOIN 
    ActivePosts AP ON UP.UserId = AP.Id 
WHERE 
    UP.UserRank <= 10 
    AND AP.PopularityRank <= 50 
ORDER BY 
    UP.UpVotes DESC, AP.ViewCount DESC;
