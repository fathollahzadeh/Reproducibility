WITH UserStats AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id) AS PostCount,
        (SELECT COUNT(*) FROM Badges WHERE UserId = Users.Id) AS BadgeCount
    FROM 
        Users
),
PostStats AS (
    SELECT 
        Id,
        PostTypeId,
        CreationDate,
        ViewCount,
        Score,
        (SELECT COUNT(*) FROM Comments WHERE PostId = Posts.Id) AS CommentCount
    FROM 
        Posts
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    U.Id AS UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    P.Id AS PostId,
    P.ViewCount,
    P.Score,
    P.CommentCount,
    VS.UpVotes,
    VS.DownVotes,
    (VS.UpVotes - VS.DownVotes) AS NetVotes
FROM 
    UserStats U
JOIN 
    Posts P ON P.OwnerUserId = U.Id
LEFT JOIN 
    VoteStats VS ON VS.PostId = P.Id
ORDER BY 
    U.Reputation DESC, 
    P.ViewCount DESC
LIMIT 100;