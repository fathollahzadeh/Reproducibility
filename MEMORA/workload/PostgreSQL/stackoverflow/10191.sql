WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END) AS VotesReceived
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.Reputation
),
FinalStats AS (
    SELECT
        ps.PostId,
        ps.PostTypeId,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.VoteCount,
        us.Reputation AS UserReputation,
        us.BadgeCount
    FROM
        PostStats ps
    LEFT JOIN Users u ON ps.PostTypeId = u.Id  
    LEFT JOIN UserStats us ON u.Id = us.UserId
)
SELECT
    PostId,
    PostTypeId,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    UserReputation,
    BadgeCount
FROM
    FinalStats
ORDER BY
    Score DESC, ViewCount DESC;