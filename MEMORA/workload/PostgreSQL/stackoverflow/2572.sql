WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalBounty,
        BadgeCount,
        UserRank
    FROM UserStatistics
    WHERE UserRank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS Upvotes,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
FinalReport AS (
    SELECT 
        tu.DisplayName AS TopUserName,
        pd.Title AS PostTitle,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.Upvotes,
        pd.Downvotes
    FROM TopUsers tu
    JOIN PostDetails pd ON tu.UserId = pd.PostId
    ORDER BY tu.Reputation DESC, pd.Score DESC
)

SELECT * FROM FinalReport
WHERE Upvotes >= 5
EXCEPT 
SELECT 
    TopUserName,
    PostTitle,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    Upvotes,
    Downvotes
FROM FinalReport
WHERE Downvotes > Upvotes
ORDER BY TopUserName, CreationDate DESC;