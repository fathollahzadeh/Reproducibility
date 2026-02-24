WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(AVG(COALESCE(p.Score, 0)), 0) AS AvgScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        Upvotes,
        Downvotes,
        GoldBadges + SilverBadges + BronzeBadges AS TotalBadges,
        AvgScore,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, Upvotes DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    Upvotes,
    Downvotes,
    TotalBadges,
    AvgScore,
    TotalViews
FROM TopUsers
WHERE UserRank <= 10;