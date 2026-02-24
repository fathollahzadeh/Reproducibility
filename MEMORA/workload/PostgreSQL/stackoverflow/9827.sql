
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.CreationDate,
        P.Title,
        U.DisplayName AS AuthorName,
        P.ViewCount,
        DENSE_RANK() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.CommentCount,
    UA.UpVotes,
    UA.DownVotes,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount
FROM 
    UserActivity UA
LEFT JOIN 
    RecentPosts RP ON UA.DisplayName = RP.AuthorName
WHERE 
    UA.Rank <= 10 AND 
    (RP.RecentRank IS NULL OR RP.RecentRank <= 5)
ORDER BY 
    UA.Rank, RP.CreationDate DESC;
