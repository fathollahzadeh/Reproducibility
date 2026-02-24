
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        u.Id AS OwnerUserId,
        u.Reputation AS OwnerReputation,
        u.CreationDate AS UserCreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.Id, u.Reputation, u.CreationDate, u.DisplayName
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(v.BountyAmount) AS TotalBounty
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.OwnerUserId,
    ps.OwnerReputation,
    ps.UserCreationDate,
    ps.OwnerDisplayName,
    us.UserId,
    us.DisplayName AS UserDisplayName,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    us.TotalBounty
FROM
    PostStats ps
JOIN
    UserStats us ON ps.OwnerUserId = us.UserId
ORDER BY
    ps.CreationDate DESC
LIMIT 100;
