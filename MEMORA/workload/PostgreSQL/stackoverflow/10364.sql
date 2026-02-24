
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, p.PostTypeId, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(ph.Id) AS HistoryCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
)

SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    us.UserId,
    us.DisplayName AS AuthorDisplayName,
    us.Reputation AS AuthorReputation,
    us.BadgeCount AS AuthorBadgeCount,
    us.HistoryCount AS AuthorHistoryCount
FROM
    PostStats ps
JOIN
    UserStats us ON ps.PostTypeId = 1 AND ps.PostId = us.UserId 
ORDER BY
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100;
