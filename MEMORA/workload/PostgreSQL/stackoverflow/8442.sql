WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(BadgeCount.BadgeCount, 0) AS BadgeCount,
        COALESCE(PostCount.PostCount, 0) AS PostCount,
        COALESCE(CommentCount.CommentCount, 0) AS CommentCount,
        COALESCE(VoteCount.VoteCount, 0) AS VoteCount
    FROM Users U
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) AS BadgeCount ON U.Id = BadgeCount.UserId
    LEFT JOIN (
        SELECT OwnerUserId, COUNT(*) AS PostCount
        FROM Posts
        GROUP BY OwnerUserId
    ) AS PostCount ON U.Id = PostCount.OwnerUserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY UserId
    ) AS CommentCount ON U.Id = CommentCount.UserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY UserId
    ) AS VoteCount ON U.Id = VoteCount.UserId
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        PostCount,
        CommentCount,
        VoteCount,
        RANK() OVER (ORDER BY Reputation DESC, BadgeCount DESC, PostCount DESC) AS Rank
    FROM UserReputation
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.BadgeCount,
    R.PostCount,
    R.CommentCount,
    R.VoteCount,
    R.Rank
FROM RankedUsers R
WHERE R.Rank <= 10
ORDER BY R.Rank;
