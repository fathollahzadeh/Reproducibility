WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN P.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.Score,
        RANK() OVER (ORDER BY P.Score DESC) as RankScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    UA.DisplayName,
    UA.UpVoteCount,
    UA.DownVoteCount,
    UA.CommentCount,
    UA.PostCount,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore
FROM 
    UserActivity UA
LEFT JOIN 
    PopularPosts PP ON UA.UserId = PP.OwnerUserId
WHERE 
    (UA.UpVoteCount - UA.DownVoteCount) > 10 
    OR PP.RankScore IS NOT NULL
ORDER BY 
    UA.UpVoteCount DESC, UA.CommentCount DESC
LIMIT 50;