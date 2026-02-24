
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation, u.CreationDate, u.UpVotes, u.DownVotes
),
PostDetail AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        pt.Name AS PostTypeName,
        p.Tags,
        p.OwnerUserId
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT
    us.UserId,
    us.Reputation,
    us.CreationDate,
    us.PostCount,
    us.CommentCount,
    us.TotalBounty,
    pd.PostId,
    pd.Title,
    pd.CreationDate AS PostCreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount AS PostCommentCount,
    pd.PostTypeName,
    pd.Tags
FROM UserStats us
JOIN PostDetail pd ON us.UserId = pd.OwnerUserId
ORDER BY us.Reputation DESC, pd.ViewCount DESC
LIMIT 100;
