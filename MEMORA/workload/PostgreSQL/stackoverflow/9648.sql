
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
PopularPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.OwnerUserId, 
        P.Score, 
        P.ViewCount,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.Score, P.ViewCount
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
    LIMIT 10
),
UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName, 
    U.TotalVotes, 
    U.UpVotes, 
    U.DownVotes, 
    PP.Title AS PopularPost, 
    PP.Score, 
    PP.ViewCount, 
    UBC.BadgeCount
FROM 
    UserVoteStats U
JOIN 
    PopularPosts PP ON U.UserId = PP.OwnerUserId
JOIN 
    UserBadgeCounts UBC ON U.UserId = UBC.UserId
WHERE 
    U.TotalVotes > 50
ORDER BY 
    U.TotalVotes DESC, U.UpVotes DESC;
