WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY Upvotes DESC) AS UpvoteRank
    FROM 
        UserActivity
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounty,
        Upvotes,
        Downvotes,
        TotalViews,
        ViewRank,
        UpvoteRank
    FROM 
        RankedUsers
    WHERE 
        ViewRank <= 10 OR UpvoteRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalBounty,
    tu.Upvotes,
    tu.Downvotes,
    tu.TotalViews,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
               FROM Tags t 
               INNER JOIN Posts p ON t.WikiPostId = p.Id 
               WHERE p.OwnerUserId = tu.UserId), 'No Tags') AS TagsList
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
WHERE 
    b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.TotalBounty, tu.Upvotes, tu.Downvotes, tu.TotalViews
ORDER BY 
    tu.TotalViews DESC, tu.Upvotes DESC;