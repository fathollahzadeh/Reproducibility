WITH RECURSIVE UserPostCount AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
RecentVotes AS (
    SELECT
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    WHERE
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY
        v.UserId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COALESCE(upc.PostCount, 0) AS PostCount,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        COALESCE(rv.UpVotes, 0) AS UpVoteCount,
        COALESCE(rv.DownVotes, 0) AS DownVoteCount,
        CASE
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
            ELSE 'Expert'
        END AS UserLevel
    FROM
        Users u
    LEFT JOIN UserPostCount upc ON u.Id = upc.UserId
    LEFT JOIN RecentVotes rv ON u.Id = rv.UserId
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.PostCount,
    ur.RecentVoteCount,
    ur.UpVoteCount,
    ur.DownVoteCount,
    ur.UserLevel,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate,
    ps.PostRank
FROM
    UserReputation ur
LEFT JOIN
    PostStats ps ON ur.UserId = ps.OwnerUserId
WHERE
    (ur.Reputation > 0 OR ur.PostCount > 0)
    AND (ps.PostRank IS NULL OR ps.PostRank < 5)  
ORDER BY
    ur.Reputation DESC, ps.CreationDate DESC
LIMIT 50;