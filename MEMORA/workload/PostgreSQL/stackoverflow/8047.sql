
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        UpvoteCount, 
        DownvoteCount, 
        BadgeCount, 
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, UpvoteCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.UpvoteCount,
    tu.DownvoteCount,
    tu.BadgeCount,
    tu.LastPostDate
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.PostCount DESC, 
    tu.UpvoteCount DESC;
