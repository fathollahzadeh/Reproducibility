WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        TotalViews,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY TotalViews DESC, UpVotes - DownVotes DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.UpVotes,
    tu.DownVotes,
    tu.BadgeCount,
    CASE
        WHEN tu.BadgeCount > 5 THEN 'Active Contributor'
        WHEN tu.BadgeCount > 2 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus,
    COALESCE((
        SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM Posts p 
        JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
        WHERE p.OwnerUserId = tu.UserId
    ), 'No Tags') AS MostUsedTags
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
