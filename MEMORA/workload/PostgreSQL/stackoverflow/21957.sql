WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ActivityRank AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpvoteCount,
        DownvoteCount,
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC, UpvoteCount DESC, BadgeCount DESC) AS Rank
    FROM 
        UserActivity
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpvoteCount,
        DownvoteCount,
        BadgeCount,
        Rank
    FROM 
        ActivityRank
    WHERE 
        Rank <= 10
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        h.Name AS HistoryTypeName,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    WHERE 
        ph.CreationDate > CAST('2022-01-01' AS timestamp) 
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(PH.RecentHistoryCount, 0) AS RecentHistoryCount,
        (SELECT COUNT(DISTINCT c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.PostId = p.Id AND V.VoteTypeId = 8) AS TotalBounty,
        (SELECT ARRAY_AGG(DISTINCT t.TagName) FROM Tags t WHERE t.ExcerptPostId = p.Id) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId,
            COUNT(*) AS RecentHistoryCount
         FROM 
            PostHistories
         GROUP BY 
            PostId) PH ON p.Id = PH.PostId
    WHERE 
        p.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    ps.Title,
    ps.RecentHistoryCount,
    ps.CommentCount,
    ps.TotalBounty,
    ps.Tags
FROM 
    TopUsers tu
JOIN 
    PostStatistics ps ON tu.UserId = ps.PostId 
WHERE 
    ps.RecentHistoryCount > 0
ORDER BY 
    tu.Reputation DESC, ps.CommentCount DESC;