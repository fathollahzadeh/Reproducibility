WITH PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalPostViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
)
SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.OwnerDisplayName,
    us.UserId,
    us.DisplayName AS UserDisplayName,
    us.Reputation,
    pd.CommentCount,
    pd.VoteCount,
    pd.UpVotes,
    pd.DownVotes,
    us.BadgeCount,
    us.TotalPostViews,
    us.TotalAnswers
FROM
    PostDetails pd
JOIN
    UserStats us ON pd.OwnerUserId = us.UserId
ORDER BY
    pd.CreationDate DESC
LIMIT 100;